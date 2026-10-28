package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.Map;

/** Đánh giá phim: chỉ khách đã xem (vé đã soát) mới được đánh giá, mỗi phim một lần — {@code sp_AddReview}. */
public class ReviewDAO {

    public List<Map<String, Object>> findByMovie(int movieId) throws SQLException {
        return Rows.query("SELECT r.review_id, r.rating, r.comment, r.created_at, a.full_name AS reviewer_name "
                + "FROM Review r JOIN Account a ON a.account_id = r.customer_id "
                + "WHERE r.movie_id = ? ORDER BY r.created_at DESC", movieId);
    }

    /** Điểm trung bình (0 nếu chưa có) và số lượt đánh giá. */
    public Map<String, Object> stats(int movieId) throws SQLException {
        return Rows.query("SELECT CAST(ISNULL(AVG(CAST(rating AS DECIMAL(4,2))), 0) AS DECIMAL(3,1)) AS avg_rating, "
                + "COUNT(*) AS review_count FROM Review WHERE movie_id = ?", movieId).get(0);
    }

    /** Khách đã xem phim (có vé đã soát) chưa? */
    public boolean hasWatched(int customerId, int movieId) throws SQLException {
        return !Rows.query("SELECT TOP 1 1 AS x FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id "
                + "JOIN Showtime s ON s.showtime_id = t.showtime_id "
                + "WHERE b.customer_id = ? AND s.movie_id = ? AND t.status = 'Used'", customerId, movieId).isEmpty();
    }

    public boolean hasReviewed(int customerId, int movieId) throws SQLException {
        return !Rows.query("SELECT TOP 1 1 AS x FROM Review WHERE customer_id = ? AND movie_id = ?",
                customerId, movieId).isEmpty();
    }

    public void add(int customerId, int movieId, int rating, String comment) throws SQLException {
        try (Connection c = DBContext.getConnection();
             CallableStatement cs = c.prepareCall("{call dbo.sp_AddReview(?, ?, ?, ?)}")) {
            cs.setInt(1, customerId);
            cs.setInt(2, movieId);
            cs.setInt(3, rating);
            if (comment == null || comment.isEmpty()) {
                cs.setNull(4, Types.NVARCHAR);
            } else {
                cs.setString(4, comment);
            }
            cs.execute();
        }
    }
}
