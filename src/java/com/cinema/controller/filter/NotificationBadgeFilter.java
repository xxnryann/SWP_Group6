package com.cinema.controller.filter;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.EmailOutboxDAO;
import com.cinema.model.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Chuông thông báo: với khách hàng đã đăng nhập, đặt {@code unreadNotifications} = số thông báo
 * chưa đọc trong Hộp thư để header hiện số đỏ. Bỏ qua file tĩnh và các vai trò khác.
 */
@WebFilter(urlPatterns = "/*")
public class NotificationBadgeFilter extends HttpFilter {

    private final EmailOutboxDAO dao = new EmailOutboxDAO();

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        String path = req.getServletPath();
        boolean asset = path.startsWith("/assets/") || path.startsWith("/media/")
                || path.lastIndexOf('.') > path.lastIndexOf('/');
        if (!asset && "GET".equals(req.getMethod())) {
            HttpSession session = req.getSession(false);
            Object u = session == null ? null : session.getAttribute(BaseServlet.SESSION_USER);
            if (u instanceof User && "CUSTOMER".equals(((User) u).getRole())) {
                try {
                    req.setAttribute("unreadNotifications", dao.countUnreadByEmail(((User) u).getEmail()));
                } catch (SQLException e) {
                    // Không đếm được thì chỉ không hiện số, trang vẫn hoạt động bình thường.
                    req.getServletContext().log("Cannot count unread notifications", e);
                }
            }
        }
        chain.doFilter(req, res);
    }
}
