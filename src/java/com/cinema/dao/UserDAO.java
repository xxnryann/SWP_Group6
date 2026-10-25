package com.cinema.dao;

import com.cinema.model.User;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    private static final String COLS = "UserId, FullName, Email, Phone, PasswordHash, DateOfBirth, Gender, "
            + "Role, Status, OtpHash, OtpExpiry, OtpAttempts, "
            + "(SELECT COALESCE(SUM(points), 0) FROM MyPointTransaction WHERE customer_id = Users.UserId) AS MyPoint";

    private User map(ResultSet rs) throws SQLException {
        User u = new User();
        u.setUserId(rs.getInt("UserId"));
        u.setFullName(rs.getString("FullName"));
        u.setEmail(rs.getString("Email"));
        u.setPhone(rs.getString("Phone"));
        u.setPasswordHash(rs.getString("PasswordHash"));
        Date d = rs.getDate("DateOfBirth");
        u.setDateOfBirth(d == null ? null : d.toLocalDate());
        u.setGender(rs.getString("Gender"));
        u.setRole(rs.getString("Role"));
        u.setStatus(rs.getString("Status"));
        u.setOtpHash(rs.getString("OtpHash"));
        Timestamp t = rs.getTimestamp("OtpExpiry");
        u.setOtpExpiry(t == null ? null : t.toLocalDateTime());
        u.setOtpAttempts(rs.getInt("OtpAttempts"));
        u.setMyPoint(rs.getInt("MyPoint"));
        return u;
    }

    private User findOne(String where, Object... args) throws SQLException {
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement("SELECT " + COLS + " FROM Users WHERE " + where)) {
            for (int i = 0; i < args.length; i++) {
                ps.setObject(i + 1, args[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public User findById(int id) throws SQLException {
        return findOne("UserId = ?", id);
    }

    public User findByEmail(String email) throws SQLException {
        return findOne("Email = ?", email);
    }

    /** Login identifier: email or phone. */
    public User findByIdentifier(String identifier) throws SQLException {
        return findOne("Email = ? OR Phone = ?", identifier, identifier);
    }

    public boolean emailExists(String email, int excludeId) throws SQLException {
        return exists("Email = ? AND UserId <> ?", email, excludeId);
    }

    public boolean phoneExists(String phone, int excludeId) throws SQLException {
        return exists("Phone = ? AND UserId <> ?", phone, excludeId);
    }

    private boolean exists(String where, Object... args) throws SQLException {
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement("SELECT 1 FROM Users WHERE " + where)) {
            for (int i = 0; i < args.length; i++) {
                ps.setObject(i + 1, args[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Inserts a new CUSTOMER with Status = PENDING and an OTP. Returns the new id. */
    public int insertPending(User u, String otpHash, LocalDateTime expiry) throws SQLException {
        String sql = "INSERT INTO Users (FullName, Email, Phone, PasswordHash, DateOfBirth, Gender, Role, Status, "
                + "OtpHash, OtpExpiry, OtpAttempts) VALUES (?,?,?,?,?,?, 'CUSTOMER', 'PENDING', ?, ?, 0)";
        try (Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, u.getFullName());
            ps.setString(2, u.getEmail());
            ps.setString(3, u.getPhone());
            ps.setString(4, u.getPasswordHash());
            ps.setDate(5, u.getDateOfBirth() == null ? null : Date.valueOf(u.getDateOfBirth()));
            ps.setString(6, u.getGender());
            ps.setString(7, otpHash);
            ps.setTimestamp(8, Timestamp.valueOf(expiry));
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public void saveOtp(int userId, String otpHash, LocalDateTime expiry) throws SQLException {
        update("UPDATE Users SET OtpHash = ?, OtpExpiry = ?, OtpAttempts = 0 WHERE UserId = ?",
                otpHash, Timestamp.valueOf(expiry), userId);
    }

    public void incrementOtpAttempts(int userId) throws SQLException {
        update("UPDATE Users SET OtpAttempts = OtpAttempts + 1 WHERE UserId = ?", userId);
    }

    public void activate(int userId) throws SQLException {
        update("UPDATE Users SET Status = 'ACTIVE', OtpHash = NULL, OtpExpiry = NULL, OtpAttempts = 0 "
                + "WHERE UserId = ?", userId);
    }

    public void updateProfile(int userId, String fullName, String phone, LocalDate dob, String gender)
            throws SQLException {
        update("UPDATE Users SET FullName = ?, Phone = ?, DateOfBirth = ?, Gender = ? WHERE UserId = ?",
                fullName, phone, dob == null ? null : Date.valueOf(dob), gender, userId);
    }

    public void updatePassword(int userId, String hash) throws SQLException {
        update("UPDATE Users SET PasswordHash = ? WHERE UserId = ?", hash, userId);
    }

    /** Admin listing; keyword matches name/email/phone, blank role/status = no filter. */
    public List<User> search(String keyword, String role, String status) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT " + COLS + " FROM Users WHERE 1=1");
        List<Object> args = new ArrayList<>();
        if (keyword != null && !keyword.isEmpty()) {
            sql.append(" AND (FullName LIKE ? OR Email LIKE ? OR Phone LIKE ?)");
            String like = "%" + keyword.replace("[", "[[]").replace("%", "[%]").replace("_", "[_]") + "%";
            args.add(like);
            args.add(like);
            args.add(like);
        }
        if (role != null && !role.isEmpty()) {
            sql.append(" AND Role = ?");
            args.add(role);
        }
        if (status != null && !status.isEmpty()) {
            sql.append(" AND Status = ?");
            args.add(status);
        }
        sql.append(" ORDER BY CreatedAt DESC");
        List<User> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    public void updateRole(int userId, String role) throws SQLException {
        update("UPDATE Users SET Role = ? WHERE UserId = ?", role, userId);
    }

    /** Block / unblock only; PENDING (unverified) accounts are left untouched. */
    public void updateStatus(int userId, String status) throws SQLException {
        update("UPDATE Users SET Status = ? WHERE UserId = ? AND Status <> 'PENDING'", status, userId);
    }

    private void update(String sql, Object... args) throws SQLException {
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < args.length; i++) {
                ps.setObject(i + 1, args[i]);
            }
            ps.executeUpdate();
        }
    }
}
