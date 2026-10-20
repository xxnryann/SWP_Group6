package com.cinema.dao;

import com.cinema.model.News;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO bảng News — STT 12, STT 16.
 * Cột/tên bảng khớp script database của nhóm (news_id, thumbnail_url,
 * status IN ('Draft','Published','Hidden'), created_by NOT NULL).
 */
public class NewsDAO {

    private News map(ResultSet rs) throws SQLException {
        News n = new News();
        n.setNewsId(rs.getInt("news_id"));
        n.setTitle(rs.getString("title"));
        n.setContent(rs.getString("content"));
        n.setThumbnailUrl(rs.getString("thumbnail_url"));
        n.setStatus(rs.getString("status"));
        n.setCreatedBy(rs.getInt("created_by"));
        Timestamp c = rs.getTimestamp("created_at");
        n.setCreatedAt(c == null ? null : c.toLocalDateTime());
        Timestamp u = rs.getTimestamp("updated_at");
        n.setUpdatedAt(u == null ? null : u.toLocalDateTime());
        // author_name chỉ có khi query JOIN với Account
        try {
            n.setAuthorName(rs.getString("author_name"));
        } catch (SQLException ignored) {
        }
        return n;
    }

    /**
     * Danh sách tin cho trang quản lý, có lọc theo trạng thái + tìm theo tiêu đề
     * (giống các tab lọc trong mockup: Tất cả / Đã xuất bản / Bản nháp / Đã ẩn).
     */
    public List<News> findAll(String statusFilter, String keyword) throws SQLException {
        List<News> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT n.*, a.full_name AS author_name FROM News n " +
                        "JOIN Account a ON a.account_id = n.created_by WHERE 1 = 1");
        List<Object> params = new ArrayList<>();
        if (statusFilter != null && !statusFilter.isEmpty()) {
            sql.append(" AND n.status = ?");
            params.add(statusFilter);
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append(" AND n.title LIKE ?");
            params.add("%" + keyword.trim() + "%");
        }
        sql.append(" ORDER BY n.created_at DESC");

        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    /** Chỉ tin Published (khách xem — STT 16). */
    public List<News> findPublished() throws SQLException {
        List<News> list = new ArrayList<>();
        String sql = "SELECT n.*, a.full_name AS author_name FROM News n " +
                "JOIN Account a ON a.account_id = n.created_by " +
                "WHERE n.status = 'Published' ORDER BY n.created_at DESC";
        try (Connection c = DBContext.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) list.add(map(rs));
        }
        return list;
    }

    public News findById(int id) throws SQLException {
        String sql = "SELECT n.*, a.full_name AS author_name FROM News n " +
                "JOIN Account a ON a.account_id = n.created_by WHERE n.news_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    public void insert(News n) throws SQLException {
        String sql = "INSERT INTO News (title, content, thumbnail_url, status, created_by) " +
                "VALUES (?, ?, ?, ?, ?)";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, n.getTitle());
            ps.setString(2, n.getContent());
            ps.setString(3, n.getThumbnailUrl());
            ps.setString(4, n.getStatus());
            ps.setInt(5, n.getCreatedBy());
            ps.executeUpdate();
        }
    }

    public void update(News n) throws SQLException {
        String sql = "UPDATE News SET title = ?, content = ?, thumbnail_url = ?, status = ?, " +
                "updated_at = SYSDATETIME() WHERE news_id = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, n.getTitle());
            ps.setString(2, n.getContent());
            ps.setString(3, n.getThumbnailUrl());
            ps.setString(4, n.getStatus());
            ps.setInt(5, n.getNewsId());
            ps.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM News WHERE news_id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /**
     * Tìm account_id trong bảng Account theo email của user đang đăng nhập.
     * Cần vì News.created_by NOT NULL REFERENCES Account(account_id),
     * trong khi đăng nhập của khung code dùng bảng Users.
     *
     * @return account_id, hoặc 0 nếu email chưa có trong bảng Account
     */
    public int findAccountIdByEmail(String email) throws SQLException {
        String sql = "SELECT account_id FROM Account WHERE email = ?";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }
}
