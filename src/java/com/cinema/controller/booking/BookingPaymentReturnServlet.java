package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.RequestParams;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

/**
 * Cổng thanh toán chuyển khách hàng về sau khi thanh toán (UC15).
 *
 * <p>Đây là đường xác nhận thanh toán ở môi trường local: cổng gửi kèm chữ
 * ký HMAC-SHA512 trong query string, ta kiểm tra chữ ký và đối soát số tiền
 * trước khi ghi nhận đơn hàng là đã thanh toán. Đơn hàng chỉ chuyển sang
 * trạng thái {@code Paid} khi bước này hoàn tất — không có chuyện tự xác nhận
 * thành công.</p>
 *
 * <p>Endpoint này nằm trong {@code /booking/*} nhưng được
 * {@code BookingAuthFilter} cố ý bỏ qua: cổng thanh toán gọi bằng GET và
 * không mang cookie phiên làm bắt buộc. Việc tra cứu đơn dựa trên
 * {@code vnp_TxnRef} (= mã đơn) chứ không dựa vào session, nên vẫn an toàn.</p>
 */
@WebServlet("/booking/payment/return")
public class BookingPaymentReturnServlet extends BaseServlet {

    private final OnlineBookingService service = new OnlineBookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Map<String, String> params = RequestParams.collect(req);

        OnlineBookingService.StepResult result = service.confirmGatewayPayment(params);
        if (result.isSuccess()) {
            BookingSession.clear(req);
            flash(req, "success", result.getMessage());
            resp.sendRedirect(req.getContextPath() + "/account/tickets");
            return;
        }
        flash(req, "error", result.getMessage());
        resp.sendRedirect(req.getContextPath() + "/booking/cancel-result");
    }
}
