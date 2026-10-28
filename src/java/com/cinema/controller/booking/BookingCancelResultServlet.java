package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Trang kết quả thất bại / huỷ / hết hạn của luồng đặt vé online.
 */
@WebServlet("/booking/cancel-result")
public class BookingCancelResultServlet extends BaseServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("pageTitle", "Đặt vé — Thanh toán không thành công");
        forward(req, resp, "booking/booking-cancel-result");
    }
}
