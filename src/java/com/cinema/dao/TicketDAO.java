package com.cinema.dao;

import com.cinema.model.PointTransaction;
import com.cinema.model.Ticket;
import com.cinema.util.DBContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * Truy vấn lịch sử vé của khách + biến động MyPoint.
 *
 * <p>Lịch sử vé đọc qua stored procedure {@code sp_GetCustomerTickets} của DB
 * nhóm: procedure tự {@code sp_ExpirePastTickets} (vé đã qua giờ chiếu →
 * {@code Expired}) rồi trả về <b>từng vé</b> kèm cờ {@code can_cancel} —
 * nút "Huỷ vé" chỉ hiện khi vé còn hiệu lực và còn trong thời hạn huỷ.</p>
 *
 * <p>Lưu ý quan trọng: {@code Booking.customer_id} / {@code MyPointTransaction.customer_id}
 * trỏ tới {@code Account.account_id} (hệ thống nghiệp vụ), KHÔNG phải
 * {@code Users.UserId}. Vì vậy các truy vấn dưới đây resolve customer_id qua
 * email của user đang đăng nhập thay vì dùng thẳng userId.</p>
 */
public class TicketDAO {

    /** Số giờ tối thiểu trước giờ chiếu để còn huỷ được vé (đồng bộ CANCEL_BEFORE_HOURS). */
    private static final int DEFAULT_CANCEL_HOURS = 2;

