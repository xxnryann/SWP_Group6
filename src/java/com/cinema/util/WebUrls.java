package com.cinema.util;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Dựng URL tuyệt đối của ứng dụng.
 *
 * <p>Cổng thanh toán VNPAY bắt buộc {@code vnp_ReturnUrl} là URL tuyệt đối
 * (vd {@code http://192.168.1.10:9999/CinemaWeb/booking/payment/return}),
 * và gọi IPN server-to-server nên địa chỉ đó phải truy cập được từ
 * ngoài máy chủ.</p>
 *
 * <p>Thứ tự ưu tiên:</p>
 * <ol>
 *   <li>{@code vnpay.publicBaseUrl} trong {@code app.properties} (hoặc
 *       {@code -Dvnpay.publicBaseUrl=...} / biến môi trường
 *       {@code VNPAY_PUBLICBASEURL}) — địa chỉ công khai do người vận hành
 *       khai báo (vd URL Cloudflare tunnel mà {@code scripts/public-qr.ps1}
 *       đang chạy). Đây là cách duy nhất để VNPAY gọi được IPN khi ứng
 *       dụng chạy trên máy local;</li>
 *   <li>địa chỉ của request hiện tại (có tính {@code X-Forwarded-Proto} /
 *       {@code X-Forwarded-Host} nếu chạy sau reverse-proxy) — dùng được khi
 *       truy cập qua đúng địa chỉ đó (ví dụ trong mạng LAN).</li>
 * </ol>
 */
public final class WebUrls {

    private WebUrls() {
    }

    /**
     * Gốc ứng dụng dạng tuyệt đối, không có dấu {@code /} cuối.
     *
     * <p>Ví dụ: {@code http://192.168.1.10:9999/CinemaWeb}.</p>
     *
     * @param req request hiện tại
     * @return gốc ứng dụng, không rỗng
     */
    public static String absoluteBase(HttpServletRequest req) {
        String configured = AppConfig.resolve("vnpay.publicBaseUrl");
        if (!configured.isEmpty()) {
            return trimTrailingSlash(configured);
        }
        // Sau reverse-proxy/tunnel, scheme và host thật nằm trong header.
        String scheme = firstHeader(req, "X-Forwarded-Proto");
        if (scheme.isEmpty()) {
            scheme = req.getScheme();
        }
        String host = firstHeader(req, "X-Forwarded-Host");
        if (host.isEmpty()) {
            host = req.getServerName();
            int port = req.getServerPort();
            // Bỏ cổng mặc định để URL gọn và khớp dạng VNPAY mong đợi.
            boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                    || ("https".equalsIgnoreCase(scheme) && port == 443);
            if (!defaultPort) {
                host = host + ":" + port;
            }
        }
        return trimTrailingSlash(scheme + "://" + host + req.getContextPath());
    }

    /**
     * Địa chỉ IP của khách hàng.
     *
     * <p>Ưu tiên header {@code X-Forwarded-For} (đầu tiên trong danh sách) vì
     * khi ứng dụng chạy sau reverse-proxy hoặc tunnel, địa chỉ kết nối thực
     * tế là của proxy chứ không phải của khách. Nếu không có header thì dùng
     * địa chỉ peer của request.</p>
     *
     * @param req request hiện tại
     * @return địa chỉ IP của khách
     */
    public static String clientIp(HttpServletRequest req) {
        String forwarded = req.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.trim().isEmpty()) {
            String first = forwarded.split(",")[0].trim();
            if (!first.isEmpty()) {
                return first;
            }
        }
        return req.getRemoteAddr();
    }

    /** Giá trị đầu tiên của một header, rỗng nếu thiếu. */
    private static String firstHeader(HttpServletRequest req, String name) {
        String value = req.getHeader(name);
        if (value == null) {
            return "";
        }
        int comma = value.indexOf(',');
        String first = comma < 0 ? value : value.substring(0, comma);
        return first.trim();
    }

    /** Bỏ dấu {@code /} cuối chuỗi (nếu có). */
    private static String trimTrailingSlash(String value) {
        String result = value.trim();
        while (result.endsWith("/")) {
            result = result.substring(0, result.length() - 1);
        }
        return result;
    }
}
