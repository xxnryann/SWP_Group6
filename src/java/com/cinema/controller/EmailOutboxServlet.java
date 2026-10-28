package com.cinema.controller;

import com.cinema.dao.EmailOutboxDAO;
import com.cinema.service.EmailDispatcher;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Set;

/** Hộp thư đi (nhân viên): xem trạng thái email, gửi ngay các thư chờ, gửi lại thư lỗi. */
@WebServlet("/staff/emails")
public class EmailOutboxServlet extends BaseServlet {

    private static final Set<String> STATUSES = Set.of("Pending", "Sent", "Failed");
    private final EmailOutboxDAO dao = new EmailOutboxDAO();
    private final EmailDispatcher dispatcher = new EmailDispatcher();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        String status = Validator.trim(req.getParameter("status"));
        if (!STATUSES.contains(status)) status = "";
        try {
            req.setAttribute("emails", dao.recent(status, 100));
            req.setAttribute("counts", dao.counts());
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải hộp thư: " + e.getMessage());
        }
        req.setAttribute("status", status);
        req.setAttribute("pageTitle", "Hộp thư đi");
        forward(req, resp, "staff/emails");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        if (!csrfOk(req, resp)) return;
        String action = Validator.trim(req.getParameter("action"));
        try {
            if ("retry".equals(action)) {
                int n = dao.retryFailed();
                flash(req, "success", "Đã đưa " + n + " thư lỗi vào hàng đợi gửi lại.");
            } else if ("dispatch".equals(action)) {
                int sent = dispatcher.dispatchPending(50);
                flash(req, "success", "Đã gửi " + sent + " thư.");
            }
        } catch (SQLException e) {
            flash(req, "error", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/staff/emails");
    }
}
