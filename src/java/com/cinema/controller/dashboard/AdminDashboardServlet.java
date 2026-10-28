package com.cinema.controller.dashboard;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.cinema.dao.DashboardDAO;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns = "/dashboard/admin")
public class AdminDashboardServlet extends DashboardBaseServlet {
    private final DashboardDAO dashboardDAO = new DashboardDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("stats", dashboardDAO.getAdminStats());
            req.setAttribute("showtimeBars", dashboardDAO.getShowtimesPerDay(14));
            req.setAttribute("roleBars", dashboardDAO.getUsersByRole());
        } catch (SQLException e) {
            req.setAttribute("statsError", "Không thể tải số liệu: " + e.getMessage());
        }
        forward(req, resp, "dashboard/admin-dashboard");
    }
}
