package com.cinema.controller;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.ReviewDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Gửi đánh giá phim (khách hàng đã xem). POST /movies/review */
@WebServlet("/movies/review")
public class ReviewServlet extends BaseServlet {

    private final ReviewDAO dao = new ReviewDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/movies");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "CUSTOMER")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        int movieId = safeId(req.getParameter("movieId"));
        if (movieId < 0) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        String ratingText = Validator.trim(req.getParameter("rating"));
        String comment = Validator.trim(req.getParameter("comment"));
        String back = req.getContextPath() + "/movies/detail?id=" + movieId;
        int rating;
        try {
            rating = Integer.parseInt(ratingText);
        } catch (NumberFormatException e) {
            rating = 0;
        }
        if (rating < 1 || rating > 5) {
            flash(req, "error", "Vui lòng chọn số sao từ 1 đến 5.");
        } else if (comment.length() > 1000) {
            flash(req, "error", "Nhận xét tối đa 1000 ký tự.");
        } else {
            try {
                int customerId = accountDAO.findAccountIdByEmail(currentUser(req).getEmail());
                if (customerId == 0) {
                    flash(req, "error", "Không tìm thấy tài khoản khách hàng của bạn.");
                } else if (dao.hasReviewed(customerId, movieId)) {
                    flash(req, "error", "Bạn đã đánh giá phim này rồi.");
                } else {
                    dao.add(customerId, movieId, rating, comment);
                    flash(req, "success", "Cảm ơn bạn đã đánh giá phim!");
                }
            } catch (SQLException e) {
                flash(req, "error", e.getMessage());
            }
        }
        resp.sendRedirect(back);
    }
}
