package com.cinema.controller;

import com.cinema.dao.PricingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import com.cinema.model.PriceRow;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Bảng giá vé công khai (đọc động từ bảng TicketPrice). URL: /pricing */
@WebServlet("/pricing")
public class PricingServlet extends BaseServlet {

    private final PricingDAO dao = new PricingDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            List<PriceRow> rows = dao.findPriceTable();
            // Gom theo loại ghế: mỗi loại ghế một bảng (khung giờ x loại ngày).
            Map<String, List<PriceRow>> bySeatType = new LinkedHashMap<>();
            for (PriceRow r : rows) {
                bySeatType.computeIfAbsent(r.getSeatTypeName(), k -> new java.util.ArrayList<>()).add(r);
            }
            req.setAttribute("priceRows", rows);
            req.setAttribute("priceGroups", bySeatType);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.setAttribute("pageTitle", "Bảng giá vé");
        forward(req, resp, "pricing");
    }
}
