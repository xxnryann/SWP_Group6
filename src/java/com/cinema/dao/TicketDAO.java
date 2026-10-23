package com.cinema.dao;

import com.cinema.model.PointTransaction;
import com.cinema.model.Ticket;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** Read-only queries for a customer's ticket history and MyPoint ledger. */
public class TicketDAO {

    public List<Ticket> findByUser(int userId) throws SQLException {
        String sql = "SELECT b.booking_id, m.title, ci.cinema_name, r.room_name, st.start_time, b.total_amount, b.created_at, "
                + "CASE WHEN b.status = 'Paid' AND NOT EXISTS (SELECT 1 FROM Ticket x WHERE x.booking_id = b.booking_id "
                + "AND x.status <> 'Used') THEN 'USED' WHEN b.status = 'Paid' THEN 'PAID' ELSE 'CANCELLED' END AS status, "
                + "(SELECT STRING_AGG(CONCAT(sc.row_label, sc.seat_number), ', ') FROM Ticket t "
                + "JOIN Seat sc ON sc.seat_id = t.seat_id WHERE t.booking_id = b.booking_id) AS seats "
                + "FROM Booking b JOIN Showtime st ON st.showtime_id = b.showtime_id "
                + "JOIN Movie m ON m.movie_id = st.movie_id JOIN Room r ON r.room_id = st.room_id "
                + "JOIN Cinema ci ON ci.cinema_id = r.cinema_id "
                + "WHERE b.customer_id = ? AND b.status IN ('Paid', 'Cancelled') ORDER BY b.created_at DESC";
        List<Ticket> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Ticket t = new Ticket();
                    t.setTicketId(rs.getInt("booking_id"));
                    t.setMovieTitle(rs.getString("title"));
                    t.setCinemaName(rs.getString("cinema_name"));
                    t.setRoomName(rs.getString("room_name"));
                    t.setSeats(rs.getString("seats"));
                    t.setShowTime(rs.getTimestamp("start_time").toLocalDateTime());
                    t.setTotalPrice(rs.getBigDecimal("total_amount"));
                    t.setStatus(rs.getString("status"));
                    t.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                    list.add(t);
                }
            }
        }
        return list;
    }

    public List<PointTransaction> findPointHistory(int userId) throws SQLException {
        String sql = "SELECT p.txn_id, p.points, p.created_at, "
                + "CASE p.txn_type WHEN 'Earn' THEN N'Tích điểm đơn ' WHEN 'Redeem' THEN N'Dùng điểm cho đơn ' "
                + "ELSE N'Điều chỉnh điểm' END + COALESCE(b.booking_code, '') AS reason "
                + "FROM MyPointTransaction p LEFT JOIN Booking b ON b.booking_id = p.booking_id "
                + "WHERE p.customer_id = ? ORDER BY p.created_at DESC, p.txn_id DESC";
        List<PointTransaction> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
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
