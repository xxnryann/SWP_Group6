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
            int page = Math.max(1, safeId(request.getParameter("page")));
            Integer rating = parseRating(request.getParameter("rating"));
            ReviewModerationDAO.Page result = reviewDAO.findPage(request.getParameter("movie"),
                    rating, request.getParameter("from"), request.getParameter("to"),
                    request.getParameter("keyword"), request.getParameter("status"), page, 10);
            request.setAttribute("reviewPage", result);
            request.setAttribute("reviews", result.reviews());
            request.setAttribute("reviewMovies", reviewDAO.findMoviesWithReviews());
            request.setAttribute("movieSummaries", reviewDAO.findNowShowingMovieSummaries());
            ReviewModerationDAO.Summary summary = reviewDAO.findNowShowingSummary();
            request.setAttribute("reviewSummary", summary);
            request.setAttribute("summaryTotal", summary.total());
            request.setAttribute("summaryComments", summary.totalComments());
            request.setAttribute("summaryAverage", summary.averageRating());
            request.setAttribute("reviewPageCount", result.pageCount());
            request.setAttribute("reviewCurrentPage", result.page());
            request.setAttribute("filterMovie", request.getParameter("movie"));
            request.setAttribute("filterRating", request.getParameter("rating"));
            request.setAttribute("filterFrom", request.getParameter("from"));
            request.setAttribute("filterTo", request.getParameter("to"));
            request.setAttribute("filterStatus", request.getParameter("status"));
            request.setAttribute("pageTitle", "Kiểm duyệt đánh giá");
            forward(request, response, "movie/manage-reviews");
        } catch (SQLException e) {
            throw new ServletException("Không thể tải đánh giá.", e);
        }

    }

    private Integer parseRating(String value) {
        try { int n = Integer.parseInt(value); return n >= 1 && n <= 5 ? n : null; }
        catch (Exception e) { return null; }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (!requireRole(request, response, MovieAccess.ROLE_MANAGER)) return;
        if (!csrfOk(request, response)) return;
        try {
            String action = request.getParameter("action");
            int reviewId = safeId(request.getParameter("id"));
            if ("unhide-comment".equals(action)) {
                int restored = reviewDAO.unhideComment(reviewId);
                flash(request, "success", "Đã hiện lại bình luận" + (restored > 0
                        ? " và trả lại " + restored + " điểm MyPoint thưởng đánh giá cho khách." : "."));
            } else if ("hide-comment".equals(action)) {
                String reason = trimToNull(request.getParameter("reason"));
                if (reason == null || reason.length() > 500) {
                    throw new IllegalArgumentException("Lý do ẩn bắt buộc và tối đa 500 ký tự.");
                }
                Map<String, Object> review = reviewDAO.findForModeration(reviewId);
                if (review == null) throw new IllegalStateException("Bình luận không tồn tại.");
                int revoked = reviewDAO.hideComment(reviewId, currentUser(request).getUserId(), reason);
                insertNotification((Integer) review.get("customer_id"), (Integer) review.get("movie_id"),
                        (String) review.get("title"), reason, revoked);
                flash(request, "success", "Đã ẩn bình luận" + (revoked > 0 ? ", thu hồi " + revoked + " điểm MyPoint thưởng" : "")
                        + " và gửi thông báo lý do cho khách hàng.");
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (IllegalArgumentException | IllegalStateException e) {
            flash(request, "error", e.getMessage());
        } catch (SQLException e) {
            getServletContext().log("Review moderation failed", e);
            flash(request, "error", "Không thể kiểm duyệt bình luận.");
        }
        response.sendRedirect(request.getContextPath() + "/manage/reviews");
    }

    private void insertNotification(int customerId, int movieId, String title, String reason, int revoked)
            throws SQLException {
        try (var connection = com.cinema.util.DBContext.getConnection();
                var statement = connection.prepareStatement(
                        "INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, movie_id, status) "
                                + "VALUES (?, 'ReviewModerated', N'Bình luận đã được kiểm duyệt', ?, ?, 'InApp')")) {
            statement.setInt(1, customerId);
            statement.setString(2, "Bình luận của bạn về phim \"" + title + "\" đã bị ẩn vì lý do: " + reason + "."
                    + (revoked > 0 ? " " + revoked + " điểm MyPoint thưởng đánh giá đã bị thu hồi." : ""));
            statement.setInt(3, movieId);
            statement.executeUpdate();
        }
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

}
