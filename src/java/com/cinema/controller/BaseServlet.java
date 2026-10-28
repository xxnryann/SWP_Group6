package com.cinema.controller;

import com.cinema.model.User;
import com.cinema.util.SecurityUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public abstract class BaseServlet extends HttpServlet {

    public static final String SESSION_USER = "authUser";

    /** Đọc id số nguyên dương từ tham số; trả -1 nếu thiếu hoặc không hợp lệ (thay cho Integer.parseInt gây 500). */
    protected static int safeId(String value) {
        if (value == null) return -1;
        try {
            int id = Integer.parseInt(value.trim());
            return id > 0 ? id : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    protected void forward(HttpServletRequest req, HttpServletResponse resp, String view)
            throws ServletException, IOException {
        req.setAttribute("csrf", SecurityUtil.csrfToken(req.getSession()));
        req.getRequestDispatcher("/WEB-INF/views/" + view + ".jsp").forward(req, resp);
    }

    /** Rejects the POST (403) when the CSRF token is missing or wrong. */
    protected boolean csrfOk(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (SecurityUtil.csrfValid(req)) {
            return true;
        }
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid CSRF token");
        return false;
    }

    /**
     * Chặn truy cập theo vai trò: chưa đăng nhập -> chuyển về /login, sai vai trò -> 403.
     * @return true nếu người dùng có một trong các vai trò cho phép.
     */
    protected boolean requireRole(HttpServletRequest req, HttpServletResponse resp, String... roles)
            throws IOException {
        User u = currentUser(req);
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        for (String role : roles) {
            if (role.equals(u.getRole())) return true;
        }
        resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền truy cập trang này.");
        return false;
    }

    protected User currentUser(HttpServletRequest req) {
        var s = req.getSession(false);
        return s == null ? null : (User) s.getAttribute(SESSION_USER);
    }

    /** Session copy without secrets (hash, OTP). */
    protected User sessionCopy(User u) {
        User c = new User();
        c.setUserId(u.getUserId());
        c.setFullName(u.getFullName());
        c.setEmail(u.getEmail());
        c.setRole(u.getRole());
        c.setStatus(u.getStatus());
        c.setMyPoint(u.getMyPoint());
        return c;
    }

    protected void flash(HttpServletRequest req, String type, String message) {
        var s = req.getSession();
        s.setAttribute("flashType", type);
        s.setAttribute("flashMsg", message);
    }
}
