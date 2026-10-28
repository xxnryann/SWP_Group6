package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.SecurityUtil;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/** Manage Personal Account – change password. */
@WebServlet("/account/password")
public class PasswordServlet extends BaseServlet {

    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Đổi mật khẩu nằm trong trang Thông tin cá nhân; giữ URL cũ chuyển hướng về đó.
        resp.sendRedirect(req.getContextPath() + "/account/profile#password");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        String current = req.getParameter("currentPassword");
        String next = req.getParameter("newPassword");
        String confirm = req.getParameter("confirmPassword");
        Map<String, String> errors = new LinkedHashMap<>();
        try {
            User u = dao.findById(currentUser(req).getUserId());
            if (u == null || current == null || !SecurityUtil.checkPassword(current, u.getPasswordHash())) {
                errors.put("currentPassword", "Mật khẩu hiện tại không đúng.");
            }
            if (!Validator.isStrongPassword(next)) {
                errors.put("newPassword", Validator.PASSWORD_RULE);
            } else if (next.equals(current)) {
                errors.put("newPassword", "Mật khẩu mới phải khác mật khẩu hiện tại.");
            } else if (!next.equals(confirm)) {
                errors.put("confirmPassword", "Mật khẩu xác nhận không khớp.");
            }
            if (!errors.isEmpty()) {
                req.setAttribute("profile", u);
                req.setAttribute("errors", errors);
                req.setAttribute("passwordOpen", true);
                forward(req, resp, "profile");
                return;
            }
            dao.updatePassword(u.getUserId(), SecurityUtil.hashPassword(next));
            req.changeSessionId();
            flash(req, "success", "Đã đổi mật khẩu.");
            resp.sendRedirect(req.getContextPath() + "/account/profile");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}
