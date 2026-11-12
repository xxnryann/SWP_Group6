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

/** Quản lý voucher và cấu hình MyPoint (Manager). Giá vé / ngày lễ: xem PriceAdminDAO. */
public class PromoDAO {

    /* ---------------- Voucher ---------------- */

    public List<Map<String, Object>> vouchers() throws SQLException {
        return Rows.query("SELECT v.voucher_id, v.code, v.description, v.discount_type, v.discount_value, v.max_discount, "
                + "v.min_order_amount, v.min_cumulative_spending, v.usage_limit, v.used_count, v.per_customer_limit, "
                + "v.valid_from, v.valid_to, v.status, v.is_compensation, v.grant_valid_days, "
                + "(SELECT COUNT(*) FROM VoucherGrant g WHERE g.voucher_id = v.voucher_id) AS grants_issued, "
                + "(SELECT COUNT(*) FROM VoucherGrant g WHERE g.voucher_id = v.voucher_id "
                + "AND g.used_booking_id IS NOT NULL) AS grants_used "
                + "FROM Voucher v ORDER BY v.is_compensation DESC, v.voucher_id DESC");
    }

    /** Voucher đền bù: số ngày hiệu lực của mỗi lượt cấp cho khách khi rạp hủy suất chiếu. */
    public void setGrantValidDays(int id, int days) throws SQLException {
        exec("UPDATE Voucher SET grant_valid_days = ? WHERE voucher_id = ? AND is_compensation = 1", days, id);
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
        // Voucher đền bù (DENBU25) không xóa được: dùng "Tắt" để ngừng cấp.
        if (!Rows.query("SELECT 1 AS x FROM VoucherUsage WHERE voucher_id = ? "
                + "UNION SELECT 1 FROM Booking WHERE voucher_id = ? "
                + "UNION SELECT 1 FROM Voucher WHERE voucher_id = ? AND is_compensation = 1", id, id, id).isEmpty()) {
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

    private void exec(String sql, Object... params) throws SQLException {
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            ps.executeUpdate();
        }
    }
}
