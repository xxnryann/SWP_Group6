package com.cinema.controller.dashboard;

import com.cinema.dao.DashboardDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet(urlPatterns = "/dashboard/customer")
public class CustomerDashboardServlet extends DashboardBaseServlet {
    private final DashboardDAO dashboardDAO;
    
    public CustomerDashboardServlet() {
        this(new DashboardDAO());
    }
    
    CustomerDashboardServlet(DashboardDAO dashboardDAO) {
        this.dashboardDAO = dashboardDAO;
    }
    
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("nowShowingMovies", dashboardDAO.getNowShowingMovies());
            req.setAttribute("upcomingMovies", dashboardDAO.getUpcomingMovies());
        } catch (SQLException e) {
            getServletContext().log("Unable to load customer dashboard movies.", e);
            req.setAttribute("nowShowingMovies", List.of());
            req.setAttribute("upcomingMovies", List.of());
            flash(req, "error", "Không thể tải danh sách phim: " + e.getMessage());
        }
        try {
            // Tin nổi bật: tối đa 4 tin đã đăng có ảnh, mới nhất trước.
            List<com.cinema.model.News> featured = new com.cinema.dao.NewsDAO().findPublished().stream()
                    .filter(n -> n.getThumbnailUrl() != null && !n.getThumbnailUrl().isBlank())
                    .limit(4).toList();
            req.setAttribute("featuredNews", featured);
        } catch (SQLException e) {
            getServletContext().log("Unable to load featured news.", e);
            req.setAttribute("featuredNews", List.of());
        }
        forward(req, resp, "dashboard/customer-dashboard");
    }
}
