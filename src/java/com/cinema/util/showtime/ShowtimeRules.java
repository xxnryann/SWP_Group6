package com.cinema.util.showtime;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Quy tắc kinh doanh cho lịch chiếu tự động.
 */
public final class ShowtimeRules {
    
    /** Giờ mở cửa rạp mặc định (9h00). */
    public static final LocalTime OPEN_TIME = LocalTime.of(9, 0);
    
    /** Giờ đóng cửa rạp mặc định (23h00, khớp script CSDL và lịch mẫu). */
    public static final LocalTime CLOSE_TIME = LocalTime.of(23, 0);
    
    /** Thời gian nghỉ tối thiểu giữa hai suất chiếu; phần bù làm tròn block nằm trong turnoverFor(). */
    public static final int TURNOVER_MINUTES = 15;
    
    /** Thời lượng phim tối đa cho phép (300 phút = 5 giờ). */
    public static final int MAX_MOVIE_MINUTES = 300;
    
    /** Lưới thời gian xếp lịch: các mốc giờ đẹp, chia hết cho 5 phút. */
    public static final int GRID_MINUTES = 5;
    
    private ShowtimeRules() {}
    
    /**
     * Tính giờ bắt đầu sớm nhất cho một ngày.
     * Nếu hôm nay, bắt đầu từ giờ mở cửa nhưng không sớm hơn giờ hiện tại.
     * Nếu ngày trong tương lai, bắt đầu từ giờ mở cửa.
     */
    public static LocalTime earliestStartFor(LocalDate date, LocalDateTime now) {
        if (date.equals(now.toLocalDate())) {
            LocalTime nowTime = now.toLocalTime();
            return nowTime.isAfter(OPEN_TIME) ? nowTime : OPEN_TIME;
        }
        return OPEN_TIME;
    }
    
    /**
     * Kiểm tra xem suất chiếu có phù hợp với giờ mở cửa không.
     * Suất phải bắt đầu từ giờ mở cửa và kết thúc trước hoặc đúng giờ đóng cửa.
     */
    public static boolean fitsOpeningHours(LocalDateTime startTime, int durationMinutes) {
        LocalTime start = startTime.toLocalTime();
        // So sánh theo LocalDateTime để suất kéo qua nửa đêm không bị coi là hợp lệ.
        LocalDateTime end = startTime.plusMinutes(durationMinutes);
        return !start.isBefore(OPEN_TIME) && !end.isAfter(startTime.toLocalDate().atTime(CLOSE_TIME));
    }

    /** Giờ bắt đầu phải nằm trên lưới 15 phút. */
    public static boolean onGrid(LocalDateTime startTime) {
        return startTime.getMinute() % GRID_MINUTES == 0 && startTime.getSecond() == 0;
    }

    /**
     * Nghỉ ít nhất 15 phút và bù phần lẻ để tổng thời lượng phim + nghỉ
     * luôn là bội số của 5 (ví dụ phim 94 phút được nghỉ 16 phút).
     */
    public static int turnoverFor(int durationMinutes) {
        int remainder = (durationMinutes + TURNOVER_MINUTES) % GRID_MINUTES;
        return TURNOVER_MINUTES + (remainder == 0 ? 0 : GRID_MINUTES - remainder);
    }

    public static int blockMinutes(int durationMinutes) {
        return durationMinutes + turnoverFor(durationMinutes);
    }
}
