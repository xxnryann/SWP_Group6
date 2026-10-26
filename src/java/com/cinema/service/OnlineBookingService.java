package com.cinema.service;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.BookingDAO;
import com.cinema.integration.vnpay.VNPayCallback;
import com.cinema.integration.vnpay.VNPayGateway;
import com.cinema.integration.vnpay.VNPayProperties;
import com.cinema.model.Combo;
import com.cinema.model.OnlineBooking;
import com.cinema.model.PointConfig;
import com.cinema.model.SeatCell;
import com.cinema.model.ShowtimeInfo;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * STT 25 — Đặt vé online + thanh toán cho khách hàng (BF-02 / UC12–UC18).
 *
 * <p>Tầng service này là nơi duy nhất quyết định một đơn có hợp lệ hay không:
 * <ul>
 *   <li><b>Ownership</b>: booking phải thuộc {@code customer_id} của người đang
 *       đăng nhập (không tin id gửi lên từ client).</li>
 *   <li><b>Trạng thái</b>: chỉ đơn {@code PendingPayment} mới được áp combo /
 *       voucher / điểm và chuyển sang bước thanh toán.</li>
 *   <li><b>TTL</b> (GBR-01/02): gọi {@code sp_ReleaseExpiredHolds} trước khi đọc
 *       để ghế hết hạn được giải phóng kể cả khi khách đóng trình duyệt.
 *       Procedure này idempotent nên gọi ở mọi lần đọc là an toàn.</li>
 *   <li><b>Đối soát</b>: số tiền cổng thanh toán trả về phải khớp tổng tiền đơn.</li>
 * </ul>
 *
 * <p>Business rule thực sự (điều kiện voucher, trần điểm, tồn kho, cộng/trừ
 * điểm…) nằm trong stored procedure của DB nhóm; service chỉ gọi và chuyển
 * thông báo tiếng Việt cho UI.</p>
 */
public class OnlineBookingService {

    /** Phương thức thanh toán online (Payment.method chỉ cho phép Cash/BankTransfer). */
    private static final String METHOD_ONLINE = "BankTransfer";

    /**
     * Cấu hình quy đổi MyPoint được cache trong bộ nhớ.
     *
     * <p>Bảng {@code MyPointConfig} là cấu hình hệ thống, đổi rất hiếm.
     * Cache giúp bỏ 1 vòng truy vấn DB ở mỗi lần mở màn hình combo/điểm.
     * Cache có <b>TTL</b> nên Manager sửa cấu hình thì vẫn được áp dụng mà
     * không cần restart ứng dụng.</p>
     */
    private static volatile PointConfig cachedPointConfig;

    /** Thời điểm cache {@link #cachedPointConfig} hết hạn (epoch millis). */
    private static volatile long cachedPointConfigExpiresAt;

    /** TTL của cache cấu hình MyPoint (5 phút). */
    private static final long POINT_CONFIG_TTL_MILLIS = 5L * 60L * 1000L;

    /** Khoảng cách tối thiểu giữa 2 lần gọi {@code sp_ReleaseExpiredHolds}. */
    private static final long RELEASE_THROTTLE_MILLIS = 2000L;

    /** Mốc thời gian lần gọi {@code sp_ReleaseExpiredHolds} gần nhất. */
    private static volatile long lastReleaseAt;

    private final BookingDAO bookingDAO;
    private final AccountDAO accountDAO;
    private final DiscountService discountService;
    private final VNPayGateway gateway;

    public OnlineBookingService() {
        this(new BookingDAO(), new AccountDAO(), new DiscountService(),
                new VNPayGateway(VNPayProperties.load()));
    }

    public OnlineBookingService(BookingDAO bookingDAO, AccountDAO accountDAO,
            DiscountService discountService, VNPayGateway gateway) {
        this.bookingDAO = bookingDAO;
        this.accountDAO = accountDAO;
        this.discountService = discountService;
        this.gateway = gateway;
    }

    /* ================= kết quả bước ================= */

    /** Kết quả của một thao tác nghiệp vụ: thành công hay thất bại kèm thông báo. */
    public static class StepResult {
        private final boolean success;
        private final String message;
        private final OnlineBooking booking;
        private final Outcome outcome;

        StepResult(boolean success, String message, OnlineBooking booking) {
            this(success, message, booking, success ? Outcome.SUCCESS : Outcome.FAILED);
        }

        StepResult(boolean success, String message, OnlineBooking booking, Outcome outcome) {
            this.success = success;
            this.message = message;
            this.booking = booking;
            this.outcome = outcome;
        }

        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }

