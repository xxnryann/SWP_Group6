package com.cinema.controller;

import com.cinema.dao.DashboardDAO;
import com.cinema.dao.NewsDAO;
import com.cinema.model.News;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Trang chủ cho khách (GUEST) và khách hàng: dùng chung giao diện "tổng quan customer"
 * (slider tin nổi bật + tab phim đang chiếu / sắp chiếu).
 */
@WebServlet(urlPatterns = {"/home", ""})
public class HomeServlet extends BaseServlet {
    private final DashboardDAO dashboardDAO;

    public HomeServlet() {
        this(new DashboardDAO());
    }

    HomeServlet(DashboardDAO dashboardDAO) {
        this.dashboardDAO = dashboardDAO;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("nowShowingMovies", dashboardDAO.getNowShowingMovies());
            req.setAttribute("upcomingMovies", dashboardDAO.getUpcomingMovies());
        } catch (SQLException e) {
            // Không redirect về /home: trang này chính là /home nên sẽ lặp vô hạn.
            // Hiển thị trang với danh sách rỗng kèm thông báo lỗi cho khách.
            getServletContext().log("Unable to load home page movies.", e);
            req.setAttribute("nowShowingMovies", List.of());
            req.setAttribute("upcomingMovies", List.of());
            flash(req, "error", "Không thể tải danh sách phim: " + e.getMessage());
        }
        try {
            // Tin nổi bật: tối đa 4 tin đã đăng có ảnh, mới nhất trước.
            List<News> featured = new NewsDAO().findPublished().stream()
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
