package com.cinema.controller.dashboard;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Filter để xác thực user khi truy cập dashboard.
 * Kiểm tra session xác thực và chuyển hướng nếu chưa đăng nhập.
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
        chain.doFilter(req, res);
    }
}
