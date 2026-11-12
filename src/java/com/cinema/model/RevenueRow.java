package com.cinema.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/** Một đơn đã thanh toán trong lịch sử doanh thu. */
public class RevenueRow {
    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private String bookingCode;
    private LocalDateTime paidAt;
    private String channel;
    private String customerName;
    private String customerEmail;
    private String staffName;
    private String movieTitle;
    private String roomName;
    private LocalDateTime showStart;
    private int ticketCount;
    private long ticketTotal;
    private long comboTotal;
    private long voucherDiscount;
    private String voucherCode;
    private long pointsDiscount;
    private int pointsUsed;
    private long totalAmount;
    private long amount;

    public String getPaidAtDisplay() { return paidAt == null ? "" : paidAt.format(DT); }
    public String getPaidDate() { return paidAt == null ? "" : paidAt.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")); }
    public String getPaidTime() { return paidAt == null ? "" : paidAt.format(DateTimeFormatter.ofPattern("HH:mm")); }
    public String getShowStartDisplay() { return showStart == null ? "" : showStart.format(DT); }
    public boolean isCounter() { return "Counter".equals(channel); }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String v) { bookingCode = v; }
    public LocalDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(LocalDateTime v) { paidAt = v; }
    public String getChannel() { return channel; }
    public void setChannel(String v) { channel = v; }
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String v) { customerName = v; }
    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String v) { customerEmail = v; }
    public String getStaffName() { return staffName; }
    public void setStaffName(String v) { staffName = v; }
    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String v) { movieTitle = v; }
    public String getRoomName() { return roomName; }
    public void setRoomName(String v) { roomName = v; }
    public LocalDateTime getShowStart() { return showStart; }
    public void setShowStart(LocalDateTime v) { showStart = v; }
    public int getTicketCount() { return ticketCount; }
    public void setTicketCount(int v) { ticketCount = v; }
    public long getTicketTotal() { return ticketTotal; }
    public void setTicketTotal(long v) { ticketTotal = v; }
    public long getComboTotal() { return comboTotal; }
    public void setComboTotal(long v) { comboTotal = v; }
    public long getVoucherDiscount() { return voucherDiscount; }
    public void setVoucherDiscount(long v) { voucherDiscount = v; }
    public String getVoucherCode() { return voucherCode; }
    public void setVoucherCode(String v) { voucherCode = v; }
    public long getPointsDiscount() { return pointsDiscount; }
    public void setPointsDiscount(long v) { pointsDiscount = v; }
    public int getPointsUsed() { return pointsUsed; }
    public void setPointsUsed(int v) { pointsUsed = v; }
    public long getTotalAmount() { return totalAmount; }
    public void setTotalAmount(long v) { totalAmount = v; }
    public long getAmount() { return amount; }
    public void setAmount(long v) { amount = v; }
}
