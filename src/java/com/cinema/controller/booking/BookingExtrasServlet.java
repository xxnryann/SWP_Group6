package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import com.cinema.model.OnlineBooking;
import com.cinema.model.PointConfig;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Bước 2 của luồng đặt vé online: combo → voucher → MyPoint.
 *
 * <p>Thứ tự áp dụng đúng theo nghiệp vụ: <b>voucher trước, MyPoint sau</b> —
 * vì áp voucher sẽ reset số điểm đã dùng trước đó (xem DiscountService).</p>
 */
@WebServlet("/booking/extras")
public class BookingExtrasServlet extends BaseServlet {

    private final OnlineBookingService service = new OnlineBookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        OnlineBooking booking = BookingSession.currentBooking(req, service);
        if (booking == null) {
            flash(req, "error", "Phiên đặt vé đã hết hạn hoặc không tồn tại. Vui lòng chọn ghế lại.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        if (!booking.isPendingPayment()) {
            BookingSession.clear(req);
            flash(req, "error", "Đơn đặt vé không còn hiệu lực. Vui lòng đặt vé lại.");
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
        try {
            switch (action) {
                case "updateCombos":
                    updateCombos(req, booking);
                    break;
                case "applyDiscount":
                    applyDiscount(req, booking);
                    break;
                case "back":
                    // Quay lại chọn ghế: huỷ đơn đang giữ để nhả ghế, tránh tự chặn chính mình khi chọn lại.
                    service.cancelBooking(booking.getBookingId());
                    BookingSession.clear(req);
                    resp.sendRedirect(req.getContextPath() + "/booking/seats?showtimeId=" + booking.getShowtimeId());
                    return;
                case "next":
                    resp.sendRedirect(req.getContextPath() + "/booking/payment");
                    return;
                default:
                    break;
            }
        } catch (Exception e) {
            flash(req, "error", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/booking/extras");
    }

    /** Cập nhật combo của đơn (số lượng 0 = bỏ combo). */
    private void updateCombos(HttpServletRequest req, OnlineBooking booking) throws Exception {
        String[] ids = req.getParameterValues("comboId");
        String[] qtys = req.getParameterValues("qty");
        if (ids == null || qtys == null || ids.length != qtys.length) {
            return;
        }
        for (int i = 0; i < ids.length; i++) {
            int comboId = parseInt(ids[i]);
            int qty = Math.max(0, parseInt(qtys[i]));
            if (comboId <= 0) {
                continue;
            }
            try {
                service.updateCombo(booking.getBookingId(), comboId, qty);
            } catch (Exception e) {
                // Ví dụ: không đủ tồn kho → báo ngay, giữ nguyên các combo đã cập nhật
                flash(req, "error", e.getMessage());
                return;
            }
        }
        flash(req, "success", "Đã cập nhật combo.");
    }

    /** Áp voucher rồi MyPoint. */
    private void applyDiscount(HttpServletRequest req, OnlineBooking booking) {
        String code = Validator.trim(req.getParameter("voucherCode"));
        int points = Math.max(0, parseInt(req.getParameter("points")));
        OnlineBookingService.StepResult result = service.applyExtras(
                booking.getBookingId(), code, points);
        flash(req, result.isSuccess() ? "success" : "error", result.getMessage());
    }

    private void render(HttpServletRequest req, HttpServletResponse resp, OnlineBooking booking)
            throws ServletException, IOException {
        Map<Integer, Integer> comboQty = new LinkedHashMap<>();
        for (OnlineBooking.ComboLine cl : booking.getComboLines()) {
            comboQty.put(cl.getComboId(), cl.getQuantity());
        }
        PointConfig pointConfig = service.getPointConfig();
        int accountId = booking.getCustomerId();
        int balance = service.getPointBalance(accountId);

        req.setAttribute("booking", booking);
        req.setAttribute("combos", service.getActiveCombos());
        req.setAttribute("comboQty", comboQty);
        req.setAttribute("pointConfig", pointConfig);
        req.setAttribute("pointBalance", balance);
        req.setAttribute("pageTitle", "Đặt vé — Combo & ưu đãi");
        forward(req, resp, "booking/booking-extras");
    }

    private int parseInt(String raw) {
        try {
            return Integer.parseInt(Validator.trim(raw));
        } catch (Exception e) {
            return 0;
        }
    }
}
