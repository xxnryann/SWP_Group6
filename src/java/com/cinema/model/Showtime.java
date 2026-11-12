package com.cinema.model;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import com.cinema.util.showtime.ShowtimeRules;

public class Showtime {
    private static final DateTimeFormatter DISPLAY_FORMAT = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");
    private int showtimeId;
    private int movieId;
    private String movieTitle;
    private int movieDurationMinutes;
    private String roomName;
    private LocalDateTime startsAt;
    private String status = "Scheduled";
    private int purchasedTicketCount;
    /** Hình thức ngôn ngữ của suất: "Orig" (nguyên bản), "Sub" (phụ đề) hoặc "Dub" (lồng tiếng); null = chưa khai báo. */
    private String languageMode;
    /** Ngôn ngữ phụ đề / lồng tiếng — phải là một trong các ngôn ngữ của phim. */
    private String language;

    public int getShowtimeId() {
        return showtimeId;
    }

    public void setShowtimeId(int showtimeId) {
        this.showtimeId = showtimeId;
    }

    public int getMovieId() {
        return movieId;
    }

    public void setMovieId(int movieId) {
        this.movieId = movieId;
    }

    public String getMovieTitle() {
        return movieTitle;
    }

    public void setMovieTitle(String movieTitle) {
        this.movieTitle = movieTitle;
    }

    public int getMovieDurationMinutes() {
        return movieDurationMinutes;
    }

    public void setMovieDurationMinutes(int movieDurationMinutes) {
        this.movieDurationMinutes = movieDurationMinutes;
    }

    public String getRoomName() {
        return roomName;
    }

    public void setRoomName(String roomName) {
        this.roomName = roomName;
    }

    public LocalDateTime getStartsAt() {
        return startsAt;
    }

    public void setStartsAt(LocalDateTime startsAt) {
        this.startsAt = startsAt;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public int getPurchasedTicketCount() {
        return purchasedTicketCount;
    }

    public void setPurchasedTicketCount(int purchasedTicketCount) {
        this.purchasedTicketCount = purchasedTicketCount;
    }

    public boolean isLockedByPurchasedTickets() {
        return purchasedTicketCount > 0;
    }

    public boolean getLockedByPurchasedTickets() {
        return isLockedByPurchasedTickets();
    }

    public String getStartDisplay() {
        return startsAt == null ? "" : startsAt.format(DISPLAY_FORMAT);
    }

    public String getStartTimeOnly() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    public String getScheduleDateDisplay() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }

    public String getScheduleTimeDisplay() {
        return startsAt == null ? "" : getStartTimeOnly() + " – " + getEndTimeOnly()
                + " (thực tế: " + getSlotEndTimeOnly() + ")";
    }

    public String getManagementStatus() {
        if ("Cancelled".equals(status)) return "Cancelled";
        if ("Maintenance".equals(status)) return "Maintenance";
        return startsAt != null && startsAt.toLocalDate().equals(LocalDate.now())
                ? "Scheduled" : "Pending";
    }

    /** Suất đã tới giờ bắt đầu (đang chiếu hoặc đã chiếu xong) — không được sửa/xóa nữa. */
    public boolean isStarted() {
        return startsAt != null && !startsAt.isAfter(LocalDateTime.now());
    }

    public boolean getStarted() {
        return isStarted();
    }

    public String getEndDisplay() {
        return startsAt == null ? "" : startsAt.plusMinutes(movieDurationMinutes).format(DISPLAY_FORMAT);
    }

    public String getEndTimeOnly() {
        return startsAt == null ? "" : startsAt.plusMinutes(movieDurationMinutes)
                .format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    /** Kết thúc block lịch chiếu, gồm phim và thời gian nghỉ đã bù để chia hết cho 5. */
    public String getSlotEndTimeOnly() {
        return startsAt == null ? "" : startsAt
                .plusMinutes(ShowtimeRules.blockMinutes(movieDurationMinutes))
                .format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    public String getInputDateTime() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));
    }

    public String getInputDate() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
    }

    public String getInputTime() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    public String getLanguageMode() {
        return languageMode;
    }

    public void setLanguageMode(String languageMode) {
        this.languageMode = languageMode;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    /** Nhãn ngắn kiểu rạp: "Nguyên bản Việt", "Phụ đề Việt", "Lồng tiếng Việt"; rỗng nếu chưa khai báo. */
    public static String shortLanguageLabel(String mode, String language) {
        if (language == null || language.isBlank() || mode == null) return "";
        String name = language.startsWith("Tiếng ") ? language.substring(6) : language;
        return modePrefix(mode) + name;
    }

    private static String modePrefix(String mode) {
        if ("Orig".equals(mode)) return "Nguyên bản ";
        return "Dub".equals(mode) ? "Lồng tiếng " : "Phụ đề ";
    }

    public String getLanguageShort() {
        return shortLanguageLabel(languageMode, language);
    }

    /** Nhãn hiển thị, ví dụ "Phụ đề Tiếng Việt" hoặc "Lồng tiếng Tiếng Việt"; rỗng nếu chưa khai báo. */
    public String getLanguageLabel() {
        if (language == null || language.isBlank() || languageMode == null) return "";
        return modePrefix(languageMode) + language;
    }
}
