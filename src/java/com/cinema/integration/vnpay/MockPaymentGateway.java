package com.cinema.integration.vnpay;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Cổng thanh toán giả lập nội bộ, dùng cho môi trường dev.
 *
 * <p>VNPAY Sandbox từ chối mọi chữ ký khi {@code vnp_HashSecret} không
 * khớp với khoá do họ cấp — mã lỗi trả về luôn là {@code 99} và không
 * thể xác định nguyên nhân từ phía merchant. Cổng giả lập cho phép
 * chạy và kiểm thử trọn luồng thanh toán (UC15, UC16) mà không phụ
 * thuộc tài khoản VNPAY thật.</p>
 *
 * <p>Adapter này giữ nguyên hợp đồng với {@link VNPayGateway}: cùng
 * kiểu trả về, cùng tham số, cùng quy trình xác thực chữ ký ở phía
 * nhận. Khi bổ sung khoá thật, chỉ cần đổi
 * {@link VNPayProperties#isGatewayMock()} và
 * {@link VNPayProperties#getPaymentUrl()}.</p>
 *
 * <p>Chữ ký vẫn dùng HMAC-SHA512 để phía nhận chạy đúng đường kiểm
 * tra {@link VNPaySigner#verify(Map, String)} như thật, chỉ khác ở chỗ
 * khoá dùng chung với cả hai đầu nằm trong cùng hệ thống.</p>
 */
public class MockPaymentGateway {

    /** Múi giờ dùng cho mốc thời gian, khớp VNPAY. */
    private static final ZoneId VNPAY_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    /** Định dạng thời gian của VNPAY. */
    private static final DateTimeFormatter VNPAY_TIME
            = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    /** Mã trả về khi giao dịch thành công. */
    public static final String RESPONSE_SUCCESS = "00";

    /** Mã trả về khi khách hàng huỷ giao dịch. */
    public static final String RESPONSE_CANCELLED = "02";

    private MockPaymentGateway() {
    }

    /**
     * Dựng tham số thanh toán giả lập, ký bằng HMAC-SHA512.
     *
     * @param txnRef mã tham chiếu (dùng làm mã đơn hàng)
     * @param amount tổng tiền cần thanh toán
     * @param orderInfo mô tả đơn hàng
     * @param clientIp địa chỉ IP của khách hàng
     * @param returnUrl URL quay về sau khi "thanh toán"
     * @param expireMinutes số phút cho phép thanh toán
     * @return map tham số đã ký, sẵn sàng đưa vào query string
     */
    public static Map<String, String> buildSignedParams(String txnRef,
            BigDecimal amount, String orderInfo, String clientIp,
            String returnUrl, int expireMinutes) {
        Map<String, String> params
                = new LinkedHashMap<String, String>();
        params.put("vnp_Version", VNPayProperties.API_VERSION);
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", VNPayProperties.mockPartnerCode());
        params.put("vnp_Amount", VNPayGateway.toVnpAmount(amount));
        params.put("vnp_CurrCode", VNPayProperties.CURRENCY_CODE);
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_OrderInfo",
                VNPayGateway.sanitizeOrderInfo(orderInfo));
        params.put("vnp_OrderType", "other");
        params.put("vnp_Locale", "vn");
        params.put("vnp_ReturnUrl", returnUrl);
        params.put("vnp_IpAddr", VNPayGateway.normalizeIp(clientIp));

        LocalDateTime now = LocalDateTime.now(VNPAY_ZONE);
        params.put("vnp_CreateDate", now.format(VNPAY_TIME));
        params.put("vnp_ExpireDate",
                now.plusMinutes(expireMinutes).format(VNPAY_TIME));

        params.put(VNPaySigner.SECURE_HASH_PARAM, VNPaySigner.sign(
                params, VNPayProperties.mockSecretKey()));

        return params;
    }

    /**
     * Sinh chữ ký cho một tập tham số do cổng giả lập phát lại.
     *
     * <p>Dùng ở phía nhận để tái tạo dữ liệu gốc rồi kiểm tra bằng
     * đúng đường kiểm tra của cổng thật.</p>
     *
     * @param params các tham số nhận được (chưa có chữ ký)
     * @return chữ ký hex
     */
    public static String signParams(Map<String, String> params) {
        Map<String, String> signable
                = new LinkedHashMap<String, String>(params);
        signable.remove(VNPaySigner.SECURE_HASH_PARAM);
        return VNPaySigner.sign(signable,
                VNPayProperties.mockSecretKey());
    }

    /**
     * Mã đơn hàng giao dịch giả lập.
     *
     * @return mã giao dịch dạng số
     */
    public static String generateTransactionNo() {
        long suffix = Math.abs(System.nanoTime() % 100_000_000L);
        return String.valueOf(10_000_000L + suffix);
    }

    /**
     * Kiểm tra thời hạn thanh toán của giao dịch giả lập.
     *
     * @param createTime thời điểm tạo (yyyyMMddHHmmss)
     * @param expireTime thời điểm hết hạn (yyyyMMddHHmmss)
     * @return true nếu đã quá thời hạn
     */
    public static boolean isExpired(String createTime, String expireTime) {
        LocalDateTime deadline = parseTime(expireTime);
        if (deadline == null) {
            // Không có thời hạn thì áp dụng mặc định 5 phút như cổng thật.
            LocalDateTime created = parseTime(createTime);
            if (created == null) {
                return false;
            }
            deadline = created.plusMinutes(5);
        }
        return LocalDateTime.now(VNPAY_ZONE).isAfter(deadline);
    }

    private static LocalDateTime parseTime(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value.trim(), VNPAY_TIME);
        } catch (java.time.format.DateTimeParseException exception) {
            return null;
        }
    }
}
