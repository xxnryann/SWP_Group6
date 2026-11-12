package com.cinema.dao;

import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** DAO bảng RoomType — loại phòng chiếu (2D, 3D, IMAX, 4DX có sẵn + loại Admin tự thêm). */
public class RoomTypeDAO {

    /** Mã các loại phòng: loại có sẵn trước (theo thứ tự 2D, 3D, IMAX, 4DX), loại tự thêm sau. */
    public List<String> findCodes() throws SQLException {
        List<String> list = new ArrayList<>();
        String sql = "SELECT type_code FROM RoomType ORDER BY is_builtin DESC, "
                + "CASE type_code WHEN '2D' THEN 1 WHEN '3D' THEN 2 WHEN 'IMAX' THEN 3 WHEN '4DX' THEN 4 ELSE 5 END, "
                + "created_at, type_code";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(rs.getString(1));
            }
        }
        return list;
    }

    /** Mã loại phòng đã có (so sánh không phân biệt hoa thường theo collation của DB); trả về mã đúng như đã lưu. */
    public String findExisting(String code) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT type_code FROM RoomType WHERE type_code = ?")) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    public void insert(String code, String description) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "INSERT INTO RoomType (type_code, description, is_builtin) VALUES (?, ?, 0)")) {
            ps.setString(1, code);
            ps.setString(2, description == null || description.isBlank() ? null : description.trim());
            ps.executeUpdate();
        }
    }
}
