package com.cinema.controller.account;

import com.cinema.controller.BaseServlet;
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
 *   <li>Khách không tự huỷ vé/combo đã thanh toán; chỉ Manager huỷ suất chiếu mới hoàn MyPoint + voucher đền bù.</li>
 * </ul>
 */
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
        if ("cancel".equals(action) || "cancelCombo".equals(action)) {
            // Rule: vé/combo đã thanh toán không thể hủy do lỗi từ phía khách hàng.
            // Chỉ Manager hủy suất chiếu (sự cố) mới hoàn MyPoint + voucher đền bù.
            flash(req, "error", "Vé và sản phẩm đã thanh toán thành công không thể hủy/đổi trả/hoàn tiền.");
        }
        resp.sendRedirect(req.getContextPath() + "/account/tickets");
    }
}
