package com.cinema.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Chi tiết một đơn đặt vé online (luồng BF-02).
 *
 * <p>Mở rộng {@link BookingSummary} (dùng chung với luồng bán tại quầy)
 * bằng các thông tin chỉ có ở luồng online: thời điểm hết hạn thanh toán,
 * ghế đã chọn và thông tin suất chiếu.</p>
 */
public class OnlineBooking extends BookingSummary {

    private int showtimeId;
    private String movieTitle;
    private String roomName;
    private LocalDateTime startTime;
    private LocalDateTime createdAt;
    private LocalDateTime sessionExpiresAt;
    private LocalDateTime paymentExpiresAt;
    private int customerId;
    private String customerEmail;
    private String voucherCode;
    private final List<String> seatLabels = new ArrayList<>();

    public int getShowtimeId() { return showtimeId; }
    public void setShowtimeId(int showtimeId) { this.showtimeId = showtimeId; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getSessionExpiresAt() { return sessionExpiresAt; }
    public void setSessionExpiresAt(LocalDateTime sessionExpiresAt) {
        this.sessionExpiresAt = sessionExpiresAt;
    }

    public LocalDateTime getPaymentExpiresAt() { return paymentExpiresAt; }
    public void setPaymentExpiresAt(LocalDateTime paymentExpiresAt) {
        this.paymentExpiresAt = paymentExpiresAt;
    }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }

    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }

    public String getVoucherCode() { return voucherCode; }
    public void setVoucherCode(String voucherCode) { this.voucherCode = voucherCode; }

    public List<String> getSeatLabels() { return seatLabels; }

    public String getSeatLabelText() { return String.join(", ", seatLabels); }

    public String getStartTimeLabel() {
        if (startTime == null) return "";
        return startTime.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm - dd/MM/yyyy"));
    }

    /** Số giây còn lại để thanh toán (0 khi đã hết hạn hoặc chưa giữ ghế). */
    public long getRemainingSeconds() {
        if (paymentExpiresAt == null) {
            return 0;
        }
        long seconds = java.time.Duration.between(LocalDateTime.now(), paymentExpiresAt).getSeconds();
        return Math.max(0, seconds);
    }

    public boolean isPaymentExpired() { return getRemainingSeconds() <= 0; }
}
