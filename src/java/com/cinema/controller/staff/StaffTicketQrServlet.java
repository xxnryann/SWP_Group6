package com.cinema.controller.staff;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.TicketDAO;
import com.cinema.model.Ticket;
import com.cinema.model.User;
import com.cinema.util.QrCodeUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.SQLException;

/** Trả về ảnh mã QR của một vé cho NHÂN VIÊN (màn hình bán vé tại quầy). */
@WebServlet("/staff/tickets/qr")
public class StaffTicketQrServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** Kích thước ảnh QR (px). */
    private static final int QR_SIZE = 260;

    private final TicketDAO dao = new TicketDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setCharacterEncoding("UTF-8");

        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        String role = user.getRole();
        if (!"STAFF".equals(role) && !"MANAGER".equals(role) && !"ADMIN".equals(role)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ nhân viên được xem mã vé.");
            return;
        }

        int ticketId;
        try {
            ticketId = Integer.parseInt(req.getParameter("ticketId"));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã vé không hợp lệ.");
            return;
        }

        byte[] png;
        try {
            Ticket ticket = dao.findById(ticketId);
            if (ticket == null || ticket.getTicketCode() == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy vé.");
                return;
            }
            png = QrCodeUtil.toPngBytes(com.cinema.util.TicketLinks.viewUrl(req, ticket.getTicketCode()), QR_SIZE);
        } catch (SQLException e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không tạo được mã QR.");
            return;
        } catch (IOException | IllegalArgumentException e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không tạo được mã QR.");
            return;
        }

        resp.setContentType("image/png");
        resp.setContentLength(png.length);
        resp.setHeader("Cache-Control", "private, max-age=300");
        try (OutputStream out = resp.getOutputStream()) {
            out.write(png);
        }
    }
}
