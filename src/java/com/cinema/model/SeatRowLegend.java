package com.cinema.model;

import java.math.BigDecimal;

/** Chú thích của một hàng ghế: loại ghế, số ghế, khoảng ghế và giá vé (tooltip nhãn hàng). */
public class SeatRowLegend {
    private String rowLabel;
    private String seatTypeName;
    private int seatCount;
    private int firstSeat;
    private int lastSeat;
    private boolean couple;
    private BigDecimal price;

    public String getRowLabel() { return rowLabel; }
    public void setRowLabel(String rowLabel) { this.rowLabel = rowLabel; }

    public String getSeatTypeName() { return seatTypeName; }
    public void setSeatTypeName(String seatTypeName) { this.seatTypeName = seatTypeName; }

    public int getSeatCount() { return seatCount; }
    public void setSeatCount(int seatCount) { this.seatCount = seatCount; }

    public int getFirstSeat() { return firstSeat; }
    public void setFirstSeat(int firstSeat) { this.firstSeat = firstSeat; }

    public int getLastSeat() { return lastSeat; }
    public void setLastSeat(int lastSeat) { this.lastSeat = lastSeat; }

    public boolean isCouple() { return couple; }
    public void setCouple(boolean couple) { this.couple = couple; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    /** "Ghế 1–10 (10 ghế)". */
    public String getSeatRangeLabel() {
        return "Ghế " + firstSeat + "–" + lastSeat + " (" + seatCount + " ghế)";
    }

    public String getPriceLabel() { return SeatTypeInfo.formatPrice(price); }

    public String getNoteLabel() { return couple ? "ghế đôi, chọn theo cặp" : "ghế đơn"; }
}
