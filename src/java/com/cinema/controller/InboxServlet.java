package com.cinema.controller;

import com.cinema.dao.EmailOutboxDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Hộp thư của khách hàng: thông báo đặt vé thành công, phim bị hủy và nhắc lịch chiếu. */
@WebServlet("/account/inbox")
public class InboxServlet extends BaseServlet {

    private final EmailOutboxDAO dao = new EmailOutboxDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "CUSTOMER")) return;
        try {
            req.setAttribute("notifications", dao.customerInbox(currentUser(req).getUserId(), 100));
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        forward(req, resp, "inbox");
    }
}
