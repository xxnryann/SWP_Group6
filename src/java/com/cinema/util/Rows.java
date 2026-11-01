package com.cinema.util;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Đọc kết quả truy vấn thành danh sách Map (khoá = tên cột viết thường) để JSP dùng trực tiếp
 * cho các màn hình báo cáo/quản trị nhỏ, không cần tạo thêm lớp model.
 */
public final class Rows {

    private static final java.time.format.DateTimeFormatter DISPLAY =
            java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private Rows() {
    }

    public static List<Map<String, Object>> read(ResultSet rs) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        int columns = meta.getColumnCount();
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= columns; i++) {
                Object value = rs.getObject(i);
                if (value instanceof java.sql.Timestamp ts) {
                    value = ts.toLocalDateTime().format(DISPLAY);
                } else if (value instanceof java.sql.Date d) {
                    value = d.toLocalDate();
                }
                row.put(meta.getColumnLabel(i).toLowerCase(), value);
            }
            list.add(row);
        }
        return list;
    }

    /** Chạy truy vấn có tham số và trả về danh sách dòng. */
    public static List<Map<String, Object>> query(java.sql.Connection connection, String sql, Object... params)
            throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return read(rs);
            }
        }
    }

    public static List<Map<String, Object>> query(String sql, Object... params) throws SQLException {
        try (java.sql.Connection c = DBContext.getConnection()) {
            return query(c, sql, params);
        }
    }
}
