package com.cinema.controller.dashboard;

import com.cinema.dao.DashboardDAO;
import com.cinema.dao.RevenueDAO;
import com.cinema.model.RevenueFilter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns = "/dashboard/manager")
public class ManagerDashboardServlet extends DashboardBaseServlet {
    private final DashboardDAO dashboardDAO = new DashboardDAO();
    private final RevenueDAO revenueDAO = new RevenueDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            RevenueFilter filter = RevenueFilter.from(req);
            req.setAttribute("rf", filter);
            req.setAttribute("revenue", revenueDAO.summary(filter));
            req.setAttribute("stats", dashboardDAO.getManagerStats());
            req.setAttribute("movieShowtimeBars", dashboardDAO.getUpcomingShowtimesPerMovie(10));
            req.setAttribute("movieStatusBars", dashboardDAO.getMoviesByStatus());
        } catch (SQLException e) {
            req.setAttribute("statsError", "Không thể tải số liệu: " + e.getMessage());
        }
        forward(req, resp, "dashboard/manager-dashboard");
    }
}
