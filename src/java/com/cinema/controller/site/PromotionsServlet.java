package com.cinema.controller.site;

import com.cinema.controller.BaseServlet;
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
        forward(req, resp, "site/promotions");
    }

    private static final String ACTIVE_VOUCHER_SQL =
            "SELECT code, description, discount_type, discount_value, max_discount, min_order_amount, "
            + "min_cumulative_spending, usage_limit, used_count, "
            + "CASE WHEN owner_customer_id IS NULL THEN 0 ELSE 1 END AS is_personal, "
            + "CONVERT(varchar(10), valid_from, 103) AS valid_from_txt, CONVERT(varchar(10), valid_to, 103) AS valid_to_txt "
            + "FROM Voucher WHERE status = 'Allowed' "
            + "AND CAST(SYSDATETIME() AS date) BETWEEN valid_from AND valid_to "
            + "AND (usage_limit IS NULL OR used_count < usage_limit) ";

    /** Voucher công khai còn hạn, còn lượt dùng (trang Khuyến mãi, bán tại quầy). Không gồm voucher cá nhân. */
    public static List<Map<String, Object>> activeVouchers() throws SQLException {
        return Rows.query(ACTIVE_VOUCHER_SQL + "AND owner_customer_id IS NULL ORDER BY valid_to, voucher_id");
    }

    /**
     * Voucher khách dùng được: công khai + voucher cá nhân của chính khách (vd. voucher bù trừ suất chiếu bị hủy).
     * Voucher cá nhân xếp trước.
     */
    public static List<Map<String, Object>> activeVouchersFor(int accountId) throws SQLException {
        return Rows.query(ACTIVE_VOUCHER_SQL
                + "AND (owner_customer_id IS NULL OR owner_customer_id = ?) "
                + "ORDER BY CASE WHEN owner_customer_id IS NULL THEN 1 ELSE 0 END, valid_to, voucher_id", accountId);
    }
}
