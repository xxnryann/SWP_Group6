package com.cinema.dao;

import com.cinema.model.Cinema;
import com.cinema.model.Room;
import com.cinema.model.RoomShowtime;
import com.cinema.model.Showtime;
import com.cinema.util.DBContext;
import com.cinema.util.room.RoomRuleException;
import com.cinema.util.room.RoomRules;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DAO bảng Room — Screening Room Management (Admin).
 * Cột khớp script database của nhóm: room_id, cinema_id, room_name, room_type, capacity, status.
 */
public class RoomDAO {

    private static final String SELECT_WITH_STATS =
            "SELECT r.room_id, r.cinema_id, c.cinema_name, r.room_name, r.room_type, r.capacity, r.status, "
            + " (SELECT COUNT(*) FROM Seat s WHERE s.room_id = r.room_id) AS seat_count, "
            + " (SELECT COUNT(*) FROM Seat s WHERE s.room_id = r.room_id AND s.status = 'Maintenance') AS maint_count, "
            + " (SELECT COUNT(*) FROM Showtime st WHERE st.room_id = r.room_id AND st.status = 'Scheduled' "
            + "     AND st.end_time > SYSDATETIME()) AS upcoming_count "
            + "FROM Room r JOIN Cinema c ON c.cinema_id = r.cinema_id ";

    private Room map(ResultSet rs) throws SQLException {
        Room r = new Room();
        r.setRoomId(rs.getInt("room_id"));
        r.setCinemaId(rs.getInt("cinema_id"));
        r.setCinemaName(rs.getString("cinema_name"));
        r.setRoomName(rs.getString("room_name"));
        r.setRoomType(rs.getString("room_type"));
        r.setCapacity(rs.getInt("capacity"));
        r.setStatus(rs.getString("status"));
        r.setSeatCount(rs.getInt("seat_count"));
        r.setMaintenanceCount(rs.getInt("maint_count"));
        r.setUpcomingShowtimes(rs.getInt("upcoming_count"));
        return r;
    }

