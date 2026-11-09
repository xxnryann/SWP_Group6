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
import com.cinema.model.SeatTypeInfo;
import com.cinema.model.ShowtimeInfo;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/** STT 25 — Đặt vé online + thanh toán cho khách hàng (BF-02 / UC12–UC18). */
public class OnlineBookingService {

    private static final Logger LOG = Logger.getLogger(OnlineBookingService.class.getName());

    /** Phương thức thanh toán online (Payment.method chỉ cho phép Cash/BankTransfer). */
    private static final String METHOD_ONLINE = "BankTransfer";

    /** Cấu hình quy đổi MyPoint được cache trong bộ nhớ. */
    private static volatile PointConfig cachedPointConfig;

    /** Thời điểm cache #cachedPointConfig hết hạn (epoch millis). */
    private static volatile long cachedPointConfigExpiresAt;

    /** TTL của cache cấu hình MyPoint (5 phút). */
    private static final long POINT_CONFIG_TTL_MILLIS = 5L * 60L * 1000L;

    /** Khoảng cách tối thiểu giữa 2 lần gọi sp_ReleaseExpiredHolds. */
    private static final long RELEASE_THROTTLE_MILLIS = 2000L;

    /** Mốc thời gian lần gọi sp_ReleaseExpiredHolds gần nhất. */
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

        /** Mã kết quả chi tiết — dùng cho webhook (API-02) trả RspCode. */
        public Outcome getOutcome() { return outcome; }
    }

    /** Mã kết quả chi tiết của một bước thanh toán. */
    public enum Outcome {
        /** Thanh toán thành công, vé đã phát hành. */
        SUCCESS,
        /** Chữ ký webhook không hợp lệ — không cập nhật gì, không retry. */
        INVALID_SIGNATURE,
        /** Giao dịch bị từ chối / khách hủy / đơn không còn hiệu lực. */
        FAILED
    }

    /* ================= đọc dữ liệu ================= */

    /** Nhả các đơn đã hết hạn (GBR-01/02). Idempotent. */
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
            LOG.log(Level.WARNING, "releaseExpiredHolds lỗi", e);
        }
    }

    /** Đọc chi tiết đơn của người đang đăng nhập. */
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
            LOG.log(Level.WARNING, "findBooking lỗi", e);
            return null;
        }
    }

    /** Đọc chi tiết đơn theo mã đơn (không kiểm tra ownership). */
    public OnlineBooking findBookingByCode(String bookingCode) {
        try {
            return bookingDAO.findOnlineBookingByCode(bookingCode);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "findBookingByCode lỗi", e);
            return null;
        }
    }

    /** Đơn có thuộc về khách đang đăng nhập hay không. */
    public boolean isOwnedBy(OnlineBooking booking, String email) {
        return booking != null && email != null && !email.trim().isEmpty()
                && email.trim().equalsIgnoreCase(booking.getCustomerEmail());
    }

    public String getRoomType(int showtimeId) {
        try {
            return bookingDAO.getRoomType(showtimeId);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "getRoomType lỗi", e);
            return null;
        }
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

    /** Loại ghế kèm giá vé của suất chiếu — dùng để dựng chú thích */
    public List<SeatTypeInfo> getSeatTypesWithPrice(int showtimeId) {
        try {
            return bookingDAO.findSeatTypesWithPrice(showtimeId);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "findSeatTypesWithPrice lỗi", e);
            return List.of();
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

    /** Mở phiên đặt vé online (15 phút) cho khách đang đăng nhập. */
    public int createBooking(String email, int showtimeId) {
        int accountId;
        try {
            accountId = accountDAO.findAccountIdByEmail(email);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "createBooking lỗi", e);
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

    /** Giữ ghế đã chọn (chuyển booking sang trạng thái chờ thanh toán). */
    public void holdSeats(int bookingId, String seatIds) throws SQLException {
        bookingDAO.holdSeats(bookingId, seatIds);
    }

    /** Hủy đơn đang dở, trả ghế về trạng thái trống. */
    public void cancelBooking(int bookingId) {
        try {
            bookingDAO.cancelPendingBooking(bookingId);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "cancelBooking lỗi", e);
        }
    }

    /* ================= bước 2: combo → voucher → MyPoint ================= */

    /** Thêm/bỏ combo của đơn. */
    public void updateCombo(int bookingId, int comboId, int quantity) throws SQLException {
        bookingDAO.addCombo(bookingId, comboId, quantity);
    }

    /** Áp voucher rồi MyPoint theo đúng thứ tự nghiệp vụ (voucher trước, điểm sau — */
    public StepResult applyExtras(int bookingId, String voucherCode, int points) {
        DiscountResult result = discountService.applyDiscounts(bookingId, voucherCode, points);
        boolean ok = result.getTotal() != null;
        return new StepResult(ok, result.getMessage(),
                ok ? findBooking(bookingId) : null);
    }

    /* ================= bước 3: thanh toán ================= */

    /** Dựng URL thanh toán của cổng. */
    public String buildPaymentUrl(OnlineBooking booking, String clientIp,
            String contextPath, String returnUrl) {
        String orderInfo = "Thanh toan ve " + booking.getBookingCode();
        // Làm tròn lên để cổng không đóng trước khi hết thời gian giữ ghế; hết giữ ghế thì đơn đã bị chặn ở servlet.
        int expireMinutes = (int) Math.max(1, (booking.getRemainingSeconds() + 59) / 60);
        return gateway.buildPaymentUrl(booking.getBookingCode(),
                booking.getTotalAmount(), orderInfo, clientIp, returnUrl, contextPath, expireMinutes);
    }

    /** Xác nhận kết quả thanh toán từ cổng (Return URL hoặc IPN). */
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

    /** Xác nhận thanh toán theo mã đơn + mã giao dịch + số tiền. */
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
            LOG.log(Level.WARNING, "Cảnh báo đối soát tiền lệch cho đơn {0}: cổng={1}, đơn={2}",
                    new Object[] {txnRef, amount, booking.getTotalAmount()});
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

    /** Xử lý giao dịch thất bại / khách huỷ: trả ghế về trạng thái trống. */
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
            LOG.log(Level.WARNING, "cancelGatewayPayment(" + reason + ") lỗi", e);
        }
    }
}
