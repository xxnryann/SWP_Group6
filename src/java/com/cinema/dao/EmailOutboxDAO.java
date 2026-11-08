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

    /** Bổ sung thông báo phim mới và voucher khách đang dùng được vào hộp thư (không gửi email). */
    public void syncInboxPromotions(int customerId) throws SQLException {
        runProc("{call dbo.sp_SyncInboxPromotions(?)}", customerId);
    }

    /** Hộp thư của khách: mọi loại thông báo (không phụ thuộc email đã gửi được hay chưa). */
    public List<Map<String, Object>> customerInbox(int customerId, int limit, String type) throws SQLException {
        String sql = "SELECT TOP (?) e.notif_id, e.notif_type, e.subject, "
                + "CASE WHEN e.notif_type = 'NewMovie' THEN N'Phim \"' + m.title + N'\"' "
                + "+ CASE WHEN m.release_date > CAST(SYSDATETIME() AS DATE) THEN N' sắp có mặt tại CineStar Cinemas, khởi chiếu ngày ' "
                + "ELSE N' đang chiếu tại CineStar Cinemas từ ngày ' END + CONVERT(NVARCHAR(10), m.release_date, 103) + N'.' "
                + "ELSE e.body END AS body, e.created_at, m.movie_id, m.title, r.room_name, "
                + "v.code AS voucher_code, CASE WHEN v.status = 'Allowed' "
                + "AND CAST(SYSDATETIME() AS DATE) BETWEEN v.valid_from AND v.valid_to AND v.used_count < v.usage_limit "
                + "AND (SELECT COUNT(*) FROM VoucherUsage u WHERE u.voucher_id = v.voucher_id AND u.customer_id = e.customer_id) < v.per_customer_limit "
                + "AND (SELECT c.total_spent FROM Customer c WHERE c.customer_id = e.customer_id) >= v.min_cumulative_spending "
                + "THEN 1 ELSE 0 END AS voucher_usable, "
                + "s.start_time, CASE WHEN s.start_time <= SYSDATETIME() THEN 1 ELSE 0 END AS has_started, "
                + "b.booking_code, CASE WHEN m.is_deleted = 0 THEN 1 ELSE 0 END AS movie_active, "
                + "CASE WHEN m.is_deleted = 0 AND NOT EXISTS (SELECT 1 FROM Review rv WHERE rv.movie_id = m.movie_id "
                + "AND rv.customer_id = e.customer_id) THEN 1 ELSE 0 END AS can_review FROM EmailNotification e "
                + "LEFT JOIN Booking b ON b.booking_id = e.booking_id "
                + "LEFT JOIN Showtime s ON s.showtime_id = COALESCE(e.showtime_id, b.showtime_id) "
                + "LEFT JOIN Movie m ON m.movie_id = COALESCE(e.movie_id, s.movie_id) "
                + "LEFT JOIN Room r ON r.room_id = s.room_id "
                + "LEFT JOIN Voucher v ON e.notif_type = 'Voucher' AND e.subject = N'Ưu đãi voucher ' + v.code "
                + "WHERE e.customer_id = ? "
                + "AND (e.notif_type <> 'Voucher' OR v.voucher_id IS NOT NULL) "
                + "AND (e.notif_type <> 'NewMovie' OR (m.is_deleted = 0 AND m.status <> 'Stopped')) "
                // Vé đã hủy hết thì nhắc lịch không còn ý nghĩa.
                + "AND (e.notif_type <> 'ShowtimeReminder' OR EXISTS (SELECT 1 FROM Ticket t WHERE t.booking_id = e.booking_id "
                + "AND t.status IN ('Booked','Used','Expired'))) "
                + (type == null ? "" : "AND e.notif_type = ? ")
                + "ORDER BY e.notif_id DESC";
        return type == null ? Rows.query(sql, limit, customerId) : Rows.query(sql, limit, customerId, type);
    }

    /** Job định kỳ: nhắc lịch chiếu cho các suất bắt đầu trong hoursBefore giờ tới. */
    public void queueReminders(int hoursBefore) throws SQLException {
        runProc("{call dbo.sp_QueueShowtimeReminders(?)}", hoursBefore);
    }

    /** Xếp email báo phim mới cho mọi khách đang hoạt động. */
    public void queueNewMovie(int movieId) throws SQLException {
        runProc("{call dbo.sp_QueueNewMovieEmail(?)}", movieId);
    }

    /** Xếp email ưu đãi cho khách đủ điều kiện của voucher (voucher đang bật, còn hạn). */
    public void queueVoucher(String code) throws SQLException {
        try (Connection c = DBContext.getConnection(); CallableStatement cs = c.prepareCall("{call dbo.sp_QueueVoucherEmail(?)}")) {
            cs.setString(1, code);
            cs.execute();
        }
    }

    /** Job định kỳ: nhắc đánh giá cho khách vừa xem xong phim. */
    public void queueReviewReminders() throws SQLException {
        runProc("{call dbo.sp_QueueReviewReminders}", null);
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
