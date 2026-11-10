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

    /** Voucher công khai còn hạn, còn lượt dùng (trang Khuyến mãi, bán tại quầy). Không gồm voucher đền bù. */
    public static List<Map<String, Object>> activeVouchers() throws SQLException {
        return Rows.query("SELECT code, description, discount_type, discount_value, max_discount, min_order_amount, "
                + "min_cumulative_spending, usage_limit, used_count, 0 AS is_personal, "
                + "CONVERT(varchar(10), valid_from, 103) AS valid_from_txt, CONVERT(varchar(10), valid_to, 103) AS valid_to_txt "
                + "FROM Voucher WHERE status = 'Allowed' AND is_compensation = 0 "
                + "AND CAST(SYSDATETIME() AS date) BETWEEN valid_from AND valid_to "
                + "AND (usage_limit IS NULL OR used_count < usage_limit) "
                + "ORDER BY valid_to, voucher_id");
    }

    /**
     * Voucher khách dùng được: voucher đền bù (vd. DENBU25) khi khách còn lượt cấp chưa dùng + voucher công khai.
     * Với voucher đền bù: usage_limit = số lượt còn lại, used_count = 0, hạn dùng = hạn sớm nhất trong các lượt.
     */
    public static List<Map<String, Object>> activeVouchersFor(int accountId) throws SQLException {
        List<Map<String, Object>> list = new java.util.ArrayList<>(Rows.query(
                "SELECT v.code, v.description, v.discount_type, v.discount_value, v.max_discount, v.min_order_amount, "
                + "v.min_cumulative_spending, g.remaining AS usage_limit, 0 AS used_count, 1 AS is_personal, "
                + "CONVERT(varchar(10), g.first_granted, 103) AS valid_from_txt, "
                + "CONVERT(varchar(10), g.first_expiry, 103) AS valid_to_txt "
                + "FROM Voucher v JOIN (SELECT voucher_id, COUNT(*) AS remaining, MIN(expires_at) AS first_expiry, "
                + "MIN(granted_at) AS first_granted FROM VoucherGrant "
                + "WHERE customer_id = ? AND used_booking_id IS NULL AND expires_at >= CAST(SYSDATETIME() AS date) "
                + "GROUP BY voucher_id) g ON g.voucher_id = v.voucher_id "
                + "WHERE v.is_compensation = 1 AND v.status = 'Allowed' ORDER BY g.first_expiry", accountId));
        list.addAll(activeVouchers());
        return list;
    }
}
