package com.cinema.dao.RoomDAO;

import com.cinema.model.Seat;
import com.cinema.model.SeatType;
import com.cinema.util.DBContext;
import com.cinema.util.RoomUtil.RoomRuleException;
import com.cinema.util.RoomUtil.RoomRules;
import com.cinema.util.RoomUtil.RoomRules.SeatSpec;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * DAO bảng Seat/SeatType — Seat Layout & Seat Type Setup và Seat Maintenance (Admin).
 * Cột khớp script database: seat_id, room_id, row_label CHAR(1), seat_number, seat_type_id,
 * pair_seat_id (ghế đôi), status IN ('Active','Maintenance').
 *
 * Quy tắc nghiệp vụ:
 *  - Ghế đôi luôn đi theo cặp (1-2, 3-4, ...): đổi loại/bảo trì đều áp dụng cho cả cặp.
 *  - Không bảo trì / đổi loại / dựng lại layout khi ghế đang có vé còn hiệu lực cho suất chiếu chưa kết thúc.
 *  - Không dựng lại layout nếu ghế của phòng đã từng có vé (khóa ngoại Ticket.seat_id).
 */
public class SeatDAO {

    /** Vé còn hiệu lực: đã thanh toán/đã dùng, hoặc đang giữ chờ thanh toán chưa hết hạn; suất chưa kết thúc. */
    private static final String ACTIVE_TICKET_CONDITION =
            " st.status = 'Scheduled' AND st.end_time > SYSDATETIME() "
            + " AND (t.status IN ('Booked', 'Used') "
            + "      OR (t.status = 'Held' AND b.payment_expires_at > SYSDATETIME())) ";

    private Seat map(ResultSet rs) throws SQLException {
        Seat s = new Seat();
        s.setSeatId(rs.getInt("seat_id"));
        s.setRoomId(rs.getInt("room_id"));
        s.setRowLabel(rs.getString("row_label"));
        s.setSeatNumber(rs.getInt("seat_number"));
        s.setSeatTypeId(rs.getInt("seat_type_id"));
        s.setSeatTypeName(rs.getString("type_name"));
        s.setCouple(rs.getBoolean("is_couple"));
        int pair = rs.getInt("pair_seat_id");
        s.setPairSeatId(rs.wasNull() ? null : pair);
        s.setStatus(rs.getString("status"));
        return s;
    }

