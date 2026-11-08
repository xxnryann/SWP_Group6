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

/** Cổng thanh toán chuyển khách hàng về sau khi thanh toán (UC15). */
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
