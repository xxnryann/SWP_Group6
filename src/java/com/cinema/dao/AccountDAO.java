package com.cinema.dao;

import com.cinema.util.DBContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * DAO cầu nối giữa {@code Users} (đăng nhập) và {@code Account}/{@code Customer}
 * (hệ thống nghiệp vụ đặt vé).
 *
 * <p>Trong DB nhóm, {@code Account.account_id} là khóa chính của hệ thống
 * nghiệp vụ (Booking.customer_id, MyPointTransaction.customer_id, ...) và
 * <b>không</b> bảo đảm bằng {@code Users.UserId}. Vì vậy mọi truy vấn đọc
 * đều resolve {@code customer_id} qua email thay vì giả định hai id bằng nhau.</p>
 */
public class AccountDAO {

    /**
     * Tra {@code account_id} trong bảng Account theo email.
     *
     * @param email email của người dùng đăng nhập
     * @return account_id, hoặc 0 nếu chưa có trong Account
     */
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

    /**
     * Bảo đảm khách đăng nhập có {@code Account} (role Customer) và {@code Customer}
     * tương ứng trong hệ thống nghiệp vụ. Nếu đã có thì trả về account_id cũ.
     *
     * <p>Dùng stored procedure {@code sp_RegisterAccount} của DB nhóm để insert
     * Account + Customer trong cùng một transaction (có bù trừ khi lỗi).</p>
     *
     * @param email email đăng nhập
     * @param fullName họ tên hiển thị
     * @param phone số điện thoại
     * @param passwordHash mật khẩu đã băm (có thể null → dùng chuỗi rỗng)
     * @return account_id của khách, hoặc 0 nếu không tạo được
     */
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

    /**
     * Số dư MyPoint và tổng chi tiêu của một khách.
     *
     * @param accountId account_id trong Account
     * @return mảng {balance, totalSpent}, hoặc null nếu khách không tồn tại
     */
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
