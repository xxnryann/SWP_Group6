package com.cinema.controller;

import com.cinema.dao.EmailOutboxDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Hộp thư của khách hàng: thông báo vé, nhắc lịch chiếu, phim mới và ưu đãi voucher. Lọc theo ?type=NewMovie|Voucher. */
@WebServlet("/account/inbox")
public class InboxServlet extends BaseServlet {

    private final EmailOutboxDAO dao = new EmailOutboxDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "CUSTOMER")) return;
        int customerId = currentUser(req).getUserId();
        String param = req.getParameter("type");
        String type = "NewMovie".equals(param) || "Voucher".equals(param) ? param : null;
        // Lỗi bổ sung thông báo mới không được làm hỏng việc xem các thông báo đã có.
        try {
            dao.syncInboxPromotions(customerId);
        } catch (SQLException e) {
            getServletContext().log("Cannot sync inbox promotions for customer " + customerId, e);
        }
        try {
            req.setAttribute("inboxType", type);
            req.setAttribute("notifications", dao.customerInbox(customerId, 100, type));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        forward(req, resp, "inbox");
    }
}
