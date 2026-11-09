package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/** Đổi ghế cho vé đã thanh toán (Staff) — dùng sp_ChangeSeat. */
public class SeatChangeDAO {

    /** Vé + suất chiếu theo mã vé; null nếu không có. */
    public Map<String, Object> findTicket(String ticketCode) throws SQLException {
        List<Map<String, Object>> rows = Rows.query(
                "SELECT t.ticket_id, t.ticket_code, t.status, t.price, t.showtime_id, "
                + "m.title AS movie_title, r.room_name, s.start_time, "
                + "CONCAT(sc.row_label, sc.seat_number) AS seat_label, sc.seat_id, sty.type_name AS seat_type, "
                + "CONCAT(ps.row_label, ps.seat_number) AS pair_label, a.full_name AS customer_name, "
                + "CASE WHEN s.status = 'Scheduled' AND s.start_time > SYSDATETIME() THEN 1 ELSE 0 END AS changeable "
                + "FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id "
                + "JOIN Movie m ON m.movie_id = s.movie_id JOIN Room r ON r.room_id = s.room_id "
                + "JOIN Seat sc ON sc.seat_id = t.seat_id JOIN SeatType sty ON sty.seat_type_id = sc.seat_type_id "
                + "LEFT JOIN Seat ps ON ps.seat_id = sc.pair_seat_id "
                + "JOIN Booking b ON b.booking_id = t.booking_id LEFT JOIN Account a ON a.account_id = b.customer_id "
                + "WHERE t.ticket_code = ?", ticketCode);
        return rows.isEmpty() ? null : rows.get(0);
    }

    /** Ghế trống (GREEN) cùng loại với ghế hiện tại; ghế đôi chỉ liệt kê mỗi cặp một lần khi cả cặp còn trống. */
    public List<Map<String, Object>> freeSeats(int showtimeId, int currentSeatId) throws SQLException {
        return Rows.query(
                "SELECT v.seat_id, v.row_label, v.seat_number, v.seat_type, "
                + "CONCAT(p.row_label, p.seat_number) AS pair_label "
                + "FROM vw_SeatMap v JOIN Seat st ON st.seat_id = v.seat_id JOIN Seat cur ON cur.seat_id = ? "
                + "LEFT JOIN vw_SeatMap p ON p.showtime_id = v.showtime_id AND p.seat_id = v.pair_seat_id "
                + "WHERE v.showtime_id = ? AND v.color = 'GREEN' AND st.seat_type_id = cur.seat_type_id "
                + "AND ((cur.pair_seat_id IS NULL AND v.pair_seat_id IS NULL) "
                + "OR (cur.pair_seat_id IS NOT NULL AND p.color = 'GREEN' AND v.seat_id < v.pair_seat_id)) "
                + "ORDER BY v.row_label, v.seat_number", currentSeatId, showtimeId);
    }

    /** Lịch sử đổi ghế gần đây. */
    public List<Map<String, Object>> recentChanges(int limit) throws SQLException {
        return Rows.query(
                "SELECT TOP (?) h.changed_at, t.ticket_code, "
                + "CONCAT(os.row_label, os.seat_number) AS old_seat, CONCAT(ns.row_label, ns.seat_number) AS new_seat, "
                + "h.reason, a.full_name AS changed_by_name "
                + "FROM TicketChangeHistory h JOIN Ticket t ON t.ticket_id = h.ticket_id "
                + "LEFT JOIN Seat os ON os.seat_id = h.old_seat_id LEFT JOIN Seat ns ON ns.seat_id = h.new_seat_id "
                + "LEFT JOIN Account a ON a.account_id = h.changed_by "
                + "WHERE h.change_type = 'SeatChange' ORDER BY h.changed_at DESC", limit);
    }

    public void changeSeat(int ticketId, int newSeatId, int staffAccountId, String reason) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call dbo.sp_ChangeSeat(?, ?, ?, ?)}")) {
            cs.setInt(1, ticketId);
            cs.setInt(2, newSeatId);
            cs.setInt(3, staffAccountId);
            cs.setString(4, reason);
            cs.execute();
        }
    }
}