    public List<SeatType> findSeatTypes() throws SQLException {
        List<SeatType> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(
                     "SELECT seat_type_id, type_name, is_couple, description FROM SeatType ORDER BY seat_type_id")) {
            while (rs.next()) {
                SeatType t = new SeatType();
                t.setSeatTypeId(rs.getInt("seat_type_id"));
                t.setTypeName(rs.getString("type_name"));
                t.setCouple(rs.getBoolean("is_couple"));
                t.setDescription(rs.getString("description"));
                list.add(t);
            }
        }
        return list;
    }

    /** Toàn bộ ghế của phòng, sắp theo hàng rồi số ghế. */
    public List<Seat> findByRoom(int roomId) throws SQLException {
        String sql = "SELECT s.seat_id, s.room_id, s.row_label, s.seat_number, s.seat_type_id, "
                + " t.type_name, t.is_couple, s.pair_seat_id, s.status "
                + "FROM Seat s JOIN SeatType t ON t.seat_type_id = s.seat_type_id "
                + "WHERE s.room_id = ? ORDER BY s.row_label, s.seat_number";
        List<Seat> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    // =====================================================================
    // Seat Layout & Seat Type Setup
    // =====================================================================

    /**
     * Dựng (hoặc dựng lại) toàn bộ layout ghế của phòng theo danh sách ghế đã sinh từ RoomRules.buildLayout.
     * Sau khi dựng, capacity của phòng được cập nhật bằng số ghế thực tế.
     */
    public void replaceLayout(int roomId, List<SeatSpec> specs) throws SQLException, RoomRuleException {
        if (specs == null || specs.isEmpty()) {
            throw new RoomRuleException("Layout không có ghế nào.");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                if (scalar(c, "SELECT COUNT(*) FROM Ticket t JOIN Seat s ON s.seat_id = t.seat_id "
                        + "WHERE s.room_id = ?", roomId) > 0) {
                    throw new RoomRuleException("Ghế của phòng này đã có vé (lịch sử đặt vé) nên không thể dựng lại "
                            + "layout. Hãy dùng \"Đổi loại hàng ghế\" hoặc \"Bảo trì ghế\" thay thế.");
                }
                exec(c, "UPDATE Seat SET pair_seat_id = NULL WHERE room_id = ?", roomId);
                exec(c, "DELETE FROM Seat WHERE room_id = ?", roomId);

                String ins = "INSERT INTO Seat (room_id, row_label, seat_number, seat_type_id, pair_seat_id, status) "
                        + "VALUES (?, ?, ?, ?, NULL, 'Active')";
                try (PreparedStatement ps = c.prepareStatement(ins)) {
                    for (SeatSpec sp : specs) {
                        ps.setInt(1, roomId);
                        ps.setString(2, sp.rowLabel);
                        ps.setInt(3, sp.seatNumber);
                        ps.setInt(4, sp.seatTypeId);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                linkCouplePairs(c, roomId, null);
                try (PreparedStatement ps = c.prepareStatement("UPDATE Room SET capacity = ? WHERE room_id = ?")) {
                    ps.setInt(1, specs.size());
                    ps.setInt(2, roomId);
                    ps.executeUpdate();
                }
                c.commit();
            } catch (SQLException | RoomRuleException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }

    /**
     * Đổi loại ghế cho cả một hàng (Standard/VIP/Couple). Đổi sang Couple: hàng phải có số ghế chẵn, đánh số
     * liên tục từ 1 và không có ghế đang bảo trì; hệ thống tự ghép cặp 1-2, 3-4, ... Đổi từ Couple sang loại
     * khác thì gỡ ghép cặp.
     */
    public void changeRowType(int roomId, String rowLabel, int seatTypeId) throws SQLException, RoomRuleException {
        if (!RoomRules.isRowLabel(rowLabel)) {
            throw new RoomRuleException("Hàng ghế không hợp lệ.");
        }
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                Boolean targetCouple = null;
                try (PreparedStatement ps = c.prepareStatement("SELECT is_couple FROM SeatType WHERE seat_type_id = ?")) {
                    ps.setInt(1, seatTypeId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            targetCouple = rs.getBoolean(1);
                        }
                    }
                }
                if (targetCouple == null) {
                    throw new RoomRuleException("Loại ghế không tồn tại.");
                }

                List<Integer> ids = new ArrayList<>();
                int maxNumber = 0;
                int maintenance = 0;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT seat_id, seat_number, status FROM Seat WHERE room_id = ? AND row_label = ?")) {
                    ps.setInt(1, roomId);
                    ps.setString(2, rowLabel);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            ids.add(rs.getInt("seat_id"));
                            maxNumber = Math.max(maxNumber, rs.getInt("seat_number"));
                            if (RoomRules.SEAT_MAINTENANCE.equals(rs.getString("status"))) {
                                maintenance++;
                            }
                        }
                    }
                }
                if (ids.isEmpty()) {
                    throw new RoomRuleException("Không tìm thấy hàng " + rowLabel + " trong phòng này.");
                }

                List<String> busy = activeTicketSeats(c, ids);
                if (!busy.isEmpty()) {
                    throw new RoomRuleException("Hàng " + rowLabel + " có vé còn hiệu lực ở các ghế: "
                            + String.join(", ", busy) + ". Hãy đổi ghế cho khách hoặc chờ suất chiếu kết thúc.");
                }
                if (targetCouple) {
                    if (ids.size() % 2 != 0 || maxNumber != ids.size()) {
                        throw new RoomRuleException("Hàng " + rowLabel + " phải có số ghế chẵn và đánh số liên tục "
                                + "từ 1 mới chuyển được sang ghế đôi.");
                    }
                    if (maintenance > 0) {
                        throw new RoomRuleException("Hàng " + rowLabel + " đang có ghế bảo trì. "
                                + "Hãy mở lại ghế trước khi chuyển sang ghế đôi.");
                    }
                }

                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE Seat SET seat_type_id = ?, pair_seat_id = NULL WHERE room_id = ? AND row_label = ?")) {
                    ps.setInt(1, seatTypeId);
                    ps.setInt(2, roomId);
                    ps.setString(3, rowLabel);
                    ps.executeUpdate();
                }
                if (targetCouple) {
                    linkCouplePairs(c, roomId, rowLabel);
                }
                c.commit();
            } catch (SQLException | RoomRuleException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }

    // =====================================================================
    // Seat Maintenance
    // =====================================================================

    /**
     * Đánh dấu bảo trì (maintenance = true) hoặc mở lại (false) các ghế đã chọn. Ghế đôi luôn được xử lý cả cặp.
     * Khi bảo trì, từ chối nếu ghế đang có vé còn hiệu lực (cần đổi ghế cho khách trước).
     *
     * @return số ghế thực sự được cập nhật (đã tính cả ghế còn lại của cặp)
     */
    public int setMaintenance(int roomId, List<Integer> seatIds, boolean maintenance)
            throws SQLException, RoomRuleException {
        if (seatIds == null || seatIds.isEmpty()) {
            throw new RoomRuleException("Chưa chọn ghế nào.");
        }
        Set<Integer> requested = new LinkedHashSet<>(seatIds);
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                Set<Integer> targets = new LinkedHashSet<>();
                int found = 0;
                try (PreparedStatement ps = c.prepareStatement(
                        "SELECT seat_id, pair_seat_id FROM Seat WHERE room_id = ? AND seat_id IN ("
                                + placeholders(requested.size()) + ")")) {
                    ps.setInt(1, roomId);
                    int i = 2;
                    for (Integer id : requested) {
                        ps.setInt(i++, id);
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            found++;
                            targets.add(rs.getInt("seat_id"));
                            int pair = rs.getInt("pair_seat_id");
                            if (!rs.wasNull()) {
                                targets.add(pair);
                            }
                        }
                    }
                }
                if (found != requested.size()) {
                    throw new RoomRuleException("Có ghế không thuộc phòng chiếu này.");
                }

                List<Integer> targetList = new ArrayList<>(targets);
                if (maintenance) {
                    List<String> busy = activeTicketSeats(c, targetList);
                    if (!busy.isEmpty()) {
                        throw new RoomRuleException("Không thể bảo trì: ghế " + String.join(", ", busy)
                                + " đang có vé còn hiệu lực. Hãy đổi ghế cho khách trước (chức năng Đổi ghế).");
                    }
                }

                int changed;
                try (PreparedStatement ps = c.prepareStatement(
                        "UPDATE Seat SET status = ? WHERE room_id = ? AND status <> ? AND seat_id IN ("
                                + placeholders(targetList.size()) + ")")) {
                    String newStatus = maintenance ? RoomRules.SEAT_MAINTENANCE : RoomRules.SEAT_ACTIVE;
                    ps.setString(1, newStatus);
                    ps.setInt(2, roomId);
                    ps.setString(3, newStatus);
                    int i = 4;
                    for (Integer id : targetList) {
                        ps.setInt(i++, id);
                    }
                    changed = ps.executeUpdate();
                }
                c.commit();
                return changed;
            } catch (SQLException | RoomRuleException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }

    // ---------- helpers ----------

    /** Gán pair_seat_id cho ghế đôi theo cặp 1-2, 3-4, ... (rowLabel = null → cả phòng). */
    private void linkCouplePairs(Connection c, int roomId, String rowLabel) throws SQLException {
        String sql = "UPDATE s SET s.pair_seat_id = p.seat_id "
                + "FROM Seat s "
                + "JOIN SeatType t ON t.seat_type_id = s.seat_type_id AND t.is_couple = 1 "
                + "JOIN Seat p ON p.room_id = s.room_id AND p.row_label = s.row_label "
                + "  AND p.seat_number = CASE WHEN s.seat_number % 2 = 1 THEN s.seat_number + 1 "
                + "                           ELSE s.seat_number - 1 END "
                + "WHERE s.room_id = ?" + (rowLabel != null ? " AND s.row_label = ?" : "");
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, roomId);
            if (rowLabel != null) {
                ps.setString(2, rowLabel);
            }
            ps.executeUpdate();
        }
    }

    /** Nhãn các ghế (VD "A1") trong danh sách đang có vé còn hiệu lực. */
    private List<String> activeTicketSeats(Connection c, List<Integer> seatIds) throws SQLException {
        List<String> labels = new ArrayList<>();
        if (seatIds.isEmpty()) {
            return labels;
        }
        String sql = "SELECT DISTINCT s.row_label, s.seat_number FROM Ticket t "
                + "JOIN Seat s ON s.seat_id = t.seat_id "
                + "JOIN Showtime st ON st.showtime_id = t.showtime_id "
                + "JOIN Booking b ON b.booking_id = t.booking_id "
                + "WHERE s.seat_id IN (" + placeholders(seatIds.size()) + ") AND" + ACTIVE_TICKET_CONDITION
                + "ORDER BY s.row_label, s.seat_number";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            int i = 1;
            for (Integer id : seatIds) {
                ps.setInt(i++, id);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    labels.add(rs.getString(1) + rs.getInt(2));
                }
            }
        }
        return labels;
    }

    private static String placeholders(int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            sb.append(i == 0 ? "?" : ",?");
        }
        return sb.toString();
    }

    private int scalar(Connection c, String sql, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private void exec(Connection c, String sql, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}
