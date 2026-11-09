package com.cinema.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Một suất chiếu nhìn từ phía phòng chiếu — dùng cho trang Admin "Lịch phòng chiếu" (/admin/room-showtimes).
 * Thời gian lấy từ cột chuẩn Showtime.start_time / end_time.
 */
public class RoomShowtime {
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm");

    private int showtimeId;
    private int movieId;
    private String movieTitle;
    private int durationMinutes;
    private String ageRating;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String status;
    private int soldTickets;

    public int getShowtimeId() { return showtimeId; }
    public void setShowtimeId(int showtimeId) { this.showtimeId = showtimeId; }

    public int getMovieId() { return movieId; }
    public void setMovieId(int movieId) { this.movieId = movieId; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public int getDurationMinutes() { return durationMinutes; }
    public void setDurationMinutes(int durationMinutes) { this.durationMinutes = durationMinutes; }

    public String getAgeRating() { return ageRating; }
    public void setAgeRating(String ageRating) { this.ageRating = ageRating; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getSoldTickets() { return soldTickets; }
    public void setSoldTickets(int soldTickets) { this.soldTickets = soldTickets; }

    public LocalDate getShowDate() { return startTime == null ? null : startTime.toLocalDate(); }

    public String getTimeRange() {
        return startTime == null ? "" : startTime.format(TIME) + " – " + (endTime == null ? "" : endTime.format(TIME));
    }

    /** Trạng thái hiển thị: CANCELLED / FINISHED / NOW / UPCOMING. */
    public String getPhase() {
        if ("Cancelled".equals(status)) return "CANCELLED";
        LocalDateTime now = LocalDateTime.now();
        if ("Finished".equals(status) || (endTime != null && !endTime.isAfter(now))) return "FINISHED";
        if (startTime != null && !startTime.isAfter(now)) return "NOW";
        return "UPCOMING";
    }

    public String getPhaseLabel() {
        switch (getPhase()) {
            case "CANCELLED": return "Đã hủy";
            case "FINISHED": return "Đã chiếu";
            case "NOW": return "Đang chiếu";
            default: return "Sắp chiếu";
        }
    }
}
