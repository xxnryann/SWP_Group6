package com.cinema.dao.ShowtimeDAO;

import com.cinema.model.Showtime;
import com.cinema.model.Movie;
import com.cinema.model.ShowtimeMovieGroup;
import com.cinema.util.DBContext;
import com.cinema.util.ShowtimeUtil.ShowtimePlanner;
import com.cinema.util.ShowtimeUtil.ShowtimeRules;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ShowtimeDAO {
    private record RoomSlot(int roomId, int slotId) {
    }

    private static final String SELECT_COLUMNS = "s.showtime_id, s.movie_id, m.title AS movie_title, "
            + "m.duration_minutes, s.room_name, s.starts_at, s.status ";
    private static final String SELECT_FROM = "FROM dbo.Showtime s JOIN dbo.Movie m ON m.movie_id = s.movie_id ";

    public List<ShowtimeMovieGroup> findForDate(LocalDate date) throws SQLException {
        Map<Integer, ShowtimeMovieGroup> schedules = new LinkedHashMap<>();
        String sql = "SELECT " + SELECT_COLUMNS
                + ", m.original_title, m.poster_url, m.age_rating, "
                + "(SELECT STRING_AGG(g.genre_name, N', ') "
                + "FROM dbo.MovieGenre mg JOIN dbo.Genre g ON g.genre_id = mg.genre_id "
                + "WHERE mg.movie_id = m.movie_id) AS genres "
                + SELECT_FROM
                + "WHERE s.status = 'Scheduled' "
                + "AND CAST(s.starts_at AS DATE) = ? "
                + "ORDER BY s.starts_at, s.room_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    int movieId = result.getInt("movie_id");
                    ShowtimeMovieGroup schedule = schedules.get(movieId);
                    if (schedule == null) {
                        Movie movie = new Movie();
                        movie.setMovieId(movieId);
                        movie.setTitle(result.getString("movie_title"));
                        movie.setOriginalTitle(result.getString("original_title"));
                        movie.setDurationMinutes(result.getInt("duration_minutes"));
                        movie.setPosterUrl(result.getString("poster_url"));
                        movie.setAgeRating(result.getString("age_rating"));
                        movie.setGenres(result.getString("genres"));
                        schedule = new ShowtimeMovieGroup(movie);
                        schedules.put(movieId, schedule);
                    }
                    schedule.addShowtime(map(result));
                }
            }
        }
        return new ArrayList<>(schedules.values());
    }

    public List<Showtime> findAllForManagement() throws SQLException {
        List<Showtime> showtimes = new ArrayList<>();
        String sql = "SELECT " + SELECT_COLUMNS + SELECT_FROM
                + "ORDER BY CAST(s.starts_at AS DATE) ASC, s.starts_at ASC, s.room_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                showtimes.add(map(result));
            }
        }
        return showtimes;
    }

    public List<String> findActiveRoomNames() throws SQLException {
        List<String> rooms = new ArrayList<>();
        String sql = "SELECT room_name FROM dbo.Room WHERE status = 'Active' ORDER BY room_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                rooms.add(result.getString("room_name"));
            }
        }
        return rooms;
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

    /**
     * Các mốc giờ bắt đầu còn trống trong phòng cho ngày đã chọn.
     *
     * <p>Không còn khung giờ cố định: mọi mốc 15 phút từ giờ mở cửa tới giờ
     * đóng cửa đều được xét. Một mốc hợp lệ khi suất chiếu kết thúc trước
     * giờ đóng cửa và không đè lên suất đã có của phòng (tính cả 15 phút
     * dọn phòng).</p>
     */
    public List<LocalTime> findAvailableStartTimes(LocalDate date, String roomName, int movieId,
            int excludedShowtimeId) throws SQLException {
        if (date.isBefore(LocalDate.now())) {
            return List.of();
        }

        // Gom 4 truy vấn (phim + phòng + lịch chiếu cùng ngày) vào MỘT connection
        // để giảm 4 round-trip xuống 1. Không mở transaction vì chỉ đọc.
        try (Connection connection = DBContext.getConnection()) {
            int duration;
            String movieStatus;
            String movieSql = "SELECT duration_minutes, release_date, end_date, status "
                    + "FROM dbo.Movie WHERE movie_id = ?";
            try (PreparedStatement statement = connection.prepareStatement(movieSql)) {
                statement.setInt(1, movieId);
                try (ResultSet result = statement.executeQuery()) {
                    if (!result.next()) {
                        throw new SQLException("Phim được chọn không tồn tại.");
                    }
                    movieStatus = result.getString("status");
                    LocalDate releaseDate = result.getDate("release_date").toLocalDate();
                    java.sql.Date endDate = result.getDate("end_date");
                    if (!"Stopped".equals(movieStatus)
                            && (date.isBefore(releaseDate)
                                    || (endDate != null && date.isAfter(endDate.toLocalDate())))) {
                        return List.of();
                    }
                    duration = result.getInt("duration_minutes");
                }
            }
            if (duration <= 0 || duration > ShowtimeRules.MAX_MOVIE_MINUTES) {
                return List.of();
            }

            String activeRoomSql = "SELECT COUNT(*) FROM dbo.Room WHERE room_name = ? AND status = 'Active'";
            try (PreparedStatement statement = connection.prepareStatement(activeRoomSql)) {
                statement.setString(1, roomName);
                try (ResultSet result = statement.executeQuery()) {
                    result.next();
                    if (result.getInt(1) == 0) {
                        throw new SQLException("Vui lòng chọn một phòng chiếu đang hoạt động.");
                    }
                }
            }

            List<LocalDateTime> existingStarts = new ArrayList<>();
            List<Integer> existingDurations = new ArrayList<>();
            String existingSql = "SELECT s.starts_at, m.duration_minutes "
                    + "FROM dbo.Showtime s JOIN dbo.Movie m ON m.movie_id = s.movie_id "
                    + "WHERE s.room_name = ? AND s.status = 'Scheduled' "
                    + "AND CAST(s.starts_at AS DATE) = ? "
                    + "AND s.showtime_id <> ?";
            try (PreparedStatement statement = connection.prepareStatement(existingSql)) {
                statement.setString(1, roomName);
                statement.setDate(2, java.sql.Date.valueOf(date));
                statement.setInt(3, excludedShowtimeId);
                try (ResultSet result = statement.executeQuery()) {
                    while (result.next()) {
                        existingStarts.add(result.getTimestamp("starts_at").toLocalDateTime());
                        existingDurations.add(result.getInt("duration_minutes"));
                    }
                }
            }

            LocalDateTime now = LocalDateTime.now();
            LocalTime earliest = ShowtimeRules.earliestStartFor(date, now);
            List<LocalTime> available = new ArrayList<>();
            for (LocalTime candidate = earliest;
                    !candidate.isAfter(ShowtimeRules.CLOSE_TIME);
                    candidate = candidate.plusMinutes(ShowtimeRules.GRID_MINUTES)) {
                LocalDateTime start = date.atTime(candidate);
                LocalDateTime end = start.plusMinutes(duration);
                if (end.isAfter(date.atTime(ShowtimeRules.CLOSE_TIME))) {
                    continue;
                }
                boolean roomAvailable = true;
                for (int i = 0; i < existingStarts.size(); i++) {
                    LocalDateTime existingStart = existingStarts.get(i);
                    LocalDateTime existingEnd = existingStart.plusMinutes(existingDurations.get(i));
                    if (start.isBefore(existingEnd.plusMinutes(ShowtimeRules.TURNOVER_MINUTES))
                            && end.plusMinutes(ShowtimeRules.TURNOVER_MINUTES).isAfter(existingStart)) {
                        roomAvailable = false;
                        break;
                    }
                }
                if (roomAvailable) {
                    available.add(candidate);
                }
            }
            return available;
        }
    }

    /** Các mốc giờ đã bị chiếm trong ngày (dùng để xếp lịch không trùng). */
    public List<ShowtimePlanner.OccupiedSlot> findOccupiedSlots(LocalDate date) throws SQLException {
        List<ShowtimePlanner.OccupiedSlot> slots = new ArrayList<>();
        String sql = "SELECT room_name, starts_at FROM dbo.Showtime "
                + "WHERE status = 'Scheduled' AND CAST(starts_at AS DATE) = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) {
                    Timestamp startsAt = result.getTimestamp("starts_at");
                    if (startsAt == null) {
                        continue;
                    }
                    slots.add(new ShowtimePlanner.OccupiedSlot(
                            result.getString("room_name"), startsAt.toLocalDateTime()));
                }
            }
        }
        return slots;
    }

    public void save(Showtime showtime) throws SQLException {
        try (Connection connection = DBContext.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                RoomSlot roomSlot = validateRoomAndSlot(connection, showtime);
                int duration = "Scheduled".equals(showtime.getStatus())
                        ? validateMovieAndRoomConflict(connection, showtime)
                        : findMovieDuration(connection, showtime.getMovieId());
                if (duration <= 0 || duration > ShowtimeRules.MAX_MOVIE_MINUTES) {
                    throw new SQLException("Thời lượng phim không hợp lệ.");
                }
                LocalDateTime start = showtime.getStartsAt();
                if (!ShowtimeRules.fitsOpeningHours(start, duration)) {
                    throw new SQLException("Suất chiếu phải nằm trong giờ mở cửa "
                            + ShowtimeRules.OPEN_TIME + " – " + ShowtimeRules.CLOSE_TIME
                            + " và phim phải kết thúc trước giờ đóng cửa.");
                }
                LocalDateTime end = start.plusMinutes(duration);
                String sql = showtime.getShowtimeId() == 0
                        ? "INSERT INTO dbo.Showtime "
                                + "(movie_id, room_id, slot_id, start_time, end_time, status, created_by, "
                                + "created_at, room_name, starts_at) "
                                + "VALUES (?, ?, ?, ?, ?, ?, NULL, SYSDATETIME(), ?, ?)"
                        : "UPDATE dbo.Showtime SET movie_id = ?, room_id = ?, slot_id = ?, "
                                + "start_time = ?, end_time = ?, status = ?, room_name = ?, starts_at = ? "
                                + "WHERE showtime_id = ?";
                try (PreparedStatement statement = connection.prepareStatement(sql)) {
                    statement.setInt(1, showtime.getMovieId());
                    statement.setInt(2, roomSlot.roomId());
                    statement.setInt(3, roomSlot.slotId());
                    statement.setTimestamp(4, Timestamp.valueOf(start));
                    statement.setTimestamp(5, Timestamp.valueOf(end));
                    statement.setString(6, showtime.getStatus());
                    statement.setString(7, showtime.getRoomName());
                    statement.setTimestamp(8, Timestamp.valueOf(start));
                    if (showtime.getShowtimeId() > 0) {
                        statement.setInt(9, showtime.getShowtimeId());
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

    /**
     * Ghi hàng loạt suất chiếu trong một transaction.
     *
     * <p>Dùng cho luồng "sinh lịch tự động": toàn bộ lịch của ngày hoặc được
     * ghi hết, hoặc không gì cả — tránh để lại nửa lịch khi một suất bị trùng.</p>
     *
     * @return số suất chiếu đã ghi
     */
    public int insertBatch(List<Showtime> showtimes) throws SQLException {
        if (showtimes == null || showtimes.isEmpty()) {
            return 0;
        }
        try (Connection connection = DBContext.getConnection()) {
            connection.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            connection.setAutoCommit(false);
            try {
                String sql = "INSERT INTO dbo.Showtime "
                        + "(movie_id, room_id, slot_id, start_time, end_time, status, created_by, "
                        + "created_at, room_name, starts_at) "
                        + "VALUES (?, ?, ?, ?, ?, 'Scheduled', NULL, SYSDATETIME(), ?, ?)";
                int inserted = 0;
                for (Showtime showtime : showtimes) {
                    RoomSlot roomSlot = validateRoomAndSlot(connection, showtime);
                    int duration = validateMovieAndRoomConflict(connection, showtime);
                    if (duration <= 0 || duration > ShowtimeRules.MAX_MOVIE_MINUTES) {
                        throw new SQLException("Thời lượng phim không hợp lệ.");
                    }
                    LocalDateTime start = showtime.getStartsAt();
                    if (!ShowtimeRules.fitsOpeningHours(start, duration)) {
                        throw new SQLException("Suất chiếu phải nằm trong giờ mở cửa "
                                + ShowtimeRules.OPEN_TIME + " – " + ShowtimeRules.CLOSE_TIME
                                + " và phim phải kết thúc trước giờ đóng cửa.");
                    }
                    try (PreparedStatement statement = connection.prepareStatement(sql)) {
                        statement.setInt(1, showtime.getMovieId());
                        statement.setInt(2, roomSlot.roomId());
                        statement.setInt(3, roomSlot.slotId());
                        statement.setTimestamp(4, Timestamp.valueOf(start));
                        statement.setTimestamp(5, Timestamp.valueOf(start.plusMinutes(duration)));
                        statement.setString(6, showtime.getRoomName());
                        statement.setTimestamp(7, Timestamp.valueOf(start));
                        statement.executeUpdate();
                    }
                    inserted++;
                }
                connection.commit();
                return inserted;
            } catch (SQLException | RuntimeException e) {
                connection.rollback();
                throw e;
            }
        }
    }

    public void delete(int id) throws SQLException {
        String bookingSql = "SELECT COUNT(*) FROM dbo.Booking WHERE showtime_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(bookingSql)) {
            statement.setInt(1, id);
            try (ResultSet result = statement.executeQuery()) {
                if (result.next() && result.getInt(1) > 0) {
                    throw new SQLException("Suất chiếu đã có đơn đặt vé nên không thể xóa. "
                            + "Hãy ngừng chiếu phim hoặc chuyển suất chiếu sang trạng thái kết thúc.");
                }
            }
        }
        String sql = "DELETE FROM dbo.Showtime WHERE showtime_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            if (statement.executeUpdate() == 0) {
                throw new SQLException("Không tìm thấy suất chiếu cần xóa.");
            }
        }
    }

    private int validateMovieAndRoomConflict(Connection connection, Showtime showtime) throws SQLException {
        String movieSql = "SELECT duration_minutes, release_date, end_date, status "
                + "FROM dbo.Movie WHERE movie_id = ?";
        int duration;
        String movieStatus;
        try (PreparedStatement statement = connection.prepareStatement(movieSql)) {
            statement.setInt(1, showtime.getMovieId());
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Phim được chọn không tồn tại.");
                }
                movieStatus = result.getString("status");
                LocalDate date = showtime.getStartsAt().toLocalDate();
                LocalDate releaseDate = result.getDate("release_date").toLocalDate();
                java.sql.Date endDateValue = result.getDate("end_date");
                if (!"Stopped".equals(movieStatus)
                        && (date.isBefore(releaseDate)
                                || (endDateValue != null && date.isAfter(endDateValue.toLocalDate())))) {
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
                + "AND DATEADD(MINUTE, m.duration_minutes + ?, s.starts_at) > ?";
        try (PreparedStatement statement = connection.prepareStatement(conflictSql)) {
            statement.setString(1, showtime.getRoomName());
            statement.setInt(2, showtime.getShowtimeId());
            statement.setInt(3, duration + ShowtimeRules.TURNOVER_MINUTES);
            statement.setTimestamp(4, Timestamp.valueOf(showtime.getStartsAt()));
            statement.setInt(5, ShowtimeRules.TURNOVER_MINUTES);
            statement.setTimestamp(6, Timestamp.valueOf(showtime.getStartsAt()));
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                if (result.getInt(1) > 0) {
                    throw new SQLException("Phòng đã có lịch chiếu bị trùng thời gian.");
                }
            }
        }
        return duration;
    }

    private int findMovieDuration(Connection connection, int movieId) throws SQLException {
        String sql = "SELECT duration_minutes FROM dbo.Movie WHERE movie_id = ?";
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, movieId);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Phim được chọn không tồn tại.");
                }
                return result.getInt("duration_minutes");
            }
        }
    }

    /**
     * Tra room_id của phòng đang hoạt động và slot_id (khung giá Sáng/Chiều/Tối)
     * suy ra từ giờ bắt đầu. Không còn khung giờ chiếu cố định.
     */
    private RoomSlot validateRoomAndSlot(Connection connection, Showtime showtime) throws SQLException {
        String roomSql = "SELECT TOP (1) r.room_id FROM dbo.Room r "
                + "WHERE r.room_name = ? AND r.status = 'Active' ORDER BY r.room_id";
        int roomId;
        try (PreparedStatement statement = connection.prepareStatement(roomSql)) {
            statement.setString(1, showtime.getRoomName());
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Vui lòng chọn một phòng chiếu đang hoạt động.");
                }
                roomId = result.getInt("room_id");
            }
        }
        String slotSql = "SELECT TOP (1) ts.slot_id FROM dbo.TimeSlot ts "
                + "WHERE CONVERT(TIME(7), ?) >= CONVERT(TIME(7), ts.start_time) "
                + "AND CONVERT(TIME(7), ?) < CONVERT(TIME(7), ts.end_time) "
                + "ORDER BY ts.start_time";
        try (PreparedStatement statement = connection.prepareStatement(slotSql)) {
            statement.setTimestamp(1, Timestamp.valueOf(showtime.getStartsAt()));
            statement.setTimestamp(2, Timestamp.valueOf(showtime.getStartsAt()));
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    throw new SQLException("Giờ chiếu không thuộc khung giá nào đã cấu hình.");
                }
                return new RoomSlot(roomId, result.getInt("slot_id"));
            }
        }
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
        showtime.setStatus(result.getString("status"));
        return showtime;
    }

}
