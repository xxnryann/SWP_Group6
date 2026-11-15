package com.cinema.controller.filter;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * DEF-001: tài khoản bị khóa (hoặc bị xóa) khi đang đăng nhập phải mất phiên ngay ở request kế tiếp,
 * trên MỌI trang — không chỉ /account, /admin, /booking (vốn có filter riêng).
 *
 * <p>Đăng ký trong web.xml (không dùng @WebFilter) để chắc chắn chạy TRƯỚC mọi filter khai báo bằng
 * annotation (Servlet spec 8.2.3), nhờ đó DashboardAuthFilter, requireRole()... đều thấy phiên đã bị hủy
 * và tự chuyển về /login như với khách chưa đăng nhập.</p>
 *
 * <p>Trang cần đăng nhập → 302 /login. Trang công khai → tiếp tục với tư cách khách vãng lai.</p>
 */
public class ActiveSessionFilter implements Filter {

    private final UserDAO dao = new UserDAO();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        HttpSession s = req.getSession(false);
        Object attr = s == null ? null : s.getAttribute(BaseServlet.SESSION_USER);
        if (!(attr instanceof User) || isStatic(req.getServletPath())) {
            chain.doFilter(request, response);
            return;
        }
        User sessionUser = (User) attr;
        User u;
        try {
            u = dao.findById(sessionUser.getUserId());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        if (u == null || !"ACTIVE".equals(u.getStatus())) {
            try {
                s.invalidate();
            } catch (IllegalStateException ignored) {
                // phiên đã bị hủy song song
            }
            if (requiresLogin(req.getServletPath())) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
        } else {
            sessionUser.setRole(u.getRole());
            sessionUser.setStatus(u.getStatus());
            sessionUser.setFullName(u.getFullName());
            sessionUser.setAvatarUrl(u.getAvatarUrl());
        }
        chain.doFilter(request, response);
    }

    private static boolean isStatic(String path) {
        return path.startsWith("/assets/") || path.startsWith("/media/") || path.equals("/favicon.ico");
    }

    private static boolean requiresLogin(String path) {
        if ("/booking/payment/return".equals(path)) return false; // cổng thanh toán gọi về, không mang phiên
        for (String p : new String[] {"/account", "/booking", "/dashboard", "/staff", "/admin",
                "/manager", "/manage", "/customer"}) {
            if (path.equals(p) || path.startsWith(p + "/")) return true;
        }
        return false;
    }
}
