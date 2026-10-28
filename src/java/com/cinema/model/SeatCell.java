package com.cinema.model;

/**
 * STT 21 — Bán vé tại quầy. Một ô ghế trên sơ đồ.
 * Màu ghế lấy từ view vw_SeatMap của database nhóm:
 * GREEN = trống | YELLOW = đang giữ chờ thanh toán | RED = đã bán | GREY = bảo trì.
 */
public class SeatCell {
    private int seatId;
    private String rowLabel;
    private int seatNumber;
    private String seatType;    // Standard / VIP / Couple
    private Integer pairSeatId; // id ghế còn lại của cặp (null nếu không phải ghế đôi)
    private String displayLabel;
    private String color;       // GREEN / YELLOW / RED / GREY

    public int getSeatId() { return seatId; }
    public void setSeatId(int seatId) { this.seatId = seatId; }

    public String getRowLabel() { return rowLabel; }
    public void setRowLabel(String rowLabel) { this.rowLabel = rowLabel; }

    public int getSeatNumber() { return seatNumber; }
    public void setSeatNumber(int seatNumber) { this.seatNumber = seatNumber; }

    public String getSeatType() { return seatType; }
    public void setSeatType(String seatType) { this.seatType = seatType; }

    public Integer getPairSeatId() { return pairSeatId; }
    public void setPairSeatId(Integer pairSeatId) { this.pairSeatId = pairSeatId; }

    public String getDisplayLabel() { return displayLabel == null ? getLabel() : displayLabel; }
    public void setDisplayLabel(String displayLabel) { this.displayLabel = displayLabel; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    /** Chỉ ghế GREEN mới được chọn. */
    public boolean isAvailable() { return "GREEN".equals(color); }

    /** Ghế đôi luôn phải chọn cả cặp (sp_HoldSeats kiểm tra ở DB). */
    public boolean isCouple() { return pairSeatId != null; }

    public String getLabel() { return (rowLabel == null ? "" : rowLabel) + seatNumber; }
}
