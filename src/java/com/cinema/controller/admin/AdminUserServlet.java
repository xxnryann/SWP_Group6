package com.cinema.controller.admin;

import com.cinema.controller.BaseServlet;
import com.cinema.controller.filter.AuditFilter;
import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.SecurityUtil;
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

/** User Account Management – list users, block / unblock, reset password (ADMIN only, see AdminFilter). */
@WebServlet("/admin/users")
public class AdminUserServlet extends BaseServlet {

    private static final Set<String> ROLES = Set.of("CUSTOMER", "STAFF", "MANAGER", "ADMIN");
    private static final Set<String> STATUSES = Set.of("PENDING", "ACTIVE", "BLOCKED");
    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String q = Validator.trim(req.getParameter("q"));
        String roleParam = req.getParameter("role");
        String statusParam = req.getParameter("status");
        String role = roleParam != null && ROLES.contains(roleParam) ? roleParam : "";
        String status = statusParam != null && STATUSES.contains(statusParam) ? statusParam : "";
        try {
            req.setAttribute("users", dao.search(q, role, status));
            req.setAttribute("q", q);
            req.setAttribute("fRole", role);
            req.setAttribute("fStatus", status);
            forward(req, resp, "admin/admin-users");
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
                flash(req, "error", "Bạn không thể khóa hoặc đặt lại mật khẩu cho chính tài khoản của mình. Hãy đổi mật khẩu ở trang Thông tin cá nhân.");
            } else if ("password".equals(action)) {
                String pw = req.getParameter("newPassword");
                if (!Validator.isStrongPassword(pw)) {
                    flash(req, "error", Validator.PASSWORD_RULE);
                } else if (!pw.equals(req.getParameter("confirmPassword"))) {
                    flash(req, "error", "Mật khẩu xác nhận không khớp.");
                } else {
                    dao.updatePassword(targetId, SecurityUtil.hashPassword(pw));
                    req.setAttribute(AuditFilter.DETAIL_ATTR, "Đặt lại mật khẩu cho " + target.getEmail());
                    flash(req, "success", "Đã đổi mật khẩu của " + target.getEmail() + ".");
                }
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
