package com.cinema.controller.staff;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.CounterSaleDAO;
import com.cinema.model.OnlineBooking;
import com.cinema.model.User;
import com.cinema.service.GatewayPaymentService;
import com.cinema.util.RequestParams;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * Cổng thanh toán VNPAY chuyển NHÂN VIÊN quầy về sau khi thu tiền.
 *
 * <p>URL: {@code GET /staff/counter/payment/return}.</p>
 *
 * <p>Đây là bản sao theo kênh bán vé của
 * {@link com.cinema.controller.booking.BookingPaymentReturnServlet} — cùng
 * cổng thanh toán, cùng cách kiểm tra chữ ký và đối soát số tiền, nhưng quay
 * về màn hình hóa đơn tại quầy thay vì trang vé của khách hàng.</p>
 *
 * <p>Khác biệt quan trọng: đơn tại quầy được tra theo mã đơn do cổng gửi
 * ({@code vnp_TxnRef}) nên phải kiểm tra thêm:</p>
 * <ul>
 *   <li>đơn phải thuộc kênh {@code Counter} — tránh nhân viên xác nhận nhầm
 *       đơn đặt vé online của khách hàng;</li>
 *   <li>nếu phiên nhân viên còn hoạt động thì đơn phải do chính nhân viên
 *       đó bán ({@code staff_id}) — tránh một nhân viên xác nhận đơn của nhân
 *       viên khác.</li>
 * </ul>
 *
 * <p>Endpoint nằm ngoài phạm vi {@code /booking/*} nên không bị
 * {@code BookingAuthFilter} (chỉ cho phép CUSTOMER) chặn.</p>
 */
@WebServlet("/staff/counter/payment/return")
public class CounterPaymentReturnServlet extends BaseServlet {

    private static final long serialVersionUID = 1L;

    /** Khóa session chứa booking_id của đơn tại quầy (xem CounterSalesServlet). */
    private static final String SESSION_BOOKING = "counterBookingId";

    /** Khóa session chứa showtime_id của đơn tại quầy. */
    private static final String SESSION_SHOWTIME = "counterShowtimeId";

    private final CounterSaleDAO dao = new CounterSaleDAO();
    private final GatewayPaymentService paymentService = new GatewayPaymentService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Map<String, String> params = RequestParams.collect(req);

        String txnRef = params.get("vnp_TxnRef");
        OnlineBooking booking = findCounterBooking(req, txnRef);
        if (booking == null) {
            flash(req, "error", "Không tìm thấy đơn hàng tại quầy tương ứng với giao dịch này.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }

        GatewayPaymentService.Result result = paymentService.confirmPayment(params);
        if (result.isSuccess()) {
            // Ghi lại booking_id vào phiên để màn hình hóa đơn tìm thấy đơn
            // (phiên có thể đã bị thay thế trong lúc chuyển sang cổng thanh toán).
            HttpSession session = req.getSession(true);
            session.setAttribute(SESSION_BOOKING, booking.getBookingId());
            session.removeAttribute(SESSION_SHOWTIME);
            flash(req, "success", result.getMessage());
            resp.sendRedirect(req.getContextPath() + "/staff/counter?action=success");
            return;
        }
        flash(req, "error", result.getMessage());
        resp.sendRedirect(req.getContextPath() + "/staff/counter");
    }

    /**
     * Tra đơn tại quầy theo mã đơn và kiểm tra quyền của người đang xử lý.
     *
     * @param req request hiện tại (để đọc phiên nhân viên đang đăng nhập)
     * @param txnRef mã đơn do cổng thanh toán gửi về
     * @return đơn hợp lệ, null nếu không tồn tại / sai kênh / sai nhân viên
     */
    private OnlineBooking findCounterBooking(HttpServletRequest req, String txnRef) {
        if (txnRef == null || txnRef.trim().isEmpty()) {
            return null;
        }
        OnlineBooking booking;
        try {
            booking = dao.findCounterBookingByCode(txnRef);
        } catch (SQLException e) {
            getServletContext().log("Counter payment return: tra don that bai", e);
            return null;
        }
        if (booking == null || !booking.isCounterChannel()) {
            // Không phải đơn bán tại quầy → không được xác nhận ở kênh này.
            return null;
        }
        User user = currentUser(req);
        if (user != null) {
            Integer staffAccountId = staffAccountIdOf(user);
            if (staffAccountId != null && booking.getStaffAccountId() != null
                    && !staffAccountId.equals(booking.getStaffAccountId())) {
                // Đơn do nhân viên khác bán → nhân viên này không được xác nhận.
                return null;
            }
        }
        return booking;
    }

    /** Tra account_id của nhân viên đang đăng nhập (null nếu không có trong Account). */
    private Integer staffAccountIdOf(User user) {
        try {
            int id = dao.findAccountIdByEmail(user.getEmail());
            return id == 0 ? null : id;
        } catch (SQLException e) {
            getServletContext().log("Counter payment return: tra staff_id that bai", e);
            return null;
        }
    }
}
