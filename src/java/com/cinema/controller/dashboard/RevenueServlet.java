package com.cinema.controller.dashboard;

import com.cinema.dao.RevenueDAO;
import com.cinema.model.RevenueFilter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Chi tiết doanh thu (Admin, Manager): các đơn đã thanh toán tạo nên con số doanh thu,
 * theo cùng bộ lọc ngày / loại doanh thu / kênh bán với ô Doanh thu trên dashboard.
 */
@WebServlet(urlPatterns = "/dashboard/revenue")
public class RevenueServlet extends DashboardBaseServlet {
    static final int MAX_ROWS = 500;
    private final RevenueDAO revenueDAO = new RevenueDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        RevenueFilter filter = RevenueFilter.from(req);
        req.setAttribute("rf", filter);
        req.setAttribute("maxRows", MAX_ROWS);
        try {
            req.setAttribute("revenue", revenueDAO.summary(filter));
            req.setAttribute("rows", revenueDAO.findBookings(filter, MAX_ROWS));
        } catch (SQLException e) {
            req.setAttribute("statsError", "Không thể tải doanh thu: " + e.getMessage());
        }
        forward(req, resp, "dashboard/revenue");
    }
}
