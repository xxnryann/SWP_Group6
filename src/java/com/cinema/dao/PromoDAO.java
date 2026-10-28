package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** Quản lý giá vé, ngày lễ, voucher và cấu hình MyPoint (Manager). */
public class PromoDAO {

    /* ---------------- Voucher ---------------- */

    public List<Map<String, Object>> vouchers() throws SQLException {
        return Rows.query("SELECT voucher_id, code, description, discount_type, discount_value, max_discount, "
                + "min_order_amount, min_cumulative_spending, usage_limit, used_count, per_customer_limit, "
                + "valid_from, valid_to, status FROM Voucher ORDER BY voucher_id DESC");
    }

    public Map<String, Object> voucher(int id) throws SQLException {
        List<Map<String, Object>> rows = Rows.query("SELECT * FROM Voucher WHERE voucher_id = ?", id);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public boolean voucherCodeExists(String code, int exceptId) throws SQLException {
        return !Rows.query("SELECT 1 AS x FROM Voucher WHERE code = ? AND voucher_id <> ?", code, exceptId).isEmpty();
    }

    /** Thêm (id = 0) hoặc cập nhật voucher. */
    public void saveVoucher(int id, String code, String description, String type, BigDecimal value,
            BigDecimal maxDiscount, BigDecimal minOrder, BigDecimal minSpent, int usageLimit, int perCustomer,
            LocalDate from, LocalDate to, String status, int createdBy) throws SQLException {
        String sql = id == 0
                ? "INSERT INTO Voucher(code, description, discount_type, discount_value, max_discount, min_order_amount, "
                + "min_cumulative_spending, usage_limit, per_customer_limit, valid_from, valid_to, status, created_by) "
                + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)"
                : "UPDATE Voucher SET code=?, description=?, discount_type=?, discount_value=?, max_discount=?, "
                + "min_order_amount=?, min_cumulative_spending=?, usage_limit=?, per_customer_limit=?, valid_from=?, "
                + "valid_to=?, status=? WHERE voucher_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, code);
            ps.setString(2, description);
            ps.setString(3, type);
            ps.setBigDecimal(4, value);
            if (maxDiscount == null) ps.setNull(5, Types.DECIMAL); else ps.setBigDecimal(5, maxDiscount);
            ps.setBigDecimal(6, minOrder);
            ps.setBigDecimal(7, minSpent);
            ps.setInt(8, usageLimit);
            ps.setInt(9, perCustomer);
            ps.setObject(10, from);
            ps.setObject(11, to);
            ps.setString(12, status);
            ps.setInt(13, id == 0 ? createdBy : id);
            ps.executeUpdate();
        }
    }

    public void setVoucherStatus(int id, String status) throws SQLException {
        exec("UPDATE Voucher SET status = ? WHERE voucher_id = ?", status, id);
    }

    /** Xóa voucher chưa từng được dùng; trả false nếu đã có lượt dùng. */
    public boolean deleteVoucher(int id) throws SQLException {
        if (!Rows.query("SELECT 1 AS x FROM VoucherUsage WHERE voucher_id = ? "
                + "UNION SELECT 1 FROM Booking WHERE voucher_id = ?", id, id).isEmpty()) {
            return false;
        }
        exec("DELETE FROM Voucher WHERE voucher_id = ?", id);
        return true;
    }

    /* ---------------- MyPoint ---------------- */

    public List<Map<String, Object>> pointConfigs() throws SQLException {
        return Rows.query("SELECT c.config_id, c.earn_rate_percent, c.point_value_vnd, c.max_redeem_percent, "
                + "c.effective_from, c.is_active, a.full_name AS updated_by_name "
                + "FROM MyPointConfig c LEFT JOIN Account a ON a.account_id = c.updated_by "
                + "ORDER BY c.is_active DESC, c.effective_from DESC, c.config_id DESC");
    }

    /** Tạo cấu hình mới có hiệu lực từ hôm nay và tắt các cấu hình cũ. */
    public void createPointConfig(BigDecimal earnRate, int pointValueVnd, BigDecimal maxRedeem, int updatedBy)
            throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                try (PreparedStatement ps = c.prepareStatement("UPDATE MyPointConfig SET is_active = 0")) {
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = c.prepareStatement("INSERT INTO MyPointConfig(earn_rate_percent, "
                        + "point_value_vnd, max_redeem_percent, effective_from, is_active, updated_by) "
                        + "VALUES (?, ?, ?, CAST(SYSDATETIME() AS DATE), 1, ?)")) {
                    ps.setBigDecimal(1, earnRate);
                    ps.setInt(2, pointValueVnd);
                    ps.setBigDecimal(3, maxRedeem);
                    ps.setInt(4, updatedBy);
                    ps.executeUpdate();
                }
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }
    }

    /* ---------------- Giá vé & ngày lễ ---------------- */

    /** Ma trận giá: mỗi dòng (loại ghế × khung giờ) có 3 giá. */
    public List<Map<String, Object>> priceMatrix() throws SQLException {
        return Rows.query("SELECT st.seat_type_id, st.type_name, ts.slot_id, ts.slot_name, "
                + "MAX(CASE WHEN tp.day_type='Weekday' THEN tp.price END) AS weekday, "
                + "MAX(CASE WHEN tp.day_type='Weekend' THEN tp.price END) AS weekend, "
                + "MAX(CASE WHEN tp.day_type='Holiday' THEN tp.price END) AS holiday "
                + "FROM SeatType st CROSS JOIN TimeSlot ts "
                + "LEFT JOIN TicketPrice tp ON tp.seat_type_id = st.seat_type_id AND tp.slot_id = ts.slot_id "
                + "GROUP BY st.seat_type_id, st.type_name, ts.slot_id, ts.slot_name, ts.start_time "
                + "ORDER BY st.seat_type_id, ts.start_time");
    }

    /** Lưu một giá (thêm mới nếu chưa có). */
    public void savePrice(int seatTypeId, int slotId, String dayType, BigDecimal price) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE TicketPrice SET price = ? WHERE seat_type_id = ? AND slot_id = ? AND day_type = ?")) {
            ps.setBigDecimal(1, price);
            ps.setInt(2, seatTypeId);
            ps.setInt(3, slotId);
            ps.setString(4, dayType);
            if (ps.executeUpdate() == 0) {
                try (PreparedStatement ins = c.prepareStatement(
                        "INSERT INTO TicketPrice(seat_type_id, slot_id, day_type, price) VALUES (?,?,?,?)")) {
                    ins.setInt(1, seatTypeId);
                    ins.setInt(2, slotId);
                    ins.setString(3, dayType);
                    ins.setBigDecimal(4, price);
                    ins.executeUpdate();
                }
            }
        }
    }

    public List<Map<String, Object>> holidays() throws SQLException {
        return Rows.query("SELECT holiday_date, holiday_name FROM Holiday ORDER BY holiday_date");
    }

    public void addHoliday(LocalDate date, String name) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("INSERT INTO Holiday(holiday_date, holiday_name) VALUES (?, ?)")) {
            ps.setObject(1, date);
            ps.setString(2, name);
            ps.executeUpdate();
        }
    }

    public void deleteHoliday(LocalDate date) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM Holiday WHERE holiday_date = ?")) {
            ps.setObject(1, date);
            ps.executeUpdate();
        }
    }

    private void exec(String sql, Object... params) throws SQLException {
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            ps.executeUpdate();
        }
    }
}
