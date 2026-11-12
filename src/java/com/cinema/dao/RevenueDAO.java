package com.cinema.dao;

import com.cinema.model.RevenueFilter;
import com.cinema.model.RevenueRow;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Doanh thu theo bộ lọc (ngày thanh toán, loại doanh thu, kênh bán) và lịch sử đơn tạo nên doanh thu đó. */
public class RevenueDAO {

    /** Tổng hợp: revenue (theo loại đang lọc), bookings, tickets, ticket_total, combo_total, voucher, points, actual. */
    public Map<String, Long> summary(RevenueFilter f) throws SQLException {
        String sql = "SELECT COUNT(*) AS bookings, "
                + "ISNULL(SUM(" + f.amountExpr() + "), 0) AS revenue, "
                + "ISNULL(SUM(b.ticket_total), 0) AS ticket_total, "
                + "ISNULL(SUM(b.combo_total), 0) AS combo_total, "
                + "ISNULL(SUM(b.voucher_discount), 0) AS voucher_total, "
                + "ISNULL(SUM(b.points_discount), 0) AS points_total, "
                + "ISNULL(SUM(b.total_amount), 0) AS actual_total "
                + "FROM Booking b WHERE " + f.whereSql();
        Map<String, Long> m = new LinkedHashMap<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            f.bind(ps, 1);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    for (String k : new String[] {"revenue", "bookings", "ticket_total", "combo_total",
                            "voucher_total", "points_total", "actual_total"}) {
                        m.put(k, rs.getLong(k));
                    }
                }
            }
        }
        // SQL Server không cho SUM trên subquery -> đếm vé bằng truy vấn riêng.
        String ticketSql ="SELECT COUNT(*) FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id "
                + "WHERE t.status <> 'Held' AND " + f.whereSql();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(ticketSql)) {
            f.bind(ps, 1);
            try (ResultSet rs = ps.executeQuery()) {
                m.put("tickets", rs.next() ? rs.getLong(1) : 0L);
            }
        }
        return m;
    }

    /** Các đơn đã thanh toán khớp bộ lọc, mới nhất trước (tối đa {@code limit} đơn). */
    public List<RevenueRow> findBookings(RevenueFilter f, int limit) throws SQLException {
        String sql = "SELECT TOP (?) b.booking_code, b.paid_at, b.channel, b.ticket_total, b.combo_total, "
                + "b.voucher_discount, b.points_used, b.points_discount, b.total_amount, "
                + f.amountExpr() + " AS amount, "
                + "cu.full_name AS customer_name, cu.email AS customer_email, st.full_name AS staff_name, "
                + "m.title, r.room_name, s.start_time, v.code AS voucher_code, "
                + "(SELECT COUNT(*) FROM Ticket t WHERE t.booking_id = b.booking_id AND t.status <> 'Held') AS ticket_count "
                + "FROM Booking b "
                + "JOIN Showtime s ON s.showtime_id = b.showtime_id "
                + "JOIN Movie m ON m.movie_id = s.movie_id "
                + "JOIN Room r ON r.room_id = s.room_id "
                + "LEFT JOIN Account cu ON cu.account_id = b.customer_id "
                + "LEFT JOIN Account st ON st.account_id = b.staff_id "
                + "LEFT JOIN Voucher v ON v.voucher_id = b.voucher_id "
                + "WHERE " + f.whereSql() + " ORDER BY b.paid_at DESC, b.booking_id DESC";
        List<RevenueRow> rows = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            f.bind(ps, 2);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RevenueRow row = new RevenueRow();
                    row.setBookingCode(rs.getString("booking_code"));
                    Timestamp paid = rs.getTimestamp("paid_at");
                    row.setPaidAt(paid == null ? null : paid.toLocalDateTime());
                    row.setChannel(rs.getString("channel"));
                    row.setTicketTotal(rs.getLong("ticket_total"));
                    row.setComboTotal(rs.getLong("combo_total"));
                    row.setVoucherDiscount(rs.getLong("voucher_discount"));
                    row.setPointsUsed(rs.getInt("points_used"));
                    row.setPointsDiscount(rs.getLong("points_discount"));
                    row.setTotalAmount(rs.getLong("total_amount"));
                    row.setAmount(rs.getLong("amount"));
                    row.setCustomerName(rs.getString("customer_name"));
                    row.setCustomerEmail(rs.getString("customer_email"));
                    row.setStaffName(rs.getString("staff_name"));
                    row.setMovieTitle(rs.getString("title"));
                    row.setRoomName(rs.getString("room_name"));
                    Timestamp start = rs.getTimestamp("start_time");
                    row.setShowStart(start == null ? null : start.toLocalDateTime());
                    row.setVoucherCode(rs.getString("voucher_code"));
                    row.setTicketCount(rs.getInt("ticket_count"));
                    rows.add(row);
                }
            }
        }
        return rows;
    }
}
