package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public class ReviewModerationDAO {
    public record Page(List<Map<String, Object>> reviews, int page, int pageCount, int total,
            int totalComments, double averageRating) {}

    public record Summary(int total, int totalComments, double averageRating) {}

    public Page findPage(String movie, Integer rating, String from, String to, String keyword,
            String status, int page, int pageSize) throws SQLException {
        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        List<Object> params = new java.util.ArrayList<>();
        String movieFilter = clean(movie);
        if (movieFilter != null) {
            try {
                where.append("AND m.movie_id = ? ");
                params.add(Integer.parseInt(movieFilter));
            } catch (NumberFormatException ignored) {
                where.append("AND 1 = 0 ");
            }
        }

        if (rating != null && rating >= 1 && rating <= 5) {
            where.append("AND r.rating = ? ");
            params.add(rating);
        }
        LocalDate fromDate = parseDate(from);
        LocalDate toDate = parseDate(to);
        if (fromDate != null) { where.append("AND r.created_at >= ? "); params.add(java.sql.Date.valueOf(fromDate)); }
        if (toDate != null) { where.append("AND r.created_at < DATEADD(DAY, 1, ?) "); params.add(java.sql.Date.valueOf(toDate)); }
        String keywordFilter = clean(keyword);
        if (keywordFilter != null) { where.append("AND r.comment LIKE ? "); params.add("%" + keywordFilter + "%"); }
        String statusFilter = clean(status);
        if ("deleted".equalsIgnoreCase(statusFilter)) where.append("AND r.moderated_at IS NOT NULL ");
        if ("visible".equalsIgnoreCase(statusFilter)) where.append("AND r.moderated_at IS NULL ");
        if ("reported".equalsIgnoreCase(statusFilter)) where.append("AND EXISTS (SELECT 1 FROM dbo.ReviewReport rr0 WHERE rr0.review_id = r.review_id) ");

        String base = " FROM dbo.Review r JOIN dbo.Movie m ON m.movie_id = r.movie_id "
                + "JOIN dbo.Account a ON a.account_id = r.customer_id " + where;
        int offset = (page - 1) * pageSize;
        List<Map<String, Object>> rows = Rows.query("SELECT r.review_id, r.rating, r.comment, r.created_at, "
                + "m.movie_id, m.title AS movie_title, a.account_id AS customer_id, a.full_name AS customer_name "
                + ", r.moderated_at, r.moderated_by, r.moderation_reason, "
                + "(SELECT COUNT(*) FROM dbo.ReviewReport rr WHERE rr.review_id = r.review_id) AS report_count "
                + base + " ORDER BY r.created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                append(params, offset, pageSize));
        Map<String, Object> count = Rows.query("SELECT COUNT(*) AS total, "
                + "COALESCE(SUM(CASE WHEN r.comment IS NOT NULL AND r.moderated_at IS NULL THEN 1 ELSE 0 END), 0) AS total_comments, "
                + "AVG(CAST(r.rating AS DECIMAL(4,2))) AS average_rating " + base, params.toArray()).get(0);
        int total = ((Number) count.get("total")).intValue();
        return new Page(rows, page, Math.max(1, (total + pageSize - 1) / pageSize), total,
                ((Number) count.get("total_comments")).intValue(), count.get("average_rating") == null ? 0
                        : ((Number) count.get("average_rating")).doubleValue());
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private LocalDate parseDate(String value) {
        try {
            String cleaned = clean(value);
            return cleaned == null ? null : LocalDate.parse(cleaned);
        } catch (java.time.format.DateTimeParseException e) {
            return null;
        }
    }

    public List<Map<String, Object>> findMoviesWithReviews() throws SQLException {
        return Rows.query("SELECT DISTINCT m.movie_id, m.title "
                + "FROM dbo.Movie m JOIN dbo.Review r ON r.movie_id = m.movie_id "
                + "WHERE m.status = 'NowShowing' ORDER BY m.title");
    }

    public List<Map<String, Object>> findNowShowingMovieSummaries() throws SQLException {
        return Rows.query("SELECT m.movie_id, m.title, COUNT(r.review_id) AS review_count, "
                + "CAST(AVG(CAST(r.rating AS DECIMAL(4,2))) AS DECIMAL(3,1)) AS average_rating "
                + "FROM dbo.Movie m JOIN dbo.Review r ON r.movie_id = m.movie_id "
                + "WHERE m.status = 'NowShowing' "
                + "GROUP BY m.movie_id, m.title ORDER BY m.title");
    }

    public Summary findNowShowingSummary() throws SQLException {
        Map<String, Object> row = Rows.query(
                "SELECT COUNT(*) AS total, "
                        + "COALESCE(SUM(CASE WHEN r.comment IS NOT NULL AND r.moderated_at IS NULL THEN 1 ELSE 0 END), 0) AS total_comments, "
                        + "AVG(CAST(r.rating AS DECIMAL(4,2))) AS average_rating "
                        + "FROM dbo.Review r JOIN dbo.Movie m ON m.movie_id = r.movie_id "
                        + "WHERE m.status = 'NowShowing'").get(0);
        return new Summary(((Number) row.get("total")).intValue(),
                ((Number) row.get("total_comments")).intValue(),
                row.get("average_rating") == null ? 0 : ((Number) row.get("average_rating")).doubleValue());
    }

    private Object[] append(List<Object> values, Object... extra) {
        List<Object> all = new java.util.ArrayList<>(values);
        java.util.Collections.addAll(all, extra);
        return all.toArray();
    }

    /** Ẩn bình luận vi phạm: GIỮ nội dung (có thể hiện lại), chỉ đánh dấu đã kiểm duyệt; điểm sao giữ nguyên. */
    /**
     * Ẩn bình luận vi phạm và thu hồi điểm thưởng đánh giá (tối đa 5, không để âm số dư) — {@code sp_HideReviewComment}.
     * @return số điểm MyPoint đã thu hồi
     */
    public int hideComment(int reviewId, int managerId, String reason) throws SQLException {
        return callForInt("{CALL dbo.sp_HideReviewComment(?, ?, ?)}", reviewId, managerId, reason);
    }

    /** Hiện lại bình luận đã ẩn và trả lại điểm thưởng đã thu hồi — {@code sp_UnhideReviewComment}. */
    public int unhideComment(int reviewId) throws SQLException {
        return callForInt("{CALL dbo.sp_UnhideReviewComment(?)}", reviewId, null, null);
    }

    private int callForInt(String sql, int reviewId, Integer managerId, String reason) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                java.sql.CallableStatement statement = connection.prepareCall(sql)) {
            statement.setInt(1, reviewId);
            if (managerId != null) {
                statement.setInt(2, managerId);
                statement.setString(3, reason);
            }
            try (java.sql.ResultSet rs = statement.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            if (e.getErrorCode() == 50092 || e.getErrorCode() == 50093) throw new IllegalStateException(e.getMessage());
            throw e;
        }
    }

    public Map<String, Object> findForModeration(int reviewId) throws SQLException {
        List<Map<String, Object>> rows = Rows.query("SELECT r.review_id, r.customer_id, r.movie_id, r.comment, m.title "
                + "FROM dbo.Review r JOIN dbo.Movie m ON m.movie_id = r.movie_id "
                + "WHERE r.review_id = ? AND r.comment IS NOT NULL", reviewId);
        return rows.isEmpty() ? null : rows.get(0);
    }
}
