package com.cinema.controller.room;

import com.cinema.dao.RoomDAO;
import com.cinema.model.Room;
import com.cinema.model.RoomShowtime;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Lịch phòng chiếu (Admin) — xem từng phòng chiếu và các suất chiếu phòng đó đang có.
 *
 * URL: /admin/room-showtimes
 *   GET ?roomId=N            phòng được chọn (mặc định: phòng đầu tiên)
 *       &scope=upcoming|past|all   phạm vi suất chiếu (mặc định upcoming)
 *       &date=yyyy-MM-dd|all       lọc theo ngày (mặc định: ngày đầu tiên có suất)
 * Trang chỉ đọc; thêm/sửa suất chiếu vẫn do Manager thực hiện ở /manage/showtimes.
 */
@WebServlet("/admin/room-showtimes")
public class RoomShowtimesServlet extends AdminBaseServlet {

    private static final String[] WEEKDAYS = {"Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ nhật"};
    private static final DateTimeFormatter DAY_MONTH = DateTimeFormatter.ofPattern("dd/MM");
    private static final DateTimeFormatter FULL_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final RoomDAO roomDAO = new RoomDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }
        if ("schedule".equals(req.getParameter("action"))) {
            writeSchedule(req, resp);
            return;
        }
        try {
            List<Room> rooms = roomDAO.findAll(null, null);
            Integer roomId = intParam(req, "roomId");
            Room room = null;
            for (Room r : rooms) {
                if (roomId == null || r.getRoomId() == roomId) {
                    room = r;
                    break;
                }
            }
            if (roomId != null && room == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
                return;
            }

            String scope = req.getParameter("scope");
            if (!"past".equals(scope) && !"all".equals(scope)) {
                scope = "upcoming";
            }

            req.setAttribute("rooms", rooms);
            req.setAttribute("room", room);
            req.setAttribute("scope", scope);
            req.setAttribute("pageTitle", "Lịch phòng chiếu");
            req.setAttribute("parentTitle", "Quản lý phòng chiếu");
            req.setAttribute("parentUrl", req.getContextPath() + "/admin/rooms");

            if (room != null) {
                List<RoomShowtime> showtimes = roomDAO.findShowtimes(room.getRoomId(), scope);
                fillDays(req, showtimes, scope);
            }
            forward(req, resp, "room/room-showtimes");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    /** JSON lịch tất cả các phòng trong một ngày cho timeline "Lịch các phòng". */
    private void writeSchedule(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        LocalDate date;
        try {
            date = LocalDate.parse(req.getParameter("date"));
        } catch (RuntimeException e) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ngày không hợp lệ.");
            return;
        }
        try {
            String body = com.cinema.util.showtime.RoomScheduleJson.build(new com.cinema.dao.ShowtimeDAO(), date);
            resp.setContentType("application/json;charset=UTF-8");
            resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            resp.getWriter().write(body);
        } catch (SQLException e) {
            getServletContext().log("Unable to load room schedule.", e);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải lịch phòng.");
        }
    }

    /** Nhóm suất chiếu theo ngày, chọn ngày đang xem và tính số liệu tóm tắt. */
    private void fillDays(HttpServletRequest req, List<RoomShowtime> showtimes, String scope) {
        Map<LocalDate, DayGroup> byDay = new LinkedHashMap<>();
        Set<Integer> movies = new HashSet<>();
        int sold = 0;
        int cancelled = 0;
        for (RoomShowtime st : showtimes) {
            byDay.computeIfAbsent(st.getShowDate(), DayGroup::new).getShowtimes().add(st);
            movies.add(st.getMovieId());
            sold += st.getSoldTickets();
            if ("CANCELLED".equals(st.getPhase())) {
                cancelled++;
            }
        }

        LocalDate today = LocalDate.now();
        String dateParam = req.getParameter("date");
        LocalDate selected = null;
        boolean showAll = "all".equals(dateParam);
        if (!showAll && dateParam != null && !dateParam.isEmpty()) {
            try {
                selected = LocalDate.parse(dateParam);
            } catch (DateTimeParseException ignored) {
                selected = null;
            }
        }
        if (!showAll && (selected == null || !byDay.containsKey(selected))) {
            selected = byDay.containsKey(today) ? today
                    : (byDay.isEmpty() ? null : byDay.keySet().iterator().next());
        }

        List<DayGroup> days = new ArrayList<>(byDay.values());
        List<DayGroup> visible = new ArrayList<>();
        for (DayGroup d : days) {
            d.setToday(d.getDate().equals(today));
            d.setSelected(!showAll && d.getDate().equals(selected));
            if (showAll || d.isSelected()) {
                visible.add(d);
            }
        }

        req.setAttribute("days", days);
        // Ngày vẽ timeline "Lịch các phòng": ngày đang chọn, nếu xem "Mọi ngày" thì hôm nay.
        req.setAttribute("scheduleDate", (selected != null ? selected : today).toString());
        req.setAttribute("visibleDays", visible);
        req.setAttribute("showAllDays", showAll);
        req.setAttribute("totalShowtimes", showtimes.size());
        req.setAttribute("totalSold", sold);
        req.setAttribute("totalMovies", movies.size());
        req.setAttribute("totalCancelled", cancelled);
    }

    /** Một ngày trong lịch phòng — public để JSP/EL đọc được getter. */
    public static class DayGroup {
        private final LocalDate date;
        private final List<RoomShowtime> showtimes = new ArrayList<>();
        private boolean today;
        private boolean selected;

        DayGroup(LocalDate date) {
            this.date = date;
        }

        public LocalDate getDate() { return date; }
        public List<RoomShowtime> getShowtimes() { return showtimes; }
        public int getCount() { return showtimes.size(); }
        public String getIso() { return date.toString(); }
        public String getDayMonth() { return date.format(DAY_MONTH); }
        public String getFullDate() { return date.format(FULL_DATE); }
        public String getWeekday() { return WEEKDAYS[date.getDayOfWeek().getValue() - 1]; }
        public boolean isToday() { return today; }
        void setToday(boolean today) { this.today = today; }
        public boolean isSelected() { return selected; }
        void setSelected(boolean selected) { this.selected = selected; }
    }
}
