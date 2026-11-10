package com.cinema.service;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.TicketDAO;
import com.cinema.model.Ticket;
import java.sql.SQLException;
import java.util.List;

/**
 * Lịch sử vé và combo của khách (UC18).
 *
 * <p>Khách không tự huỷ vé/combo đã thanh toán (rule: không hoàn tiền do lỗi từ phía khách hàng).
 * Chỉ khi Manager huỷ suất chiếu do sự cố ({@code sp_CancelMovie}) giá trị đơn mới được hoàn
 * thành MyPoint kèm voucher đền bù.</p>
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

    public List<com.cinema.model.ComboOrder> getCustomerCombos(String email) throws SQLException {
        return ticketDAO.findComboOrdersByUser(email);
    }

}
