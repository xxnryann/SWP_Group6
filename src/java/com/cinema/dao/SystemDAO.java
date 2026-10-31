package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Quản lý hệ thống (Admin): cấu hình chung, sao lưu CSDL, nhật ký thao tác. */
public class SystemDAO {

    private static final DateTimeFormatter BACKUP_STAMP = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");

    public List<Map<String, Object>> configs() throws SQLException {
        return Rows.query("SELECT config_key, config_value, description FROM SystemConfig ORDER BY config_key");
    }

    /** Lưu nhiều khóa cấu hình trong một transaction. */
    public void updateConfigs(Map<String, String> values) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("UPDATE SystemConfig SET config_value = ? WHERE config_key = ?")) {
            c.setAutoCommit(false);
            try {
                for (Map.Entry<String, String> e : values.entrySet()) {
                    ps.setString(1, e.getValue());
                    ps.setString(2, e.getKey());
                    ps.executeUpdate();
                }
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        }
    }

    /**
     * Sao lưu đầy đủ CSDL vào thư mục backup mặc định của SQL Server.
     * Dùng COPY_ONLY để không ảnh hưởng chuỗi sao lưu sẵn có; file nằm trên máy chạy SQL Server.
     *
     * @return đường dẫn file .bak
     */
    public String backup() throws SQLException {
        try (Connection c = DBContext.getConnection(); Statement st = c.createStatement()) {
            Map<String, Object> info = Rows.query(c, "SELECT DB_NAME() AS db, "
                    + "CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS NVARCHAR(400)) AS folder").get(0);
            String db = (String) info.get("db");
            String folder = (String) info.get("folder");
            if (folder == null || folder.isBlank()) {
                throw new SQLException("SQL Server chưa cấu hình thư mục sao lưu mặc định.");
            }
            String path = folder + (folder.endsWith("\\") ? "" : "\\")
                    + db + "_" + LocalDateTime.now().format(BACKUP_STAMP) + ".bak";
            st.execute("BACKUP DATABASE [" + db.replace("]", "]]") + "] TO DISK = N'" + path.replace("'", "''")
                    + "' WITH COPY_ONLY, INIT, CHECKSUM");
            // Đọc hết kết quả để driver ném lỗi nếu BACKUP thất bại giữa chừng.
            while (st.getMoreResults() || st.getUpdateCount() != -1) {
                // bỏ qua
            }
            return path;
        }
    }

    /** Các lần sao lưu gần nhất của CSDL này (lịch sử trong msdb). */
    public List<Map<String, Object>> backups(int limit) throws SQLException {
        return Rows.query("SELECT TOP (?) s.backup_finish_date AS finished_at, m.physical_device_name AS file_path, "
                + "CAST(s.backup_size / 1048576.0 AS DECIMAL(10,1)) AS size_mb, s.user_name AS sql_user "
                + "FROM msdb.dbo.backupset s JOIN msdb.dbo.backupmediafamily m ON m.media_set_id = s.media_set_id "
                + "WHERE s.database_name = DB_NAME() AND s.type = 'D' ORDER BY s.backup_finish_date DESC", limit);
    }

    /** Nhật ký thao tác mới nhất; mọi điều kiện lọc đều có thể bỏ trống. */
    public List<Map<String, Object>> logs(String keyword, LocalDate from, LocalDate to, int limit) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT TOP (?) l.log_id, l.action, l.detail, l.created_at, "
                + "a.full_name, a.email FROM SystemLog l LEFT JOIN Account a ON a.account_id = l.account_id WHERE 1 = 1");
        List<Object> params = new ArrayList<>();
        params.add(limit);
        if (keyword != null && !keyword.isEmpty()) {
            String like = "%" + keyword.replace("[", "[[]").replace("%", "[%]").replace("_", "[_]") + "%";
            sql.append(" AND (l.action LIKE ? OR l.detail LIKE ? OR a.email LIKE ? OR a.full_name LIKE ?)");
            for (int i = 0; i < 4; i++) params.add(like);
        }
        if (from != null) {
            sql.append(" AND l.created_at >= ?");
            params.add(java.sql.Date.valueOf(from));
        }
        if (to != null) {
            sql.append(" AND l.created_at < ?");
            params.add(java.sql.Date.valueOf(to.plusDays(1)));
        }
        sql.append(" ORDER BY l.log_id DESC");
        return Rows.query(sql.toString(), params.toArray());
    }
}
