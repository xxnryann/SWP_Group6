package com.cinema.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Showtime {
    private static final DateTimeFormatter DISPLAY_FORMAT = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy");
    private int showtimeId;
    private int movieId;
    private String movieTitle;
    private int movieDurationMinutes;
    private String roomName;
    private LocalDateTime startsAt;
    private BigDecimal ticketPrice;
    private String status = "Scheduled";

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

    public BigDecimal getTicketPrice() {
        return ticketPrice;
    }

    public void setTicketPrice(BigDecimal ticketPrice) {
        this.ticketPrice = ticketPrice;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getStartDisplay() {
        return startsAt == null ? "" : startsAt.format(DISPLAY_FORMAT);
    }

    public String getStartTimeOnly() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    public String getEndDisplay() {
        return startsAt == null ? "" : startsAt.plusMinutes(movieDurationMinutes).format(DISPLAY_FORMAT);
    }

    public String getEndTimeOnly() {
        return startsAt == null ? "" : startsAt.plusMinutes(movieDurationMinutes)
                .format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    public String getInputDateTime() {
        return startsAt == null ? "" : startsAt.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));
    }
}
