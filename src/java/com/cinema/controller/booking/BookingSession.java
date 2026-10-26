package com.cinema.controller.booking;

import com.cinema.model.OnlineBooking;
import com.cinema.model.SeatCell;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.Validator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Tiện ích nhỏ cho luồng đặt vé online: đọc/ghi trạng thái phiên đặt vé.
 *
 * <p>Phiên đặt vé giữ {@code bookingId} và {@code showtimeId} trong session
 * giữa các bước (chọn ghế → combo/voucher/điểm → thanh toán).</p>
 */
public final class BookingSession {

    /** Khóa session chứa booking_id hiện tại. */
    public static final String BOOKING_ID = "onlineBookingId";

    private BookingSession() {
    }

    public static Integer bookingId(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (Integer) s.getAttribute(BOOKING_ID);
    }

    public static void set(HttpServletRequest req, int bookingId) {
        HttpSession s = req.getSession();
        s.setAttribute(BOOKING_ID, bookingId);
    }

    public static void clear(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s != null) {
            s.removeAttribute(BOOKING_ID);
        }
    }

    /**
     * Gom ghế theo hàng để vẽ sơ đồ.
     */
    public static List<List<SeatCell>> groupByRow(List<SeatCell> seats) {
        Map<String, List<SeatCell>> rows = new LinkedHashMap<>();
        for (SeatCell s : seats) {
            rows.computeIfAbsent(s.getRowLabel(), k -> new ArrayList<>()).add(s);
        }
        return new ArrayList<>(rows.values());
    }

    /**
     * Chuẩn hoá danh sách id ghế do client gửi lên: "41, 42,abc" → "41,42".
     */
    public static String cleanSeatIds(String raw) {
        StringBuilder sb = new StringBuilder();
        for (String part : Validator.trim(raw).split(",")) {
            String p = part.trim();
            if (p.matches("\\d+")) {
                if (sb.length() > 0) {
                    sb.append(',');
                }
                sb.append(p);
            }
        }
        return sb.toString();
    }

    /**
     * Đọc đơn hiện tại của người đang đăng nhập từ session (null nếu không có).
     */
    public static OnlineBooking currentBooking(HttpServletRequest req, OnlineBookingService service) {
        Integer id = bookingId(req);
        if (id == null) {
            return null;
        }
        String email = currentEmail(req);
        return email == null ? null : service.findOwnedBooking(id, email);
    }

    /** Email của người đang đăng nhập (null nếu chưa đăng nhập). */
    public static String currentEmail(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) {
            return null;
        }
        Object user = s.getAttribute(com.cinema.controller.BaseServlet.SESSION_USER);
        if (user instanceof com.cinema.model.User) {
            return ((com.cinema.model.User) user).getEmail();
        }
        return null;
    }
}
