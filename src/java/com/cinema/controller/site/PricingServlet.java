package com.cinema.controller.site;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.PricingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Bảng giá vé công khai (đọc động từ TicketPrice / TimeSlot / RoomType / Holiday). URL: /pricing
 * Trang trình bày bằng hình: loại ghế, thanh 24 giờ theo khung giá, tuần + ngày lễ, loại phòng.
 */
@WebServlet("/pricing")
public class PricingServlet extends BaseServlet {

    private static final String[] WEEKDAY_VN = {"Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật"};
    private static final int DAY_MIN = 24 * 60;
    private final PricingDAO dao = new PricingDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            List<Map<String, Object>> slots = buildSlots(req, dao.timeSlots());
            List<Map<String, Object>> groups = buildSeatGroups(dao.priceMatrix());
            List<Map<String, Object>> rooms = dao.roomTypes();
            req.setAttribute("seatGroups", groups);
            BigDecimal min = null;
            for (Map<String, Object> g : groups) {
                BigDecimal v = (BigDecimal) g.get("min");
                if (v != null && (min == null || v.compareTo(min) < 0)) min = v;
            }
            req.setAttribute("minPrice", min);
            req.setAttribute("roomTypes", rooms);
            buildHolidays(req, dao.holidays());

            Map<String, Object> now = dao.now();
            LocalDate today = LocalDate.now();
            req.setAttribute("nowDayType", now.get("day_type"));
            req.setAttribute("nowSlotId", now.get("slot_id"));
            req.setAttribute("todayIndex", today.getDayOfWeek().getValue() - 1);
            req.setAttribute("todayLabel", WEEKDAY_VN[today.getDayOfWeek().getValue() - 1] + ", "
                    + today.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
            LocalTime t = LocalTime.now();
            req.setAttribute("nowPct", pct(t.getHour() * 60 + t.getMinute()));
            req.setAttribute("nowTime", t.format(DateTimeFormatter.ofPattern("HH:mm")));
            buildExample(req, groups, slots, rooms);
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        req.setAttribute("pageTitle", "Bảng giá vé");
        forward(req, resp, "site/pricing");
    }

