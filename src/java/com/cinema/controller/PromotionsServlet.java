package com.cinema.controller;

import com.cinema.util.Rows;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/** Trang khuyến mãi công khai: các voucher đang áp dụng (còn hạn, còn lượt dùng). URL: /promotions */
@WebServlet("/promotions")
public class PromotionsServlet extends BaseServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            req.setAttribute("vouchers", activeVouchers());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.setAttribute("pageTitle", "Khuyến mãi");
        forward(req, resp, "promotions");
    }

    /** Voucher còn hạn, còn lượt dùng (dùng chung với tab Voucher của tài khoản). */
    public static List<Map<String, Object>> activeVouchers() throws SQLException {
        return Rows.query("SELECT code, description, discount_type, discount_value, max_discount, min_order_amount, "
                    + "min_cumulative_spending, usage_limit, used_count, "
                    + "CONVERT(varchar(10), valid_from, 103) AS valid_from_txt, CONVERT(varchar(10), valid_to, 103) AS valid_to_txt "
                    + "FROM Voucher WHERE status = 'Allowed' "
                    + "AND CAST(SYSDATETIME() AS date) BETWEEN valid_from AND valid_to "
                    + "AND (usage_limit IS NULL OR used_count < usage_limit) "
                    + "ORDER BY valid_to, voucher_id");
    }
}
