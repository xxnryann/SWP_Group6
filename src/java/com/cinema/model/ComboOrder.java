package com.cinema.model;

import com.cinema.util.Moneys;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/** Một đơn có combo của khách (đã mua hoặc đã huỷ) — dùng cho tab "Combo của tôi". */
public class ComboOrder {
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm - dd/MM/yyyy");

    private int bookingId;
    private String bookingCode;
    private String movieTitle;
    private String roomName;
    private String cinemaName;
    private LocalDateTime startTime;
    private LocalDateTime purchasedAt;
    private boolean cancelled;
    private final List<Line> lines = new ArrayList<>();

    /** Một dòng combo trong đơn. */
    public static class Line {
        private final String name;
        private final int quantity;
        private final BigDecimal unitPrice;

        public Line(String name, int quantity, BigDecimal unitPrice) {
            this.name = name;
            this.quantity = quantity;
            this.unitPrice = unitPrice;
        }

        public String getName() { return name; }
        public int getQuantity() { return quantity; }
        public String getUnitPriceLabel() { return Moneys.vnd(unitPrice) + " đ"; }
        public String getSubtotalLabel() {
            return Moneys.vnd(unitPrice.multiply(BigDecimal.valueOf(quantity))) + " đ";
        }
        BigDecimal subtotal() { return unitPrice.multiply(BigDecimal.valueOf(quantity)); }
    }

    public int getBookingId() { return bookingId; }
    public void setBookingId(int bookingId) { this.bookingId = bookingId; }
    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }
    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }
    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }
    public String getCinemaName() { return cinemaName; }
    public void setCinemaName(String cinemaName) { this.cinemaName = cinemaName; }
    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }
    public LocalDateTime getPurchasedAt() { return purchasedAt; }
    public void setPurchasedAt(LocalDateTime purchasedAt) { this.purchasedAt = purchasedAt; }
    public boolean isCancelled() { return cancelled; }
    public void setCancelled(boolean cancelled) { this.cancelled = cancelled; }
    public List<Line> getLines() { return lines; }

    public String getShowTimeLabel() { return startTime == null ? "" : startTime.format(FMT); }
    public String getPurchasedLabel() { return purchasedAt == null ? "" : purchasedAt.format(FMT); }
    public String getStatusLabel() { return cancelled ? "Đã huỷ" : "Đã mua"; }
    public String getStatusCss() { return cancelled ? "st-cancelled" : "st-active"; }

    public String getTotalLabel() {
        BigDecimal sum = BigDecimal.ZERO;
        for (Line l : lines) sum = sum.add(l.subtotal());
        return Moneys.vnd(sum) + " đ";
    }
}
