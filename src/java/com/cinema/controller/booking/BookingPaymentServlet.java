package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import com.cinema.model.OnlineBooking;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Bước 3 của luồng đặt vé online: tổng tiền + đếm ngược + chuyển sang cổng thanh toán.
 *
 * <ul>
 *   <li>GET /booking/payment → tóm tắt đơn + đồng hồ đếm ngược tới payment_expires_at</li>
 *   <li>POST /booking/payment (action=pay) → dựng URL cổng thanh toán rồi chuyển hướng</li>
 *   <li>POST /booking/payment (action=cancel) → huỷ đơn, trả ghế về trạng thái trống</li>
 * </ul>
 */
@WebServlet("/booking/payment")
public class BookingPaymentServlet extends BaseServlet {

    private final OnlineBookingService service = new OnlineBookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        OnlineBooking booking = BookingSession.currentBooking(req, service);
        if (booking == null) {
            flash(req, "error", "Phiên đặt vé đã hết hạn. Vui lòng chọn ghế lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        if (!booking.isPendingPayment()) {
            BookingSession.clear(req);
            flash(req, "error", booking.isPaymentExpired()
                    ? "Đơn đặt vé đã hết thời gian chờ thanh toán. Vui lòng đặt vé lại."
                    : "Đơn đặt vé không còn hiệu lực. Vui lòng đặt vé lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        render(req, resp, booking);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        OnlineBooking booking = BookingSession.currentBooking(req, service);
        if (booking == null || !booking.isPendingPayment()) {
            BookingSession.clear(req);
            flash(req, "error", "Đơn đặt vé không còn hiệu lực. Vui lòng đặt vé lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        String action = Validator.trim(req.getParameter("action"));
        if ("cancel".equals(action)) {
            service.cancelBooking(booking.getBookingId());
            BookingSession.clear(req);
            flash(req, "success", "Đã huỷ đơn. Ghế đã được trả lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        if (!"pay".equals(action)) {
            resp.sendRedirect(req.getContextPath() + "/booking/payment");
            return;
        }
        if (booking.isPaymentExpired()) {
            service.releaseExpiredHolds();
            BookingSession.clear(req);
            flash(req, "error",
                    "Đơn đặt vé đã hết thời gian chờ thanh toán (tối đa 5 phút). Vui lòng đặt vé lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        String returnUrl = req.getContextPath() + "/booking/payment/return";
        String url = service.buildPaymentUrl(booking, req.getRemoteAddr(),
                req.getContextPath(), returnUrl);
        resp.sendRedirect(url);
    }

    private void render(HttpServletRequest req, HttpServletResponse resp, OnlineBooking booking)
            throws ServletException, IOException {
        req.setAttribute("booking", booking);
        req.setAttribute("remainingSeconds", booking.getRemainingSeconds());
        req.setAttribute("pageTitle", "Đặt vé — Thanh toán");
        forward(req, resp, "booking/booking-payment");
    }
}
