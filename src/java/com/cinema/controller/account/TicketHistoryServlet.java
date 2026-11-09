package com.cinema.controller.account;

import com.cinema.controller.BaseServlet;
import com.cinema.service.TicketService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Lịch sử vé của khách + huỷ vé (UC18 / UC19). */
@WebServlet("/account/tickets")
public class TicketHistoryServlet extends BaseServlet {

    private static final int PAGE_SIZE = 10;
    private final TicketService service = new TicketService();

    /** Cắt danh sách theo ?page=, số trang ngoài khoảng được đưa về trang gần nhất. */
    private static <T> java.util.List<T> paginate(HttpServletRequest req, java.util.List<T> all) {
        int totalPages = Math.max(1, (all.size() + PAGE_SIZE - 1) / PAGE_SIZE);
        int page = Math.min(Math.max(requestedPage(req), 1), totalPages);
        req.setAttribute("page", page);
        req.setAttribute("totalPages", totalPages);
        return all.subList((page - 1) * PAGE_SIZE, Math.min(page * PAGE_SIZE, all.size()));
    }

    private static int requestedPage(HttpServletRequest req) {
        try {
            return Integer.parseInt(com.cinema.util.Validator.trim(req.getParameter("page")));
        } catch (NumberFormatException e) {
            return 1;
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            String email = currentUser(req).getEmail();
            boolean combos = "combos".equals(req.getParameter("tab"));
            req.setAttribute("tab", combos ? "combos" : "tickets");
            if (combos) {
                req.setAttribute("cancelHours", new com.cinema.dao.SystemDAO().configInt("CANCEL_BEFORE_HOURS", 2));
                req.setAttribute("comboOrders", paginate(req, service.getCustomerCombos(email)));
            } else {
                req.setAttribute("cancelHours", new com.cinema.dao.SystemDAO().configInt("CANCEL_BEFORE_HOURS", 2));
                req.setAttribute("tickets", paginate(req, service.getCustomerTickets(email)));
            }
            forward(req, resp, "account/tickets");
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
        if ("cancelCombo".equals(action)) {
            doCancelCombo(req, resp);
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/account/tickets");
    }

    private void doCancelCombo(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int bookingId;
        try {
            bookingId = Integer.parseInt(com.cinema.util.Validator.trim(req.getParameter("bookingId")));
        } catch (NumberFormatException e) {
            bookingId = 0;
        }
        TicketService.CancelResult result = service.cancelCombo(bookingId, currentUser(req).getEmail());
        flash(req, result.isSuccess() ? "success" : "error", result.getMessage());
        resp.sendRedirect(req.getContextPath() + "/account/tickets?tab=combos&page=" + Math.max(requestedPage(req), 1));
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
        resp.sendRedirect(req.getContextPath() + "/account/tickets?page=" + Math.max(requestedPage(req), 1));
    }
}
