package com.cinema.controller.booking;

import com.cinema.model.OnlineBooking;
import com.cinema.model.SeatCell;
import com.cinema.model.SeatRowLegend;
import com.cinema.model.SeatTypeInfo;
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
     * Tóm tắt từng hàng ghế: hàng nào thuộc loại ghế nào, có bao nhiêu ghế,
     * khoảng ghế và giá vé của loại ghế đó.
     *
     * <p>Loại ghế lấy theo ghế đầu tiên của hàng (mỗi hàng trong hệ thống hiện
     * dùng chung một loại ghế — quản trị đổi loại theo cả hàng).</p>
     *
     * @param rows        ghế đã group theo hàng
     * @param typesByName map loại ghế theo tên (key = {@code SeatType.type_name})
     * @return danh sách chú thích theo thứ tự hàng hiển thị
     */
    public static List<SeatRowLegend> buildRowLegends(List<List<SeatCell>> rows,
            Map<String, SeatTypeInfo> typesByName) {
        List<SeatRowLegend> legends = new ArrayList<>();
        if (rows == null) {
            return legends;
        }
        for (List<SeatCell> row : rows) {
            if (row == null || row.isEmpty()) {
                continue;
            }
            SeatCell first = row.get(0);
            SeatRowLegend legend = new SeatRowLegend();
            legend.setRowLabel(first.getRowLabel());
            legend.setSeatTypeName(first.getSeatType());
            legend.setSeatCount(row.size());

            int min = Integer.MAX_VALUE;
            int max = Integer.MIN_VALUE;
            for (SeatCell s : row) {
                min = Math.min(min, s.getSeatNumber());
                max = Math.max(max, s.getSeatNumber());
            }
            legend.setFirstSeat(min == Integer.MAX_VALUE ? 0 : min);
            legend.setLastSeat(max == Integer.MIN_VALUE ? 0 : max);

            SeatTypeInfo type = typesByName == null ? null : typesByName.get(first.getSeatType());
            if (type != null) {
                legend.setCouple(type.isCouple());
                legend.setPrice(type.getPrice());
            } else {
                legend.setCouple(first.isCouple());
            }
            legends.add(legend);
        }
        return legends;
    }

    /**
     * Gắn dữ liệu sơ đồ ghế + chú thích loại ghế vào request (dùng chung cho
     * đặt vé online và bán vé tại quầy).
     *
     * <p>Chú thích gồm: danh sách loại ghế kèm giá vé của suất chiếu, và map
     * chú thích theo hàng dùng để gắn tooltip lên nhãn hàng trong sơ đồ ghế.</p>
     */
    public static void applySeatGuide(HttpServletRequest req, OnlineBookingService service,
            int showtimeId, List<SeatCell> seats) {
        List<SeatTypeInfo> seatTypes = service.getSeatTypesWithPrice(showtimeId);
        Map<String, SeatTypeInfo> typesByName = new LinkedHashMap<>();
        for (SeatTypeInfo t : seatTypes) {
            if (t.getTypeName() != null) {
                typesByName.put(t.getTypeName(), t);
            }
        }
        List<List<SeatCell>> rows = groupByRow(seats);
        Map<String, SeatRowLegend> legendByRow = new LinkedHashMap<>();
        for (SeatRowLegend lg : buildRowLegends(rows, typesByName)) {
            if (lg.getRowLabel() != null) {
                legendByRow.put(lg.getRowLabel(), lg);
            }
        }
        req.setAttribute("seatRows", rows);
        req.setAttribute("seatTypes", seatTypes);
        req.setAttribute("rowLegendMap", legendByRow);
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
