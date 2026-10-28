package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
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
import java.sql.SQLException;

/** Pages under /admin/* require an ACTIVE ADMIN; role and status are re-read from the DB on every request. */
@WebFilter("/admin/*")
public class AdminFilter implements Filter {

    private final UserDAO dao = new UserDAO();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        HttpSession s = req.getSession(false);
        User sessionUser = s == null ? null : (User) s.getAttribute(BaseServlet.SESSION_USER);
        if (sessionUser == null) {
            if ("GET".equals(req.getMethod())) {
                req.getSession().setAttribute("afterLogin", req.getServletPath());
            }
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        try {
            User u = dao.findById(sessionUser.getUserId());
            if (u == null || !"ACTIVE".equals(u.getStatus())) {
                s.invalidate();
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            sessionUser.setRole(u.getRole());
            if (!"ADMIN".equals(u.getRole())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin only");
                return;
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        resp.setHeader("Cache-Control", "no-store");
        chain.doFilter(request, response);
    }
}
