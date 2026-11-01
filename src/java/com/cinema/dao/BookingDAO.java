package com.cinema.dao;

import com.cinema.model.Combo;
import com.cinema.model.OnlineBooking;
import com.cinema.model.PointConfig;
import com.cinema.model.SeatCell;
import com.cinema.model.SeatTypeInfo;
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
 * DAO trung tâm cho luồng đặt vé online (BF-02) và bán tại quầy (BF-03).
 *
 * <p>Sở hữu toàn bộ lời gọi stored procedure của database nhóm:
 * <ul>
 *   <li>{@code sp_CreateBooking} — mở phiên đặt vé (15 phút), channel Online/Counter</li>
 *   <li>{@code sp_HoldSeats} — giữ ghế (GBR-03 ghế đôi, GBR-08 bảo trì, chống bán trùng)</li>
 *   <li>{@code sp_AddCombo} — thêm/bỏ combo (kiểm tra tồn kho)</li>
 *   <li>{@code sp_ConfirmPayment} — phát vé, trừ kho, cộng/trừ MyPoint (GBR-06)</li>
 *   <li>{@code sp_ReleaseExpiredHolds} — nhả ghế khi hết hạn (GBR-01/02), idempotent</li>
 * </ul>
 *
 * <p>Lỗi nghiệp vụ được procedure THROW với message tiếng Việt → tầng service
 * chuyển nguyên văn cho UI.</p>
 *
 * <p>Lưu ý: {@code Account.account_id} có thể khác {@code Users.UserId}. Mọi
 * truy vấn đọc resolve {@code customer_id} qua email, không hardcode.</p>
 */
public class BookingDAO {

    /* ---------- đọc dữ liệu dùng chung ---------- */

