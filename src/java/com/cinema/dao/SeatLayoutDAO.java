package com.cinema.dao;

import com.cinema.model.SeatLayout;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

/** DAO bảng SeatLayout — thư viện layout ghế dùng lại khi thêm phòng chiếu (Admin). */
public class SeatLayoutDAO {

    private static final String SELECT =
            "SELECT layout_id, layout_name, room_type, seat_count, layout_data, created_at FROM SeatLayout ";

    private SeatLayout map(ResultSet rs) throws SQLException {
        SeatLayout l = new SeatLayout();
        l.setLayoutId(rs.getInt("layout_id"));
        l.setLayoutName(rs.getString("layout_name"));
        l.setRoomType(rs.getString("room_type"));
        l.setSeatCount(rs.getInt("seat_count"));
        l.setLayoutData(rs.getString("layout_data"));
        Timestamp t = rs.getTimestamp("created_at");
        l.setCreatedAt(t == null ? null : t.toLocalDateTime());
        return l;
    }

    /** Toàn bộ thư viện; layout cùng loại phòng với roomType được xếp lên trước, mới nhất trước. */
    public List<SeatLayout> findAll(String roomType) throws SQLException {
        String sql = SELECT + "ORDER BY CASE WHEN room_type = ? THEN 0 ELSE 1 END, created_at DESC, layout_id DESC";
        List<SeatLayout> list = new ArrayList<>();
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, roomType == null ? "" : roomType);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        }
        return list;
    }

    public SeatLayout findById(int layoutId) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE layout_id = ?")) {
            ps.setInt(1, layoutId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /** Tên layout đã tồn tại (so sánh theo collation của DB, không phân biệt hoa thường). */
    public boolean nameExists(String name) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("SELECT 1 FROM SeatLayout WHERE layout_name = ?")) {
            ps.setString(1, name);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Thêm layout, trả về layout_id. */
    public int insert(SeatLayout l, Integer createdBy) throws SQLException {
        String sql = "INSERT INTO SeatLayout (layout_name, room_type, seat_count, layout_data, created_by) "
                + "VALUES (?, ?, ?, ?, (SELECT account_id FROM Account WHERE account_id = ?))";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, l.getLayoutName());
            ps.setString(2, l.getRoomType());
            ps.setInt(3, l.getSeatCount());
            ps.setString(4, l.getLayoutData());
            if (createdBy == null) {
                ps.setNull(5, Types.INTEGER);
            } else {
                ps.setInt(5, createdBy);
            }
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }
}
