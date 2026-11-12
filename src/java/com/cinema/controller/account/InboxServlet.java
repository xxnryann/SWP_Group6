package com.cinema.controller.account;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.AccountDAO;
import com.cinema.dao.EmailOutboxDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/** Hộp thư của khách hàng: thông báo vé, nhắc lịch chiếu, phim mới và ưu đãi voucher. Lọc theo ?type=NewMovie|Voucher. */
@WebServlet("/account/inbox")
public class InboxServlet extends BaseServlet {

    private static final int INBOX_LIMIT = 100;
    private final EmailOutboxDAO dao = new EmailOutboxDAO();
    private final AccountDAO accountDao = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "CUSTOMER")) return;
        // EmailNotification.customer_id trỏ tới Account.account_id, số này có thể khác Users.UserId
        // (đăng ký bỏ dở chỉ tạo dòng Users), dùng nhầm sẽ đọc phải hộp thư của khách khác.
        int customerId;
        try {
            customerId = accountDao.findAccountIdByEmail(currentUser(req).getEmail());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        String param = req.getParameter("type");
        String type = "NewMovie".equals(param) || "Voucher".equals(param) ? param : null;
        // Lỗi bổ sung thông báo mới không được làm hỏng việc xem các thông báo đã có.
        try {
            if (customerId > 0) dao.syncInboxPromotions(customerId);
        } catch (SQLException e) {
            getServletContext().log("Cannot sync inbox promotions for customer " + customerId, e);
        }
        try {
            req.setAttribute("inboxType", type);
            req.setAttribute("inboxLimit", INBOX_LIMIT);
            req.setAttribute("notifications", customerId > 0 ? dao.customerInbox(customerId, INBOX_LIMIT, type) : java.util.List.of());
            // Đã mở hộp thư -> các thông báo đang xem không còn tính là "mới" trên chuông.
            if (customerId > 0) dao.markRead(customerId, type);
            req.setAttribute("unreadNotifications", customerId > 0 ? dao.countUnreadByEmail(currentUser(req).getEmail()) : 0);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        forward(req, resp, "account/inbox");
    }
}
