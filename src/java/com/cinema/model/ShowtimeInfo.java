package com.cinema.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * STT 21 — Bán vé tại quầy. Thông tin một suất chiếu sắp chiếu
 * để nhân viên chọn khi bắt đầu bán vé.
 */
public class ShowtimeInfo {
    private int showtimeId;
    private String title;
    private String roomName;
    private String slotName;
    private LocalDateTime startTime;
    private int availableSeats; // số ghế còn trống (màu GREEN trong vw_SeatMap)

    public int getShowtimeId() { return showtimeId; }
    public void setShowtimeId(int showtimeId) { this.showtimeId = showtimeId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getSlotName() { return slotName; }
    public void setSlotName(String slotName) { this.slotName = slotName; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public int getAvailableSeats() { return availableSeats; }
    public void setAvailableSeats(int availableSeats) { this.availableSeats = availableSeats; }

    public String getStartTimeLabel() {
        if (startTime == null) return "";
        return startTime.format(DateTimeFormatter.ofPattern("HH:mm - dd/MM/yyyy"));
    }

    /** Giờ chiếu dạng "19:00" (khối giờ lớn ở thẻ suất chiếu). */
    public String getStartHourLabel() {
        if (startTime == null) return "";
        return startTime.format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    /** Ngày chiếu dạng "21/10/2026". */
    public String getStartDayLabel() {
        if (startTime == null) return "";
        return startTime.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }
}
