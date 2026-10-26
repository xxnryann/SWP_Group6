package com.cinema.dao;

import com.cinema.model.Combo;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO bảng Combo — STT 13.
 * Cột/tên bảng khớp script database của nhóm (combo_id, combo_name,
 * status IN ('Active','Hidden')).
 */
public class ComboDAO {

    private Combo map(ResultSet rs) throws SQLException {
        Combo c = new Combo();
        c.setComboId(rs.getInt("combo_id"));
        c.setComboName(rs.getString("combo_name"));
        c.setDescription(rs.getString("description"));
        c.setPrice(rs.getBigDecimal("price"));
        c.setStock(rs.getInt("stock"));
        c.setStatus(rs.getString("status"));
        return c;
    }

    public List<Combo> findAll(String keyword) throws SQLException {
        List<Combo> list = new ArrayList<>();
        String sql = "SELECT * FROM Combo WHERE 1 = 1"
                + (keyword != null && !keyword.trim().isEmpty() ? " AND combo_name LIKE ?" : "")
                + " ORDER BY combo_id";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (keyword != null && !keyword.trim().isEmpty()) {
                ps.setString(1, "%" + keyword.trim() + "%");
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    public Combo findById(int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT * FROM Combo WHERE combo_id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public void insert(Combo c) throws SQLException {
        String sql = "INSERT INTO Combo (combo_name, description, price, stock, status) " +
                "VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getComboName());
            ps.setString(2, c.getDescription());
            ps.setBigDecimal(3, c.getPrice());
            ps.setInt(4, c.getStock());
            ps.setString(5, c.getStatus());
            ps.executeUpdate();
        }
    }

    public void update(Combo c) throws SQLException {
        String sql = "UPDATE Combo SET combo_name = ?, description = ?, price = ?, stock = ?, " +
                "status = ? WHERE combo_id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, c.getComboName());
            ps.setString(2, c.getDescription());
            ps.setBigDecimal(3, c.getPrice());
            ps.setInt(4, c.getStock());
            ps.setString(5, c.getStatus());
            ps.setInt(6, c.getComboId());
            ps.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM Combo WHERE combo_id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}
