package com.cinema.service;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.TicketDAO;
import com.cinema.model.Ticket;
import java.sql.SQLException;
import java.util.List;

/** Nghiệp vụ lịch sử vé + huỷ vé của khách (UC19 / BF-09). */
public class TicketService {

    private final TicketDAO ticketDAO;
    private final AccountDAO accountDAO;

    public TicketService() {
        this(new TicketDAO(), new AccountDAO());
    }

    public TicketService(TicketDAO ticketDAO, AccountDAO accountDAO) {
        this.ticketDAO = ticketDAO;
        this.accountDAO = accountDAO;
    }

    /** Lịch sử vé của khách (mỗi vé 1 thẻ 1 mã QR). */
    public List<Ticket> getCustomerTickets(String email) throws SQLException {
        return ticketDAO.findByUser(email);
    }

    public List<com.cinema.model.ComboOrder> getCustomerCombos(String email) throws SQLException {
        return ticketDAO.findComboOrdersByUser(email);
    }

    /** Huỷ MỘT vé của khách đang đăng nhập. */
    public CancelResult cancelTicket(int ticketId, String email, String reason) {
        if (ticketId <= 0) {
            return CancelResult.fail("Vé không hợp lệ.");
        }
        int accountId;
        try {
            accountId = accountDAO.findAccountIdByEmail(email);
        } catch (SQLException e) {
            return CancelResult.fail("Không kiểm tra được tài khoản. Vui lòng thử lại.");
        }
        if (accountId <= 0) {
            return CancelResult.fail("Không tìm thấy tài khoản của bạn.");
        }

        // Ownership: đọc vé và so account chủ đơn với khách đang đăng nhập.
        // Không tin ticketId do client gửi lên.
        Ticket ticket = findOwnedTicket(ticketId, email, accountId);
        if (ticket == null) {
            return CancelResult.fail("Bạn không có quyền huỷ vé này.");
        }
        if (!ticket.isActive()) {
            return CancelResult.fail("Vé này không còn hiệu lực nên không thể huỷ.");
        }
        if (!ticket.isCanCancel()) {
            return CancelResult.fail(
                    "Đã quá thời hạn huỷ vé: phải huỷ trước giờ chiếu ít nhất "
                    + new com.cinema.dao.SystemDAO().configInt("CANCEL_BEFORE_HOURS", 2)
                    + " giờ. Vui lòng liên hệ rạp để được hỗ trợ.");
        }

        try {
            ticketDAO.cancelTicket(ticketId, accountId, reason);
            return CancelResult.ok(ticket.getPairLabel() != null
                    ? "Đã huỷ cả cặp ghế đôi. Tiền vé đã được hoàn lại."
                    : "Đã huỷ vé. Tiền vé đã được hoàn lại.");
        } catch (SQLException e) {
            // Message từ THROW trong procedure đã là tiếng Việt → trả về UI.
            String message = e.getMessage();
            return CancelResult.fail(message == null || message.trim().isEmpty()
                    ? "Không huỷ được vé. Vui lòng thử lại." : message);
        }
    }

    /** Huỷ toàn bộ combo của một đơn của khách đang đăng nhập. */
    public CancelResult cancelCombo(int bookingId, String email) {
        if (bookingId <= 0) {
            return CancelResult.fail("Đơn không hợp lệ.");
        }
        try {
            int accountId = accountDAO.findAccountIdByEmail(email);
            if (accountId <= 0) {
                return CancelResult.fail("Không tìm thấy tài khoản của bạn.");
            }
            ticketDAO.cancelCombo(bookingId, accountId);
            return CancelResult.ok("Đã huỷ combo. Chi tiết hoàn tiền có trong Hộp thư.");
        } catch (SQLException e) {
            String message = e.getMessage();
            return CancelResult.fail(message == null || message.trim().isEmpty()
                    ? "Không huỷ được combo. Vui lòng thử lại." : message);
        }
    }

    /** Tìm vé theo id nhưng chỉ trả về khi thuộc đơn của khách đang đăng nhập. */
    private Ticket findOwnedTicket(int ticketId, String email, int accountId) {
        try {
            Ticket t = ticketDAO.findOneByUser(ticketId, email);
            if (t == null) {
                return null;
            }
            // So account chủ đơn: chống việc đoán ticketId của người khác.
            return t.getBookingCustomerId() == accountId ? t : null;
        } catch (SQLException e) {
            return null;
        }
    }

    /** Kết quả thao tác huỷ vé: thành công hay thất bại kèm thông báo. */
    public static class CancelResult {
        private final boolean success;
        private final String message;

        CancelResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }

        static CancelResult ok(String message) {
            return new CancelResult(true, message);
        }

        static CancelResult fail(String message) {
            return new CancelResult(false, message);
        }

        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
    }
}
