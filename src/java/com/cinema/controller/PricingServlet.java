package com.cinema.controller;

import com.cinema.dao.PricingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Bảng giá vé công khai (đọc động từ bảng TicketPrice). URL: /pricing */
@WebServlet("/pricing")
public class PricingServlet extends BaseServlet {

    private final PricingDAO dao = new PricingDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("priceRows", dao.findPriceTable());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.setAttribute("pageTitle", "Bảng giá vé");
        forward(req, resp, "pricing");
    }
}
