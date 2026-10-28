package com.cinema.dao;

import com.cinema.model.Voucher;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class VoucherDAO {
    private Voucher map(ResultSet rs) throws SQLException {
        Voucher v = new Voucher();
        v.setVoucherId(rs.getInt("voucher_id"));
        v.setCode(rs.getString("code"));
        v.setDescription(rs.getString("description"));
        v.setDiscountType(rs.getString("discount_type"));
        v.setDiscountValue(rs.getBigDecimal("discount_value"));
        v.setMaxDiscount(rs.getBigDecimal("max_discount"));
        v.setMinOrderAmount(rs.getBigDecimal("min_order_amount"));
        v.setMinCumulativeSpending(rs.getBigDecimal("min_cumulative_spending"));
        v.setUsageLimit(rs.getInt("usage_limit"));
        v.setUsedCount(rs.getInt("used_count"));
        v.setPerCustomerLimit(rs.getInt("per_customer_limit"));
        Date from = rs.getDate("valid_from");
        Date to = rs.getDate("valid_to");
        v.setValidFrom(from == null ? null : from.toLocalDate());
        v.setValidTo(to == null ? null : to.toLocalDate());
        v.setStatus(rs.getString("status"));
        return v;
    }

    public List<Voucher> findAll(String keyword) throws SQLException {
        String filter = keyword == null || keyword.trim().isEmpty() ? "" : " WHERE code LIKE ? OR description LIKE ?";
        List<Voucher> result = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT * FROM Voucher" + filter + " ORDER BY voucher_id DESC")) {
            if (!filter.isEmpty()) {
                ps.setString(1, "%" + keyword.trim() + "%");
                ps.setString(2, "%" + keyword.trim() + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(map(rs));
            }
        }
        return result;
    }

    public Voucher findById(int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT * FROM Voucher WHERE voucher_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public boolean codeExists(String code, int excludeId) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT 1 FROM Voucher WHERE code = ? AND voucher_id <> ?")) {
            ps.setString(1, code);
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) { return rs.next(); }
        }
    }

    public void insert(Voucher v, int accountId) throws SQLException {
        String sql = "INSERT INTO Voucher (code, description, discount_type, discount_value, max_discount, "
                + "min_order_amount, min_cumulative_spending, usage_limit, used_count, per_customer_limit, "
                + "valid_from, valid_to, status, created_by) VALUES (?,?,?,?,?,?,?,?,0,?,?,?,?,?)";
        executeWrite(sql, v, accountId, false);
    }

    public void update(Voucher v) throws SQLException {
        String sql = "UPDATE Voucher SET code=?, description=?, discount_type=?, discount_value=?, max_discount=?, "
                + "min_order_amount=?, min_cumulative_spending=?, usage_limit=?, per_customer_limit=?, "
                + "valid_from=?, valid_to=?, status=? WHERE voucher_id=?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, v);
            ps.setInt(9, v.getPerCustomerLimit());
            ps.setDate(10, Date.valueOf(v.getValidFrom()));
            ps.setDate(11, Date.valueOf(v.getValidTo()));
            ps.setString(12, v.getStatus());
            ps.setInt(13, v.getVoucherId());
            ps.executeUpdate();
        }
    }

    public void disable(int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("UPDATE Voucher SET status='Disabled' WHERE voucher_id=?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    private void executeWrite(String sql, Voucher v, int accountId, boolean unused) throws SQLException {
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, v);
            ps.setInt(9, v.getPerCustomerLimit());
            ps.setDate(10, Date.valueOf(v.getValidFrom()));
            ps.setDate(11, Date.valueOf(v.getValidTo()));
            ps.setString(12, v.getStatus());
            ps.setInt(13, accountId);
            ps.executeUpdate();
        }
    }

    private void bind(PreparedStatement ps, Voucher v) throws SQLException {
        ps.setString(1, v.getCode());
        ps.setString(2, v.getDescription());
        ps.setString(3, v.getDiscountType());
        ps.setBigDecimal(4, v.getDiscountValue());
        if (v.getMaxDiscount() == null) ps.setNull(5, java.sql.Types.DECIMAL); else ps.setBigDecimal(5, v.getMaxDiscount());
        ps.setBigDecimal(6, v.getMinOrderAmount());
        ps.setBigDecimal(7, v.getMinCumulativeSpending());
        ps.setInt(8, v.getUsageLimit());
    }

    public int findAccountIdByEmail(String email) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT account_id FROM Account WHERE email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getInt(1) : 0; }
        }
    }
}
