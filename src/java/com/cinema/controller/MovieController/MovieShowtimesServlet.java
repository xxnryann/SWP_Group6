package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.util.Rows;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Lịch chiếu của một phim cho cửa sổ "Mua vé" ở danh sách phim: GET /movies/showtimes?id=N → JSON.
 *
 * <ul>
 *   <li>Phim đang chiếu: các ngày còn suất chiếu trong 7 ngày tới (mỗi ngày một tab).</li>
 *   <li>Phim sắp chiếu: chỉ ngày chiếu gần nhất.</li>
 *   <li>Phim ngừng chiếu hoặc không còn suất: 404 (không có nút mua vé).</li>
 * </ul>
 */
@WebServlet("/movies/showtimes")
public class MovieShowtimesServlet extends BaseServlet {

    private static final int MAX_DAYS_NOW_SHOWING = 7;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int movieId = safeId(req.getParameter("id"));
        if (movieId < 0) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        try {
            List<Map<String, Object>> movies = Rows.query(
                    "SELECT title, status, spoken_language FROM Movie WHERE movie_id = ?", movieId);
            if (movies.isEmpty() || "Stopped".equals(movies.get(0).get("status"))) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            Map<String, Object> movie = movies.get(0);
            List<Map<String, Object>> rows = Rows.query(
                    "SELECT s.showtime_id, CONVERT(VARCHAR(10), s.show_date, 120) AS d, "
                    + "CONVERT(VARCHAR(5), s.start_time, 108) AS t, r.room_type, c.cinema_name, "
                    + "(SELECT COUNT(*) FROM vw_SeatMap v WHERE v.showtime_id = s.showtime_id AND v.color = 'GREEN') AS free_seats "
                    + "FROM Showtime s JOIN Room r ON r.room_id = s.room_id JOIN Cinema c ON c.cinema_id = r.cinema_id "
                    + "WHERE s.movie_id = ? AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() "
                    + "ORDER BY s.start_time", movieId);
            if (rows.isEmpty()) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            boolean upcoming = "Upcoming".equals(movie.get("status"));
            int maxDays = upcoming ? 1 : MAX_DAYS_NOW_SHOWING;
            resp.setContentType("application/json;charset=UTF-8");
            resp.setHeader("Cache-Control", "no-store");
            resp.getWriter().write(toJson(movie, rows, maxDays, upcoming));
        } catch (SQLException e) {
            getServletContext().log("Cannot load showtimes of movie " + movieId, e);
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }

    /** ngày → định dạng → danh sách suất, giữ thứ tự thời gian. */
    private static String toJson(Map<String, Object> movie, List<Map<String, Object>> rows, int maxDays,
            boolean upcoming) {
        String language = String.valueOf(movie.get("spoken_language")).toLowerCase(Locale.ROOT);
        String suffix = language.contains("phụ đề") ? " PHỤ ĐỀ" : language.contains("lồng tiếng") ? " LỒNG TIẾNG" : "";
        Map<String, Map<String, List<Map<String, Object>>>> days = new LinkedHashMap<>();
        for (Map<String, Object> r : rows) {
            String date = (String) r.get("d");
            if (!days.containsKey(date) && days.size() >= maxDays) continue;
            String format = r.get("room_type") + suffix;
            days.computeIfAbsent(date, k -> new LinkedHashMap<>())
                    .computeIfAbsent(format, k -> new ArrayList<>()).add(r);
        }
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"title\":").append(quote(String.valueOf(movie.get("title"))));
        sb.append(",\"upcoming\":").append(upcoming);
        sb.append(",\"cinema\":").append(quote(String.valueOf(rows.get(0).get("cinema_name"))));
        sb.append(",\"days\":[");
        boolean firstDay = true;
        for (Map.Entry<String, Map<String, List<Map<String, Object>>>> day : days.entrySet()) {
            LocalDate d = LocalDate.parse(day.getKey());
            if (!firstDay) sb.append(',');
            firstDay = false;
            sb.append("{\"date\":").append(quote(day.getKey()))
                    .append(",\"day\":").append(d.getDayOfMonth())
                    .append(",\"sub\":").append(quote("/" + String.format("%02d", d.getMonthValue()) + " - " + weekday(d)))
                    .append(",\"groups\":[");
            boolean firstGroup = true;
            for (Map.Entry<String, List<Map<String, Object>>> group : day.getValue().entrySet()) {
                if (!firstGroup) sb.append(',');
                firstGroup = false;
                sb.append("{\"format\":").append(quote(group.getKey())).append(",\"times\":[");
                boolean firstTime = true;
                for (Map<String, Object> t : group.getValue()) {
                    if (!firstTime) sb.append(',');
                    firstTime = false;
                    sb.append("{\"id\":").append(((Number) t.get("showtime_id")).intValue())
                            .append(",\"time\":").append(quote((String) t.get("t")))
                            .append(",\"free\":").append(((Number) t.get("free_seats")).intValue()).append('}');
                }
                sb.append("]}");
            }
            sb.append("]}");
        }
        return sb.append("]}").toString();
    }

    private static String weekday(LocalDate d) {
        return switch (d.getDayOfWeek()) {
            case SUNDAY -> "CN";
            default -> "T" + (d.getDayOfWeek().getValue() + 1);
        };
    }

    private static String quote(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c)); else sb.append(c);
                }
            }
        }
        return sb.append('"').toString();
    }

    /** Dùng chung với danh sách phim: id các phim còn suất sắp chiếu (để hiện nút Mua vé). */
    public static Set<Integer> bookableMovieIds() throws SQLException {
        Set<Integer> ids = new java.util.HashSet<>();
        for (Map<String, Object> r : Rows.query("SELECT DISTINCT s.movie_id FROM Showtime s "
                + "JOIN Movie m ON m.movie_id = s.movie_id "
                + "WHERE s.status = 'Scheduled' AND s.start_time > SYSDATETIME() AND m.status <> 'Stopped'")) {
            ids.add(((Number) r.get("movie_id")).intValue());
        }
        return ids;
    }
}
