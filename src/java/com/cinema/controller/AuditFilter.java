package com.cinema.controller;

import com.cinema.model.User;
import com.cinema.util.AuditLog;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Ghi nhật ký mọi thao tác ghi (POST) của nhân sự vào SystemLog: ai, làm gì, thành công hay không.
 * Chỉ ghi các tham số định danh trong {@link #LOGGED_PARAMS}, không bao giờ ghi mật khẩu hay nội dung form.
 * Servlet có thể bổ sung chi tiết qua request attribute {@link #DETAIL_ATTR}.
 */
@WebFilter({"/admin/*", "/manager/*", "/manage/*", "/staff/*", "/logout"})
public class AuditFilter implements Filter {

    public static final String DETAIL_ATTR = "auditDetail";
    private static final String[] LOGGED_PARAMS = {"id", "userId", "movieId", "showtimeId", "roomId", "ticketId",
        "ticketCode", "code", "status", "role"};

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        if (!"POST".equals(req.getMethod())) {
            chain.doFilter(request, response);
            return;
        }
        // Đọc trước khi chạy tiếp vì /logout sẽ hủy session.
        User user = sessionUser(req);
        boolean crashed = true;
        try {
            chain.doFilter(request, response);
            crashed = false;
        } finally {
            if (user != null) {
                record(req, (HttpServletResponse) response, user, crashed);
            }
        }
    }

    private static User sessionUser(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute(BaseServlet.SESSION_USER);
    }

    private static void record(HttpServletRequest req, HttpServletResponse resp, User user, boolean crashed) {
        try {
            String action = req.getParameter("action");
            String name = req.getServletPath() + (action == null || action.isBlank() ? "" : " : " + action);
            StringBuilder detail = new StringBuilder(failed(req, resp, crashed) ? "Thất bại" : "Thành công");
            for (String param : LOGGED_PARAMS) {
                String value = req.getParameter(param);
                if (value != null && !value.isBlank()) detail.append(" · ").append(param).append('=').append(value);
            }
            Object extra = req.getAttribute(DETAIL_ATTR);
            if (extra != null) detail.append(" · ").append(extra);
            AuditLog.write(user.getEmail(), name, detail.toString());
        } catch (RuntimeException e) {
            // Vd upload vượt giới hạn làm getParameter lỗi: không để việc ghi log ảnh hưởng phản hồi.
            AuditLog.write(user.getEmail(), req.getServletPath(), "Không đọc được tham số thao tác");
        }
    }

    /** Servlet báo lỗi qua mã HTTP, flash "error" (khi redirect) hoặc attribute "error" (khi forward). */
    private static boolean failed(HttpServletRequest req, HttpServletResponse resp, boolean crashed) {
        if (crashed || resp.getStatus() >= 400 || req.getAttribute("error") != null) return true;
        HttpSession s = req.getSession(false);
        return s != null && "error".equals(s.getAttribute("flashType"));
    }
}
