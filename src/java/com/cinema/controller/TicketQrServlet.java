package com.cinema.controller;

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

/**
 * Trả về ảnh mã QR của một vé (UC18 — vé điện tử QR).
 *
 * <p>URL: {@code GET /account/tickets/qr?ticketId=N} → ảnh PNG.</p>
 *
 * <p>QR chứa mã vé — đúng chuỗi {@code sp_CheckInTicket} tra cứu — nên nhân
 * viên quét mã này ở quầy là soát vé được (UC39).</p>
 *
 * <p><b>Bảo mật:</b> chỉ chủ vé mới xem được mã QR của vé mình. Servlet nằm
 * dưới {@code /account/*} nên {@code AuthFilter} đã bắt buộc đăng nhập; thêm
 * lớp kiểm tra ownership trong DAO để không lộ QR của người khác.</p>
 */
@WebServlet("/account/tickets/qr")
public class TicketQrServlet extends BaseServlet {

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
            resp.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Chưa đăng nhập.");
            return;
        }

        int ticketId;
        try {
            ticketId = Integer.parseInt(req.getParameter("ticketId"));
        } catch (NumberFormatException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Mã vé không hợp lệ.");
            return;
        }

        // Chỉ trả về QR cho vé thuộc đơn của chính người đang đăng nhập.
        Ticket ticket;
        try {
            ticket = dao.findOneByUser(ticketId, user.getEmail());
        } catch (SQLException e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không tạo được mã QR.");
            return;
        }
        if (ticket == null || ticket.getTicketCode() == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy vé.");
            return;
        }

        byte[] png;
        try {
            png = QrCodeUtil.toPngBytes(ticket.getTicketCode(), QR_SIZE);
        } catch (IOException | IllegalArgumentException e) {
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không tạo được mã QR.");
            return;
        }

        resp.setContentType("image/png");
        resp.setContentLength(png.length);
        // Mã vé không đổi theo thời gian → cho phép cache ngắn.
        resp.setHeader("Cache-Control", "private, max-age=300");
        try (OutputStream out = resp.getOutputStream()) {
            out.write(png);
        }
    }
}
