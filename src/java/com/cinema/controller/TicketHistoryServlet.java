package com.cinema.controller;

import com.cinema.dao.TicketDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Manage Personal Account – ticket purchase history. */
@WebServlet("/account/tickets")
public class TicketHistoryServlet extends BaseServlet {

    private final TicketDAO dao = new TicketDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("tickets", dao.findByUser(currentUser(req).getUserId()));
            forward(req, resp, "tickets");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }
}
