package com.cinema.util;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/** Đường link trang thông tin vé mà mã QR trỏ tới. */
public final class TicketLinks {

    private TicketLinks() {
    }

    /**
     * Link công khai tới trang thông tin vé. Điện thoại không mở được "localhost" của máy chủ, nên thứ tự ưu tiên:
     * <ol>
     *   <li>nội dung file app.public.url.file — địa chỉ tunnel công khai do scripts/public-qr.ps1 ghi khi đang chạy
     *       (vd https://abc.trycloudflare.com), đổi được mà không cần deploy lại;</li>
     *   <li>app.public.url (vd http://192.168.1.10:9999/CinemaTest);</li>
     *   <li>địa chỉ của request hiện tại.</li>
     * </ol>
     */
    public static String viewUrl(HttpServletRequest req, String ticketCode) {
        String base = tunnelUrl();
        if (base.isEmpty()) base = AppConfig.get("app.public.url");
        if (base.isEmpty()) {
            base = req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort() + req.getContextPath();
        }
        if (base.endsWith("/")) base = base.substring(0, base.length() - 1);
        return base + "/ticket/view?code=" + URLEncoder.encode(ticketCode, StandardCharsets.UTF_8);
    }

    /** Địa chỉ tunnel trong file app.public.url.file; rỗng nếu không cấu hình, không có file hoặc nội dung không phải https. */
    private static String tunnelUrl() {
        String file = AppConfig.get("app.public.url.file");
        if (file.isEmpty()) return "";
        try {
            Path path = Paths.get(file);
            if (!Files.isRegularFile(path)) return "";
            String url = new String(Files.readAllBytes(path), StandardCharsets.UTF_8).trim();
            return url.matches("https://[A-Za-z0-9.-]+(:[0-9]+)?/?") ? url : "";
        } catch (IOException | RuntimeException e) {
            return "";
        }
    }
}
