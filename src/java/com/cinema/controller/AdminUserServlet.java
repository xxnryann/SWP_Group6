package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.Set;

/** User Account Management – list users, block / unblock, change role (ADMIN only, see AdminFilter). */
@WebServlet("/admin/users")
public class AdminUserServlet extends BaseServlet {

    private static final Set<String> ROLES = Set.of("CUSTOMER", "STAFF", "MANAGER", "ADMIN");
    private static final Set<String> STATUSES = Set.of("PENDING", "ACTIVE", "BLOCKED");
    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String q = Validator.trim(req.getParameter("q"));
        String role = ROLES.contains(req.getParameter("role")) ? req.getParameter("role") : "";
        String status = STATUSES.contains(req.getParameter("status")) ? req.getParameter("status") : "";
        try {
            req.setAttribute("users", dao.search(q, role, status));
            req.setAttribute("q", q);
            req.setAttribute("fRole", role);
            req.setAttribute("fStatus", status);
            forward(req, resp, "admin-users");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        String value = req.getParameter("value");
        int targetId;
        try {
            targetId = Integer.parseInt(req.getParameter("userId"));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        try {
            User target = dao.findById(targetId);
            if (target == null) {
                flash(req, "error", "Không tìm thấy tài khoản.");
            } else if (target.getUserId() == currentUser(req).getUserId()) {
                flash(req, "error", "Bạn không thể thay đổi quyền hoặc khóa chính tài khoản của mình.");
            } else if ("role".equals(action) && ROLES.contains(value)) {
                dao.updateRole(targetId, value);
                flash(req, "success", "Đã đổi quyền của " + target.getEmail() + " thành " + value + ".");
            } else if ("status".equals(action) && ("ACTIVE".equals(value) || "BLOCKED".equals(value))) {
                if ("PENDING".equals(target.getStatus())) {
                    flash(req, "error", "Tài khoản chưa xác thực OTP, không thể khóa/mở.");
                } else {
                    dao.updateStatus(targetId, value);
                    flash(req, "success", ("BLOCKED".equals(value) ? "Đã khóa " : "Đã mở khóa ") + target.getEmail() + ".");
                }
            } else {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        // go back to the same filtered list
        String back = req.getContextPath() + "/admin/users?q=" + enc(req.getParameter("q"))
                + "&role=" + enc(req.getParameter("fRole")) + "&status=" + enc(req.getParameter("fStatus"));
        resp.sendRedirect(back);
    }

    private static String enc(String s) {
        return URLEncoder.encode(s == null ? "" : s, StandardCharsets.UTF_8);
    }
}
