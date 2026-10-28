package com.cinema.controller;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.PromoDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;

/** Cấu hình quy đổi MyPoint (Manager/Admin). URL: /manager/mypoint */
@WebServlet("/manager/mypoint")
public class PointConfigServlet extends BaseServlet {

    private final PromoDAO dao = new PromoDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        try {
            req.setAttribute("configs", dao.pointConfigs());
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải cấu hình MyPoint: " + e.getMessage());
        }
        req.setAttribute("pageTitle", "Cấu hình MyPoint");
        forward(req, resp, "manager/mypoint");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        try {
            BigDecimal earn = decimal(req.getParameter("earnRatePercent"), "Tỷ lệ tích điểm");
            BigDecimal maxRedeem = decimal(req.getParameter("maxRedeemPercent"), "Tỷ lệ dùng điểm tối đa");
            if (earn.compareTo(BigDecimal.valueOf(100)) > 0 || maxRedeem.compareTo(BigDecimal.valueOf(100)) > 0) {
                throw new IllegalArgumentException("Tỷ lệ phần trăm tối đa 100%.");
            }
            int pointValue;
            try {
                pointValue = Integer.parseInt(Validator.trim(req.getParameter("pointValueVnd")));
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Giá trị 1 điểm phải là số nguyên.");
            }
            if (pointValue <= 0) throw new IllegalArgumentException("Giá trị 1 điểm phải lớn hơn 0.");
            int updater = accountDAO.findAccountIdByEmail(currentUser(req).getEmail());
            dao.createPointConfig(earn, pointValue, maxRedeem, updater == 0 ? 2 : updater);
            flash(req, "success", "Đã áp dụng cấu hình MyPoint mới từ hôm nay.");
        } catch (IllegalArgumentException e) {
            flash(req, "error", e.getMessage());
        } catch (SQLException e) {
            flash(req, "error", "Không thể lưu cấu hình: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/manager/mypoint");
    }

    private static BigDecimal decimal(String text, String label) {
        try {
            BigDecimal v = new BigDecimal(Validator.trim(text));
            if (v.signum() < 0) throw new IllegalArgumentException(label + " không được âm.");
            return v;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(label + " phải là số.");
        }
    }
}
