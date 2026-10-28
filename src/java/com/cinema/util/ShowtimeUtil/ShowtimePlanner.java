package com.cinema.util.ShowtimeUtil;

import com.cinema.model.Movie;
import com.cinema.model.Showtime;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Máy lập lịch tự động cho lịch chiếu hàng ngày.
 * Xếp suất chiếu sao cho các phòng được sử dụng liên tục từ giờ mở cửa đến đóng cửa,
 * phim xoay vòng và lệch nhau giữa các phòng.
 */
public final class ShowtimePlanner {
    
    private ShowtimePlanner() {}
    
    /**
     * Lập lịch chiếu tự động cho một ngày.
     * 
     * @param date ngày lập lịch
     * @param openTime giờ mở cửa
     * @param rooms danh sách tên phòng  
     * @param movies danh sách phim cần xếp
     * @param occupiedSlots các suất chiếu đã được đặt trước (phòng -> tập hợp slot_id)
     * @return danh sách suất chiếu được lập lịch tự động
     */
    public static List<Showtime> plan(
            LocalDate date,
            LocalTime openTime,
            List<String> rooms,
            List<Movie> movies,
            Map<String, Set<Integer>> occupiedSlots) {
        
        List<Showtime> result = new ArrayList<>();
        
        if (rooms.isEmpty() || movies.isEmpty()) {
            return result;
        }
        
        // Tính giờ đóng cửa thực tế (đóng sau khi suất cuối cùng kết thúc)
        LocalTime closeTime = ShowtimeRules.CLOSE_TIME;
        
        // Khởi tạo trạng thái của từng phòng: thời điểm kết thúc suất cuối cùng
        Map<String, LocalDateTime> roomEndTime = new java.util.HashMap<>();
        for (String room : rooms) {
            roomEndTime.put(room, LocalDateTime.of(date, openTime));
        }
        
        // Xoay vòng các phim để lệch nhau giữa các phòng
        int movieIndex = 0;
        int attemptCount = 0;
        int maxAttempts = rooms.size() * movies.size() * 10; // tránh vòng lặp vô hạn
        
        // Lập lịch cho đến khi không thể thêm suất nào nữa
        while (attemptCount < maxAttempts) {
            attemptCount++;
            
            boolean added = false;
            
            // Thử thêm suất cho mỗi phòng
            for (String room : rooms) {
                Movie movie = movies.get(movieIndex % movies.size());
                LocalDateTime endTime = roomEndTime.get(room);
                
                // Tính giờ bắt đầu: sau khi suất trước kết thúc + turnover
                LocalDateTime startTime = endTime.plusMinutes(ShowtimeRules.TURNOVER_MINUTES);
                
                // Kiểm tra xem suất này có kết thúc trước giờ đóng cửa không
                LocalDateTime finishTime = startTime.plusMinutes(movie.getDurationMinutes());
                
                if (finishTime.toLocalTime().isBefore(closeTime) || 
                    finishTime.toLocalTime().equals(closeTime)) {
                    
                    // Tạo suất chiếu mới
                    Showtime showtime = new Showtime();
                    showtime.setMovieId(movie.getMovieId());
                    showtime.setRoomName(room);
                    showtime.setStartsAt(startTime);
                    showtime.setStatus("Scheduled");
                    
                    result.add(showtime);
                    roomEndTime.put(room, finishTime);
                    added = true;
                }
            }
            
            movieIndex++;
            
            // Nếu vòng lặp này không thêm suất nào, tức là không thể thêm nữa
            if (!added) {
                break;
            }
        }
        
        return result;
    }
}
