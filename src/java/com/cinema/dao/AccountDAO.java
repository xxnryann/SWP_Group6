package com.cinema.dao;

import com.cinema.util.DBContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/** DAO cầu nối giữa Users (đăng nhập) và Account/Customer */
public class AccountDAO {

    /** Tra account_id trong bảng Account theo email. */
    public int findAccountIdByEmail(String email) throws SQLException {
        if (email == null || email.trim().isEmpty()) {
            return 0;
        }
        String sql = "SELECT account_id FROM Account WHERE email = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    /** Khách có nhận email phim mới / ưu đãi không; không phải khách hàng thì trả về null. */
    public Boolean receivesPromoEmail(String email) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT cu.receive_promo_email FROM Customer cu "
                     + "JOIN Account a ON a.account_id = cu.customer_id WHERE a.email = ?")) {
            ps.setString(1, email == null ? "" : email.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getBoolean(1) : null;
            }
        }
    }

    /** Bảo đảm khách đăng nhập có Account (role Customer) và Customer */
    public int ensureCustomerAccount(String email, String fullName, String phone, String passwordHash) {
        if (email == null || email.trim().isEmpty()) {
            return 0;
        }
        try {
            int existing = findAccountIdByEmail(email);
            if (existing > 0) {
                return existing;
            }
            String sql = "{call sp_RegisterAccount(?, ?, ?, ?)}";
            try (Connection c = DBContext.getConnection();
                 CallableStatement cs = c.prepareCall(sql)) {
                cs.setString(1, fullName == null || fullName.trim().isEmpty()
                        ? email.trim() : fullName.trim());
                cs.setString(2, email.trim());
                cs.setString(3, phone == null ? "" : phone.trim());
                cs.setString(4, passwordHash == null ? "" : passwordHash);
                cs.execute();
            }
            return findAccountIdByEmail(email);
        } catch (SQLException e) {
            // Race: hai request cùng lúc tạo → email đã tồn tại, đọc lại id.
            try {
                int existing = findAccountIdByEmail(email);
                if (existing > 0) {
                    return existing;
                }
            } catch (SQLException ignored) {
                // rơi xuống trả 0
            }
            return 0;
        }
    }

    /** Số dư MyPoint và tổng chi tiêu của một khách. */
    public long[] findCustomerBalance(int accountId) throws SQLException {
        String sql = "SELECT my_point_balance, total_spent FROM Customer WHERE customer_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                return new long[]{rs.getInt("my_point_balance"),
                        rs.getBigDecimal("total_spent") == null ? 0L
                                : rs.getBigDecimal("total_spent").longValue()};
            }
        }
    }
}
