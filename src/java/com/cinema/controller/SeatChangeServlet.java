package com.cinema.controller;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.SeatChangeDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * Đổi ghế cho vé đã thanh toán (Staff).
 * URL: /staff/seat-change?code=... (GET tra cứu vé + ghế trống), POST đổi ghế.
 */
@WebServlet("/staff/seat-change")
public class SeatChangeServlet extends BaseServlet {

    private final SeatChangeDAO dao = new SeatChangeDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        String code = Validator.trim(req.getParameter("code")).toUpperCase();
        show(req, resp, code);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String code = Validator.trim(req.getParameter("code")).toUpperCase();
        int ticketId = safeId(req.getParameter("ticketId"));
        int newSeatId = safeId(req.getParameter("newSeatId"));
        String reason = Validator.trim(req.getParameter("reason"));
        if (reason.length() > 200) reason = reason.substring(0, 200);
        if (ticketId < 0 || newSeatId < 0) {
            flash(req, "error", "Vui lòng chọn ghế mới.");
        } else {
            try {
                int staffId = accountDAO.findAccountIdByEmail(currentUser(req).getEmail());
                if (staffId == 0) {
                    flash(req, "error", "Tài khoản nhân viên chưa có trong bảng Account.");
                } else {
                    dao.changeSeat(ticketId, newSeatId, staffId, reason.isEmpty() ? null : reason);
                    flash(req, "success", "Đã đổi ghế thành công.");
                }
            } catch (SQLException e) {
                flash(req, "error", e.getMessage());
            }
        }
        resp.sendRedirect(req.getContextPath() + "/staff/seat-change"
                + (code.isEmpty() ? "" : "?code=" + java.net.URLEncoder.encode(code, java.nio.charset.StandardCharsets.UTF_8)));
    }

    private void show(HttpServletRequest req, HttpServletResponse resp, String code) throws ServletException, IOException {
        try {
            if (!code.isEmpty()) {
                Map<String, Object> ticket = dao.findTicket(code);
                if (ticket == null) {
                    req.setAttribute("error", "Không tìm thấy vé có mã \"" + code + "\".");
                } else {
                    req.setAttribute("ticket", ticket);
                    if ("Booked".equals(ticket.get("status"))) {
                        req.setAttribute("freeSeats", dao.freeSeats(((Number) ticket.get("showtime_id")).intValue()));
                    }
                }
            }
            req.setAttribute("changes", dao.recentChanges(10));
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải dữ liệu: " + e.getMessage());
        }
        req.setAttribute("code", code);
        req.setAttribute("pageTitle", "Đổi ghế");
        forward(req, resp, "staff/seat-change");
    }
}
