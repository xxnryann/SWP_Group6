package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/** Hàng đợi email và hộp thư của khách: bảng EmailNotification (vé điện tử, nhắc lịch chiếu, hủy suất, voucher...). */
public class EmailOutboxDAO {

    /** Thư đang chờ gửi (kèm email người nhận). */
    public List<Map<String, Object>> pending(int limit) throws SQLException {
        return Rows.query("SELECT TOP (?) e.notif_id, e.notif_type, e.subject, e.body, e.booking_id, e.showtime_id, "
                + "a.email, a.full_name FROM EmailNotification e JOIN Account a ON a.account_id = e.customer_id "
                + "WHERE e.status = 'Pending' ORDER BY e.notif_id", limit);
    }

    public void markSent(int id) throws SQLException {
        update("UPDATE EmailNotification SET status = 'Sent', sent_at = SYSDATETIME() WHERE notif_id = ?", id);
    }

    public void markFailed(int id) throws SQLException {
        update("UPDATE EmailNotification SET status = 'Failed' WHERE notif_id = ?", id);
    }

    /** Nội dung chi tiết các vé của một đơn (dùng cho email vé điện tử). */
    public List<Map<String, Object>> ticketsOfBooking(int bookingId) throws SQLException {
        return Rows.query("SELECT b.booking_code, t.ticket_code, m.title, r.room_name, s.start_time, "
                + "CONCAT(sc.row_label, sc.seat_number) AS seat_label "
                + "FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id "
                + "JOIN Showtime s ON s.showtime_id = t.showtime_id JOIN Movie m ON m.movie_id = s.movie_id "
                + "JOIN Room r ON r.room_id = s.room_id JOIN Seat sc ON sc.seat_id = t.seat_id "
                + "WHERE t.booking_id = ? AND t.status IN ('Booked','Used') ORDER BY sc.row_label, sc.seat_number", bookingId);
    }

    public Map<String, Object> showtimeInfo(int showtimeId) throws SQLException {
        List<Map<String, Object>> rows = Rows.query("SELECT m.title, r.room_name, s.start_time "
                + "FROM Showtime s JOIN Movie m ON m.movie_id = s.movie_id JOIN Room r ON r.room_id = s.room_id "
                + "WHERE s.showtime_id = ?", showtimeId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    /** Hộp thư của khách: đặt vé thành công, hủy vé, phim bị hủy, nhắc lịch chiếu (không phụ thuộc email đã gửi được hay chưa). */
    public List<Map<String, Object>> customerInbox(int customerId, int limit) throws SQLException {
        return Rows.query("SELECT TOP (?) e.notif_id, e.notif_type, e.subject, e.body, e.created_at, m.title, r.room_name, "
                + "s.start_time, b.booking_code FROM EmailNotification e "
                + "LEFT JOIN Booking b ON b.booking_id = e.booking_id "
                + "LEFT JOIN Showtime s ON s.showtime_id = COALESCE(e.showtime_id, b.showtime_id) "
                + "LEFT JOIN Movie m ON m.movie_id = COALESCE(e.movie_id, s.movie_id) "
                + "LEFT JOIN Room r ON r.room_id = s.room_id "
                + "WHERE e.customer_id = ? AND e.notif_type IN ('ETicket','TicketCancelled','MovieCancelled','ShowtimeReminder') "
                + "ORDER BY e.notif_id DESC", limit, customerId);
    }

    /** Job định kỳ: nhắc lịch chiếu cho các suất bắt đầu trong {@code hoursBefore} giờ tới. */
    public void queueReminders(int hoursBefore) throws SQLException {
        runProc("{call dbo.sp_QueueShowtimeReminders(?)}", hoursBefore);
    }

    /** Job định kỳ: nhả ghế giữ quá hạn. */
    public void releaseExpiredHolds() throws SQLException {
        runProc("{call dbo.sp_ReleaseExpiredHolds}", null);
    }

    /** Job định kỳ: vé đã qua giờ chiếu chuyển sang Expired. */
    public void expirePastTickets() throws SQLException {
        runProc("{call dbo.sp_ExpirePastTickets}", null);
    }

    private void runProc(String call, Integer arg) throws SQLException {
        try (Connection c = DBContext.getConnection(); CallableStatement cs = c.prepareCall(call)) {
            if (arg != null) cs.setInt(1, arg);
            cs.execute();
        }
    }

    private void update(String sql, int id) throws SQLException {
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}
