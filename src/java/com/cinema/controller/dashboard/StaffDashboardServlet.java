package com.cinema.controller.dashboard;

import com.cinema.dao.DashboardDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns = "/dashboard/staff")
public class StaffDashboardServlet extends DashboardBaseServlet {
    private final DashboardDAO dashboardDAO = new DashboardDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("stats", dashboardDAO.getStaffStats());
            req.setAttribute("showtimeSales", dashboardDAO.getTodayShowtimeSales(12));
            req.setAttribute("comboStock", dashboardDAO.getComboStock());
        } catch (SQLException e) {
            req.setAttribute("statsError", "Không thể tải số liệu: " + e.getMessage());
        }
        forward(req, resp, "dashboard/staff-dashboard");
    }
}
