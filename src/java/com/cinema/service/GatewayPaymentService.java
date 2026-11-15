package com.cinema.service;

import com.cinema.dao.BookingDAO;
import com.cinema.integration.vnpay.VNPayCallback;
import com.cinema.integration.vnpay.VNPayGateway;
import com.cinema.integration.vnpay.VNPayProperties;
import com.cinema.model.OnlineBooking;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Tầng service dùng chung cho thanh toán qua cổng VNPAY.
 *
 * <p>Cả hai kênh bán vé đều dùng chung một cổng thanh toán: khách hàng
 * đặt vé online (kênh {@code Online}) và nhân viên bán vé tại quầy
 * (kênh {@code Counter}). Phần logic "cổng trả về kết quả gì và đơn hàng
 * có được ghi nhận là đã trả tiền hay không" là giống nhau, nên được gom
 * về đây để không phải copy-paste giữa hai servlet.</p>
 *
 * <p>Điểm khác biệt giữa hai kênh nằm ở chỗ khác nhau:</p>
 * <ul>
 *   <li><b>Đường dẫn callback</b>: khách hàng dùng {@code /booking/payment/return},
 *       quầy dùng {@code /staff/counter/payment/return}.</li>
 *   <li><b>Kiểm tra sở hữu đơn</b>: kênh online đối chiếu email người đăng nhập,
 *       kênh quầy đối chiếu {@code channel = 'Counter'} và {@code staff_id}.</li>
 * </ul>
 *
 * <p>Đơn hàng được xác nhận ở đây luôn ghi {@code Payment.method = 'BankTransfer'}
 * vì cột {@code Payment.method} chỉ cho phép {@code Cash} hoặc {@code BankTransfer}
 * (ràng buộc {@code CK_Payment_Method}) — cả tiền mặt lẫn VNPAY đều quy về
 * chuyển khoản ngân hàng nên không cần (và không nên) thêm giá trị mới vào
 * schema.</p>
 */
public class GatewayPaymentService {

    private static final Logger LOG = Logger.getLogger(GatewayPaymentService.class.getName());

    /** Phương thức thanh toán ghi vào {@code Payment.method} cho giao dịch qua cổng. */
    public static final String METHOD_GATEWAY = "BankTransfer";

    private final BookingDAO bookingDAO;
    private final VNPayGateway gateway;

    public GatewayPaymentService() {
        this(new BookingDAO(), new VNPayGateway(VNPayProperties.load()));
    }

    public GatewayPaymentService(BookingDAO bookingDAO, VNPayGateway gateway) {
        this.bookingDAO = bookingDAO;
        this.gateway = gateway;
    }

    /* ================= kết quả ================= */

    /**
     * Mã kết quả chi tiết của một giao dịch cổng thanh toán.
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

    /** Kết quả của một thao tác thanh toán: thành công hay thất bại kèm thông báo. */
    public static class Result {
        private final boolean success;
        private final String message;
        private final OnlineBooking booking;
        private final Outcome outcome;

        Result(boolean success, String message, OnlineBooking booking) {
            this(success, message, booking, success ? Outcome.SUCCESS : Outcome.FAILED);
        }

        Result(boolean success, String message, OnlineBooking booking, Outcome outcome) {
            this.success = success;
            this.message = message;
            this.booking = booking;
            this.outcome = outcome;
        }

        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
        public OnlineBooking getBooking() { return booking; }

        /** Mã kết quả chi tiết — dùng cho webhook trả {@code RspCode}. */
        public Outcome getOutcome() { return outcome; }
    }

    /* ================= dựng URL thanh toán ================= */

    /**
     * Dựng URL thanh toán cho một đơn đang chờ thanh toán.
     *
     * @param booking đơn cần thanh toán
     * @param orderInfo mô tả đơn hàng hiển thị trên cổng (sẽ tự bỏ dấu)
     * @param clientIp IP người thanh toán
     * @param contextPath context path ứng dụng
     * @param returnUrl URL cổng chuyển người thanh toán về
     * @return URL thanh toán đã ký
     */
    public String buildPaymentUrl(OnlineBooking booking, String orderInfo, String clientIp,
            String contextPath, String returnUrl) {
        // Làm tròn lên để cổng không đóng trước khi hết thời gian giữ ghế.
        int expireMinutes = (int) Math.max(1, (booking.getRemainingSeconds() + 59) / 60);
        return gateway.buildPaymentUrl(booking.getBookingCode(),
                booking.getTotalAmount(), orderInfo, clientIp, returnUrl, contextPath, expireMinutes);
    }

    /* ================= xác nhận kết quả từ cổng ================= */

    /**
     * Xác nhận kết quả thanh toán mà cổng trả về (Return URL hoặc IPN).
     *
     * <p>Luồng: kiểm tra chữ ký → đối soát số tiền → {@code sp_ConfirmPayment}.
     * Hàm này idempotent: gọi lại với cùng giao dịch không phát vé 2 lần
     * (procedure chỉ chạy khi đơn còn {@code PendingPayment}).</p>
     *
     * @param params tham số cổng trả về
     * @return kết quả xác nhận
     */
    public Result confirmPayment(Map<String, String> params) {
        VNPayCallback callback = gateway.parseCallback(params);
        if (callback == null) {
            return new Result(false,
                    "Chữ ký giao dịch không hợp lệ. Thanh toán không được ghi nhận.", null,
                    Outcome.INVALID_SIGNATURE);
        }
        if (!callback.isSuccess()) {
            cancelPayment(callback.getTxnRef(),
                    "Khách hàng huỷ giao dịch trên cổng thanh toán.");
            return new Result(false,
                    "Thanh toán không thành công. Đơn hàng đã được huỷ và ghế đã được giải phóng.", null);
        }
        return confirmPayment(callback.getTxnRef(), callback.getTransactionNo(),
                callback.getAmount());
    }

