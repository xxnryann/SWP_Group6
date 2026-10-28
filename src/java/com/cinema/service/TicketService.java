package com.cinema.service;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.TicketDAO;
import com.cinema.model.Ticket;
import java.sql.SQLException;
import java.util.List;

/**
 * Nghiệp vụ lịch sử vé + huỷ vé của khách (UC19 / BF-09).
 *
 * <p>Tầng service là nơi duy nhất quyết định khách có được huỷ vé hay không.
 * Điều kiện kiểm tra (đã chốt):</p>
 * <ol>
 *   <li><b>Ownership</b>: vé phải thuộc đơn của chính khách đang đăng nhập
 *       (không tin id gửi lên từ client).</li>
 *   <li><b>Còn hiệu lực</b>: vé phải {@code Booked} — chưa soát vé, chưa huỷ,
 *       chưa quá giờ chiếu.</li>
 *   <li><b>Còn trong thời hạn huỷ</b>: còn trước mốc
 *       {@code CANCEL_BEFORE_HOURS} giờ trước giờ chiếu.</li>
 * </ol>
 *
 * <p>Việc kiểm tra cuối cùng nằm trong stored procedure
 * {@code sp_CancelTicket} (transaction + ownership + hoàn tiền/điểm), nên
 * service chỉ chịu trách nhiệm tiền điều kiện + dịch message tiếng Việt
 * cho UI. Không copy-paste logic giữa controller.</p>
 */
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

    /**
     * Lịch sử vé của khách (mỗi vé 1 thẻ 1 mã QR).
     *
     * @param email email khách đang đăng nhập
     */
    public List<Ticket> getCustomerTickets(String email) throws SQLException {
        return ticketDAO.findByUser(email);
    }

    /**
     * Huỷ MỘT vé của khách đang đăng nhập.
     *
     * @param ticketId id vé (từ form, KHÔNG tin tuyệt đối — kiểm tra ownership)
     * @param email    email khách đang đăng nhập
     * @param reason   lý do huỷ (tuỳ chọn)
     * @return kết quả kèm thông báo tiếng Việt
     */
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
                    "Đã quá thời hạn cho phép huỷ vé. Vui lòng liên hệ rạp để được hỗ trợ.");
        }

        try {
            ticketDAO.cancelTicket(ticketId, accountId, reason);
            return CancelResult.ok("Đã huỷ vé. Tiền vé đã được hoàn lại.");
        } catch (SQLException e) {
            // Message từ THROW trong procedure đã là tiếng Việt → trả về UI.
            String message = e.getMessage();
            return CancelResult.fail(message == null || message.trim().isEmpty()
                    ? "Không huỷ được vé. Vui lòng thử lại." : message);
        }
    }

    /**
     * Tìm vé theo id nhưng chỉ trả về khi thuộc đơn của khách đang đăng nhập.
     *
     * @param ticketId  id vé
     * @param email     email khách đang đăng nhập
     * @param accountId account_id của khách đang đăng nhập
     * @return vé, hoặc null nếu không tồn tại / không thuộc khách đó
     */
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

    /**
     * Kết quả thao tác huỷ vé: thành công hay thất bại kèm thông báo.
     */
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
