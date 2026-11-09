package com.cinema.integration.vnpay;

import com.cinema.util.AppConfig;

/** Cấu hình kết nối tới Cổng thanh toán VNPAY. */
public final class VNPayProperties {

    /** Phiên bản API thanh toán VNPAY. */
    public static final String API_VERSION = "2.1.0";

    /** Đơn vị tiền tệ — VNPAY hiện chỉ hỗ trợ VND. */
    public static final String CURRENCY_CODE = "VND";

    /** Mã cổng của cổng giả lập nội bộ. */
    public static final String MOCK_PARTNER_CODE = "MOCKVINPAY";

    /** Khoá chữ ký nội bộ của cổng giả lập. */
    public static final String MOCK_SECRET_KEY
            = "MOCK-CINESTAR-LOCAL-CHECKSUM-KEY";

    /** Cấu hình đã nạp, cache lại để không đọc lại app.properties mỗi request. */
    private static volatile VNPayProperties cached;

    /** Mã cổng thanh toán VNPAY (vnp_TmnCode). */
    private final String partnerCode;

    /** Khoá bí mật dùng tạo và kiểm tra chữ ký (vnp_HashSecret). */
    private final String secretKey;

    /** URL trang thanh toán của VNPAY. */
    private final String paymentUrl;

    /** Mã ngân hàng/phương thức thanh toán, rỗng để khách chọn. */
    private final String bankCode;

    /** Có đang dùng cổng giả lập nội bộ hay không. */
    private final boolean mockGateway;

    private VNPayProperties(String partnerCode, String secretKey,
            String paymentUrl, String bankCode, boolean mockGateway) {
        this.partnerCode = partnerCode;
        this.secretKey = secretKey;
        this.paymentUrl = paymentUrl;
        this.bankCode = bankCode;
        this.mockGateway = mockGateway;
    }

    /** Nạp cấu hình từ system property / biến môi trường / app.properties. */
    public static VNPayProperties load() {
        VNPayProperties instance = cached;
        if (instance != null) {
            return instance;
        }
        synchronized (VNPayProperties.class) {
            if (cached == null) {
                cached = build();
            }
            return cached;
        }
    }

    /** Xoá cache cấu hình (dùng khi test hoặc khi đổi cấu hình lúc chạy). */
    public static void invalidateCache() {
        synchronized (VNPayProperties.class) {
            cached = null;
        }
    }

    /** Đọc cấu hình thật từ system property / biến môi trường / app.properties. */
    private static VNPayProperties build() {
        String partnerCode = resolve("vnpay.partnerCode", "DEMOV210");
        String secretKey = resolve("vnpay.secretKey", "");
        boolean mockGateway = resolveBoolean("vnpay.mockGateway", false)
                || secretKey.isEmpty();
        if (mockGateway) {
            return new VNPayProperties(MOCK_PARTNER_CODE, MOCK_SECRET_KEY,
                    "", resolve("vnpay.bankCode", ""), true);
        }
        return new VNPayProperties(partnerCode, secretKey,
                resolve("vnpay.paymentUrl",
                        "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"),
                resolve("vnpay.bankCode", ""), false);
    }

    /** Mã cổng dùng cho cổng giả lập. */
    public static String mockPartnerCode() {
        return MOCK_PARTNER_CODE;
    }

    /** Khoá chữ ký dùng cho cổng giả lập. */
    public static String mockSecretKey() {
        return MOCK_SECRET_KEY;
    }

    /** Đọc một giá trị cấu hình. */
    private static String resolve(String key, String fallback) {
        String value = System.getProperty(key);
        if (value == null || value.trim().isEmpty()) {
            value = System.getenv(
                    key.replace('.', '_').toUpperCase());
        }
        if (value == null || value.trim().isEmpty()) {
            value = AppConfig.get(key);
        }
        if (value == null || value.trim().isEmpty()) {
            return fallback == null ? "" : fallback;
        }
        return value.trim();
    }

    /** Đọc một cờ cấu hình kiểu boolean. */
    private static boolean resolveBoolean(String key, boolean fallback) {
        String value = System.getProperty(key);
        if (value == null || value.trim().isEmpty()) {
            value = System.getenv(
                    key.replace('.', '_').toUpperCase());
        }
        if (value == null || value.trim().isEmpty()) {
            value = AppConfig.get(key);
        }
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return "true".equalsIgnoreCase(value.trim())
                || "1".equals(value.trim())
                || "yes".equalsIgnoreCase(value.trim());
    }

    public String getPartnerCode() {
        return partnerCode;
    }

    public String getSecretKey() {
        return secretKey;
    }

    public String getPaymentUrl() {
        return paymentUrl;
    }

    /** URL trang thanh toán giả lập nội bộ. */
    public String getMockPaymentUrl() {
        return resolve("vnpay.mockPaymentUrl", "/mock/payment");
    }

    public String getBankCode() {
        return bankCode;
    }

    /** Đang chạy với cổng giả lập nội bộ. */
    public boolean isGatewayMock() {
        return mockGateway;
    }
}
