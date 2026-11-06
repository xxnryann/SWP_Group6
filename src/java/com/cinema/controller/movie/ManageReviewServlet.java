package com.cinema.controller.movie;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.ReviewModerationDAO;
import com.cinema.util.movie.MovieAccess;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

@WebServlet("/manage/reviews")
public class ManageReviewServlet extends BaseServlet {
    private final ReviewModerationDAO reviewDAO = new ReviewModerationDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!requireRole(request, response, MovieAccess.ROLE_MANAGER)) return;
        try {
            request.setAttribute("reviews", reviewDAO.findAll());
            request.setAttribute("pageTitle", "Kiểm duyệt đánh giá");
            forward(request, response, "movie/manage-reviews");
        } catch (SQLException e) {
            throw new ServletException("Không thể tải đánh giá.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (!requireRole(request, response, MovieAccess.ROLE_MANAGER)) return;
        if (!csrfOk(request, response)) return;
        try {
            if (!"delete-comment".equals(request.getParameter("action"))) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
            String reason = trimToNull(request.getParameter("reason"));
            if (reason == null || reason.length() > 500) {
                throw new IllegalArgumentException("Lý do xóa bắt buộc và tối đa 500 ký tự.");
            }
            int reviewId = safeId(request.getParameter("id"));
            Map<String, Object> review = reviewDAO.findForDeletion(reviewId);
            if (review == null) throw new IllegalStateException("Bình luận không tồn tại hoặc đã được xóa.");
            reviewDAO.deleteComment(reviewId, currentUser(request).getUserId(), reason);
            insertNotification((Integer) review.get("customer_id"), (Integer) review.get("movie_id"), reason);
            flash(request, "success", "Đã xóa bình luận và gửi thông báo cho khách hàng.");
        } catch (IllegalArgumentException | IllegalStateException e) {
            flash(request, "error", e.getMessage());
        } catch (SQLException e) {
            getServletContext().log("Review moderation failed", e);
            flash(request, "error", "Không thể kiểm duyệt bình luận.");
        }
        response.sendRedirect(request.getContextPath() + "/manage/reviews");
    }

    private void insertNotification(int customerId, int movieId, String reason) throws SQLException {
        try (var connection = com.cinema.util.DBContext.getConnection();
                var statement = connection.prepareStatement(
                        "INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, movie_id, status) "
                                + "VALUES (?, 'ReviewModerated', N'Bình luận đã được kiểm duyệt', ?, ?, 'InApp')")) {
            statement.setInt(1, customerId);
            statement.setString(2, "Bình luận của bạn đã bị xóa vì lý do: " + reason);
            statement.setInt(3, movieId);
            statement.executeUpdate();
        }
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

}
