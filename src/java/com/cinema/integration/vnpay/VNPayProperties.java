package com.cinema.integration.vnpay;

import com.cinema.util.AppConfig;

/**
 * Cấu hình kết nối tới Cổng thanh toán VNPAY.
 *
 * <p>Đọc theo cùng pattern với {@code util.AppConfig}: system property
 * trước, sau đó tới biến môi trường, sau đó tới {@code app.properties},
 * cuối cùng mới dùng giá trị mặc định (môi trường Sandbox) để chạy dev
 * local. Không hardcode secret thật trong source (rule 09).</p>
 *
 * <p>Cờ {@code vnpay.mockGateway} cho phép chuyển sang cổng giả lập nội
 * bộ khi chưa có {@code vnpay.secretKey} hợp lệ. Xem
 * {@link MockPaymentGateway}.</p>
 */
public final class VNPayProperties {

    /** Phiên bản API thanh toán VNPAY. */
    public static final String API_VERSION = "2.1.0";

    /** Đơn vị tiền tệ — VNPAY hiện chỉ hỗ trợ VND. */
    public static final String CURRENCY_CODE = "VND";

    /** Mã cổng của cổng giả lập nội bộ. */
    public static final String MOCK_PARTNER_CODE = "MOCKVINPAY";

    /**
     * Khoá chữ ký nội bộ của cổng giả lập.
     *
     * <p>Không phải khoá của VNPAY, chỉ dùng để hai đầu của hệ thống
     * kiểm tra checksum trong khi dev.</p>
     */
    public static final String MOCK_SECRET_KEY
            = "MOCK-CINESTAR-LOCAL-CHECKSUM-KEY";

    /**
     * Cấu hình đã nạp, cache lại để không đọc lại app.properties mỗi request.
     *
     * <p>Cấu hình thanh toán gần như không đổi trong vòng đời ứng dụng.
     * Cache ở đây giúp mỗi lần mở màn hình thanh toán không phải dựng
     * lại map cấu hình. Nếu cần đổi cấu hình khi đang chạy thì restart
     * ứng dụng (đây là hành vi chấp nhận được cho môi trường dev).</p>
     */
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

    /**
     * Nạp cấu hình từ system property / biến môi trường / app.properties.
     *
     * <p>Cổng giả lập bật khi {@code vnpay.mockGateway} bằng true, hoặc
     * khi chưa có khoá bí mật hợp lệ để tự động tránh bị chặn ở cổng
     * thật.</p>
     *
     * @return cấu hình VNPAY hiện tại
     */
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

    /**
     * Xoá cache cấu hình (dùng khi test hoặc khi đổi cấu hình lúc chạy).
     */
    public static void invalidateCache() {
        synchronized (VNPayProperties.class) {
            cached = null;
        }
    }

    /**
     * Đọc cấu hình thật từ system property / biến môi trường / app.properties.
     */
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

    /**
     * Mã cổng dùng cho cổng giả lập.
     *
     * @return mã cổng giả lập
     */
    public static String mockPartnerCode() {
        return MOCK_PARTNER_CODE;
    }

    /**
     * Khoá chữ ký dùng cho cổng giả lập.
     *
     * @return khoá chữ ký nội bộ
     */
    public static String mockSecretKey() {
        return MOCK_SECRET_KEY;
    }

    /**
     * Đọc một giá trị cấu hình.
     *
     * @param key tên khóa
     * @param fallback giá trị dùng khi không cấu hình
     * @return giá trị đã cắt khoảng trắng
     */
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

    /**
     * Đọc một cờ cấu hình kiểu boolean.
     *
     * @param key tên khóa
     * @param fallback giá trị dùng khi không cấu hình
     * @return true nếu cờ được bật
     */
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

    /**
     * URL trang thanh toán giả lập nội bộ.
     *
     * @return đường dẫn tới {@code /mock/payment}
     */
    public String getMockPaymentUrl() {
        return resolve("vnpay.mockPaymentUrl", "/mock/payment");
    }

    public String getBankCode() {
        return bankCode;
    }

    /**
     * Đang chạy với cổng giả lập nội bộ.
     *
     * @return true nếu dùng cổng giả lập
     */
    public boolean isGatewayMock() {
        return mockGateway;
    }
}