        /** Mã kết quả chi tiết — dùng cho webhook (API-02) trả {@code RspCode}. */
        public Outcome getOutcome() { return outcome; }
    }

    /**
     * Mã kết quả chi tiết của một bước thanh toán.
     *
     * <p>Webhook cần phân biệt "chữ ký sai" (không retry) với "giao dịch không
     * thành công" (đã xử lý xong) — nên không thể dựa vào chuỗi message.</p>
     */
    public enum Outcome {
        /** Thanh toán thành công, vé đã phát hành. */
        SUCCESS,
        /** Chữ ký webhook không hợp lệ — không cập nhật gì, không retry. */
        INVALID_SIGNATURE,
        /** Giao dịch bị từ chối / khách hủy / đơn không còn hiệu lực. */
        FAILED
    }

    /* ================= đọc dữ liệu ================= */

    /**
     * Nhả các đơn đã hết hạn (GBR-01/02). Idempotent.
     *
     * <p><b>Throttle 2 giây:</b> procedure này gồm 3 lệnh UPDATE nên không
     * miễn phí. Mỗi lần mở màn hình trong luồng đặt vé đều đọc đơn, nên
     * gọi liên tục sẽ dồn 3 vòng truy vấn thừa mà không đổi kết quả —
     * ghế hết hạn đã hiện GREEN trong {@code vw_SeatMap} và
     * {@code sp_HoldSeats} tự gọi lại procedure này trước khi giữ ghế
     * (tức là việc giải phóng không phụ thuộc lưu lượng truy cập).</p>
     */
    public void releaseExpiredHolds() {
        long now = System.currentTimeMillis();
        if (now - lastReleaseAt < RELEASE_THROTTLE_MILLIS) {
            return;
        }
        lastReleaseAt = now;
        try {
            bookingDAO.releaseExpiredHolds();
        } catch (SQLException e) {
            // Không chặn luồng: lỗi ở đây chỉ làm chậm việc giải phóng ghế.
            System.err.println("[OnlineBookingService] releaseExpiredHolds lỗi: " + e.getMessage());
        }
    }

    /**
     * Đọc chi tiết đơn của người đang đăng nhập.
     *
     * @param bookingId id đơn
     * @param email email người đang đăng nhập (dùng để kiểm tra ownership)
     * @return đơn, hoặc null nếu không tồn tại / không thuộc người đang đăng nhập
     */
    public OnlineBooking findOwnedBooking(int bookingId, String email) {
        releaseExpiredHolds();
        OnlineBooking booking = findBooking(bookingId);
        if (booking == null || !isOwnedBy(booking, email)) {
            return null;
        }
        return booking;
    }

    /** Đọc chi tiết đơn mà không kiểm tra ownership (dùng cho webhook/return). */
    public OnlineBooking findBooking(int bookingId) {
        try {
            return bookingDAO.findOnlineBooking(bookingId);
        } catch (SQLException e) {
            System.err.println("[OnlineBookingService] findBooking lỗi: " + e.getMessage());
            return null;
        }
    }

    /** Đọc chi tiết đơn theo mã đơn (không kiểm tra ownership). */
    public OnlineBooking findBookingByCode(String bookingCode) {
        try {
            return bookingDAO.findOnlineBookingByCode(bookingCode);
        } catch (SQLException e) {
            System.err.println("[OnlineBookingService] findBookingByCode lỗi: " + e.getMessage());
            return null;
        }
    }

    /** Đơn có thuộc về khách đang đăng nhập hay không. */
    public boolean isOwnedBy(OnlineBooking booking, String email) {
        return booking != null && email != null && !email.trim().isEmpty()
                && email.trim().equalsIgnoreCase(booking.getCustomerEmail());
    }

    /** Sơ đồ ghế của suất chiếu. */
    public List<SeatCell> getSeatMap(int showtimeId) {
        try {
            return bookingDAO.getSeatMap(showtimeId);
        } catch (SQLException e) {
            return List.of();
        }
    }

    /** Thông tin suất chiếu. */
    public ShowtimeInfo getShowtime(int showtimeId) {
        try {
            return bookingDAO.findShowtimeById(showtimeId);
        } catch (SQLException e) {
            return null;
        }
    }

    /** Combo đang bán. */
    public List<Combo> getActiveCombos() {
        try {
            return bookingDAO.findActiveCombos();
        } catch (SQLException e) {
            return List.of();
        }
    }

    /** Cấu hình quy đổi MyPoint (cache trong bộ nhớ, TTL 5 phút). */
    public PointConfig getPointConfig() {
        PointConfig cached = cachedPointConfig;
        if (cached != null && System.currentTimeMillis() < cachedPointConfigExpiresAt) {
            return cached;
        }
        try {
            PointConfig config = bookingDAO.getPointConfig();
            if (config != null) {
                cachedPointConfig = config;
                cachedPointConfigExpiresAt =
                        System.currentTimeMillis() + POINT_CONFIG_TTL_MILLIS;
            }
            return config;
        } catch (SQLException e) {
            return null;
        }
    }

    /** Số dư MyPoint của khách (0 nếu chưa có trong hệ thống nghiệp vụ). */
    public int getPointBalance(int accountId) {
        try {
            long[] balance = accountDAO.findCustomerBalance(accountId);
            return balance == null ? 0 : (int) balance[0];
        } catch (SQLException e) {
            return 0;
        }
    }

    /* ================= bước 1: mở phiên đặt vé ================= */

    /**
     * Mở phiên đặt vé online (15 phút) cho khách đang đăng nhập.
     *
     * @param email email khách (đã đăng nhập)
     * @param showtimeId suất chiếu
     * @return booking_id mới, hoặc 0 nếu không tạo được
     */
    public int createBooking(String email, int showtimeId) {
        int accountId;
        try {
            accountId = accountDAO.findAccountIdByEmail(email);
        } catch (SQLException e) {
            System.err.println("[OnlineBookingService] createBooking lỗi: " + e.getMessage());
            return 0;
        }
        if (accountId <= 0) {
            return 0;
        }
        try {
            return bookingDAO.createOnlineBooking(accountId, showtimeId);
        } catch (SQLException e) {
            return 0;
        }
    }

    /**
     * Giữ ghế đã chọn (chuyển booking sang trạng thái chờ thanh toán).
     *
     * @param bookingId đơn đang mở
     * @param seatIds danh sách id ghế, dạng "41,42"
     */
    public void holdSeats(int bookingId, String seatIds) throws SQLException {
        bookingDAO.holdSeats(bookingId, seatIds);
    }

    /**
     * Hủy đơn đang dở, trả ghế về trạng thái trống.
     */
    public void cancelBooking(int bookingId) {
        try {
            bookingDAO.cancelPendingBooking(bookingId);
        } catch (SQLException e) {
            System.err.println("[OnlineBookingService] cancelBooking lỗi: " + e.getMessage());
        }
    }

    /* ================= bước 2: combo → voucher → MyPoint ================= */

    /**
     * Thêm/bỏ combo của đơn.
     *
     * @param bookingId đơn
     * @param comboId combo
     * @param quantity số lượng (0 để bỏ)
     */
    public void updateCombo(int bookingId, int comboId, int quantity) throws SQLException {
        bookingDAO.addCombo(bookingId, comboId, quantity);
    }

    /**
     * Áp voucher rồi MyPoint theo đúng thứ tự nghiệp vụ (voucher trước, điểm sau —
     * vì áp voucher sẽ reset điểm đã dùng).
     *
     * @param bookingId đơn
     * @param voucherCode mã voucher (có thể rỗng)
     * @param points số điểm dùng
     * @return kết quả kèm thông báo tiếng Việt
     */
    public StepResult applyExtras(int bookingId, String voucherCode, int points) {
        DiscountResult result = discountService.applyDiscounts(bookingId, voucherCode, points);
        boolean ok = result.getTotal() != null;
        return new StepResult(ok, result.getMessage(),
                ok ? findBooking(bookingId) : null);
    }

    /* ================= bước 3: thanh toán ================= */

    /**
     * Dựng URL thanh toán của cổng.
     *
     * @param booking đơn cần thanh toán
     * @param clientIp IP khách hàng
     * @param contextPath context path ứng dụng
     * @param returnUrl URL cổng chuyển khách về
     * @return URL thanh toán đã ký
     */
    public String buildPaymentUrl(OnlineBooking booking, String clientIp,
            String contextPath, String returnUrl) {
        String orderInfo = "Thanh toan ve " + booking.getBookingCode();
        return gateway.buildPaymentUrl(booking.getBookingCode(),
                booking.getTotalAmount(), orderInfo, clientIp, returnUrl, contextPath);
    }

    /**
     * Xác nhận kết quả thanh toán từ cổng (Return URL hoặc IPN).
     *
     * <p>Luồng: kiểm tra chữ ký → đối soát số tiền → {@code sp_ConfirmPayment}.
     * Hàm này idempotent: gọi lại với cùng giao dịch không phát vé 2 lần
     * (procedure chỉ chạy khi booking còn {@code PendingPayment}).</p>
     *
     * @param params tham số cổng trả về
     * @return kết quả xác nhận
     */
    public StepResult confirmGatewayPayment(Map<String, String> params) {
        VNPayCallback callback = gateway.parseCallback(params);
        if (callback == null) {
            return new StepResult(false,
                    "Chữ ký giao dịch không hợp lệ. Thanh toán không được ghi nhận.", null,
                    Outcome.INVALID_SIGNATURE);
        }
        if (!callback.isSuccess()) {
            cancelGatewayPayment(callback.getTxnRef(),
                    "Khách hàng huỷ giao dịch trên cổng thanh toán.");
            return new StepResult(false,
                    "Thanh toán không thành công. Đơn hàng đã được huỷ và ghế đã được giải phóng.", null,
                    Outcome.FAILED);
        }
        return confirmGatewayPayment(callback.getTxnRef(), callback.getTransactionNo(),
                callback.getAmount());
    }

    /**
     * Xác nhận thanh toán theo mã đơn + mã giao dịch + số tiền.
     *
     * @param txnRef mã đơn (booking_code)
     * @param gatewayTxnId mã giao dịch cổng thanh toán
     * @param amount số tiền cổng báo (đơn vị tiền)
     */
    public StepResult confirmGatewayPayment(String txnRef, String gatewayTxnId, BigDecimal amount) {
        if (txnRef == null || txnRef.trim().isEmpty()) {
            return new StepResult(false, "Thiếu mã đơn hàng trong kết quả thanh toán.", null);
        }
        releaseExpiredHolds();
        // Một lần đọc duy nhất: tra theo mã đơn + lấy chi tiết trong cùng
        // connection (tránh 2 vòng truy vấn cho cùng một đơn).
        OnlineBooking booking = findBookingByCode(txnRef);
        if (booking == null) {
            return new StepResult(false, "Không tìm thấy đơn hàng " + txnRef + ".", null);
        }
        int bookingId = booking.getBookingId();
        if (!"PendingPayment".equals(booking.getStatus())) {
            // Đơn đã hết hạn hoặc đã thanh toán trước đó → không phát vé lần 2.
            // Đơn đã trả tiền vẫn trả về thành công: cổng thanh toán có thể gọi
            // lại (retry IPN hoặc người dùng bấm F5) và lần gọi đó không phải lỗi.
            if ("Paid".equals(booking.getStatus())) {
                return new StepResult(true,
                        "Đơn hàng đã được thanh toán trước đó. Vé của bạn đã được phát hành.",
                        booking);
            }
            return new StepResult(false,
                    "Đơn hàng đã hết thời gian chờ thanh toán và được huỷ. Vui lòng đặt vé lại.",
                    booking, Outcome.FAILED);
        }
        if (amount != null && booking.getTotalAmount() != null
                && amount.compareTo(booking.getTotalAmount()) != 0) {
            // Lệch số tiền → không cấp vé, ghi cảnh báo.
            System.err.println("[OnlineBookingService] Cảnh báo đối soát tiền lệch cho đơn "
                    + txnRef + ": cổng=" + amount + ", đơn=" + booking.getTotalAmount());
            cancelGatewayPayment(txnRef, "Số tiền thanh toán không khớp với đơn hàng.");
            return new StepResult(false,
                    "Số tiền thanh toán không khớp với đơn hàng. Vui lòng liên hệ rạp.", booking);
        }
        String txnId = gatewayTxnId == null || gatewayTxnId.trim().isEmpty()
                ? "VNPAY-" + txnRef : gatewayTxnId.trim();
        try {
            bookingDAO.confirmPayment(bookingId, txnId, true, METHOD_ONLINE);
            return new StepResult(true, "Thanh toán thành công. Vé của bạn đã được phát hành.",
                    findBooking(bookingId));
        } catch (SQLException e) {
            return new StepResult(false,
                    "Không thể ghi nhận thanh toán: " + e.getMessage(), null);
        }
    }

    /**
     * Xử lý giao dịch thất bại / khách huỷ: trả ghế về trạng thái trống.
     *
     * @param txnRef mã đơn
     * @param reason lý do
     */
    public void cancelGatewayPayment(String txnRef, String reason) {
        OnlineBooking booking = findBookingByCode(txnRef);
        if (booking == null) {
            return;
        }
        try {
            bookingDAO.confirmPayment(booking.getBookingId(), null, false, METHOD_ONLINE);
        } catch (SQLException e) {
            // sp_ConfirmPayment chỉ chạy khi booking ở trạng thái PendingPayment;
            // nếu đơn đã hết hạn thì ghế đã được sp_ReleaseExpiredHolds nhả.
            System.err.println("[OnlineBookingService] cancelGatewayPayment(" + reason + ") lỗi: "
                    + e.getMessage());
        }
    }
}
