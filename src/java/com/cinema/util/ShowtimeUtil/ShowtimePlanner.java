package com.cinema.util.ShowtimeUtil;

import com.cinema.model.Movie;
import com.cinema.model.Showtime;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Máy lập lịch tự động cho lịch chiếu hàng ngày.
 * Mỗi phòng được xếp suất liên tục từ giờ bắt đầu đến giờ đóng cửa; phim xoay vòng và lệch nhau giữa
 * các phòng. Giờ bắt đầu luôn nằm trên lưới 15 phút, suất kết thúc trước giờ đóng cửa và không đè lên
 * các suất đã có (kể cả thời gian dọn phòng) nên kết quả luôn qua được bước kiểm tra khi ghi vào CSDL.
 */
public final class ShowtimePlanner {

    /** Một suất đã có trong phòng. {@code endTime} có thể null nếu không rõ (khi đó chỉ coi là chiếm mốc bắt đầu). */
    public static class OccupiedSlot {
        public final String roomName;
        public final LocalDateTime startTime;
        public final LocalDateTime endTime;

        public OccupiedSlot(String roomName, LocalDateTime startTime) {
            this(roomName, startTime, null);
        }

        public OccupiedSlot(String roomName, LocalDateTime startTime, LocalDateTime endTime) {
            this.roomName = roomName;
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }

    private ShowtimePlanner() {}

    /**
     * Lập lịch chiếu tự động cho một ngày.
     *
     * @param date ngày lập lịch
     * @param openTime giờ bắt đầu suất đầu tiên
     * @param rooms danh sách tên phòng
     * @param movies danh sách phim cần xếp
     * @param occupiedSlots các suất đã có trong ngày (được giữ nguyên, không bị đè)
     * @return danh sách suất chiếu mới
     */
    public static List<Showtime> plan(LocalDate date, LocalTime openTime, List<String> rooms,
            List<Movie> movies, List<OccupiedSlot> occupiedSlots) {
        List<Showtime> result = new ArrayList<>();
        if (rooms.isEmpty() || movies.isEmpty()) {
            return result;
        }
        LocalDateTime close = date.atTime(ShowtimeRules.CLOSE_TIME);
        int turnover = ShowtimeRules.TURNOVER_MINUTES;
        Map<Integer, List<LocalDateTime>> startsByMovie = new HashMap<>();

        for (int r = 0; r < rooms.size(); r++) {
            String room = rooms.get(r);
            List<OccupiedSlot> busy = new ArrayList<>();
            if (occupiedSlots != null) {
                for (OccupiedSlot slot : occupiedSlots) {
                    if (room.equals(slot.roomName) && slot.startTime != null) busy.add(slot);
                }
            }
            LocalDateTime cursor = roundUp(date.atTime(openTime));
            // Mỗi phòng bắt đầu ở một phim khác nhau để các phòng lệch nhau.
            int next = (r * movies.size()) / rooms.size();
            int guard = 0;
            while (cursor.isBefore(close) && guard++ < 200) {
                Movie chosen = null;
                LocalDateTime moved = null;
                // Lượt 1: tránh cùng một phim bắt đầu gần nhau ở nhiều phòng; lượt 2 (nới lỏng): chấp nhận nếu không còn lựa chọn.
                for (int pass = 0; pass < 2 && chosen == null && moved == null; pass++) {
                    for (int tries = 0; tries < movies.size() && chosen == null; tries++) {
                        Movie candidate = movies.get((next + tries) % movies.size());
                        LocalDateTime finish = cursor.plusMinutes(candidate.getDurationMinutes());
                        if (finish.isAfter(close)) continue;
                        LocalDateTime clash = clashEnd(busy, cursor, candidate.getDurationMinutes(), turnover);
                        if (clash != null) {
                            moved = clash;
                            break;
                        }
                        if (pass == 0 && sameMovieTooClose(startsByMovie.get(candidate.getMovieId()), cursor)) continue;
                        chosen = candidate;
                        next = (next + tries + 1) % movies.size();
                    }
                }
                if (moved != null) {
                    // Đụng suất có sẵn: nhảy tới sau suất đó rồi thử lại.
                    cursor = roundUp(moved.plusMinutes(turnover));
                    continue;
                }
                if (chosen == null) {
                    // Không phim nào còn vừa trước giờ đóng cửa: phòng này đã xếp xong.
                    break;
                }
                Showtime showtime = new Showtime();
                showtime.setMovieId(chosen.getMovieId());
                showtime.setRoomName(room);
                showtime.setStartsAt(cursor);
                showtime.setStatus("Scheduled");
                result.add(showtime);
                startsByMovie.computeIfAbsent(chosen.getMovieId(), k -> new ArrayList<>()).add(cursor);
                cursor = roundUp(cursor.plusMinutes(chosen.getDurationMinutes() + turnover));
            }
        }
        return result;
    }

    /** Làm tròn lên mốc 15 phút. */
    private static LocalDateTime roundUp(LocalDateTime time) {
        LocalDateTime t = time.withSecond(0).withNano(0);
        int rest = t.getMinute() % ShowtimeRules.GRID_MINUTES;
        return rest == 0 && time.getSecond() == 0 && time.getNano() == 0
                ? t : t.plusMinutes(ShowtimeRules.GRID_MINUTES - rest);
    }

    /** Nếu suất [start, start+duration+turnover) đè lên suất có sẵn thì trả về giờ kết thúc của suất đó, ngược lại null. */
    private static LocalDateTime clashEnd(List<OccupiedSlot> busy, LocalDateTime start, int duration, int turnover) {
        LocalDateTime end = start.plusMinutes(duration + turnover);
        for (OccupiedSlot slot : busy) {
            LocalDateTime slotEnd = slot.endTime != null ? slot.endTime : slot.startTime.plusMinutes(1);
            if (slot.startTime.isBefore(end) && slotEnd.plusMinutes(turnover).isAfter(start)) {
                return slotEnd;
            }
        }
        return null;
    }

    /** Tránh hai phòng bắt đầu cùng một phim trong vòng 2 giờ (cho khán giả nhiều lựa chọn giờ khác nhau). */
    private static boolean sameMovieTooClose(List<LocalDateTime> starts, LocalDateTime start) {
        if (starts == null) return false;
        for (LocalDateTime s : starts) {
            if (Math.abs(java.time.Duration.between(s, start).toMinutes()) < 120) return true;
        }
        return false;
    }
}