    /**
     * Lịch sử vé của khách — mỗi phần tử là MỘT vé (1 thẻ, 1 mã QR).
     *
     * @param email email của người dùng đang đăng nhập
     */
    public List<Ticket> findByUser(String email) throws SQLException {
        List<Ticket> list = new ArrayList<>();
        // Account.email dùng collation CI_AS (case-insensitive) → so sánh trực tiếp,
        // không bọc LOWER() để tránh mất khả năng seek index.
        String sql = "{call sp_GetCustomerTickets(?, ?)}";
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.setString(1, email == null ? "" : email);
            cs.setInt(2, DEFAULT_CANCEL_HOURS);
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    Ticket t = new Ticket();
                    t.setTicketId(rs.getInt("ticket_id"));
                    t.setTicketCode(rs.getString("ticket_code"));
                    t.setBookingId(rs.getInt("booking_id"));
                    t.setBookingCode(rs.getString("booking_code"));
                    t.setBookingCustomerId(rs.getInt("customer_id"));
                    t.setMovieTitle(rs.getString("movie_title"));
                    t.setCinemaName(rs.getString("cinema_name"));
                    t.setRoomName(rs.getString("room_name"));
                    t.setSeatLabel(rs.getString("seat_label"));
                    t.setPrice(rs.getBigDecimal("price"));
                    t.setStatus(rs.getString("ticket_status"));
                    t.setCanCancel(rs.getInt("can_cancel") == 1);
                    Timestamp start = rs.getTimestamp("start_time");
                    t.setStartTime(start == null ? null : start.toLocalDateTime());
                    Timestamp end = rs.getTimestamp("end_time");
                    t.setEndTime(end == null ? null : end.toLocalDateTime());
                    list.add(t);
                }
            }
            // Thời điểm mua vé: procedure không trả về nên đọc riêng theo ticket_id.
            java.util.Map<Integer, java.time.LocalDateTime> bought = new java.util.HashMap<>();
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT t.ticket_id, COALESCE(b.paid_at, b.created_at) AS purchased_at "
                    + "FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id "
                    + "JOIN Account a ON a.account_id = b.customer_id WHERE a.email = ?")) {
                ps.setString(1, email == null ? "" : email);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Timestamp ts = rs.getTimestamp("purchased_at");
                        if (ts != null) bought.put(rs.getInt("ticket_id"), ts.toLocalDateTime());
                    }
                }
            }
            for (Ticket t : list) t.setPurchasedAt(bought.get(t.getTicketId()));
        }
        // Còn hiệu lực lên đầu, đã huỷ xuống cuối; trong mỗi nhóm vé mua gần nhất trước.
        list.sort(java.util.Comparator
                .comparingInt(Ticket::getSortRank)
                .thenComparing(Ticket::getPurchasedAt, java.util.Comparator.nullsLast(java.util.Comparator.reverseOrder()))
                .thenComparing(Ticket::getTicketId, java.util.Comparator.reverseOrder()));
        return list;
    }

    /**
     * Các đơn có combo của khách đã thanh toán ("Đã mua"), hoặc đã bị huỷ
     * (mọi vé của đơn đã huỷ → "Đã huỷ"). Đơn chưa từng thanh toán không được liệt kê.
     * Đơn còn hiệu lực lên đầu, trong mỗi nhóm mua gần nhất trước.
     */
    public List<com.cinema.model.ComboOrder> findComboOrdersByUser(String email) throws SQLException {
        String sql = "SELECT b.booking_id, b.booking_code, b.status AS booking_status, "
                + "COALESCE(b.paid_at, b.created_at) AS purchased_at, "
                + "m.title, r.room_name, ci.cinema_name, s.start_time, "
                + "(SELECT COUNT(*) FROM Ticket t WHERE t.booking_id = b.booking_id AND t.status <> 'Cancelled') AS live_tickets, "
                + "cb.combo_name, bc.quantity, bc.unit_price "
                + "FROM Booking b "
                + "JOIN Account a ON a.account_id = b.customer_id "
                + "JOIN BookingCombo bc ON bc.booking_id = b.booking_id "
                + "JOIN Combo cb ON cb.combo_id = bc.combo_id "
                + "JOIN Showtime s ON s.showtime_id = b.showtime_id "
                + "JOIN Movie m ON m.movie_id = s.movie_id "
                + "JOIN Room r ON r.room_id = s.room_id "
                + "JOIN Cinema ci ON ci.cinema_id = r.cinema_id "
                + "WHERE a.email = ? AND b.paid_at IS NOT NULL "
                + "ORDER BY b.booking_id, cb.combo_name";
        java.util.Map<Integer, com.cinema.model.ComboOrder> byId = new java.util.LinkedHashMap<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email == null ? "" : email);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int id = rs.getInt("booking_id");
                    com.cinema.model.ComboOrder o = byId.get(id);
                    if (o == null) {
                        o = new com.cinema.model.ComboOrder();
                        o.setBookingId(id);
                        o.setBookingCode(rs.getString("booking_code"));
                        o.setMovieTitle(rs.getString("title"));
                        o.setRoomName(rs.getString("room_name"));
                        o.setCinemaName(rs.getString("cinema_name"));
                        Timestamp st = rs.getTimestamp("start_time");
                        o.setStartTime(st == null ? null : st.toLocalDateTime());
                        Timestamp pu = rs.getTimestamp("purchased_at");
                        o.setPurchasedAt(pu == null ? null : pu.toLocalDateTime());
                        o.setCancelled("Cancelled".equalsIgnoreCase(rs.getString("booking_status"))
                                || rs.getInt("live_tickets") == 0);
                        byId.put(id, o);
                    }
                    o.getLines().add(new com.cinema.model.ComboOrder.Line(
                            rs.getString("combo_name"), rs.getInt("quantity"), rs.getBigDecimal("unit_price")));
                }
            }
        }
        List<com.cinema.model.ComboOrder> list = new ArrayList<>(byId.values());
        list.sort(java.util.Comparator
                .comparing(com.cinema.model.ComboOrder::isCancelled)
                .thenComparing(com.cinema.model.ComboOrder::getPurchasedAt,
                        java.util.Comparator.nullsLast(java.util.Comparator.reverseOrder())));
        return list;
    }

    /**
     * Đọc MỘT vé theo id (không kiểm tra ownership — dành cho nhân viên quầy
     * in mã QR lúc bán vé).
     *
     * @param ticketId id vé
     * @return vé, hoặc null nếu không tồn tại
     */
    public Ticket findById(int ticketId) throws SQLException {
        String sql = "SELECT t.ticket_id, t.ticket_code, t.status AS ticket_status, t.price, "
                + "b.booking_id, b.booking_code, b.status AS booking_status, b.customer_id, "
                + "m.title AS movie_title, ci.cinema_name, r.room_name, "
                + "CONCAT(sc.row_label, sc.seat_number) AS seat_label, "
                + "s.start_time, s.end_time, 0 AS can_cancel "
                + "FROM Ticket t "
                + "JOIN Booking b  ON b.booking_id = t.booking_id "
                + "JOIN Showtime s ON s.showtime_id = t.showtime_id "
                + "JOIN Movie m    ON m.movie_id = s.movie_id "
                + "JOIN Room r     ON r.room_id = s.room_id "
                + "JOIN Cinema ci  ON ci.cinema_id = r.cinema_id "
                + "JOIN Seat sc    ON sc.seat_id = t.seat_id "
                + "WHERE t.ticket_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Ticket t = new Ticket();
                t.setTicketId(rs.getInt("ticket_id"));
                t.setTicketCode(rs.getString("ticket_code"));
                t.setBookingId(rs.getInt("booking_id"));
                t.setBookingCode(rs.getString("booking_code"));
                t.setBookingCustomerId(rs.getInt("customer_id"));
                t.setMovieTitle(rs.getString("movie_title"));
                t.setCinemaName(rs.getString("cinema_name"));
                t.setRoomName(rs.getString("room_name"));
                t.setSeatLabel(rs.getString("seat_label"));
                t.setPrice(rs.getBigDecimal("price"));
                t.setStatus(rs.getString("ticket_status"));
                t.setCanCancel(false);
                Timestamp start = rs.getTimestamp("start_time");
                t.setStartTime(start == null ? null : start.toLocalDateTime());
                Timestamp end = rs.getTimestamp("end_time");
                t.setEndTime(end == null ? null : end.toLocalDateTime());
                return t;
            }
        }
    }

    /**
     * Đọc MỘT vé của khách theo id (dùng để kiểm tra ownership trước khi huỷ).
     *
     * <p>Trả về {@code null} nếu vé không tồn tại hoặc không thuộc đơn của khách
     * đang đăng nhập — nhờ vậy controller không thể đoán/id giả để huỷ vé của
     * người khác.</p>
     *
     * @param ticketId id vé
     * @param email    email khách đang đăng nhập
     * @return vé của khách, hoặc null
     */
    public Ticket findOneByUser(int ticketId, String email) throws SQLException {
        String sql = "SELECT t.ticket_id, t.ticket_code, t.status AS ticket_status, t.price, "
                + "b.booking_id, b.booking_code, b.status AS booking_status, b.customer_id, "
                + "m.title AS movie_title, ci.cinema_name, r.room_name, "
                + "CONCAT(sc.row_label, sc.seat_number) AS seat_label, "
                + "s.start_time, s.end_time, "
                + "CASE WHEN t.status = 'Booked' "
                + "     AND DATEADD(HOUR, -?, s.start_time) >= SYSDATETIME() "
                + "    THEN 1 ELSE 0 END AS can_cancel "
                + "FROM Ticket t "
                + "JOIN Booking b  ON b.booking_id = t.booking_id "
                + "JOIN Account a  ON a.account_id = b.customer_id "
                + "JOIN Showtime s ON s.showtime_id = t.showtime_id "
                + "JOIN Movie m    ON m.movie_id = s.movie_id "
                + "JOIN Room r     ON r.room_id = s.room_id "
                + "JOIN Cinema ci  ON ci.cinema_id = r.cinema_id "
                + "JOIN Seat sc    ON sc.seat_id = t.seat_id "
                + "WHERE t.ticket_id = ? AND a.email = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, DEFAULT_CANCEL_HOURS);
            ps.setInt(2, ticketId);
            ps.setString(3, email == null ? "" : email);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Ticket t = new Ticket();
                t.setTicketId(rs.getInt("ticket_id"));
                t.setTicketCode(rs.getString("ticket_code"));
                t.setBookingId(rs.getInt("booking_id"));
                t.setBookingCode(rs.getString("booking_code"));
                t.setBookingCustomerId(rs.getInt("customer_id"));
                t.setMovieTitle(rs.getString("movie_title"));
                t.setCinemaName(rs.getString("cinema_name"));
                t.setRoomName(rs.getString("room_name"));
                t.setSeatLabel(rs.getString("seat_label"));
                t.setPrice(rs.getBigDecimal("price"));
                t.setStatus(rs.getString("ticket_status"));
                t.setCanCancel(rs.getInt("can_cancel") == 1);
                Timestamp start = rs.getTimestamp("start_time");
                t.setStartTime(start == null ? null : start.toLocalDateTime());
                Timestamp end = rs.getTimestamp("end_time");
                t.setEndTime(end == null ? null : end.toLocalDateTime());
                return t;
            }
        }
    }

    /**
     * Huỷ MỘT vé đã thanh toán (UC19 / BF-09).
     *
     * <p>Gọi {@code sp_CancelTicket} — procedure kiểm tra ownership (vé phải
     * thuộc đơn của khách đang đăng nhập), trạng thái vé, thời hạn huỷ, rồi
     * hoàn tiền cho đúng 1 vé và trả lại MyPoint/voucher khi đơn không còn
     * vé hiệu lực nào.</p>
     *
     * @param ticketId  vé cần huỷ
     * @param accountId account_id của khách đang đăng nhập
     * @param reason    lý do huỷ (tuỳ chọn)
     * @throws SQLException message tiếng Việt từ procedure khi nghiệp vụ không cho phép
     */
    public void cancelTicket(int ticketId, int accountId, String reason) throws SQLException {
        String sql = "{call sp_CancelTicket(?, ?, ?)}";
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            cs.setInt(1, ticketId);
            cs.setInt(2, accountId);
            cs.setString(3, reason == null ? null : reason);
            cs.execute();
        }
    }

    /**
     * Lịch sử biến động MyPoint của khách.
     *
     * @param email email của người dùng đang đăng nhập
     */
    public List<PointTransaction> findPointHistory(String email) throws SQLException {
        // Account.email dùng collation CI_AS → so sánh trực tiếp để giữ index seek.
        String sql = "SELECT p.txn_id, p.points, p.created_at, "
                + "CASE p.txn_type WHEN 'Earn' THEN N'Tích điểm đơn ' WHEN 'Redeem' THEN N'Dùng điểm cho đơn ' "
                + "ELSE N'Điều chỉnh điểm' END + COALESCE(b.booking_code, '') AS reason "
                + "FROM MyPointTransaction p "
                + "JOIN Account a ON a.account_id = p.customer_id "
                + "LEFT JOIN Booking b ON b.booking_id = p.booking_id "
                + "WHERE a.email = ? ORDER BY p.created_at DESC, p.txn_id DESC";
        List<PointTransaction> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email == null ? "" : email);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PointTransaction p = new PointTransaction();
                    p.setTxId(rs.getInt("txn_id"));
                    p.setPoints(rs.getInt("points"));
                    p.setReason(rs.getString("reason"));
                    p.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                    list.add(p);
                }
            }
        }
        return list;
    }
}
