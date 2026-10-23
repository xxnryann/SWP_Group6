package com.cinema.dao.ShowtimeDAO;

import com.cinema.model.Showtime;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ShowtimeDAO {
    private static final String SELECT_COLUMNS = "s.showtime_id, s.movie_id, m.title AS movie_title, "
            + "m.duration_minutes, s.room_name, s.starts_at, s.ticket_price, s.status ";
    private static final String SELECT_FROM = "FROM dbo.Showtime s JOIN dbo.Movie m ON m.movie_id = s.movie_id ";

    public List<Showtime> findForDate(LocalDate date) throws SQLException {
        List<Showtime> showtimes = new ArrayList<>();
        String sql = "SELECT " + SELECT_COLUMNS + SELECT_FROM
                + "WHERE s.status = 'Scheduled' AND m.status <> 'Stopped' "
                + "AND CAST(s.starts_at AS DATE) = ? "
                + "ORDER BY s.starts_at, s.room_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    showtimes.add(map(result));
                }
            }
        }
        return showtimes;
    }

    public List<Showtime> findAllForManagement() throws SQLException {
        List<Showtime> showtimes = new ArrayList<>();
        String sql = "SELECT " + SELECT_COLUMNS + SELECT_FROM
                + "ORDER BY s.starts_at DESC, s.room_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                showtimes.add(map(result));
            }
        }
        return showtimes;
    }

    public Showtime findById(int id) throws SQLException {
        String sql = "SELECT " + SELECT_COLUMNS + SELECT_FROM + "WHERE s.showtime_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? map(result) : null;
            }
        }
    }

    public void save(Showtime showtime) throws SQLException {
        try (Connection connection = DBContext.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                if ("Scheduled".equals(showtime.getStatus())) {
                    validateMovieAndRoomConflict(connection, showtime);
                }
                String sql = showtime.getShowtimeId() == 0
                        ? "INSERT INTO dbo.Showtime (movie_id, room_name, starts_at, ticket_price, status) "
                                + "VALUES (?, ?, ?, ?, ?)"
                        : "UPDATE dbo.Showtime SET movie_id = ?, room_name = ?, starts_at = ?, "
                                + "ticket_price = ?, status = ? WHERE showtime_id = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    bindSave(statement, showtime);
                    if (showtime.getShowtimeId() > 0) {
                        statement.setInt(6, showtime.getShowtimeId());
                        if (statement.executeUpdate() == 0) {
                            throw new SQLException("Không tìm thấy suất chiếu cần sửa.");
                        }
                    } else {
                        statement.executeUpdate();
                    }
                }
                connection.commit();
            } catch (SQLException | RuntimeException e) {
                connection.rollback();
                throw e;
            }
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM dbo.Showtime WHERE showtime_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            if (statement.executeUpdate() == 0) {
                throw new SQLException("Không tìm thấy suất chiếu cần xóa.");
            }
        }
    }

    private void validateMovieAndRoomConflict(Connection connection, Showtime showtime) throws SQLException {
        String movieSql = "SELECT duration_minutes, release_date, end_date, status "
                + "FROM dbo.Movie WHERE movie_id = ?";
        int duration;
        try (PreparedStatement statement = connection.prepareStatement(movieSql)) {
            statement.setInt(1, showtime.getMovieId());
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Phim được chọn không tồn tại.");
                }
                if ("Stopped".equals(result.getString("status"))) {
                    throw new SQLException("Không thể tạo lịch chiếu cho phim đã ngừng chiếu.");
                }
                LocalDate date = showtime.getStartsAt().toLocalDate();
                LocalDate releaseDate = result.getDate("release_date").toLocalDate();
                java.sql.Date endDateValue = result.getDate("end_date");
                if (date.isBefore(releaseDate) || (endDateValue != null && date.isAfter(endDateValue.toLocalDate()))) {
                    throw new SQLException("Ngày chiếu phải nằm trong thời gian phát hành của phim.");
                }
                duration = result.getInt("duration_minutes");
            }
        }
        String conflictSql = "SELECT COUNT(*) FROM dbo.Showtime s WITH (UPDLOCK, HOLDLOCK) "
                + "JOIN dbo.Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.room_name = ? AND s.status = 'Scheduled' "
                + "AND s.showtime_id <> ? "
                + "AND s.starts_at < DATEADD(MINUTE, ?, ?) "
                + "AND DATEADD(MINUTE, m.duration_minutes, s.starts_at) > ?";
        try (PreparedStatement statement = connection.prepareStatement(conflictSql)) {
            statement.setString(1, showtime.getRoomName());
            statement.setInt(2, showtime.getShowtimeId());
            statement.setInt(3, duration);
            statement.setTimestamp(4, Timestamp.valueOf(showtime.getStartsAt()));
            statement.setTimestamp(5, Timestamp.valueOf(showtime.getStartsAt()));
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                if (result.getInt(1) > 0) {
                    throw new SQLException("Phòng đã có suất chiếu trùng giờ với phim khác.");
                }
            }
        }
    }

    private void bindSave(PreparedStatement statement, Showtime showtime) throws SQLException {
        statement.setInt(1, showtime.getMovieId());
        statement.setString(2, showtime.getRoomName());
        statement.setTimestamp(3, Timestamp.valueOf(showtime.getStartsAt()));
        statement.setBigDecimal(4, showtime.getTicketPrice());
        statement.setString(5, showtime.getStatus());
    }

    private Showtime map(ResultSet result) throws SQLException {
        Showtime showtime = new Showtime();
        showtime.setShowtimeId(result.getInt("showtime_id"));
        showtime.setMovieId(result.getInt("movie_id"));
        showtime.setMovieTitle(result.getString("movie_title"));
        showtime.setMovieDurationMinutes(result.getInt("duration_minutes"));
        showtime.setRoomName(result.getString("room_name"));
        Timestamp startsAt = result.getTimestamp("starts_at");
        showtime.setStartsAt(startsAt == null ? null : startsAt.toLocalDateTime());
        showtime.setTicketPrice(result.getBigDecimal("ticket_price"));
        showtime.setStatus(result.getString("status"));
        return showtime;
    }

}
