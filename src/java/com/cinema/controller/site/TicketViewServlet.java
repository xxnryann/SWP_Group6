package com.cinema.controller.site;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.TicketDAO;
import com.cinema.model.Ticket;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.regex.Pattern;

/** Trang thông tin vé mà mã QR trỏ tới: GET /ticket/view?code=TK... */
@WebServlet("/ticket/view")
public class TicketViewServlet extends BaseServlet {

    private static final Pattern CODE = Pattern.compile("^TK[0-9A-Z]{6,28}$");
    private final TicketDAO dao = new TicketDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setHeader("Cache-Control", "no-store");
        resp.setHeader("X-Robots-Tag", "noindex");
        String code = req.getParameter("code") == null ? "" : req.getParameter("code").trim().toUpperCase();
        Ticket ticket = null;
        if (CODE.matcher(code).matches()) {
            try {
                ticket = dao.findByCode(code);
            } catch (SQLException e) {
                throw new ServletException(e);
            }
        }
        if (ticket == null) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
        }
        req.setAttribute("ticket", ticket);
        req.getRequestDispatcher("/WEB-INF/views/site/ticket-view.jsp").forward(req, resp);
    }
}
