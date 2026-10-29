package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO.GenreDAO;
import com.cinema.dao.MovieDAO.MovieDAO;
import com.cinema.model.Movie;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(urlPatterns = {"/movies", "/movies/detail"})
public class MovieServlet extends BaseServlet {
    private static final int PAGE_SIZE = 50;
    private final MovieDAO movieDAO;
    private final GenreDAO genreDAO;
    private final com.cinema.dao.ReviewDAO reviewDAO = new com.cinema.dao.ReviewDAO();
    private final com.cinema.dao.AccountDAO accountDAO = new com.cinema.dao.AccountDAO();

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
        // Mọi người dùng xem được toàn bộ danh sách phim và lọc theo trạng thái.
        boolean canFilterByStatus = true;
        String status = request.getParameter("status");
        if (!"Upcoming".equals(status) && !"NowShowing".equals(status) && !"Stopped".equals(status)) status = null;
        Integer genreId = parsePositiveInt(request.getParameter("genre"));
        int requestedPage = parsePositiveInt(request.getParameter("page")) == null
                ? 1 : parsePositiveInt(request.getParameter("page"));
        // Khách và customer không thấy phim đã kết thúc; quản lý vẫn xem được tất cả.
        User viewer = currentUser(request);
        boolean publicView = viewer == null || "CUSTOMER".equals(viewer.getRole());
        if (publicView && "Stopped".equals(status)) status = null;
        MovieDAO.MoviePage result = movieDAO.filter(genreId, status, requestedPage, PAGE_SIZE, publicView);
        request.setAttribute("hideEndedFilter", publicView);
        request.setAttribute("moviePage", result);
        request.setAttribute("movies", result.movies());
        request.setAttribute("genres", genreDAO.findAll());
        request.setAttribute("selectedGenre", genreId);
        request.setAttribute("selectedStatus", status);
        request.setAttribute("pageTitle", "Phim");
        request.setAttribute("showStatusFilter", canFilterByStatus);
        // Nút "Mua vé" chỉ hiện cho khách / khách vãng lai và chỉ với phim còn suất chiếu sắp tới.
        boolean canBuy = viewer == null || "CUSTOMER".equals(viewer.getRole());
        request.setAttribute("canBuy", canBuy);
        if (canBuy) request.setAttribute("bookableIds", MovieShowtimesServlet.bookableMovieIds());
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
        loadReviews(request, movie.getMovieId());
        User viewer = currentUser(request);
        request.setAttribute("canBuy", viewer == null || "CUSTOMER".equals(viewer.getRole()));
        request.setAttribute("movie", movie);
        request.setAttribute("pageTitle", movie.getTitle());
        forward(request, response, "movie-detail");
    }

    /** Nạp đánh giá của phim và trạng thái được phép đánh giá của khách đang đăng nhập. */
    private void loadReviews(HttpServletRequest request, int movieId) {
        try {
            request.setAttribute("reviews", reviewDAO.findByMovie(movieId));
            request.setAttribute("reviewStats", reviewDAO.stats(movieId));
            User user = currentUser(request);
            if (user != null && "CUSTOMER".equals(user.getRole())) {
                int customerId = accountDAO.findAccountIdByEmail(user.getEmail());
                if (customerId > 0) {
                    boolean reviewed = reviewDAO.hasReviewed(customerId, movieId);
                    request.setAttribute("hasReviewed", reviewed);
                    request.setAttribute("canReview", !reviewed && reviewDAO.hasWatched(customerId, movieId));
                }
            }
        } catch (SQLException e) {
            getServletContext().log("Cannot load reviews for movie " + movieId, e);
        }
    }

    private boolean canManageMovies(HttpServletRequest request) {
        User user = currentUser(request);
        return user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole());
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
