package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO.GenreDAO;
import com.cinema.dao.MovieDAO.MovieDAO;
import com.cinema.model.Movie;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns = {"/movies", "/movies/detail"})
public class MovieServlet extends BaseServlet {
    private static final int PAGE_SIZE = 10;
    private final MovieDAO movieDAO;
    private final GenreDAO genreDAO;

    public MovieServlet() {
        this(new MovieDAO(), new GenreDAO());
    }

    MovieServlet(MovieDAO movieDAO, GenreDAO genreDAO) {
        this.movieDAO = movieDAO;
        this.genreDAO = genreDAO;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            if ("/movies/detail".equals(request.getServletPath())) {
                showDetail(request, response);
            } else {
                showMovies(request, response);
            }
        } catch (SQLException e) {
            flash(request, "error", "Không thể tải dữ liệu phim: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }

    private void showMovies(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, ServletException, IOException {
        String status = request.getParameter("status");
        if (!"Upcoming".equals(status) && !"NowShowing".equals(status) && !"Stopped".equals(status)) status = null;
        Integer genreId = parsePositiveInt(request.getParameter("genre"));
        int requestedPage = parsePositiveInt(request.getParameter("page")) == null
                ? 1 : parsePositiveInt(request.getParameter("page"));
        MovieDAO.MoviePage result = movieDAO.filter(genreId, status, requestedPage, PAGE_SIZE);
        request.setAttribute("moviePage", result);
        request.setAttribute("movies", result.movies());
        request.setAttribute("genres", genreDAO.findAll());
        request.setAttribute("selectedGenre", genreId);
        request.setAttribute("selectedStatus", status);
        request.setAttribute("pageTitle", "Phim");
        forward(request, response, "movies");
    }

    private void showDetail(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, ServletException, IOException {
        Integer id = parsePositiveInt(request.getParameter("id"));
        if (id == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        Movie movie = movieDAO.findById(id);
        if (movie == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        request.setAttribute("movie", movie);
        request.setAttribute("pageTitle", movie.getTitle());
        forward(request, response, "movie-detail");
    }

    private Integer parsePositiveInt(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            int parsed = Integer.parseInt(value);
            return parsed > 0 ? parsed : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
