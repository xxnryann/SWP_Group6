package com.cinema.integration.vnpay;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Adapter kết nối tới Cổng thanh toán VNPAY.
 *
 * <p>Chỉ chứa logic thuần tuý về giao thức (dựng URL, ký, đọc kết
 * quả) — không chứa business rule của rạp phim. Việc quyết định đơn
 * hàng có được phát vé hay không thuộc tầng service.</p>
 */
public class VNPayGateway {

    /** Múi giờ VNPAY sử dụng khi sinh mốc thời gian. */
    private static final ZoneId VNPAY_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    /** Định dạng thời gian của VNPAY. */
    private static final DateTimeFormatter VNPAY_TIME
            = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    /** Thời hạn thanh toán trên cổng, khớp với TTL giữ ghế 5 phút. */
    private static final int EXPIRE_MINUTES = 5;

    private final VNPayProperties properties;

    public VNPayGateway() {
        this(VNPayProperties.load());
    }

    public VNPayGateway(VNPayProperties properties) {
        this.properties = properties;
    }

    public VNPayProperties getProperties() {
        return properties;
    }

    /**
     * Dựng URL thanh toán để chuyển khách hàng sang VNPAY.
 *
     * <p>Khách hàng quét mã QR hoặc nhập thẻ trên trang VNPAY, sau đó
     * VNPAY chuyển họ về {@code vnp_ReturnUrl} kèm kết quả.</p>
 *
     * <p>Khi dùng cổng giả lập nội bộ, URL trả về là đường dẫn tương
     * đối để giữ nguyên context path của ứng dụng.</p>
 *
     * @param txnRef mã tham chiếu giao dịch (dùng làm mã đơn hàng)
     * @param amount tổng tiền cần thanh toán
     * @param orderInfo mô tả đơn hàng, không dấu và không ký tự đặc biệt
     * @param clientIp địa chỉ IP của khách hàng
     * @param returnUrl URL VNPAY chuyển khách hàng về
     * @return URL thanh toán đầy đủ đã ký
     */
    public String buildPaymentUrl(String txnRef, BigDecimal amount,
            String orderInfo, String clientIp, String returnUrl) {
        return buildPaymentUrl(txnRef, amount, orderInfo, clientIp,
                returnUrl, "");
    }

    /**
     * Dựng URL thanh toán, biết context path của ứng dụng.
     *
     * @param txnRef mã tham chiếu giao dịch (dùng làm mã đơn hàng)
     * @param amount tổng tiền cần thanh toán
     * @param orderInfo mô tả đơn hàng, không dấu và không ký tự đặc biệt
     * @param clientIp địa chỉ IP của khách hàng
     * @param returnUrl URL cổng thanh toán chuyển khách hàng về
     * @param contextPath context path ứng dụng, vd {@code /CineStar}
     * @return URL thanh toán đầy đủ đã ký
     */
    public String buildPaymentUrl(String txnRef, BigDecimal amount,
            String orderInfo, String clientIp, String returnUrl,
            String contextPath) {
        if (properties.isGatewayMock()) {
            return buildMockPaymentUrl(txnRef, amount, orderInfo,
                    clientIp, returnUrl, contextPath);
        }

        Map<String, String> params = new LinkedHashMap<String, String>();
        params.put("vnp_Version", VNPayProperties.API_VERSION);
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", properties.getPartnerCode());
        params.put("vnp_Amount", toVnpAmount(amount));
        params.put("vnp_CurrCode", VNPayProperties.CURRENCY_CODE);
        params.put("vnp_TxnRef", txnRef);
        params.put("vnp_OrderInfo", sanitizeOrderInfo(orderInfo));
        params.put("vnp_OrderType", "other");
        params.put("vnp_Locale", "vn");
        params.put("vnp_ReturnUrl", returnUrl);
        params.put("vnp_IpAddr", normalizeIp(clientIp));

        LocalDateTime now = LocalDateTime.now(VNPAY_ZONE);
        params.put("vnp_CreateDate", now.format(VNPAY_TIME));
        params.put("vnp_ExpireDate", now.plusMinutes(EXPIRE_MINUTES)
                .format(VNPAY_TIME));

        String bankCode = properties.getBankCode();
        if (bankCode != null && !bankCode.trim().isEmpty()) {
            params.put("vnp_BankCode", bankCode.trim());
        }

        params.put(VNPaySigner.SECURE_HASH_PARAM,
                VNPaySigner.sign(params, properties.getSecretKey()));

        return properties.getPaymentUrl() + "?" + toQueryString(params);
    }

