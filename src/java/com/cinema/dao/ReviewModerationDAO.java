package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

public class ReviewModerationDAO {
    public List<Map<String, Object>> findAll() throws SQLException {
        return Rows.query("SELECT r.review_id, r.rating, r.comment, r.created_at, "
                + "m.movie_id, m.title AS movie_title, a.account_id AS customer_id, a.full_name AS customer_name "
                + "FROM dbo.Review r JOIN dbo.Movie m ON m.movie_id = r.movie_id "
                + "JOIN dbo.Account a ON a.account_id = r.customer_id ORDER BY r.created_at DESC");
    }

    public void deleteComment(int reviewId, int managerId, String reason) throws SQLException {
        String sql = "UPDATE dbo.Review SET comment = NULL, moderated_at = SYSDATETIME(), "
                + "moderated_by = ?, moderation_reason = ? WHERE review_id = ? AND comment IS NOT NULL";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, managerId);
            statement.setString(2, reason);
            statement.setInt(3, reviewId);
            if (statement.executeUpdate() == 0) {
                throw new IllegalStateException("Bình luận không tồn tại hoặc đã được xóa.");
            }
        }
    }

    public Map<String, Object> findForDeletion(int reviewId) throws SQLException {
        List<Map<String, Object>> rows = Rows.query("SELECT review_id, customer_id, movie_id, comment "
                + "FROM dbo.Review WHERE review_id = ? AND comment IS NOT NULL", reviewId);
        return rows.isEmpty() ? null : rows.get(0);
    }
}
