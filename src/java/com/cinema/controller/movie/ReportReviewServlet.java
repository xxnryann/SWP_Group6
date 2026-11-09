package com.cinema.controller.movie;

import com.cinema.controller.BaseServlet;
import com.cinema.util.DBContext;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.PreparedStatement;

@WebServlet("/movies/report-review")
public class ReportReviewServlet extends BaseServlet {
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (!requireRole(request, response, "CUSTOMER") || !csrfOk(request, response)) return;
        int reviewId = safeId(request.getParameter("reviewId"));
        String reason = request.getParameter("reason");
        if (reviewId < 1 || reason == null || reason.isBlank() || reason.length() > 200) {
            flash(request, "error", "Vui lòng chọn lý do báo cáo hợp lệ.");
        } else {
            try (var connection = DBContext.getConnection();
                    PreparedStatement statement = connection.prepareStatement(
                            "INSERT INTO dbo.ReviewReport(review_id, customer_id, reason) VALUES (?, ?, ?)")) {
                statement.setInt(1, reviewId);
                statement.setInt(2, currentUser(request).getUserId());
                statement.setString(3, reason.trim());
                statement.executeUpdate();
                flash(request, "success", "Đã gửi báo cáo bình luận cho quản lý.");
            } catch (java.sql.SQLException e) {
                flash(request, "error", e.getErrorCode() == 2601 || e.getErrorCode() == 2627
                        ? "Bạn đã báo cáo bình luận này." : "Không thể gửi báo cáo.");
            }
        }
        response.sendRedirect(request.getContextPath() + "/movies/detail?id="
                + safeId(request.getParameter("movieId")) + "#reviews");
    }
}
