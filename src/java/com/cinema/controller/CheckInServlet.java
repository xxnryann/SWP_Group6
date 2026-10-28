package com.cinema.controller;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.CheckInDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * Soát vé (QR) tại cửa phòng chiếu — nhân viên nhập/quét mã vé, hệ thống gọi sp_CheckInTicket.
 * URL: /staff/checkin  (GET: form + vé soát gần đây, POST: soát vé)
 */
@WebServlet("/staff/checkin")
public class CheckInServlet extends BaseServlet {

    private final CheckInDAO dao = new CheckInDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        render(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "STAFF")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String code = Validator.trim(req.getParameter("ticketCode")).toUpperCase();
        if (code.isEmpty() || code.length() > 30) {
            req.setAttribute("error", "Vui lòng nhập hoặc quét mã vé hợp lệ.");
            render(req, resp);
            return;
        }
        try {
            int staffId = accountDAO.findAccountIdByEmail(currentUser(req).getEmail());
            if (staffId == 0) {
                req.setAttribute("error", "Tài khoản của bạn chưa có trong bảng Account nên không thể soát vé.");
            } else {
                dao.checkIn(code, staffId);
                req.setAttribute("success", "Soát vé thành công — mời khách vào phòng chiếu.");
            }
            Map<String, Object> ticket = dao.findTicket(code);
            req.setAttribute("ticket", ticket);
        } catch (SQLException e) {
            req.setAttribute("error", e.getMessage());
            try {
                req.setAttribute("ticket", dao.findTicket(code));
            } catch (SQLException ignore) {
                // khong co thong tin ve de hien thi
            }
        }
        render(req, resp);
    }

    private void render(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("recent", dao.recent(10));
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải danh sách soát vé: " + e.getMessage());
        }
        req.setAttribute("pageTitle", "Soát vé");
        forward(req, resp, "staff/checkin");
    }
}
