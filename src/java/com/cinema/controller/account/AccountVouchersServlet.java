package com.cinema.controller.account;

import com.cinema.controller.BaseServlet;
import com.cinema.controller.site.PromotionsServlet;
import com.cinema.dao.AccountDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Tab "Voucher" trong khu Thông tin tài khoản: các voucher đang áp dụng. URL: /account/vouchers */
@WebServlet("/account/vouchers")
public class AccountVouchersServlet extends BaseServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            int accountId = new AccountDAO().findAccountIdByEmail(currentUser(req).getEmail());
            req.setAttribute("vouchers", accountId > 0
                    ? PromotionsServlet.activeVouchersFor(accountId) : PromotionsServlet.activeVouchers());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        forward(req, resp, "account/account-vouchers");
    }
}
