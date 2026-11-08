package com.cinema.dao;

import com.cinema.model.Movie;
import com.cinema.util.DBContext;
import com.cinema.util.movie.MovieSchedule;
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
    /** Trang kết quả phim + thông tin phân trang. */
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

    /** xếp phim đang chiếu lên đầu, phim sắp chiếu phía sau. Phim kết thúc chỉ hiện lại */
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
        String sql = "SELECT d.*, (SELECT COUNT(*) FROM dbo.Ticket t "
                + "JOIN dbo.Showtime sx ON sx.showtime_id = t.showtime_id "
                + "WHERE sx.movie_id = d.movie_id AND t.status = 'Booked' "
                + "AND sx.start_time > SYSDATETIME()) AS active_ticket_count "
                + FROM_VIEW + visible
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
        String sql = "SELECT d.*, (SELECT COUNT(*) FROM dbo.Ticket t "
                + "JOIN dbo.Showtime sx ON sx.showtime_id = t.showtime_id "
                + "WHERE sx.movie_id = d.movie_id AND t.status = 'Booked' "
                + "AND sx.start_time > SYSDATETIME()) AS active_ticket_count "
                + "FROM dbo.vw_MovieDetail d WHERE d.movie_id = ?";
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
        String sql = "SELECT d.*, 0 AS active_ticket_count FROM dbo.vw_MovieDetail d "
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

    /** Các phim đang được phát hành vào một ngày cụ thể (dùng để xếp lịch tự động). */
    public List<Movie> findAllForDate(LocalDate date) throws SQLException {
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT d.*, 0 AS active_ticket_count FROM dbo.vw_MovieDetail d "
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
        String relatedSql = "SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id = ?) "
                + "OR EXISTS (SELECT 1 FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id "
                + "WHERE s.movie_id = ?) THEN 1 ELSE 0 END";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement related = connection.prepareStatement(relatedSql)) {
            related.setInt(1, id);
            related.setInt(2, id);
            try (ResultSet result = related.executeQuery()) {
                result.next();
                if (result.getInt(1) == 1) {
                    throw new IllegalStateException("Không thể xóa phim vì vẫn còn suất chiếu hoặc vé liên quan.");
                }
            }
        }
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_DeleteMovie(?, ?)}")) {
            statement.setInt(1, id);
            statement.registerOutParameter(2, Types.BIT);
            statement.execute();
            return statement.getBoolean(2);
        }
    }

    public void stop(int id) throws SQLException {
        int bookedShowtimes = countFutureBookedShowtimes(id);
        if (bookedShowtimes > 0) {
            throw new IllegalStateException("Phim còn " + bookedShowtimes
                    + " suất chiếu đã bán vé, hãy dùng Hủy & hoàn tiền.");
        }
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_StopMovie(?)}")) {
            statement.setInt(1, id);
            statement.execute();
        }
    }

    public int countFutureBookedShowtimes(int movieId) throws SQLException {
            String sql = "SELECT COUNT(DISTINCT s.showtime_id) FROM dbo.Showtime s "
                    + "JOIN dbo.Ticket t ON t.showtime_id = s.showtime_id "
                    + "WHERE s.movie_id = ? AND s.start_time > SYSDATETIME() "
                    + "AND s.status = 'Scheduled' AND t.status = 'Booked'";
            try (Connection connection = DBContext.getConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, movieId);
                try (ResultSet result = statement.executeQuery()) {
                    result.next();
                    return result.getInt(1);
            }
        }
    }

    /** Xem trước tác động của việc hủy phim: các suất sắp chiếu bị hủy và số vé đã bán (sp_CancelMovie @confirm=0). */
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

    public java.util.Map<String, Object> cancelSummary(int movieId) throws SQLException {
            String sql = "SELECT COUNT(DISTINCT t.ticket_id) AS ticket_count, "
                    + "COALESCE(SUM(DISTINCT b.total_amount - ISNULL((SELECT SUM(p.refunded_amount) "
                    + "FROM dbo.Payment p WHERE p.booking_id = b.booking_id), 0)), 0) AS refund_amount, "
                    + "COUNT(DISTINCT b.customer_id) AS customer_count "
                    + "FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id "
                    + "JOIN dbo.Ticket t ON t.booking_id = b.booking_id "
                    + "WHERE s.movie_id = ? AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() "
                    + "AND b.status = 'Paid' AND t.status = 'Booked'";
            try (Connection connection = DBContext.getConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, movieId);
                try (ResultSet result = statement.executeQuery()) {
                    result.next();
                    java.util.Map<String, Object> summary = new java.util.HashMap<>();
                    summary.put("ticketCount", result.getInt("ticket_count"));
                    summary.put("refundAmount", result.getBigDecimal("refund_amount"));
                    summary.put("customerCount", result.getInt("customer_count"));
                    return summary;
                }
            }
        }

    /** Hủy phim đang chiếu: hủy mọi suất sắp chiếu, hoàn tiền/điểm/voucher và gửi email báo khách (sp_CancelMovie @confirm=1). */
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

    public void recordCancellationReason(int movieId, int managerAccountId, String reason) throws SQLException {
            String sql = "INSERT INTO dbo.SystemLog(account_id, action, detail) VALUES (?, N'CANCEL_MOVIE_REASON', ?)";
            try (Connection connection = DBContext.getConnection();
                    PreparedStatement statement = connection.prepareStatement(sql)) {
                statement.setInt(1, managerAccountId);
                statement.setString(2, "movie_id=" + movieId + "; reason=" + reason);
                statement.executeUpdate();
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
        movie.setActiveTicketCount(result.getInt("active_ticket_count"));
        return movie;
    }
}
