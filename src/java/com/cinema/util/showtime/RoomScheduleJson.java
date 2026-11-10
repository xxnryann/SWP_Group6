package com.cinema.util.showtime;

import com.cinema.dao.ShowtimeDAO;
import com.cinema.model.Showtime;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * JSON lịch các phòng trong một ngày, dùng cho timeline "Lịch các phòng"
 * (form thêm/sửa suất chiếu của Manager và trang Lịch phòng chiếu của Admin):
 * <pre>{"open":"07:00","close":"23:55","rooms":[{"room":"Phòng 1","shows":[{"id":1,"title":"...",
 * "start":"09:15","end":"10:55","slotEnd":"11:10","tickets":3}]}]}</pre>
 * {@code slotEnd} = giờ phim kết thúc + thời gian dọn phòng (kết thúc thực tế).
 */
public final class RoomScheduleJson {

    private static final DateTimeFormatter HM = DateTimeFormatter.ofPattern("HH:mm");

    private RoomScheduleJson() {}

    public static String build(ShowtimeDAO showtimeDAO, LocalDate date) throws SQLException {
        Map<String, StringBuilder> byRoom = new LinkedHashMap<>();
        for (String room : showtimeDAO.findActiveRoomNames()) {
            byRoom.put(room, new StringBuilder());
        }
        for (Showtime s : showtimeDAO.findScheduleForDate(date)) {
            StringBuilder shows = byRoom.computeIfAbsent(s.getRoomName(), k -> new StringBuilder());
            if (shows.length() > 0) {
                shows.append(',');
            }
            shows.append("{\"id\":").append(s.getShowtimeId())
                    .append(",\"title\":").append(quote(s.getMovieTitle()))
                    .append(",\"start\":\"").append(s.getStartsAt().format(HM))
                    .append("\",\"end\":\"").append(s.getEndTimeOnly())
                    .append("\",\"slotEnd\":\"").append(s.getSlotEndTimeOnly())
                    .append("\",\"tickets\":").append(s.getPurchasedTicketCount()).append('}');
        }
        StringBuilder out = new StringBuilder("{\"open\":\"").append(ShowtimeRules.OPEN_TIME)
                .append("\",\"close\":\"").append(ShowtimeRules.CLOSE_TIME).append("\",\"rooms\":[");
        boolean first = true;
        for (Map.Entry<String, StringBuilder> e : byRoom.entrySet()) {
            if (!first) {
                out.append(',');
            }
            first = false;
            out.append("{\"room\":").append(quote(e.getKey())).append(",\"shows\":[").append(e.getValue()).append("]}");
        }
        return out.append("]}").toString();
    }

    /** Chuỗi JSON có escape ký tự đặc biệt (kể cả &lt; &gt; &amp; để an toàn khi nhúng). */
    public static String quote(String value) {
        if (value == null) {
            return "null";
        }
        StringBuilder sb = new StringBuilder("\"");
        for (char ch : value.toCharArray()) {
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < 0x20 || ch == '<' || ch == '>' || ch == '&') {
                        sb.append(String.format("\\u%04x", (int) ch));
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.append('"').toString();
    }
}
