package com.cinema.model;

import java.math.BigDecimal;

/** Một dòng bảng giá vé: (khung giờ, loại ghế) cùng giá theo loại ngày. Giá null = chưa cấu hình. */
public class PriceRow {
    private String slotName;
    private String seatTypeName;
    private BigDecimal weekday;
    private BigDecimal weekend;
    private BigDecimal holiday;

    public String getSlotName() { return slotName; }
    public void setSlotName(String slotName) { this.slotName = slotName; }

    public String getSeatTypeName() { return seatTypeName; }
    public void setSeatTypeName(String seatTypeName) { this.seatTypeName = seatTypeName; }

    public BigDecimal getWeekday() { return weekday; }
    public void setWeekday(BigDecimal weekday) { this.weekday = weekday; }

    public BigDecimal getWeekend() { return weekend; }
    public void setWeekend(BigDecimal weekend) { this.weekend = weekend; }

    public BigDecimal getHoliday() { return holiday; }
    public void setHoliday(BigDecimal holiday) { this.holiday = holiday; }
}
