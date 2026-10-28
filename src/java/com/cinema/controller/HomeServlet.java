package com.cinema.controller;

import com.cinema.dao.MovieDAO.HomeMovieDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet(urlPatterns = {"/home", ""})
public class HomeServlet extends BaseServlet {
    private final HomeMovieDAO homeMovieDAO;

    public HomeServlet() {
        this(new HomeMovieDAO());
    }

    HomeServlet(HomeMovieDAO homeMovieDAO) {
        this.homeMovieDAO = homeMovieDAO;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("nowShowingMovies", homeMovieDAO.findNowShowing());
            req.setAttribute("upcomingMovies", homeMovieDAO.findUpcoming());
        } catch (SQLException e) {
            // Không redirect về /home: trang này chính là /home nên sẽ lặp vô hạn.
            // Hiển thị trang với danh sách rỗng kèm thông báo lỗi cho khách.
            getServletContext().log("Unable to load home page movies.", e);
            req.setAttribute("nowShowingMovies", List.of());
            req.setAttribute("upcomingMovies", List.of());
            flash(req, "error", "Không thể tải danh sách phim: " + e.getMessage());
        }
        forward(req, resp, "home");
    }
}