    /**
     * Dựng URL tới cổng giả lập nội bộ khi chưa cấu hình được cổng
     * thanh toán thật.
     *
     * @param txnRef mã tham chiếu giao dịch
     * @param amount tổng tiền
     * @param orderInfo mô tả đơn hàng
     * @param clientIp địa chỉ IP của khách hàng
     * @param returnUrl URL cổng thật sẽ chuyển khách hàng về
     * @return URL trang thanh toán giả lập đã ký
     */
    private String buildMockPaymentUrl(String txnRef, BigDecimal amount,
            String orderInfo, String clientIp, String returnUrl,
            String contextPath) {
        Map<String, String> params = MockPaymentGateway.buildSignedParams(
                txnRef, amount, orderInfo, clientIp, returnUrl,
                EXPIRE_MINUTES);
        String base = properties.getMockPaymentUrl();
        if (!base.startsWith("/")) {
            base = "/" + base;
        }
        String prefix = contextPath == null ? "" : contextPath;
        return prefix + base + "?" + toQueryString(params);
    }

    /**
     * Kiểm tra chữ ký và đọc kết quả thanh toán.
     *
     * @param params các tham số do VNPAY gửi về
     * @return kết quả thanh toán, null nếu chữ ký không hợp lệ
     */
    public VNPayCallback parseCallback(Map<String, String> params) {
        if (!VNPaySigner.verify(params, properties.getSecretKey())) {
            return null;
        }
        return VNPayCallback.from(params);
    }

    /**
     * Quy đổi số tiền sang đơn vị VNPAY (nhân 100, bỏ phần thập phân).
     *
     * @param amount số tiền
     * @return số tiền theo định dạng VNPAY
     */
    public static String toVnpAmount(BigDecimal amount) {
        if (amount == null) {
            return "0";
        }
        return amount.setScale(0, RoundingMode.HALF_UP)
                .movePointRight(2).toPlainString();
    }

    /**
     * Quy đổi số tiền từ đơn vị VNPAY (nhân 100) về đơn vị tiền.
     *
     * <p>VNPAY quy ước {@code vnp_Amount} là số tiền nhân 100: 179.000 ₫
     * được gửi đi là {@code 17900000}. Mọi nơi hiển thị số tiền cho
     * khách (ví dụ trang cổng thanh toán) phải quy đổi ngược lại về
     * đơn vị tiền trước khi in ra.</p>
     *
     * @param rawAmount giá trị thô của {@code vnp_Amount}
     * @return số tiền ở đơn vị tiền, null nếu không đọc được
     */
    public static BigDecimal fromVnpAmount(String rawAmount) {
        if (rawAmount == null || rawAmount.trim().isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(rawAmount.trim())
                    .divide(new BigDecimal("100"), 2,
                            RoundingMode.DOWN);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    /**
     * Loại bỏ dấu và ký tự đặc biệt khỏi mô tả đơn hàng.
     *
     * <p>VNPAY yêu cầu {@code vnp_OrderInfo} là chữ tiếng Việt
     * **không dấu** và không chứa ký tự đặc biệt. Dấu tiếng Việt được
     * tách bằng {@code Normalizer} rồi loại bỏ, giữ lại chữ cái cơ
     * bản ASCII.</p>
     *
     * @param orderInfo mô tả đơn hàng
     * @return mô tả đã làm sạch
     */
    public static String sanitizeOrderInfo(String orderInfo) {
        if (orderInfo == null) {
            return "";
        }
        String withoutDiacritics = java.text.Normalizer.normalize(
                orderInfo, java.text.Normalizer.Form.NFD);
        StringBuilder builder = new StringBuilder();
        for (char character
                : withoutDiacritics.toCharArray()) {
            if (Character.isLetterOrDigit(character)
                    || character == ' ') {
                builder.append(character);
            }
        }
        return builder.toString().replaceAll("\\s+", " ").trim();
    }

    /**
     * Chuẩn hoá địa chỉ IP cho đúng định dạng VNPAY yêu cầu.
     *
     * @param clientIp địa chỉ IP của khách hàng
     * @return địa chỉ IP hợp lệ
     */
    public static String normalizeIp(String clientIp) {
        if (clientIp == null || clientIp.trim().isEmpty()) {
            return "127.0.0.1";
        }
        String ip = clientIp.trim();
        // IPv6 loopback dài hơn giới hạn 45 ký tự mà VNPAY cho phép.
        if (ip.length() > 45) {
            return "127.0.0.1";
        }
        if (ip.contains(",")) {
            ip = ip.substring(0, ip.indexOf(','));
        }
        return ip;
    }

    /**
     * Ghép các tham số thành query string đã URL-encode.
     *
     * @param params các tham số
     * @return query string
     */
    private static String toQueryString(Map<String, String> params) {
        StringBuilder builder = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (builder.length() > 0) {
                builder.append('&');
            }
            builder.append(VNPaySigner.encode(entry.getKey()))
                    .append('=')
                    .append(VNPaySigner.encode(entry.getValue()));
        }
        return builder.toString();
    }
}

