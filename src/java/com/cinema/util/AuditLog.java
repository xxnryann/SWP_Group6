package com.cinema.util;

import com.cinema.dao.AccountDAO;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Ghi nhật ký thao tác vào bảng SystemLog. Lỗi ghi log không được làm hỏng thao tác của người dùng. */
public final class AuditLog {

    private static final Logger LOG = Logger.getLogger(AuditLog.class.getName());
    private static final int MAX_ACTION = 100;
    private static final int MAX_DETAIL = 500;

    private AuditLog() {
    }

    /** @param email email người thực hiện; null nếu chưa xác định (vd đăng nhập sai). */
    public static void write(String email, String action, String detail) {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "INSERT INTO SystemLog(account_id, action, detail) VALUES (?, ?, ?)")) {
            int accountId = email == null ? 0 : new AccountDAO().findAccountIdByEmail(email);
            if (accountId > 0) ps.setInt(1, accountId);
            else ps.setNull(1, Types.INTEGER);
            ps.setString(2, cut(action, MAX_ACTION));
            ps.setString(3, cut(detail, MAX_DETAIL));
            ps.executeUpdate();
        } catch (SQLException | RuntimeException e) {
            LOG.log(Level.WARNING, "Cannot write audit log: " + action, e);
        }
    }

    private static String cut(String value, int max) {
        return value != null && value.length() > max ? value.substring(0, max) : value;
    }
}
