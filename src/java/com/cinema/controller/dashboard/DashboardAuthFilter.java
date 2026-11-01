package com.cinema.controller.dashboard;

import com.cinema.model.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;

/**
 * Bảo vệ các URL dashboard: chưa đăng nhập → 302 /login; sai vai trò → 403.
 *
 * <p>Quy ước: admin → ADMIN · manager → MANAGER, ADMIN · staff → STAFF, MANAGER, ADMIN ·
 * customer → CUSTOMER.</p>
 */
@WebFilter(urlPatterns = "/dashboard/*")
public class DashboardAuthFilter extends HttpFilter {

    @Override
    protected void doFilter(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        Object authUser = req.getSession().getAttribute("authUser");
        if (authUser == null) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        String role = authUser instanceof User ? ((User) authUser).getRole() : null;
        if (!allowedRoles(req.getServletPath()).contains(role == null ? "" : role.toUpperCase())) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập trang này.");
            return;
        }
        chain.doFilter(req, res);
    }

    private static Set<String> allowedRoles(String servletPath) {
        switch (servletPath) {
            case "/dashboard/admin":
                return Set.of("ADMIN");
            case "/dashboard/manager":
                return Set.of("MANAGER", "ADMIN");
            case "/dashboard/staff":
                return Set.of("STAFF", "MANAGER", "ADMIN");
            case "/dashboard/customer":
                return Set.of("CUSTOMER");
            default:
                return Set.of();
        }
    }
}
