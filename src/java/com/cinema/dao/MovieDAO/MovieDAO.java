package com.cinema.dao.MovieDAO;

import com.cinema.model.Movie;
import com.cinema.util.DBContext;
import com.cinema.util.MovieUtil.MovieSchedule;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class MovieDAO {
    /**
     * Trang kết quả phim + thông tin phân trang.
     *
     * <p>EL của JSP chỉ nhận accessor theo quy ước JavaBean
     * ({@code getX()}/{@code isX()}), <b>không</b> nhận accessor kiểu record
     * ({@code x()}). Vì vậy các getter dưới đây là bắt buộc để
     * {@code ${moviePage.totalPages}} hoạt động trong JSP.</p>
     */
    public record MoviePage(List<Movie> movies, int page, int totalPages, int totalItems) {
        public int getPage() {
            return page;
        }

        public int getTotalPages() {
            return totalPages;
        }

        public int getTotalItems() {
            return totalItems;
        }
    }

    private static final String FROM_VIEW = " FROM dbo.vw_MovieDetail d "
            + "WHERE (? IS NULL OR "
            + "((? = 'Upcoming' AND d.release_date > CAST(GETDATE() AS DATE)) "
            + "OR (? = 'NowShowing' AND d.release_date <= CAST(GETDATE() AS DATE) "
            + "AND (d.end_date IS NULL OR d.end_date >= CAST(GETDATE() AS DATE)) "
            + "AND d.status <> 'Stopped') "
            + "OR (? = 'Stopped' AND (d.status = 'Stopped' "
            + "OR (d.end_date IS NOT NULL AND d.end_date < CAST(GETDATE() AS DATE)))))) "
            + "AND (? IS NULL OR EXISTS (SELECT 1 FROM dbo.MovieGenre mg "
            + "WHERE mg.movie_id = d.movie_id AND mg.genre_id = ?)) ";

    /** Quản lý: xem tất cả phim, kể cả phim đã kết thúc. */
    public MoviePage filter(Integer genreId, String status, int requestedPage, int pageSize)
            throws SQLException {
        return filter(genreId, status, requestedPage, pageSize, false);
    }

    /**
     * @param publicView true = khách / customer: ẩn phim đã kết thúc (hết hạn chiếu hoặc bị dừng),
     *                   xếp phim đang chiếu lên đầu, phim sắp chiếu phía sau. Phim kết thúc chỉ hiện lại
     *                   khi được mở chiếu lại (status khác Stopped và end_date còn hiệu lực).
     */
    public MoviePage filter(Integer genreId, String status, int requestedPage, int pageSize, boolean publicView)
            throws SQLException {
        String visible = publicView
                ? " AND d.status <> 'Stopped' AND (d.end_date IS NULL OR d.end_date >= CAST(GETDATE() AS DATE)) "
                : "";
        String order = publicView
                ? "ORDER BY CASE WHEN d.release_date <= CAST(GETDATE() AS DATE) THEN 0 ELSE 1 END, "
                  + "CASE WHEN d.release_date <= CAST(GETDATE() AS DATE) THEN d.created_at END DESC, "
                  + "d.release_date ASC, d.movie_id DESC "
                : "ORDER BY d.created_at DESC, d.movie_id DESC ";
        String cleanStatus = status == null || status.isBlank() ? null : status;
        int count;
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*)" + FROM_VIEW + visible)) {
            bindFilters(statement, genreId, cleanStatus);
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                count = result.getInt(1);
            }
        }
        int totalPages = Math.max(1, (int) Math.ceil((double) count / pageSize));
        int page = Math.max(1, Math.min(requestedPage, totalPages));
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT d.*" + FROM_VIEW + visible
                + order + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            int next = bindFilters(statement, genreId, cleanStatus);
            statement.setInt(next++, (page - 1) * pageSize);
            statement.setInt(next, pageSize);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) movies.add(map(result));
            }
        }
        return new MoviePage(movies, page, totalPages, count);
    }

    public Movie findById(int id) throws SQLException {
        String sql = "SELECT * FROM dbo.vw_MovieDetail WHERE movie_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? map(result) : null;
            }
        }
    }

    public List<Movie> findAllForShowtime() throws SQLException {
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT * FROM dbo.vw_MovieDetail "
                + "WHERE status <> 'Stopped' "
                + "AND (end_date IS NULL OR end_date >= CAST(GETDATE() AS DATE)) "
                + "ORDER BY title";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                movies.add(map(result));
            }
        }
        return movies;
    }

    /**
     * Các phim đang được phát hành vào một ngày cụ thể (dùng để xếp lịch tự động).
     *
     * @param date ngày cần xếp lịch
     */
    public List<Movie> findAllForDate(LocalDate date) throws SQLException {
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT * FROM dbo.vw_MovieDetail "
                + "WHERE status <> 'Stopped' "
                + "AND release_date <= ? "
                + "AND (end_date IS NULL OR end_date >= ?) "
                + "ORDER BY title";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(date));
            statement.setDate(2, Date.valueOf(date));
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    movies.add(map(result));
                }
            }
        }
        return movies;
    }

    public int save(Movie movie, String genreIds, int accountId) throws SQLException {
        String sql = "{CALL dbo.sp_SaveMovie(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall(sql)) {
            if (movie.getMovieId() > 0) statement.setInt(1, movie.getMovieId());
            else statement.setNull(1, Types.INTEGER);
            statement.setString(2, movie.getTitle());
            statement.setString(3, movie.getOriginalTitle());
            statement.setString(4, movie.getSynopsis());
            statement.setString(5, movie.getDirector());
            statement.setString(6, movie.getMainCast());
            statement.setInt(7, movie.getDurationMinutes());
            statement.setString(8, movie.getSpokenLanguage());
            statement.setString(9, movie.getCountry());
            statement.setString(10, movie.getAgeRating());
            statement.setString(11, movie.getTrailerUrl());
            statement.setString(12, movie.getPosterUrl());
            statement.setDate(13, Date.valueOf(movie.getReleaseDate()));
            if (movie.getEndDate() == null) statement.setNull(14, Types.DATE);
            else statement.setDate(14, Date.valueOf(movie.getEndDate()));
            statement.setString(15, movie.getStatus());
            statement.setString(16, genreIds);
            statement.setInt(17, accountId);
            statement.registerOutParameter(18, Types.INTEGER);
            statement.setString(19, movie.getTrailerFile());
            statement.execute();
            return statement.getInt(18);
        }
    }

    /** Xóa phim; phim đã có lịch sử chỉ bị ẩn. @return true nếu dòng phim thực sự bị xóa khỏi CSDL. */
    public boolean delete(int id) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_DeleteMovie(?, ?)}")) {
            statement.setInt(1, id);
            statement.registerOutParameter(2, Types.BIT);
            statement.execute();
            return statement.getBoolean(2);
        }
    }

    public void stop(int id) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_StopMovie(?)}")) {
            statement.setInt(1, id);
            statement.execute();
        }
    }

    /** Xem trước tác động của việc hủy phim: các suất sắp chiếu bị hủy và số vé đã bán ({@code sp_CancelMovie} @confirm=0). */
    public java.util.List<java.util.Map<String, Object>> cancelPreview(int movieId) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_CancelMovie(?, ?, ?)}")) {
            statement.setInt(1, movieId);
            statement.setInt(2, 0);
            statement.setBoolean(3, false);
            boolean hasResult = statement.execute();
            while (!hasResult && statement.getUpdateCount() != -1) {
                hasResult = statement.getMoreResults();
            }
            if (!hasResult) return new ArrayList<>();
            try (ResultSet result = statement.getResultSet()) {
                return com.cinema.util.Rows.read(result);
            }
        }
    }

    /** Hủy phim đang chiếu: hủy mọi suất sắp chiếu, hoàn tiền/điểm/voucher và gửi email báo khách ({@code sp_CancelMovie} @confirm=1). */
    public void cancelMovie(int movieId, int managerAccountId) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_CancelMovie(?, ?, ?)}")) {
            statement.setInt(1, movieId);
            statement.setInt(2, managerAccountId);
            statement.setBoolean(3, true);
            // Procedure trả về một result set (danh sách suất) trước khi thực hiện các lệnh hủy/hoàn tiền;
            // phải đọc hết mọi kết quả thì driver mới chạy xong procedure và ném lỗi (nếu có).
            boolean hasResult = statement.execute();
            while (hasResult || statement.getUpdateCount() != -1) {
                hasResult = statement.getMoreResults();
            }
        }
    }

    private int bindFilters(PreparedStatement statement, Integer genreId, String status)
            throws SQLException {
        int index = 1;
        statement.setString(index++, status);
        statement.setString(index++, status);
        statement.setString(index++, status);
        statement.setString(index++, status);
        if (genreId == null) statement.setNull(index++, Types.INTEGER);
        else statement.setInt(index++, genreId);
        if (genreId == null) statement.setNull(index++, Types.INTEGER);
        else statement.setInt(index++, genreId);
        return index;
    }

    private Movie map(ResultSet result) throws SQLException {
        Movie movie = new Movie();
        movie.setMovieId(result.getInt("movie_id"));
        movie.setTitle(result.getString("title"));
        movie.setOriginalTitle(result.getString("original_title"));
        movie.setSynopsis(result.getString("synopsis"));
        movie.setDirector(result.getString("director"));
        movie.setMainCast(result.getString("main_cast"));
        movie.setDurationMinutes(result.getInt("duration_minutes"));
        movie.setSpokenLanguage(result.getString("spoken_language"));
        movie.setCountry(result.getString("country"));
        movie.setAgeRating(result.getString("age_rating"));
        movie.setTrailerUrl(result.getString("trailer_url"));
        movie.setTrailerFile(result.getString("trailer_file"));
        movie.setPosterUrl(result.getString("poster_url"));
        Date releaseDate = result.getDate("release_date");
        movie.setReleaseDate(releaseDate == null ? null : releaseDate.toLocalDate());
        Date endDate = result.getDate("end_date");
        movie.setEndDate(endDate == null ? null : endDate.toLocalDate());
        movie.setStatus(result.getString("status"));
        movie.setStatus(MovieSchedule.statusFor(movie));
        var created = result.getTimestamp("created_at");
        movie.setCreatedAt(created == null ? null : created.toLocalDateTime());
        var updated = result.getTimestamp("updated_at");
        movie.setUpdatedAt(updated == null ? null : updated.toLocalDateTime());
        movie.setGenres(result.getString("genres"));
        movie.setGenreIds(result.getString("genre_ids"));
        return movie;
    }
}