    /** Danh sách phòng (kèm số ghế, ghế bảo trì, suất chiếu sắp tới); keyword lọc theo tên phòng. */
    public List<Room> findAll(String keyword, LocalDate scheduleDate) throws SQLException {
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        String sql = SELECT_WITH_STATS + (hasKeyword ? "WHERE r.room_name LIKE ? " : "")
                + "ORDER BY c.cinema_name, r.room_name";
        List<Room> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (hasKeyword) {
                ps.setString(1, "%" + keyword.trim() + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        loadSchedules(list, scheduleDate == null ? LocalDate.now() : scheduleDate);
        return list;
    }

    private void loadSchedules(List<Room> rooms, LocalDate date) throws SQLException {
        if (rooms.isEmpty()) return;
        Map<Integer, Room> byId = new HashMap<>();
        for (Room room : rooms) {
            byId.put(room.getRoomId(), room);
        }
        String sql = "SELECT s.room_id, s.showtime_id, s.movie_id, m.title, m.duration_minutes, "
                + "s.room_name, s.starts_at, s.status "
                + "FROM Showtime s JOIN Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.status = 'Scheduled' AND CAST(s.starts_at AS DATE) = ? "
                + "AND s.room_id IS NOT NULL ORDER BY s.room_id, s.starts_at";
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Room room = byId.get(rs.getInt("room_id"));
                    if (room == null) continue;
                    Showtime showtime = new Showtime();
                    showtime.setShowtimeId(rs.getInt("showtime_id"));
                    showtime.setMovieId(rs.getInt("movie_id"));
                    showtime.setMovieTitle(rs.getString("title"));
                    showtime.setMovieDurationMinutes(rs.getInt("duration_minutes"));
                    showtime.setRoomName(rs.getString("room_name"));
                    Timestamp startsAt = rs.getTimestamp("starts_at");
                    showtime.setStartsAt(startsAt == null ? null : startsAt.toLocalDateTime());
                    showtime.setStatus(rs.getString("status"));
                    room.getSchedule().add(showtime);
                }
            }
        }
    }

    public Room findById(int roomId) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT_WITH_STATS + "WHERE r.room_id = ?")) {
            ps.setInt(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /** Danh sách rạp để chọn khi tạo phòng. */
    public List<Cinema> findCinemas() throws SQLException {
        List<Cinema> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT cinema_id, cinema_name FROM Cinema ORDER BY cinema_name")) {
            while (rs.next()) {
                Cinema cn = new Cinema();
                cn.setCinemaId(rs.getInt("cinema_id"));
                cn.setCinemaName(rs.getString("cinema_name"));
                list.add(cn);
            }
        }
        return list;
    }

    public boolean cinemaExists(int cinemaId) throws SQLException {
        return exists("SELECT 1 FROM Cinema WHERE cinema_id = ?", cinemaId);
    }

    /** Tên phòng đã tồn tại trong rạp (UNIQUE cinema_id + room_name); excludeRoomId = 0 khi thêm mới. */
    public boolean nameExists(int cinemaId, String roomName, int excludeRoomId) throws SQLException {
        String sql = "SELECT 1 FROM Room WHERE cinema_id = ? AND room_name = ? AND room_id <> ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, cinemaId);
            ps.setString(2, roomName);
            ps.setInt(3, excludeRoomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Tổng số phòng chiếu, tính cả phòng đã đóng. */
    public int countAll() throws SQLException {
        try (Connection c = DBContext.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM Room")) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /**
     * Thêm phòng mới, trả về room_id. Đếm và thêm trong cùng một câu lệnh (khóa UPDLOCK, HOLDLOCK)
     * để hai admin thêm cùng lúc không vượt quá giới hạn số phòng.
     */
    public int insert(Room r) throws SQLException, RoomRuleException {
        String sql = "INSERT INTO Room (cinema_id, room_name, room_type, capacity, status) "
                + "SELECT ?, ?, ?, ?, ? WHERE (SELECT COUNT(*) FROM Room WITH (UPDLOCK, HOLDLOCK)) < ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, r.getCinemaId());
            ps.setString(2, r.getRoomName());
            ps.setString(3, r.getRoomType());
            ps.setInt(4, r.getCapacity());
            ps.setString(5, r.getStatus());
            ps.setInt(6, RoomRules.MAX_ROOMS);
            if (ps.executeUpdate() == 0) {
                throw new RoomRuleException(RoomRules.ROOM_LIMIT_MESSAGE);
            }
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    public void update(Room r) throws SQLException {
        String sql = "UPDATE Room SET cinema_id = ?, room_name = ?, room_type = ?, capacity = ?, status = ? "
                + "WHERE room_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, r.getCinemaId());
            ps.setString(2, r.getRoomName());
            ps.setString(3, r.getRoomType());
            ps.setInt(4, r.getCapacity());
            ps.setString(5, r.getStatus());
            ps.setInt(6, r.getRoomId());
            ps.executeUpdate();
        }
    }

    /** Số suất chiếu sắp tới/đang chiếu (chưa hủy, chưa kết thúc) của phòng. */
    public int countUpcomingShowtimes(int roomId) throws SQLException {
        return count("SELECT COUNT(*) FROM Showtime WHERE room_id = ? AND status = 'Scheduled' "
                + "AND end_time > SYSDATETIME()", roomId);
    }

    /** Đóng/mở phòng. Không cho đóng khi còn suất chiếu sắp tới. */
    public void setStatus(int roomId, String status) throws SQLException, RoomRuleException {
        if ("Closed".equals(status) && countUpcomingShowtimes(roomId) > 0) {
            throw new RoomRuleException("Phòng còn suất chiếu sắp tới, không thể đóng. "
                    + "Hãy hủy hoặc dời các suất chiếu trước.");
        }
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("UPDATE Room SET status = ? WHERE room_id = ?")) {
            ps.setString(1, status);
            ps.setInt(2, roomId);
            ps.executeUpdate();
        }
    }

    /**
     * Xóa phòng cùng toàn bộ ghế. Chỉ xóa được khi phòng chưa từng có suất chiếu và chưa có vé nào
     * (các bảng Showtime/Ticket có khóa ngoại tới phòng/ghế). Nếu không, nên "Đóng" phòng thay vì xóa.
     */
    public void delete(int roomId) throws SQLException, RoomRuleException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                if (count(c, "SELECT COUNT(*) FROM Showtime WHERE room_id = ?", roomId) > 0) {
                    throw new RoomRuleException("Phòng đã có suất chiếu nên không thể xóa. "
                            + "Hãy chuyển phòng sang trạng thái \"Đã đóng\".");
                }
                if (count(c, "SELECT COUNT(*) FROM Ticket t JOIN Seat s ON s.seat_id = t.seat_id "
                        + "WHERE s.room_id = ?", roomId) > 0) {
                    throw new RoomRuleException("Ghế của phòng đã có vé nên không thể xóa phòng.");
                }
                run(c, "UPDATE Seat SET pair_seat_id = NULL WHERE room_id = ?", roomId);
                run(c, "DELETE FROM Seat WHERE room_id = ?", roomId);
                run(c, "DELETE FROM Room WHERE room_id = ?", roomId);
                c.commit();
            } catch (SQLException | RoomRuleException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }

    // ---------- helpers ----------

    private boolean exists(String sql, int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private int count(String sql, int id) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            return count(c, sql, id);
        }
    }

    private int count(Connection c, String sql, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private void run(Connection c, String sql, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /**
     * Các suất chiếu của một phòng (trang Admin "Lịch phòng chiếu").
     * scope: "upcoming" = suất chưa kết thúc và chưa hủy (tăng dần theo giờ),
     *        "past"     = suất đã kết thúc hoặc đã hủy (giảm dần),
     *        còn lại    = tất cả (tăng dần).
     */
    public List<RoomShowtime> findShowtimes(int roomId, String scope) throws SQLException {
        String where;
        String order;
        if ("upcoming".equals(scope)) {
            where = "AND s.status = 'Scheduled' AND s.end_time > SYSDATETIME() ";
            order = "ORDER BY s.start_time ASC";
        } else if ("past".equals(scope)) {
            where = "AND (s.status <> 'Scheduled' OR s.end_time <= SYSDATETIME()) ";
            order = "ORDER BY s.start_time DESC";
        } else {
            where = "";
            order = "ORDER BY s.start_time ASC";
        }
        String sql = "SELECT s.showtime_id, s.movie_id, m.title, m.duration_minutes, m.age_rating, "
                + " s.start_time, s.end_time, s.status, "
                + " (SELECT COUNT(*) FROM Ticket t WHERE t.showtime_id = s.showtime_id "
                + "     AND t.status IN ('Booked', 'Used')) AS sold "
                + "FROM Showtime s JOIN Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.room_id = ? " + where + order;
        List<RoomShowtime> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RoomShowtime st = new RoomShowtime();
                    st.setShowtimeId(rs.getInt("showtime_id"));
                    st.setMovieId(rs.getInt("movie_id"));
                    st.setMovieTitle(rs.getString("title"));
                    st.setDurationMinutes(rs.getInt("duration_minutes"));
                    st.setAgeRating(rs.getString("age_rating"));
                    st.setStartTime(rs.getTimestamp("start_time").toLocalDateTime());
                    st.setEndTime(rs.getTimestamp("end_time").toLocalDateTime());
                    st.setStatus(rs.getString("status"));
                    st.setSoldTickets(rs.getInt("sold"));
                    list.add(st);
                }
            }
        }
        return list;
    }
}
