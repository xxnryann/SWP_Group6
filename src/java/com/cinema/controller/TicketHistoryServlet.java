package com.cinema.controller;

import com.cinema.service.TicketService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Lịch sử vé của khách + huỷ vé (UC18 / UC19).
 *
 * <ul>
 *   <li>GET /account/tickets → danh sách vé (mỗi vé 1 thẻ 1 mã QR)</li>
 *   <li>POST /account/tickets (action=cancel) → huỷ 1 vé còn hiệu lực</li>
 * </ul>
 */
@WebServlet("/account/tickets")
public class TicketHistoryServlet extends BaseServlet {

    private final TicketService service = new TicketService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("tickets", service.getCustomerTickets(currentUser(req).getEmail()));
            forward(req, resp, "tickets");
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

        String action = com.cinema.util.Validator.trim(req.getParameter("action"));
        if ("cancel".equals(action)) {
            doCancel(req, resp);
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/account/tickets");
    }

    /** Huỷ một vé. Vé hết hạn / đã dùng / của người khác → bị từ chối. */
    private void doCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int ticketId;
        try {
            ticketId = Integer.parseInt(com.cinema.util.Validator.trim(req.getParameter("ticketId")));
        } catch (NumberFormatException e) {
            ticketId = 0;
        }

        TicketService.CancelResult result = service.cancelTicket(
                ticketId, currentUser(req).getEmail(),
                com.cinema.util.Validator.trim(req.getParameter("reason")));

        flash(req, result.isSuccess() ? "success" : "error", result.getMessage());
        resp.sendRedirect(req.getContextPath() + "/account/tickets");
    }
}
