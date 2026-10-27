package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO.GenreDAO;
import com.cinema.dao.MovieDAO.MovieDAO;
import com.cinema.model.Genre;
import com.cinema.model.Movie;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import com.cinema.util.MovieUtil.MediaUploadUtil;
import com.cinema.util.MovieUtil.MovieValidator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@WebServlet("/manage/movies")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 101L * 1024L * 1024L,
        maxRequestSize = 110L * 1024L * 1024L
)
public class ManageMovieServlet extends BaseServlet {
    private static final int PAGE_SIZE = 10;
    private final MovieDAO movieDAO;
    private final GenreDAO genreDAO;

    public ManageMovieServlet() {
        this(new MovieDAO(), new GenreDAO());
    }

    ManageMovieServlet(MovieDAO movieDAO, GenreDAO genreDAO) {
        this.movieDAO = movieDAO;
        this.genreDAO = genreDAO;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isManager(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        String idValue = request.getParameter("id");
        try {
            if (idValue != null || "new".equals(request.getParameter("action"))) {
                Movie movie = null;
                if (idValue != null) {
                    int id = parseId(idValue);
                    movie = movieDAO.findById(id);
                    if (movie == null) {
                        response.sendError(HttpServletResponse.SC_NOT_FOUND);
                        return;
                    }
                }
                forwardForm(request, response, movie);
                return;
            }
            int page = positiveInt(request.getParameter("page"), 1);
            MovieDAO.MoviePage result = movieDAO.search(null, null, null, page, PAGE_SIZE);
            request.setAttribute("movies", result.movies());
            request.setAttribute("moviePage", result);
            request.setAttribute("pageTitle", "Quản lý phim");
            forward(request, response, "manage-movies");
        } catch (SQLException e) {
            flash(request, "error", "Không thể tải dữ liệu phim: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/home");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isManager(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        String newPoster = null;
        String newTrailer = null;
        try {
            if (!csrfOk(request, response)) return;
            String action = request.getParameter("action");
            if ("save".equals(action)) {
                Movie oldMovie = saveMovie(request, response);
                newPoster = (String) request.getAttribute("newPoster");
                newTrailer = (String) request.getAttribute("newTrailer");
                flash(request, "success", "Đã lưu thông tin phim thành công.");
                String cleanupWarning = oldMovie == null ? "" : deleteSupersededFiles(oldMovie,
                        (String) request.getAttribute("savedPoster"),
                        (String) request.getAttribute("savedTrailer"));
                if (!cleanupWarning.isEmpty()) flash(request, "info",
                        "Thông tin phim đã lưu nhưng chưa dọn được tệp cũ: " + cleanupWarning);
                newPoster = null;
                newTrailer = null;
            } else if ("delete".equals(action)) {
                deleteMovie(request);
            } else if ("stop".equals(action)) {
                int id = parseId(request.getParameter("id"));
                movieDAO.stop(id);
                flash(request, "success", "Đã ngừng chiếu phim và hủy các suất tương lai chưa bán.");
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (SQLException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            String message = e.getMessage();
            if (e.getErrorCode() == 50200 && (message == null || !message.contains("Ngừng chiếu"))) {
                message = (message == null ? "" : message + " ") + "Hãy dùng chức năng Ngừng chiếu.";
            }
            flash(request, "error", appendCleanupMessage(message, extra));
        } catch (IllegalArgumentException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            flash(request, "error", appendCleanupMessage(e.getMessage(), extra));
        } catch (DateTimeParseException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            flash(request, "error", appendCleanupMessage("Ngày phim không hợp lệ.", extra));
        } catch (IllegalStateException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            flash(request, "error", appendCleanupMessage(
                    "Tệp tải lên vượt giới hạn cho phép (poster tối đa 5 MB, video tối đa 100 MB).", extra));
        } catch (IOException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            flash(request, "error", appendCleanupMessage("Không thể lưu hoặc dọn tệp media: " + e.getMessage(), extra));
        } catch (ServletException e) {
            String extra = cleanupNewFilesFromRequest(request, newPoster, newTrailer);
            if (isUploadSizeException(e)) {
                flash(request, "error", appendCleanupMessage(
                        "Tệp tải lên vượt giới hạn cho phép (poster tối đa 5 MB, video tối đa 100 MB).", extra));
            } else {
                throw e;
            }
        }
        response.sendRedirect(request.getContextPath() + "/manage/movies");
    }

    private Movie saveMovie(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException, ServletException {
        String idValue = request.getParameter("id");
        int id = idValue == null || idValue.isBlank() ? 0 : parseId(idValue);
        Movie oldMovie = id == 0 ? null : movieDAO.findById(id);
        if (id > 0 && oldMovie == null) throw new IllegalArgumentException("Không tìm thấy phim cần sửa.");
        Movie movie = readMovie(request, id);
        String posterInput = trimToNull(request.getParameter("posterUrl"));
        String trailerInput = trimToNull(request.getParameter("trailerUrl"));
        boolean removePoster = request.getParameter("deletePoster") != null;
        boolean removeTrailer = request.getParameter("deleteTrailer") != null;
        if (posterInput != null && posterInput.startsWith("/media/")
                && (oldMovie == null || !posterInput.equals(oldMovie.getPosterUrl()))) {
            throw new IllegalArgumentException("Không được nhập trực tiếp đường dẫn tệp media.");
        }
        if (removePoster) movie.setPosterUrl(null);
        else if (posterInput != null) movie.setPosterUrl(posterInput);
        else movie.setPosterUrl(oldMovie == null ? null : oldMovie.getPosterUrl());
        if (removeTrailer) {
            movie.setTrailerUrl(null);
            movie.setTrailerFile(null);
        } else {
            movie.setTrailerUrl(trailerInput != null ? trailerInput : oldMovie == null ? null : oldMovie.getTrailerUrl());
            movie.setTrailerFile(oldMovie == null ? null : oldMovie.getTrailerFile());
        }
        String validationMessage = MovieValidator.validate(movie);
        if (validationMessage != null) throw new IllegalArgumentException(validationMessage);

        Part posterPart = request.getPart("posterFile");
        Part trailerPart = request.getPart("trailerFile");
        String posterPath = MediaUploadUtil.store(posterPart, MediaUploadUtil.MediaType.POSTER);
        request.setAttribute("newPoster", posterPath);
        String trailerPath = MediaUploadUtil.store(trailerPart, MediaUploadUtil.MediaType.TRAILER);
        request.setAttribute("newTrailer", trailerPath);
        if (posterPath != null) movie.setPosterUrl(posterPath);
        if (trailerPath != null) movie.setTrailerFile(trailerPath);
        int[] genreIds = parseGenreIds(request.getParameterValues("genreIds"));
        String savedPoster = movie.getPosterUrl();
        String savedTrailer = movie.getTrailerFile();
        movieDAO.save(movie, join(genreIds), currentUser(request).getUserId());
        request.setAttribute("savedPoster", savedPoster);
        request.setAttribute("savedTrailer", savedTrailer);
        return oldMovie;
    }

    private void deleteMovie(HttpServletRequest request) throws SQLException, IOException {
        int id = parseId(request.getParameter("id"));
        Movie movie = movieDAO.findById(id);
        if (movie == null) throw new IllegalArgumentException("Không tìm thấy phim cần xóa.");
        movieDAO.delete(id);
        String failure = cleanupNewFiles(movie.getPosterUrl(), movie.getTrailerFile());
        if (failure.isEmpty()) flash(request, "success", "Đã xóa phim và các tệp poster, trailer.");
        else flash(request, "info", "Đã xóa phim nhưng không dọn được một số tệp media: " + failure);
    }

    private void forwardForm(HttpServletRequest request, HttpServletResponse response, Movie movie)
            throws SQLException, ServletException, IOException {
        List<Genre> genres = genreDAO.findAll();
        Set<Integer> selected = movie == null ? Set.of() : parseGenreIdSet(movie.getGenreIds());
        for (Genre genre : genres) genre.setSelected(selected.contains(genre.getGenreId()));
        request.setAttribute("movie", movie == null ? new Movie() : movie);
        request.setAttribute("posterExternalUrl", movie != null && movie.getPosterDisplayUrl() != null
                && movie.getPosterUrl() != null && !movie.getPosterUrl().startsWith("/media/") ? movie.getPosterUrl() : "");
        request.setAttribute("genres", genres);
        request.setAttribute("pageTitle", movie == null ? "Thêm phim" : "Sửa phim");
        forward(request, response, "movie-form");
    }

    private Movie readMovie(HttpServletRequest request, int id) {
        Movie movie = new Movie();
        movie.setMovieId(id);
        movie.setTitle(request.getParameter("title") == null ? null : request.getParameter("title").trim());
        movie.setOriginalTitle(trimToNull(request.getParameter("originalTitle")));
        movie.setSynopsis(trimToNull(request.getParameter("synopsis")));
        movie.setDirector(trimToNull(request.getParameter("director")));
        movie.setMainCast(trimToNull(request.getParameter("mainCast")));
        movie.setDurationMinutes(positiveInt(request.getParameter("durationMinutes"), 0));
        movie.setSpokenLanguage(trimToNull(request.getParameter("spokenLanguage")));
        movie.setCountry(trimToNull(request.getParameter("country")));
        movie.setAgeRating(request.getParameter("ageRating"));
        movie.setReleaseDate(MovieValidator.parseDate(request.getParameter("releaseDate")));
        movie.setEndDate(MovieValidator.parseDate(request.getParameter("endDate")));
        movie.setStatus(request.getParameter("status"));
        movie.setPosterUrl(trimToNull(request.getParameter("posterUrl")));
        movie.setTrailerUrl(trimToNull(request.getParameter("trailerUrl")));
        return movie;
    }

    private boolean isManager(HttpServletRequest request) {
        User user = currentUser(request);
        return user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole());
    }

    private int[] parseGenreIds(String[] values) {
        if (values == null || values.length == 0) return new int[0];
        return java.util.Arrays.stream(values).mapToInt(value -> parseId(value)).distinct().toArray();
    }

    private Set<Integer> parseGenreIdSet(String ids) {
        if (ids == null || ids.isBlank()) return Set.of();
        return java.util.Arrays.stream(ids.split(",")).map(String::trim)
                .filter(value -> !value.isEmpty()).map(this::parseId).collect(java.util.stream.Collectors.toSet());
    }

    private String join(int[] values) {
        return java.util.Arrays.stream(values).mapToObj(Integer::toString)
                .collect(java.util.stream.Collectors.joining(","));
    }

    private int parseId(String value) {
        try {
            int id = Integer.parseInt(value);
            if (id > 0) return id;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Mã phim hoặc thể loại không hợp lệ.");
        }
        throw new IllegalArgumentException("Mã phim hoặc thể loại không hợp lệ.");
    }

    private int positiveInt(String value, int fallback) {
        if (value == null || value.isBlank()) return fallback;
        try {
            int parsed = Integer.parseInt(value);
            return parsed > 0 ? parsed : fallback;
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String deleteSupersededFiles(Movie oldMovie, String newPoster, String newTrailer) {
        String failure = "";
        if (oldMovie.getPosterUrl() != null && !Objects.equals(oldMovie.getPosterUrl(), newPoster)) {
            failure = appendMessage(failure, cleanupNewFiles(oldMovie.getPosterUrl(), null));
        }
        if (oldMovie.getTrailerFile() != null && !Objects.equals(oldMovie.getTrailerFile(), newTrailer)) {
            failure = appendMessage(failure, cleanupNewFiles(null, oldMovie.getTrailerFile()));
        }
        return failure;
    }

    private String cleanupNewFiles(String poster, String trailer) {
        String failure = "";
        try {
            MediaUploadUtil.delete(poster);
        } catch (IOException e) {
            failure = appendMessage(failure, "poster: " + e.getMessage());
        }
        try {
            MediaUploadUtil.delete(trailer);
        } catch (IOException e) {
            failure = appendMessage(failure, "trailer: " + e.getMessage());
        }
        return failure;
    }

    private String cleanupNewFilesFromRequest(HttpServletRequest request, String poster, String trailer) {
        String newPoster = poster != null ? poster : (String) request.getAttribute("newPoster");
        String newTrailer = trailer != null ? trailer : (String) request.getAttribute("newTrailer");
        return cleanupNewFiles(newPoster, newTrailer);
    }

    private String appendCleanupMessage(String message, String cleanup) {
        return cleanup.isEmpty() ? message : appendMessage(message, "Không thể dọn tệp mới: " + cleanup);
    }

    private String appendMessage(String first, String second) {
        if (first == null || first.isBlank()) return second == null ? "" : second;
        if (second == null || second.isBlank()) return first;
        return first + " " + second;
    }

    private boolean isUploadSizeException(Throwable error) {
        for (Throwable current = error; current != null; current = current.getCause()) {
            if (current instanceof IllegalStateException) return true;
        }
        return false;
    }
}
