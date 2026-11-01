package com.cinema.dao;

import com.cinema.model.ChartBar;
import com.cinema.model.DashboardShowtime;
import com.cinema.model.Movie;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * DAO để lấy dữ liệu cho các dashboard (Admin, Manager, Staff, Customer).
 */
public class DashboardDAO {
    
    /**
     * Số liệu tổng quan cho dashboard quản trị viên (giữ thứ tự khai báo).
     */
    public Map<String, Long> getAdminStats() throws SQLException {
        String sql = "SELECT "
                + "(SELECT COUNT(*) FROM Users) AS users_total, "
                + "(SELECT COUNT(*) FROM Users WHERE Role = 'CUSTOMER') AS customers, "
                + "(SELECT COUNT(*) FROM Users WHERE Role IN ('STAFF','MANAGER','ADMIN')) AS staff_accounts, "
                + "(SELECT COUNT(*) FROM Users WHERE Status = 'BLOCKED') AS blocked, "
                + "(SELECT COUNT(*) FROM Room WHERE status = 'Active') AS rooms, "
                + "(SELECT COUNT(*) FROM Seat) AS seats, "
                + "(SELECT COUNT(*) FROM Movie WHERE status <> 'Stopped') AS movies_active, "
                + "(SELECT COUNT(*) FROM Showtime WHERE status = 'Scheduled' AND start_time >= SYSDATETIME()) AS showtimes_upcoming, "
                + "(SELECT COUNT(*) FROM Booking WHERE status = 'Paid') AS bookings_paid, "
                + "(SELECT ISNULL(SUM(total_amount), 0) FROM Booking WHERE status = 'Paid') AS revenue";
        Map<String, Long> stats = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            if (result.next()) {
                for (String key : new String[] {"users_total", "customers", "staff_accounts", "blocked", "rooms",
                        "seats", "movies_active", "showtimes_upcoming", "bookings_paid", "revenue"}) {
                    stats.put(key, result.getLong(key));
                }
            }
        }
        return stats;
    }

    /** Số suất chiếu đang mở theo từng ngày trong {@code days} ngày tới (kể cả hôm nay); ngày không có suất = 0. */
    public List<ChartBar> getShowtimesPerDay(int days) throws SQLException {
        Map<LocalDate, Long> counts = new LinkedHashMap<>();
        LocalDate today = LocalDate.now();
        for (int i = 0; i < days; i++) counts.put(today.plusDays(i), 0L);
        String sql = "SELECT show_date, COUNT(*) AS n FROM Showtime "
                + "WHERE status = 'Scheduled' AND show_date >= CAST(GETDATE() AS DATE) "
                + "AND show_date < DATEADD(DAY, ?, CAST(GETDATE() AS DATE)) GROUP BY show_date";
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, days);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) counts.put(result.getDate("show_date").toLocalDate(), result.getLong("n"));
            }
        }
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM");
        Map<String, Long> byLabel = new LinkedHashMap<>();
        counts.forEach((d, n) -> byLabel.put(d.format(fmt), n));
        return toBars(byLabel);
    }

    /** Số tài khoản theo vai trò (bảng Users). */
    public List<ChartBar> getUsersByRole() throws SQLException {
        Map<String, Long> byRole = new LinkedHashMap<>();
        byRole.put("Khách hàng", 0L);
        byRole.put("Nhân viên", 0L);
        byRole.put("Quản lý", 0L);
        byRole.put("Quản trị", 0L);
        String sql = "SELECT Role, COUNT(*) AS n FROM Users GROUP BY Role";
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                String label = switch (result.getString("Role")) {
                    case "CUSTOMER" -> "Khách hàng";
                    case "STAFF" -> "Nhân viên";
                    case "MANAGER" -> "Quản lý";
                    case "ADMIN" -> "Quản trị";
                    default -> null;
                };
                if (label != null) byRole.put(label, result.getLong("n"));
            }
        }
        return toBars(byRole);
    }

    /** Số liệu trong ngày cho dashboard nhân viên bán vé. */
    public Map<String, Long> getStaffStats() throws SQLException {
        String sql = "SELECT "
                + "(SELECT COUNT(*) FROM Showtime WHERE status = 'Scheduled' AND show_date = CAST(GETDATE() AS DATE) "
                + "   AND start_time >= SYSDATETIME()) AS showtimes_left, "
                + "(SELECT COUNT(*) FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id "
                + "   WHERE b.channel = 'Counter' AND b.status = 'Paid' AND t.status IN ('Booked','Used') "
                + "   AND CAST(b.paid_at AS DATE) = CAST(GETDATE() AS DATE)) AS counter_tickets, "
                + "(SELECT ISNULL(SUM(total_amount), 0) FROM Booking WHERE channel = 'Counter' AND status = 'Paid' "
                + "   AND CAST(paid_at AS DATE) = CAST(GETDATE() AS DATE)) AS counter_revenue, "
                + "(SELECT COUNT(*) FROM Ticket WHERE status = 'Used' AND CAST(checked_in_at AS DATE) = CAST(GETDATE() AS DATE)) AS checked_in, "
                + "(SELECT COUNT(*) FROM Combo WHERE status = 'Active' AND stock <= 10) AS combos_low";
        Map<String, Long> stats = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            if (result.next()) {
                for (String key : new String[] {"showtimes_left", "counter_tickets", "counter_revenue", "checked_in",
                        "combos_low"}) {
                    stats.put(key, result.getLong(key));
                }
            }
        }
        return stats;
    }

    /** Số vé đã bán của các suất chiếu hôm nay (theo giờ chiếu), dùng để quầy biết suất nào còn nhiều chỗ. */
    public List<ChartBar> getTodayShowtimeSales(int limit) throws SQLException {
        String sql = "SELECT TOP (?) CONVERT(VARCHAR(5), s.start_time, 108) + N' · ' + r.room_name + N' · ' + m.title AS label, "
                + "(SELECT COUNT(*) FROM Ticket t WHERE t.showtime_id = s.showtime_id AND t.status IN ('Booked','Used')) AS sold "
                + "FROM Showtime s JOIN Room r ON r.room_id = s.room_id JOIN Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.status = 'Scheduled' AND s.show_date = CAST(GETDATE() AS DATE) AND s.start_time >= SYSDATETIME() "
                + "ORDER BY s.start_time";
        Map<String, Long> byShowtime = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) byShowtime.put(result.getString("label"), result.getLong("sold"));
            }
        }
        return toBars(byShowtime);
    }

    /** Tồn kho các combo đang bán, ít nhất trước. */
    public List<ChartBar> getComboStock() throws SQLException {
        Map<String, Long> stock = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "SELECT combo_name, stock FROM Combo WHERE status = 'Active' ORDER BY stock, combo_name");
             ResultSet result = statement.executeQuery()) {
            while (result.next()) stock.put(result.getString("combo_name"), result.getLong("stock"));
        }
        return toBars(stock);
    }

    /** Số liệu tổng quan cho dashboard quản lý rạp. */
    public Map<String, Long> getManagerStats() throws SQLException {
        String sql = "SELECT "
                + "(SELECT ISNULL(SUM(total_amount), 0) FROM Booking WHERE status = 'Paid') AS revenue, "
                + "(SELECT COUNT(*) FROM Booking WHERE status = 'Paid') AS bookings_paid, "
                + "(SELECT COUNT(*) FROM Movie WHERE status = 'NowShowing') AS movies_now, "
                + "(SELECT COUNT(*) FROM Movie WHERE status = 'Upcoming') AS movies_upcoming, "
                + "(SELECT COUNT(*) FROM Showtime WHERE status = 'Scheduled' AND show_date = CAST(GETDATE() AS DATE) "
                + "   AND start_time >= SYSDATETIME()) AS showtimes_today, "
                + "(SELECT COUNT(*) FROM Showtime WHERE status = 'Scheduled' AND start_time >= SYSDATETIME()) AS showtimes_upcoming, "
                + "(SELECT COUNT(*) FROM News WHERE status = 'Published') AS news_published";
        Map<String, Long> stats = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            if (result.next()) {
                for (String key : new String[] {"revenue", "bookings_paid", "movies_now", "movies_upcoming",
                        "showtimes_today", "showtimes_upcoming", "news_published"}) {
                    stats.put(key, result.getLong(key));
                }
            }
        }
        return stats;
    }

    /** Số suất chiếu sắp tới của từng phim, nhiều nhất trước (tối đa {@code limit} phim). */
    public List<ChartBar> getUpcomingShowtimesPerMovie(int limit) throws SQLException {
        String sql = "SELECT TOP (?) m.title, COUNT(*) AS n FROM Showtime s JOIN Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.status = 'Scheduled' AND s.start_time >= SYSDATETIME() "
                + "GROUP BY m.movie_id, m.title ORDER BY COUNT(*) DESC, m.title";
        Map<String, Long> byMovie = new LinkedHashMap<>();
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) byMovie.put(result.getString("title"), result.getLong("n"));
            }
        }
        return toBars(byMovie);
    }

    /** Số phim theo trạng thái (cột Movie.status). */
    public List<ChartBar> getMoviesByStatus() throws SQLException {
        Map<String, Long> byStatus = new LinkedHashMap<>();
        byStatus.put("Đang chiếu", 0L);
        byStatus.put("Sắp chiếu", 0L);
        byStatus.put("Ngừng chiếu", 0L);
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(
                     "SELECT status, COUNT(*) AS n FROM Movie WHERE is_deleted = 0 GROUP BY status");
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                String label = switch (result.getString("status")) {
                    case "NowShowing" -> "Đang chiếu";
                    case "Upcoming" -> "Sắp chiếu";
                    case "Stopped" -> "Ngừng chiếu";
                    default -> null;
                };
                if (label != null) byStatus.put(label, result.getLong("n"));
            }
        }
        return toBars(byStatus);
    }

    private static List<ChartBar> toBars(Map<String, Long> values) {
        long max = values.values().stream().mapToLong(Long::longValue).max().orElse(0);
        List<ChartBar> bars = new ArrayList<>();
        values.forEach((label, value) ->
                bars.add(new ChartBar(label, value, max == 0 ? 0 : (int) Math.round(value * 100.0 / max))));
        return bars;
    }

    /**
     * Lấy danh sách phim đang chiếu cho dashboard customer.
     */
    public List<DashboardShowtime> getNowShowingMovies() throws SQLException {
        return queryMovies("m.release_date <= CAST(GETDATE() AS DATE) "
                + "AND (m.end_date IS NULL OR m.end_date >= CAST(GETDATE() AS DATE)) "
                + "AND m.status <> 'Stopped'", "m.created_at DESC, m.movie_id DESC");
    }

    /** Phim sắp chiếu (ngày khởi chiếu còn ở tương lai), phim ra mắt sớm nhất trước. */
    public List<DashboardShowtime> getUpcomingMovies() throws SQLException {
        return queryMovies("m.release_date > CAST(GETDATE() AS DATE) AND m.status <> 'Stopped'",
                "m.release_date ASC, m.movie_id DESC");
    }

    private List<DashboardShowtime> queryMovies(String where, String orderBy) throws SQLException {
        List<DashboardShowtime> items = new ArrayList<>();
        
        String sql = "SELECT DISTINCT "
                + "  m.movie_id, m.title, m.original_title, m.synopsis, m.director, "
                + "  m.main_cast, m.duration_minutes, m.spoken_language, m.country, "
                + "  m.age_rating, m.trailer_url, m.trailer_file, m.poster_url, "
                + "  m.release_date, m.end_date, m.status, m.created_at, m.updated_at, "
                + "  mg.genre_ids, "
                + "  (SELECT STRING_AGG(g.genre_name, ', ') "
                + "   FROM Genre g WHERE g.genre_id IN (SELECT value FROM STRING_SPLIT(mg.genre_ids, ','))) as genres, "
                + "  (SELECT MIN(CAST(s.start_time AS DATE)) FROM Showtime s "
                + "   WHERE s.movie_id = m.movie_id AND s.start_time >= GETDATE()) as next_show_date, "
                + "  (SELECT MIN(ts.slot_name) FROM Showtime s "
                + "   JOIN TimeSlot ts ON ts.slot_id = s.slot_id "
                + "   WHERE s.movie_id = m.movie_id AND s.start_time >= GETDATE()) as next_showtime "
                + "FROM Movie m "
                + "LEFT JOIN (SELECT movie_id, STRING_AGG(CAST(genre_id AS VARCHAR(10)), ',') as genre_ids "
                + "           FROM MovieGenre GROUP BY movie_id) mg ON m.movie_id = mg.movie_id "
                + "WHERE " + where + " ORDER BY " + orderBy;
        
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                Movie movie = mapMovie(result);
                Date nextShowDate = result.getDate("next_show_date");
                String nextShowtime = result.getString("next_showtime");
                
                DashboardShowtime item = new DashboardShowtime(
                    movie,
                    nextShowDate == null ? null : nextShowDate.toLocalDate(),
                    nextShowtime
                );
                items.add(item);
            }
        }
        
        return items;
    }
    
    private Movie mapMovie(ResultSet result) throws SQLException {
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
        
        java.sql.Date releaseDate = result.getDate("release_date");
        movie.setReleaseDate(releaseDate == null ? null : releaseDate.toLocalDate());
        java.sql.Date endDate = result.getDate("end_date");
        movie.setEndDate(endDate == null ? null : endDate.toLocalDate());
        
        movie.setStatus(result.getString("status"));
        
        java.sql.Timestamp created = result.getTimestamp("created_at");
        movie.setCreatedAt(created == null ? null : created.toLocalDateTime());
        java.sql.Timestamp updated = result.getTimestamp("updated_at");
        movie.setUpdatedAt(updated == null ? null : updated.toLocalDateTime());
        
        movie.setGenres(result.getString("genres"));
        movie.setGenreIds(result.getString("genre_ids"));
        
        return movie;
    }
}
