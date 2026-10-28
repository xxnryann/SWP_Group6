package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/** Soát vé tại cửa phòng chiếu: dùng stored procedure {@code sp_CheckInTicket}. */
public class CheckInDAO {

    private static final String TICKET_INFO =
            "SELECT t.ticket_id, t.ticket_code, t.status, t.price, t.checked_in_at, m.title AS movie_title, "
            + "r.room_name, s.start_time, s.end_time, CONCAT(sc.row_label, sc.seat_number) AS seat_label, "
            + "a.full_name AS customer_name "
            + "FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id "
            + "JOIN Movie m ON m.movie_id = s.movie_id JOIN Room r ON r.room_id = s.room_id "
            + "JOIN Seat sc ON sc.seat_id = t.seat_id "
            + "JOIN Booking b ON b.booking_id = t.booking_id "
            + "LEFT JOIN Account a ON a.account_id = b.customer_id ";

    /** Thông tin vé theo mã; null nếu không tồn tại. */
    public Map<String, Object> findTicket(String ticketCode) throws SQLException {
        List<Map<String, Object>> rows = Rows.query(TICKET_INFO + "WHERE t.ticket_code = ?", ticketCode);
        return rows.isEmpty() ? null : rows.get(0);
    }

    /**
     * Soát vé. Procedure ném lỗi 5006x (không tồn tại, đã dùng, không hợp lệ, ngoài giờ cho phép).
     */
    public void checkIn(String ticketCode, int staffAccountId) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call dbo.sp_CheckInTicket(?, ?)}")) {
            cs.setString(1, ticketCode);
            cs.setInt(2, staffAccountId);
            cs.execute();
        }
    }

    /** Các vé đã soát gần đây nhất. */
    public List<Map<String, Object>> recent(int limit) throws SQLException {
        return Rows.query("SELECT TOP (?) t.ticket_code, m.title AS movie_title, r.room_name, "
                + "CONCAT(sc.row_label, sc.seat_number) AS seat_label, t.checked_in_at, st.full_name AS staff_name "
                + "FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id "
                + "JOIN Movie m ON m.movie_id = s.movie_id JOIN Room r ON r.room_id = s.room_id "
                + "JOIN Seat sc ON sc.seat_id = t.seat_id LEFT JOIN Account st ON st.account_id = t.checked_in_by "
                + "WHERE t.status = 'Used' AND t.checked_in_at IS NOT NULL ORDER BY t.checked_in_at DESC", limit);
    }
}
