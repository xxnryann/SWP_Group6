package com.cinema.model;

/** Loại ghế (bảng SeatType): Standard / VIP / Couple. is_couple = ghế đôi, luôn đặt theo cặp. */
public class SeatType {
    private int seatTypeId;
    private String typeName;
    private boolean couple;
    private String description;

    public int getSeatTypeId() { return seatTypeId; }
    public void setSeatTypeId(int seatTypeId) { this.seatTypeId = seatTypeId; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }

    public boolean isCouple() { return couple; }
    public void setCouple(boolean couple) { this.couple = couple; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
