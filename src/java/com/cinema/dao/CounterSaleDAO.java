package com.cinema.dao;

import com.cinema.model.BookingSummary;
import com.cinema.model.Combo;
import com.cinema.model.SeatCell;
import com.cinema.model.ShowtimeInfo;
import com.cinema.util.DBContext;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

/**
 * STT 21 — Bán vé tại quầy (Staff).
 *
 * Nghiệp vụ bán vé nằm trong stored procedure của database nhóm:
 *  - sp_CreateBooking (@channel = 'Counter'): mở phiên đặt vé
 *  - sp_HoldSeats: giữ ghế (kiểm tra ghế đôi phải chọn cả cặp, chống đặt trùng)
 *  - sp_AddCombo: thêm/bỏ combo (kiểm tra tồn kho)
 *  - sp_ConfirmPayment (@method = 'Cash'): xác nhận thanh toán tiền mặt
 *  - vw_SeatMap: sơ đồ ghế kèm màu trạng thái
 *
 * Lỗi nghiệp vụ được procedure THROW với message tiếng Việt → servlet
 * hiện trực tiếp cho nhân viên.
 */
public class CounterSaleDAO {

    /* ---------- thông tin phụ trợ ---------- */

    /** Thông tin khách hàng đã đăng ký (để gắn vào booking tại quầy). */
    public static class CustomerInfo {
        private int accountId;
        private String fullName;
        private String email;
        private String phone;
        private int pointBalance;

        public int getAccountId() { return accountId; }
        public String getFullName() { return fullName; }
        public String getEmail() { return email; }
        public String getPhone() { return phone; }
        public int getPointBalance() { return pointBalance; }
    }

    /** Cấu hình quy đổi MyPoint đang có hiệu lực (để nhân viên tư vấn). */
    public static class PointConfig {
        private int pointValueVnd;
        private BigDecimal maxRedeemPercent;

        public int getPointValueVnd() { return pointValueVnd; }
        public BigDecimal getMaxRedeemPercent() { return maxRedeemPercent; }
    }

