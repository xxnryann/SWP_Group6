package com.cinema.controller.account;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.TicketDAO;
import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.service.OnlineBookingService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Manage Personal Account – MyPoint balance and ledger. */
@WebServlet("/account/points")
public class PointServlet extends BaseServlet {

    private final TicketDAO ticketDao = new TicketDAO();
    private final UserDAO userDao = new UserDAO();
    private final OnlineBookingService bookingService = new OnlineBookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            int id = currentUser(req).getUserId();
            User fresh = userDao.findById(id);
            if (fresh == null) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            req.getSession().setAttribute(SESSION_USER, sessionCopy(fresh)); // keep sidebar balance current
            req.setAttribute("points", fresh.getMyPoint());
            req.setAttribute("history", ticketDao.findPointHistory(fresh.getEmail()));
            req.setAttribute("pointConfig", bookingService.getPointConfig());
            forward(req, resp, "account/points");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}