    /**
     * Xác nhận thanh toán theo mã đơn + mã giao dịch + số tiền.
     *
     * @param txnRef mã đơn (booking_code)
     * @param gatewayTxnId mã giao dịch cổng thanh toán
     * @param amount số tiền cổng báo (đơn vị tiền)
     */
    public Result confirmPayment(String txnRef, String gatewayTxnId, BigDecimal amount) {
        if (txnRef == null || txnRef.trim().isEmpty()) {
            return new Result(false, "Thiếu mã đơn hàng trong kết quả thanh toán.", null);
        }
        releaseExpiredHolds();
        OnlineBooking booking = findBookingByCode(txnRef);
        if (booking == null) {
            return new Result(false, "Không tìm thấy đơn hàng " + txnRef + ".", null);
        }
        int bookingId = booking.getBookingId();
        if (!"PendingPayment".equals(booking.getStatus())) {
            // Đơn đã hết hạn hoặc đã thanh toán trước đó → không phát vé lần 2.
            // Đơn đã trả tiền vẫn trả về thành công: cổng thanh toán có thể gọi
            // lại (retry IPN hoặc người dùng bấm F5) và lần gọi đó không phải lỗi.
            if ("Paid".equals(booking.getStatus())) {
                return new Result(true,
                        "Đơn hàng đã được thanh toán trước đó. Vé của bạn đã được phát hành.",
                        booking);
            }
            return new Result(false,
                    "Đơn hàng đã hết thời gian chờ thanh toán và được huỷ. Vui lòng đặt vé lại.",
                    booking);
        }
        if (amount != null && booking.getTotalAmount() != null
                && amount.compareTo(booking.getTotalAmount()) != 0) {
            // Lệch số tiền → không cấp vé, ghi cảnh báo.
            LOG.log(Level.WARNING, "Cảnh báo đối soát tiền lệch cho đơn {0}: cổng={1}, đơn={2}",
                    new Object[] {txnRef, amount, booking.getTotalAmount()});
            cancelPayment(txnRef, "Số tiền thanh toán không khớp với đơn hàng.");
            return new Result(false,
                    "Số tiền thanh toán không khớp với đơn hàng. Vui lòng liên hệ rạp.", booking);
        }
        String txnId = gatewayTxnId == null || gatewayTxnId.trim().isEmpty()
                ? "VNPAY-" + txnRef : gatewayTxnId.trim();
        try {
            bookingDAO.confirmPayment(bookingId, txnId, true, METHOD_GATEWAY);
            return new Result(true, "Thanh toán thành công. Vé của bạn đã được phát hành.",
                    findBooking(bookingId));
        } catch (SQLException e) {
            return new Result(false,
                    "Không thể ghi nhận thanh toán: " + e.getMessage(), null);
        }
    }

    /**
     * Xử lý giao dịch thất bại / khách huỷ: trả ghế về trạng thái trống.
     *
     * @param txnRef mã đơn
     * @param reason lý do
     */
    public void cancelPayment(String txnRef, String reason) {
        OnlineBooking booking = findBookingByCode(txnRef);
        if (booking == null) {
            return;
        }
        try {
            bookingDAO.confirmPayment(booking.getBookingId(), null, false, METHOD_GATEWAY);
        } catch (SQLException e) {
            // sp_ConfirmPayment chỉ chạy khi booking ở trạng thái PendingPayment;
            // nếu đơn đã hết hạn thì ghế đã được sp_ReleaseExpiredHolds nhả.
            LOG.log(Level.WARNING, "cancelPayment(" + reason + ") lỗi", e);
        }
    }

    /* ================= đọc đơn ================= */

    /** Đọc chi tiết đơn theo mã đơn (không kiểm tra quyền sở hữu). */
    public OnlineBooking findBookingByCode(String bookingCode) {
        try {
            return bookingDAO.findOnlineBookingByCode(bookingCode);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "findBookingByCode lỗi", e);
            return null;
        }
    }

    /** Đọc chi tiết đơn theo id (không kiểm tra quyền sở hữu). */
    public OnlineBooking findBooking(int bookingId) {
        try {
            return bookingDAO.findOnlineBooking(bookingId);
        } catch (SQLException e) {
            LOG.log(Level.WARNING, "findBooking lỗi", e);
            return null;
        }
    }

    /**
     * Nhả các đơn đã hết hạn (GBR-01/02). Idempotent.
     */
    public void releaseExpiredHolds() {
        try {
            bookingDAO.releaseExpiredHolds();
        } catch (SQLException e) {
            // Không chặn luồng: lỗi ở đây chỉ làm chậm việc giải phóng ghế.
            LOG.log(Level.WARNING, "releaseExpiredHolds lỗi", e);
        }
    }
}
