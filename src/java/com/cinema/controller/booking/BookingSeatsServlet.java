package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import com.cinema.model.SeatCell;
import com.cinema.model.SeatRowLegend;
import com.cinema.model.SeatTypeInfo;
import com.cinema.model.ShowtimeInfo;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Bước 1 của luồng đặt vé online: chọn suất chiếu + chọn ghế.
 *
 * <ul>
 *   <li>GET /booking/seats?showtimeId=… → sơ đồ ghế (màu từ vw_SeatMap)</li>
 *   <li>POST /booking/seats → mở phiên đặt vé (sp_CreateBooking) + giữ ghế (sp_HoldSeats)</li>
 * </ul>
 *
 * <p>Phân quyền do {@link BookingAuthFilter} lo (bắt buộc đăng nhập, role CUSTOMER).</p>
 */
@WebServlet("/booking/seats")
public class BookingSeatsServlet extends BaseServlet {

    private final OnlineBookingService service = new OnlineBookingService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int showtimeId = parseInt(req.getParameter("showtimeId"), 0);
        ShowtimeInfo show = showtimeId > 0 ? service.getShowtime(showtimeId) : null;
        if (show == null) {
            flash(req, "error", "Suất chiếu không tồn tại hoặc đã bắt đầu.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        List<SeatCell> seats = service.getSeatMap(showtimeId);
        req.setAttribute("showtime", show);
        applySeatGuide(req, showtimeId, seats);
        req.setAttribute("pageTitle", "Đặt vé — Chọn ghế");
        forward(req, resp, "booking/booking-seats");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        int showtimeId = parseInt(req.getParameter("showtimeId"), 0);
        String seatIds = BookingSession.cleanSeatIds(req.getParameter("seatIds"));
        if (showtimeId <= 0 || seatIds.isEmpty()) {
            flash(req, "error", "Vui lòng chọn ít nhất một ghế.");
            resp.sendRedirect(req.getContextPath() + "/booking/seats?showtimeId=" + showtimeId);
            return;
        }
        String email = BookingSession.currentEmail(req);
        int bookingId = service.createBooking(email, showtimeId);
        if (bookingId <= 0) {
            flash(req, "error",
                    "Không thể mở phiên đặt vé. Suất chiếu có thể đã bắt đầu hoặc bị hủy.");
            resp.sendRedirect(req.getContextPath() + "/showtimes");
            return;
        }
        try {
            service.holdSeats(bookingId, seatIds);
        } catch (SQLException e) {
            // Phiên vừa mở nhưng giữ ghế thất bại (ghế trùng/ghế đôi/bảo trì).
            service.cancelBooking(bookingId);
            req.setAttribute("error", e.getMessage());
            req.setAttribute("showtime", service.getShowtime(showtimeId));
            applySeatGuide(req, showtimeId, service.getSeatMap(showtimeId));
            req.setAttribute("pageTitle", "Đặt vé — Chọn ghế");
            forward(req, resp, "booking/booking-seats");
            return;
        }
        BookingSession.set(req, bookingId);
        resp.sendRedirect(req.getContextPath() + "/booking/extras");
    }

    private int parseInt(String raw, int dflt) {
        try {
            return Integer.parseInt(Validator.trim(raw));
        } catch (Exception e) {
            return dflt;
        }
    }

    /**
     * Gắn dữ liệu sơ đồ ghế + chú thích loại ghế vào request.
     *
     * <p>Chú thích gồm: danh sách loại ghế kèm giá vé của suất chiếu, và map
     * chú thích theo hàng dùng để gắn tooltip lên nhãn hàng trong sơ đồ ghế.</p>
     */
    private void applySeatGuide(HttpServletRequest req, int showtimeId, List<SeatCell> seats) {
        List<SeatTypeInfo> seatTypes = service.getSeatTypesWithPrice(showtimeId);
        List<List<SeatCell>> rows = BookingSession.groupByRow(seats);
        req.setAttribute("seatRows", rows);
        req.setAttribute("seatTypes", seatTypes);
        req.setAttribute("rowLegendMap",
                legendByRow(BookingSession.buildRowLegends(rows, typesByName(seatTypes))));
    }

    /** Map chú thích theo nhãn hàng (key = {@code row_label}) để JSP gắn tooltip. */
    private Map<String, SeatRowLegend> legendByRow(List<SeatRowLegend> legends) {
        Map<String, SeatRowLegend> map = new LinkedHashMap<>();
        for (SeatRowLegend lg : legends) {
            if (lg.getRowLabel() != null) {
                map.put(lg.getRowLabel(), lg);
            }
        }
        return map;
    }

    /** Map loại ghế theo tên (key = {@code SeatType.type_name}). */
    private Map<String, SeatTypeInfo> typesByName(List<SeatTypeInfo> seatTypes) {
        Map<String, SeatTypeInfo> map = new LinkedHashMap<>();
        for (SeatTypeInfo t : seatTypes) {
            if (t.getTypeName() != null) {
                map.put(t.getTypeName(), t);
            }
        }
        return map;
    }
}