    /** Thông tin suất chiếu để hiển thị trên màn hình đặt vé. */
    public ShowtimeInfo findShowtimeById(int showtimeId) throws SQLException {
        String sql =
                "SELECT s.showtime_id, m.title, m.duration_minutes, r.room_name, ts.slot_name, s.start_time " +
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
                s.setDurationMinutes(rs.getInt("duration_minutes"));
                s.setRoomName(rs.getString("room_name"));
                s.setSlotName(rs.getString("slot_name"));
                Timestamp t = rs.getTimestamp("start_time");
                s.setStartTime(t == null ? null : t.toLocalDateTime());
                return s;
            }
        }
    }

    /** Sơ đồ ghế của một suất chiếu (màu GREEN/YELLOW/RED/GREY từ vw_SeatMap). */
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

    /**
     * Danh sách loại ghế kèm giá vé của suất chiếu.
     *
     * <p>Giá lấy từ {@code dbo.fn_GetTicketPrice} — hàm này tự suy ra khung giờ
     * và loại ngày (thường / cuối tuần / lễ) của suất chiếu rồi tra bảng
     * {@code TicketPrice}. Nếu chưa cấu hình giá cho (loại ghế, khung giờ, loại ngày)
     * thì giá là {@code null} và UI hiển thị "—".</p>
     *
     * @param showtimeId suất chiếu
     * @return danh sách loại ghế (không rỗng trừ khi lỗi truy vấn)
     */
    public List<SeatTypeInfo> findSeatTypesWithPrice(int showtimeId) throws SQLException {
        List<SeatTypeInfo> list = new ArrayList<>();
        String sql = "SELECT st.seat_type_id, st.type_name, st.is_couple, st.description, "
                + "dbo.fn_GetTicketPrice(?, st.seat_type_id) AS price "
                + "FROM SeatType st ORDER BY st.seat_type_id";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SeatTypeInfo t = new SeatTypeInfo();
                    t.setSeatTypeId(rs.getInt("seat_type_id"));
                    t.setTypeName(rs.getString("type_name"));
                    t.setCouple(rs.getBoolean("is_couple"));
                    t.setDescription(rs.getString("description"));
                    BigDecimal price = rs.getBigDecimal("price");
                    t.setPrice(price);
                    list.add(t);
                }
            }
        }
        return list;
    }

    /** Combo đang bán (kèm tồn kho) để khách chọn ở bước combo. */
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

    /** Cấu hình quy đổi MyPoint đang có hiệu lực. */
    public PointConfig getPointConfig() throws SQLException {
        String sql = "SELECT TOP 1 point_value_vnd, max_redeem_percent FROM MyPointConfig " +
                "WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) return null;
            PointConfig pc = new PointConfig();
            pc.setPointValueVnd(rs.getInt("point_value_vnd"));
            pc.setMaxRedeemPercent(rs.getBigDecimal("max_redeem_percent"));
            return pc;
        }
    }

    /* ---------- ghi dữ liệu qua stored procedure ---------- */

    /**
     * Mở phiên đặt vé online: sp_CreateBooking với {@code @channel = 'Online'}.
     *
     * @param customerAccountId account_id của khách (null = khách vãng lai)
     * @param showtimeId suất chiếu
     * @return booking_id vừa tạo
     */
    public int createOnlineBooking(Integer customerAccountId, int showtimeId) throws SQLException {
        return createBooking(customerAccountId, null, showtimeId, "Online");
    }

    /**
     * Mở phiên bán tại quầy: sp_CreateBooking với {@code @channel = 'Counter'}.
     *
     * @param customerId account_id khách đã đăng ký (null = khách vãng lai)
     * @param staffAccountId account_id của nhân viên (null = không ghi)
     * @param showtimeId suất chiếu
     * @return booking_id vừa tạo
     */
    public int createCounterBooking(Integer customerId, Integer staffAccountId, int showtimeId)
            throws SQLException {
        return createBooking(customerId, staffAccountId, showtimeId, "Counter");
    }

    private int createBooking(Integer customerId, Integer staffId, int showtimeId, String channel)
            throws SQLException {
        String sql = "{call sp_CreateBooking(?, ?, ?, ?, ?)}";
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall(sql)) {
            if (customerId == null) cs.setNull(1, Types.INTEGER);
            else cs.setInt(1, customerId);
            if (staffId == null) cs.setNull(2, Types.INTEGER);
            else cs.setInt(2, staffId);
            cs.setInt(3, showtimeId);
            cs.setString(4, channel);
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

    /**
     * Xác nhận thanh toán: sp_ConfirmPayment. Procedure tự chuyển vé Held → Booked,
     * trừ kho combo, cộng/trừ MyPoint và ghi email e-ticket (nếu có khách hàng).
     *
     * @param bookingId đơn cần xác nhận
     * @param gatewayTxnId mã giao dịch của cổng thanh toán (null ở quầy)
     * @param success true khi cổng báo thanh toán thành công
     * @param method 'Cash' (quầy) hoặc 'BankTransfer' (online)
     */
    public void confirmPayment(int bookingId, String gatewayTxnId, boolean success, String method)
            throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call sp_ConfirmPayment(?, ?, ?, ?)}")) {
            cs.setInt(1, bookingId);
            if (gatewayTxnId == null || gatewayTxnId.trim().isEmpty()) {
                cs.setNull(2, Types.VARCHAR);
            } else {
                cs.setString(2, gatewayTxnId.trim());
            }
            cs.setBoolean(3, success);
            cs.setString(4, method);
            cs.execute();
        }
    }

    /**
     * Nhả ghế / hủy booking đã hết hạn (GBR-01, GBR-02). Idempotent — có thể
     * gọi ở mọi lần đọc dữ liệu mà không phụ thuộc lưu lượng truy cập.
     */
    public void releaseExpiredHolds() throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call sp_ReleaseExpiredHolds}")) {
            cs.execute();
        }
    }

    /**
     * Hủy đơn đang dở (nhả ghế đã giữ) — dùng cho nút "Huỷ đơn".
     *
     * <p>Chạy trong transaction: nếu không, có thể xảy ra trường hợp vé đã bị
     * huỷ nhưng đơn vẫn còn ở trạng thái chờ thanh toán (hoặc ngược lại) —
     * khi đó ghế bị mất mà đơn vẫn "sống".</p>
     */
    public void cancelPendingBooking(int bookingId) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            boolean autoCommit = c.getAutoCommit();
            c.setAutoCommit(false);
            try {
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
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(autoCommit);
            }
        }
    }

    /* ---------- đọc chi tiết đơn ---------- */

    /**
     * Đọc chi tiết đơn theo mã đơn (booking_code).
     *
     * <p>Gộp "tra booking_id" + "đọc chi tiết" vào <b>cùng một connection</b>
     * để tiết kiệm 1 round-trip: luồng thanh toán (return URL / IPN) luôn
     * cần cả hai bước.</p>
     *
     * @param bookingCode mã đơn
     * @return chi tiết đơn, null nếu không tồn tại
     */
    public OnlineBooking findOnlineBookingByCode(String bookingCode) throws SQLException {
        if (bookingCode == null || bookingCode.trim().isEmpty()) {
            return null;
        }
        try (Connection c = DBContext.getConnection()) {
            int bookingId;
            try (PreparedStatement ps = c.prepareStatement(
                    "SELECT booking_id FROM Booking WHERE booking_code = ?")) {
                ps.setString(1, bookingCode.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        return null;
                    }
                    bookingId = rs.getInt(1);
                }
            }
            return findOnlineBooking(c, bookingId);
        }
    }

    /**
     * Đọc chi tiết một booking (vé, ghế, combo, thời điểm hết hạn, voucher).
     * Trả về null nếu không tồn tại.
     */
    public OnlineBooking findOnlineBooking(int bookingId) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            return findOnlineBooking(c, bookingId);
        }
    }

    /** Đọc chi tiết đơn trên một connection có sẵn (dùng chung cho các truy vấn con). */
    private OnlineBooking findOnlineBooking(Connection c, int bookingId) throws SQLException {
        OnlineBooking b = new OnlineBooking();
        String sql =
                "SELECT b.booking_id, b.booking_code, b.status, b.customer_id, b.showtime_id, " +
                        "       b.ticket_total, b.combo_total, b.voucher_discount, b.points_discount, " +
                        "       b.points_used, b.total_amount, b.voucher_id, b.created_at, " +
                        "       b.session_expires_at, b.payment_expires_at, " +
                        "       m.title AS movie_title, r.room_name, s.start_time, " +
                        "       a.email AS customer_email, a.full_name AS customer_name, " +
                        "       v.code AS voucher_code " +
                        "FROM Booking b " +
                        "JOIN Showtime s ON s.showtime_id = b.showtime_id " +
                        "JOIN Movie m ON m.movie_id = s.movie_id " +
                        "JOIN Room r ON r.room_id = s.room_id " +
                        "LEFT JOIN Account a ON a.account_id = b.customer_id " +
                        "LEFT JOIN Voucher v ON v.voucher_id = b.voucher_id " +
                        "WHERE b.booking_id = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                b.setBookingId(rs.getInt("booking_id"));
                b.setBookingCode(rs.getString("booking_code"));
                b.setStatus(rs.getString("status"));
                b.setCustomerId(rs.getInt("customer_id"));
                b.setShowtimeId(rs.getInt("showtime_id"));
                b.setTicketTotal(rs.getBigDecimal("ticket_total"));
                b.setComboTotal(rs.getBigDecimal("combo_total"));
                b.setVoucherDiscount(rs.getBigDecimal("voucher_discount"));
                b.setPointsDiscount(rs.getBigDecimal("points_discount"));
                b.setPointsUsed(rs.getInt("points_used"));
                b.setTotalAmount(rs.getBigDecimal("total_amount"));
                b.setMovieTitle(rs.getString("movie_title"));
                b.setRoomName(rs.getString("room_name"));
                b.setCustomerEmail(rs.getString("customer_email"));
                b.setCustomerName(rs.getString("customer_name"));
                b.setVoucherCode(rs.getString("voucher_code"));
                Timestamp t = rs.getTimestamp("start_time");
                b.setStartTime(t == null ? null : t.toLocalDateTime());
                t = rs.getTimestamp("created_at");
                b.setCreatedAt(t == null ? null : t.toLocalDateTime());
                t = rs.getTimestamp("session_expires_at");
                b.setSessionExpiresAt(t == null ? null : t.toLocalDateTime());
                t = rs.getTimestamp("payment_expires_at");
                b.setPaymentExpiresAt(t == null ? null : t.toLocalDateTime());
            }

            try (PreparedStatement ps2 = c.prepareStatement(
                    "SELECT t.ticket_code, sc.row_label, sc.seat_number, t.status " +
                            "FROM Ticket t JOIN Seat sc ON sc.seat_id = t.seat_id " +
                            "WHERE t.booking_id = ? AND t.status IN ('Held','Booked','Used') " +
                            "ORDER BY sc.row_label, sc.seat_number")) {
                ps2.setInt(1, bookingId);
                try (ResultSet rs2 = ps2.executeQuery()) {
                    while (rs2.next()) {
                        b.getTicketCodes().add(rs2.getString("ticket_code"));
                        b.getSeatLabels().add(rs2.getString("row_label") + rs2.getInt("seat_number"));
                    }
                }
            }

            try (PreparedStatement ps3 = c.prepareStatement(
                    "SELECT bc.combo_id, c.combo_name, bc.quantity, bc.unit_price " +
                            "FROM BookingCombo bc JOIN Combo c ON c.combo_id = bc.combo_id " +
                            "WHERE bc.booking_id = ?")) {
                ps3.setInt(1, bookingId);
                try (ResultSet rs3 = ps3.executeQuery()) {
                    while (rs3.next()) {
                        OnlineBooking.ComboLine cl = new OnlineBooking.ComboLine();
                        cl.setComboId(rs3.getInt("combo_id"));
                        cl.setComboName(rs3.getString("combo_name"));
                        cl.setQuantity(rs3.getInt("quantity"));
                        cl.setUnitPrice(rs3.getBigDecimal("unit_price"));
                        b.getComboLines().add(cl);
                    }
                }
            }
        }
        return b;
    }
}