    /**
     * Tra account_id trong bảng Account theo email của user đăng nhập
     * (dùng cho Booking.staff_id). Trả về 0 nếu email chưa có trong Account.
     */
    public int findAccountIdByEmail(String email) throws SQLException {
        String sql = "SELECT account_id FROM Account WHERE email = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /* ---------- bước 1: chọn suất chiếu ---------- */

    public List<ShowtimeInfo> findUpcomingShowtimes() throws SQLException {
        List<ShowtimeInfo> list = new ArrayList<>();
        String sql =
                "SELECT s.showtime_id, m.title, r.room_name, ts.slot_name, s.start_time, " +
                        "       SUM(CASE WHEN sm.color = 'GREEN' THEN 1 ELSE 0 END) AS available_seats " +
                        "FROM Showtime s " +
                        "JOIN Movie m ON m.movie_id = s.movie_id " +
                        "JOIN Room r ON r.room_id = s.room_id " +
                        "JOIN TimeSlot ts ON ts.slot_id = s.slot_id " +
                        "LEFT JOIN vw_SeatMap sm ON sm.showtime_id = s.showtime_id " +
                        "WHERE s.status = 'Scheduled' AND s.start_time > SYSDATETIME() " +
                        "GROUP BY s.showtime_id, m.title, r.room_name, ts.slot_name, s.start_time " +
                        "ORDER BY s.start_time";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ShowtimeInfo s = new ShowtimeInfo();
                s.setShowtimeId(rs.getInt("showtime_id"));
                s.setTitle(rs.getString("title"));
                s.setRoomName(rs.getString("room_name"));
                s.setSlotName(rs.getString("slot_name"));
                Timestamp t = rs.getTimestamp("start_time");
                s.setStartTime(t == null ? null : t.toLocalDateTime());
                s.setAvailableSeats(rs.getInt("available_seats"));
                list.add(s);
            }
        }
        return list;
    }

    public ShowtimeInfo findShowtimeById(int showtimeId) throws SQLException {
        String sql =
                "SELECT s.showtime_id, m.title, r.room_name, ts.slot_name, s.start_time " +
                        "FROM Showtime s " +
                        "JOIN Movie m ON m.movie_id = s.movie_id " +
                        "JOIN Room r ON r.room_id = s.room_id " +
                        "JOIN TimeSlot ts ON ts.slot_id = s.slot_id " +
                        "WHERE s.showtime_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                ShowtimeInfo s = new ShowtimeInfo();
                s.setShowtimeId(rs.getInt("showtime_id"));
                s.setTitle(rs.getString("title"));
                s.setRoomName(rs.getString("room_name"));
                s.setSlotName(rs.getString("slot_name"));
                Timestamp t = rs.getTimestamp("start_time");
                s.setStartTime(t == null ? null : t.toLocalDateTime());
                return s;
            }
        }
    }

    /* ---------- bước 2: sơ đồ ghế ---------- */

    public List<SeatCell> getSeatMap(int showtimeId) throws SQLException {
        List<SeatCell> list = new ArrayList<>();
        String sql = "SELECT seat_id, row_label, seat_number, seat_type, pair_seat_id, color " +
                "FROM vw_SeatMap WHERE showtime_id = ? " +
                "ORDER BY row_label, seat_number";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SeatCell s = new SeatCell();
                    s.setSeatId(rs.getInt("seat_id"));
                    s.setRowLabel(rs.getString("row_label"));
                    s.setSeatNumber(rs.getInt("seat_number"));
                    s.setSeatType(rs.getString("seat_type"));
                    int pair = rs.getInt("pair_seat_id");
                    s.setPairSeatId(rs.wasNull() ? null : pair);
                    s.setColor(rs.getString("color"));
                    list.add(s);
                }
            }
        }
        return list;
    }

    /* ---------- bước 2-3: booking, giữ ghế, combo ---------- */

    /**
     * Mở phiên bán tại quầy: sp_CreateBooking với @channel = 'Counter'.
     * @return booking_id vừa tạo
     */
    public int createCounterBooking(Integer customerId, Integer staffAccountId, int showtimeId)
            throws SQLException {
        String sql = "{call sp_CreateBooking(?, ?, ?, ?, ?)}";
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            if (customerId == null) cs.setNull(1, Types.INTEGER);
            else cs.setInt(1, customerId);
            if (staffAccountId == null) cs.setNull(2, Types.INTEGER);
            else cs.setInt(2, staffAccountId);
            cs.setInt(3, showtimeId);
            cs.setString(4, "Counter");
            cs.registerOutParameter(5, Types.INTEGER);
            cs.execute();
            return cs.getInt(5);
        }
    }

    /** Giữ ghế: seatIds dạng "41,42,43". */
    public void holdSeats(int bookingId, String seatIds) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call sp_HoldSeats(?, ?)}")) {
            cs.setInt(1, bookingId);
            cs.setString(2, seatIds);
            cs.execute();
        }
    }

    /** Thêm combo vào booking (quantity = 0 để bỏ combo). */
    public void addCombo(int bookingId, int comboId, int quantity) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call sp_AddCombo(?, ?, ?)}")) {
            cs.setInt(1, bookingId);
            cs.setInt(2, comboId);
            cs.setInt(3, quantity);
            cs.execute();
        }
    }

    public List<Combo> findActiveCombos() throws SQLException {
        List<Combo> list = new ArrayList<>();
        String sql = "SELECT combo_id, combo_name, description, price, stock, status " +
                "FROM Combo WHERE status = 'Active' ORDER BY combo_id";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Combo cb = new Combo();
                cb.setComboId(rs.getInt("combo_id"));
                cb.setComboName(rs.getString("combo_name"));
                cb.setDescription(rs.getString("description"));
                cb.setPrice(rs.getBigDecimal("price"));
                cb.setStock(rs.getInt("stock"));
                cb.setStatus(rs.getString("status"));
                list.add(cb);
            }
        }
        return list;
    }

    /* ---------- bước 3: khách hàng + thanh toán ---------- */

    /** Tìm khách hàng đã đăng ký theo email hoặc số điện thoại. */
    public CustomerInfo findCustomer(String emailOrPhone) throws SQLException {
        String sql =
                "SELECT a.account_id, a.full_name, a.email, a.phone, c.my_point_balance " +
                        "FROM Account a JOIN Customer c ON c.customer_id = a.account_id " +
                        "WHERE a.status = 'Active' AND (a.email = ? OR a.phone = ?)";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, emailOrPhone);
            ps.setString(2, emailOrPhone);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                CustomerInfo ci = new CustomerInfo();
                ci.accountId = rs.getInt("account_id");
                ci.fullName = rs.getString("full_name");
                ci.email = rs.getString("email");
                ci.phone = rs.getString("phone");
                ci.pointBalance = rs.getInt("my_point_balance");
                return ci;
            }
        }
    }

    /** Gắn khách hàng đã đăng ký vào booking (để dùng voucher / MyPoint). */
    public void attachCustomer(int bookingId, int customerId) throws SQLException {
        String sql = "UPDATE Booking SET customer_id = ? WHERE booking_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            ps.setInt(2, bookingId);
            ps.executeUpdate();
        }
    }

    public PointConfig getPointConfig() throws SQLException {
        String sql = "SELECT TOP 1 point_value_vnd, max_redeem_percent FROM MyPointConfig " +
                "WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) return null;
            PointConfig pc = new PointConfig();
            pc.pointValueVnd = rs.getInt("point_value_vnd");
            pc.maxRedeemPercent = rs.getBigDecimal("max_redeem_percent");
            return pc;
        }
    }

    public BookingSummary getBookingSummary(int bookingId) throws SQLException {
        BookingSummary s = null;
        String sql =
                "SELECT b.booking_id, b.booking_code, b.status, b.ticket_total, b.combo_total, " +
                        "       b.voucher_discount, b.points_discount, b.points_used, b.total_amount, " +
                        "       a.full_name AS customer_name " +
                        "FROM Booking b LEFT JOIN Account a ON a.account_id = b.customer_id " +
                        "WHERE b.booking_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                s = new BookingSummary();
                s.setBookingId(rs.getInt("booking_id"));
                s.setBookingCode(rs.getString("booking_code"));
                s.setStatus(rs.getString("status"));
                s.setTicketTotal(rs.getBigDecimal("ticket_total"));
                s.setComboTotal(rs.getBigDecimal("combo_total"));
                s.setVoucherDiscount(rs.getBigDecimal("voucher_discount"));
                s.setPointsDiscount(rs.getBigDecimal("points_discount"));
                s.setPointsUsed(rs.getInt("points_used"));
                s.setTotalAmount(rs.getBigDecimal("total_amount"));
                s.setCustomerName(rs.getString("customer_name"));
            }

            try (PreparedStatement ps2 = c.prepareStatement(
                    "SELECT ticket_code FROM Ticket WHERE booking_id = ? ORDER BY ticket_id")) {
                ps2.setInt(1, bookingId);
                try (ResultSet rs2 = ps2.executeQuery()) {
                    while (rs2.next()) s.getTicketCodes().add(rs2.getString("ticket_code"));
                }
            }

            try (PreparedStatement ps3 = c.prepareStatement(
                    "SELECT bc.combo_id, c.combo_name, bc.quantity, bc.unit_price " +
                            "FROM BookingCombo bc JOIN Combo c ON c.combo_id = bc.combo_id " +
                            "WHERE bc.booking_id = ?")) {
                ps3.setInt(1, bookingId);
                try (ResultSet rs3 = ps3.executeQuery()) {
                    while (rs3.next()) {
                        BookingSummary.ComboLine cl = new BookingSummary.ComboLine();
                        cl.setComboId(rs3.getInt("combo_id"));
                        cl.setComboName(rs3.getString("combo_name"));
                        cl.setQuantity(rs3.getInt("quantity"));
                        cl.setUnitPrice(rs3.getBigDecimal("unit_price"));
                        s.getComboLines().add(cl);
                    }
                }
            }
        }
        return s;
    }

    /**
     * Xác nhận thanh toán tiền mặt: sp_ConfirmPayment với @is_success = 1,
     * @method = 'Cash'. Procedure tự: chuyển vé Held → Booked, trừ kho combo,
     * cộng/trừ MyPoint, ghi email e-ticket (nếu có khách hàng).
     */
    public void confirmCashPayment(int bookingId) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call sp_ConfirmPayment(?, ?, ?, ?)}")) {
            cs.setInt(1, bookingId);
            cs.setNull(2, Types.VARCHAR); // không có mã giao dịch gateway ở quầy
            cs.setBoolean(3, true);
            cs.setString(4, "Cash");
            cs.execute();
        }
    }

    /** Hủy đơn đang dở (nhả ghế đã giữ) khi nhân viên bấm "Hủy đơn". */
    public void cancelPendingBooking(int bookingId) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE Ticket SET status = 'Cancelled' " +
                            "WHERE booking_id = ? AND status = 'Held'")) {
                ps.setInt(1, bookingId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE Booking SET status = 'Cancelled' " +
                            "WHERE booking_id = ? AND status IN ('Selecting','PendingPayment')")) {
                ps.setInt(1, bookingId);
                ps.executeUpdate();
            }
        }
    }
}
