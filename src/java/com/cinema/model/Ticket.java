package com.cinema.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Một vé điện tử của khách (UC18 — vé điện tử QR, lịch sử đặt vé).
 *
 * <p>Mỗi vé là <b>1 thẻ</b> trên màn hình "Lịch sử vé": có mã vé riêng, 1 mã QR
 * riêng, 1 ghế, và trạng thái riêng. Vé hết hạn (quá giờ chiếu) chuyển sang
 * {@code EXPIRED} và không còn huỷ được.</p>
 *
 * <p>Trạng thái vé lấy từ cột {@code Ticket.status}:
 * {@code Held} · {@code Booked} · {@code Used} · {@code Expired} · {@code Cancelled}.</p>
 */
public class Ticket {

    private int ticketId;
    private String ticketCode;

    private int bookingId;
    private String bookingCode;

    /** account_id của chủ đơn (Booking.customer_id) — dùng kiểm tra ownership khi huỷ vé. */
    private int bookingCustomerId;

    private String movieTitle;
    private String cinemaName;
    private String roomName;
    private String seatLabel;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private BigDecimal price = BigDecimal.ZERO;

    /** Trạng thái vé: {@code HELD}, {@code BOOKED}, {@code USED}, {@code EXPIRED}, {@code CANCELLED}. */
    private String status;

    /** Vé còn hiệu lực và còn trong thời hạn huỷ được không. */
    private boolean canCancel;
    private int movieId;
    private boolean canReview;
    private LocalDateTime purchasedAt;

    public int getTicketId() { return ticketId; }
    public void setTicketId(int ticketId) { this.ticketId = ticketId; }

    public String getTicketCode() { return ticketCode; }
    public void setTicketCode(String ticketCode) { this.ticketCode = ticketCode; }

    public int getBookingId() { return bookingId; }
    public void setBookingId(int bookingId) { this.bookingId = bookingId; }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }

    public int getBookingCustomerId() { return bookingCustomerId; }
    public void setBookingCustomerId(int bookingCustomerId) {
        this.bookingCustomerId = bookingCustomerId;
    }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getCinemaName() { return cinemaName; }
    public void setCinemaName(String cinemaName) { this.cinemaName = cinemaName; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getSeatLabel() { return seatLabel; }
    public void setSeatLabel(String seatLabel) { this.seatLabel = seatLabel; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price == null ? BigDecimal.ZERO : price; }

    public String getStatus() { return status; }

    /**
     * Gán trạng thái vé. Chuẩn hoá về chữ HOA để so sánh không phụ thuộc
     * cách viết trong DB ({@code 'Booked'} vs {@code 'BOOKED'}).
     *
     * <p>DB lưu trạng thái dạng PascalCase ({@code Held}, {@code Booked},
     * {@code Used}, {@code Expired}, {@code Cancelled}); nếu để nguyên thì
     * mọi so sánh {@code "BOOKED".equals(status)} ở tầng service/JSP sẽ
     * sai → vé hợp lệ bị hiển thị như hết hạn, nút "Huỷ vé" bị ẩn.</p>
     */
    public void setStatus(String status) {
        this.status = status == null ? null : status.trim().toUpperCase(java.util.Locale.ROOT);
    }

    /** Thời điểm mua vé (thanh toán thành công; nếu chưa có thì lấy lúc tạo đơn). */
    public LocalDateTime getPurchasedAt() { return purchasedAt; }
    public void setPurchasedAt(LocalDateTime purchasedAt) { this.purchasedAt = purchasedAt; }

    /** Ngày giờ mua dạng "20:45 - 22/10/2026". */
    public String getPurchasedLabel() {
        if (purchasedAt == null) {
            return "";
        }
        return purchasedAt.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm - dd/MM/yyyy"));
    }

    /** Thứ tự hiển thị lịch sử: còn hiệu lực -> đã dùng -> hết hạn -> đã huỷ. */
    public int getSortRank() {
        if (isActive()) return 0;
        if (isUsed()) return 1;
        if (isExpired()) return 2;
        return 3;
    }

    public boolean isCanCancel() { return canCancel; }
    public void setCanCancel(boolean canCancel) { this.canCancel = canCancel; }

    public int getMovieId() { return movieId; }
    public void setMovieId(int movieId) { this.movieId = movieId; }

    public boolean isCanReview() { return canReview; }
    public void setCanReview(boolean canReview) { this.canReview = canReview; }

    /* ---------- tiện ích hiển thị ---------- */

    /** Vé còn hiệu lực (chưa huỷ, chưa quá hạn, chưa soát vé). */
    public boolean isActive() {
        return "BOOKED".equalsIgnoreCase(status);
    }

    /** Vé đã quá thời gian chiếu → không còn hiệu lực. */
    public boolean isExpired() {
        return "EXPIRED".equalsIgnoreCase(status);
    }

    /** Vé đã soát vé tại rạp (check-in). */
    public boolean isUsed() {
        return "USED".equalsIgnoreCase(status);
    }

    /** Vé đã bị khách huỷ. */
    public boolean isCancelled() {
        return "CANCELLED".equalsIgnoreCase(status);
    }

    /** Nhãn trạng thái hiển thị cho khách (tiếng Việt). */
    public String getStatusLabel() {
        if (status == null) {
            return "";
        }
        switch (status.trim().toUpperCase(java.util.Locale.ROOT)) {
            case "BOOKED": return "Còn hiệu lực";
            case "USED": return "Đã sử dụng";
            case "EXPIRED": return "Đã hết hạn";
            case "CANCELLED": return "Đã huỷ";
            case "HELD": return "Đang giữ";
            default: return "";
        }
    }

    /** Lớp CSS cho nhãn trạng thái. */
    public String getStatusCss() {
        if (status == null) {
            return "st-expired";
        }
        switch (status.trim().toUpperCase(java.util.Locale.ROOT)) {
            case "BOOKED": return "st-active";
            case "USED": return "st-used";
            case "EXPIRED": return "st-expired";
            case "CANCELLED": return "st-cancelled";
            default: return "st-expired";
        }
    }

    /** Ghế hiển thị dạng "B9" (hàng + số). */
    public String getSeatDisplay() {
        return seatLabel == null ? "" : seatLabel;
    }

    /** Suất chiếu dạng "20:45 - 22/10/2026". */
    public String getShowTimeLabel() {
        if (startTime == null) {
            return "";
        }
        return startTime.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm - dd/MM/yyyy"));
    }

    /** Giá vé dạng "75.000 đ". */
    public String getPriceLabel() {
        return com.cinema.util.Moneys.vnd(price) + " đ";
    }
}
