package com.cinema.util.ShowtimeUtil;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Quy tắc kinh doanh cho lịch chiếu tự động.
 */
public final class ShowtimeRules {
    
    /** Giờ mở cửa rạp mặc định (9h00). */
    public static final LocalTime OPEN_TIME = LocalTime.of(9, 0);
    
    /** Giờ đóng cửa rạp mặc định (22h00). */
    public static final LocalTime CLOSE_TIME = LocalTime.of(22, 0);
    
    /** Thời gian từ khi bộ phim kết thúc đến khi suất tiếp theo bắt đầu (15 phút). */
    public static final int TURNOVER_MINUTES = 15;
    
    /** Thời lượng phim tối đa cho phép (300 phút = 5 giờ). */
    public static final int MAX_MOVIE_MINUTES = 300;
    
    /** Lưới thời gian xếp lịch (15 phút). */
    public static final int GRID_MINUTES = 15;
    
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
        LocalTime end = start.plusMinutes(durationMinutes);
        return !start.isBefore(OPEN_TIME) && !end.isAfter(CLOSE_TIME);
    }
}