    /** Khung giờ + các đoạn trên thanh 24 giờ (khung qua nửa đêm tách thành 2 đoạn). */
    private List<Map<String, Object>> buildSlots(HttpServletRequest req, List<Map<String, Object>> rows) {
        List<Map<String, Object>> segments = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            Map<String, Object> s = rows.get(i);
            int start = minutes(String.valueOf(s.get("slot_from")));
            int end = minutes(String.valueOf(rows.get((i + 1) % rows.size()).get("slot_from")));
            if (rows.size() == 1) end = start;
            boolean overnight = end <= start;
            boolean night = overnight || start >= 18 * 60;
            s.put("night", night);
            s.put("overnight", overnight);
            s.put("slot_to", rows.size() == 1 ? s.get("slot_from") : rows.get((i + 1) % rows.size()).get("slot_from"));
            int len = overnight ? DAY_MIN - start + end : end - start;
            s.put("hours", len / 60);
            if (overnight) {
                if (start < DAY_MIN) segments.add(segment(s, start, DAY_MIN, night));
                if (end > 0) segments.add(segment(s, 0, end, night));
            } else {
                segments.add(segment(s, start, end, night));
            }
        }
        segments.sort((a, b) -> Double.compare((Double) a.get("left"), (Double) b.get("left")));
        req.setAttribute("slots", rows);
        req.setAttribute("segments", segments);
        return rows;
    }

    private static Map<String, Object> segment(Map<String, Object> slot, int from, int to, boolean night) {
        Map<String, Object> m = new HashMap<>();
        m.put("name", slot.get("slot_name"));
        m.put("night", night);
        m.put("left", pct(from));
        m.put("width", pct(to - from));
        m.put("from", String.format("%02d:%02d", from / 60, from % 60));
        m.put("to", to == DAY_MIN ? "24:00" : String.format("%02d:%02d", to / 60, to % 60));
        return m;
    }

    /** Gom giá theo loại ghế; mỗi loại có "từ … đ" và lớp màu minh họa. */
    private List<Map<String, Object>> buildSeatGroups(List<Map<String, Object>> matrix) {
        Map<Object, Map<String, Object>> groups = new LinkedHashMap<>();
        for (Map<String, Object> row : matrix) {
            Map<String, Object> g = groups.computeIfAbsent(row.get("seat_type_id"), k -> {
                Map<String, Object> m = new HashMap<>();
                String name = String.valueOf(row.get("type_name"));
                boolean couple = Boolean.TRUE.equals(row.get("is_couple"));
                m.put("id", row.get("seat_type_id"));
                m.put("name", name);
                m.put("label", couple ? "Ghế đôi" : "Standard".equalsIgnoreCase(name) ? "Ghế thường" : "Ghế " + name);
                m.put("desc", row.get("type_desc"));
                m.put("couple", couple);
                m.put("kind", couple ? "cpl" : "VIP".equalsIgnoreCase(name) ? "vip" : "std");
                m.put("rows", new ArrayList<Map<String, Object>>());
                return m;
            });
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rows = (List<Map<String, Object>>) g.get("rows");
            rows.add(row);
            for (String k : new String[]{"weekday", "weekend", "holiday"}) {
                BigDecimal v = (BigDecimal) row.get(k);
                BigDecimal min = (BigDecimal) g.get("min");
                if (v != null && (min == null || v.compareTo(min) < 0)) g.put("min", v);
            }
        }
        return new ArrayList<>(groups.values());
    }

    /** 4 ngày lễ sắp tới (ngày lặp hằng năm tính lần kế tiếp). */
    private void buildHolidays(HttpServletRequest req, List<Map<String, Object>> rows) {
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> list = new ArrayList<>();
        for (Map<String, Object> h : rows) {
            LocalDate d = (LocalDate) h.get("holiday_date");
            if (Boolean.TRUE.equals(h.get("is_recurring")) && d.isBefore(today)) {
                d = d.withYear(today.getYear());
                if (d.isBefore(today)) d = d.plusYears(1);
            }
            if (d.isBefore(today)) continue;
            Map<String, Object> m = new HashMap<>();
            m.put("name", h.get("holiday_name"));
            m.put("date", d);
            m.put("day", d.getDayOfMonth());
            m.put("month", d.getMonthValue());
            m.put("weekday", WEEKDAY_VN[d.getDayOfWeek().getValue() - 1]);
            m.put("days_until", ChronoUnit.DAYS.between(today, d));
            list.add(m);
        }
        list.sort((a, b) -> ((LocalDate) a.get("date")).compareTo((LocalDate) b.get("date")));
        req.setAttribute("holidays", list.size() > 4 ? list.subList(0, 4) : list);
    }

    /** Ví dụ tính giá: ghế thứ 2 (thường là VIP), suất 20:00 Thứ Bảy, phòng có phụ thu đầu tiên. */
    private void buildExample(HttpServletRequest req, List<Map<String, Object>> groups,
                              List<Map<String, Object>> slots, List<Map<String, Object>> rooms) {
        if (groups.isEmpty() || slots.isEmpty()) return;
        Map<String, Object> seat = groups.get(Math.min(1, groups.size() - 1));
        int at = 20 * 60;
        Map<String, Object> slot = slots.get(slots.size() - 1);           // khung bắt đầu muộn nhất (vòng qua đêm)
        for (Map<String, Object> s : slots) {
            if (minutes(String.valueOf(s.get("slot_from"))) <= at) slot = s;
        }
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> rows = (List<Map<String, Object>>) seat.get("rows");
        BigDecimal base = null;
        for (Map<String, Object> r : rows) {
            if (r.get("slot_id").equals(slot.get("slot_id"))) base = (BigDecimal) r.get("weekend");
        }
        if (base == null) return;
        Map<String, Object> room = null;
        for (Map<String, Object> r : rooms) {
            if (((BigDecimal) r.get("surcharge")).signum() > 0) { room = r; break; }
        }
        if (room == null && !rooms.isEmpty()) room = rooms.get(0);
        BigDecimal sur = room == null ? BigDecimal.ZERO : (BigDecimal) room.get("surcharge");
        Map<String, Object> ex = new HashMap<>();
        ex.put("seat", seat.get("label"));
        ex.put("kind", seat.get("kind"));
        ex.put("slot", slot.get("slot_name"));
        ex.put("night", slot.get("night"));
        ex.put("time", "20:00");
        ex.put("room", room == null ? "2D" : room.get("type_code"));
        ex.put("base", base);
        ex.put("surcharge", sur);
        ex.put("total", base.add(sur));
        req.setAttribute("example", ex);
    }

    private static int minutes(String hhmm) {
        String[] p = hhmm.split(":");
        return Integer.parseInt(p[0]) * 60 + Integer.parseInt(p[1]);
    }

    private static double pct(int minutes) {
        return Math.round(minutes * 10000.0 / DAY_MIN) / 100.0;
    }
}
