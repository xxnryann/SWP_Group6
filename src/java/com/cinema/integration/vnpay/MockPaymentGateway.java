package com.cinema.integration.vnpay;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/** Cổng thanh toán giả lập nội bộ, dùng cho môi trường dev. */
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

    /** Dựng tham số thanh toán giả lập, ký bằng HMAC-SHA512. */
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

    /** Sinh chữ ký cho một tập tham số do cổng giả lập phát lại. */
    public static String signParams(Map<String, String> params) {
        Map<String, String> signable
                = new LinkedHashMap<String, String>(params);
        signable.remove(VNPaySigner.SECURE_HASH_PARAM);
        return VNPaySigner.sign(signable,
                VNPayProperties.mockSecretKey());
    }

    /** Mã đơn hàng giao dịch giả lập. */
    public static String generateTransactionNo() {
        long suffix = Math.abs(System.nanoTime() % 100_000_000L);
        return String.valueOf(10_000_000L + suffix);
    }

    /** Kiểm tra thời hạn thanh toán của giao dịch giả lập. */
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
