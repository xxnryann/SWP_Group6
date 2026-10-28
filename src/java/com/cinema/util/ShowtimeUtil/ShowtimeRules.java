package com.cinema.util.ShowtimeUtil;

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
    
    private ShowtimeRules() {}
}
