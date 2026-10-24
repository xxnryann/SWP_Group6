package com.cinema.model;

/**
 * Ghế của một phòng chiếu (bảng Seat).
 * status IN ('Active','Maintenance'). pairSeatId != null nghĩa là ghế đôi, đi cùng ghế còn lại của cặp.
 * Không nhầm với SeatCell (sơ đồ ghế theo suất chiếu, có màu GREEN/YELLOW/RED/GREY).
 */
public class Seat {
    private int seatId;
    private int roomId;
    private String rowLabel;
    private int seatNumber;
    private int seatTypeId;
    private String seatTypeName;
    private boolean couple;
    private Integer pairSeatId;
    private String status;

    public int getSeatId() { return seatId; }
    public void setSeatId(int seatId) { this.seatId = seatId; }

    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }

    public String getRowLabel() { return rowLabel; }
    public void setRowLabel(String rowLabel) { this.rowLabel = rowLabel; }

    public int getSeatNumber() { return seatNumber; }
    public void setSeatNumber(int seatNumber) { this.seatNumber = seatNumber; }

    public int getSeatTypeId() { return seatTypeId; }
    public void setSeatTypeId(int seatTypeId) { this.seatTypeId = seatTypeId; }

    public String getSeatTypeName() { return seatTypeName; }
    public void setSeatTypeName(String seatTypeName) { this.seatTypeName = seatTypeName; }

    public boolean isCouple() { return couple; }
    public void setCouple(boolean couple) { this.couple = couple; }

    public Integer getPairSeatId() { return pairSeatId; }
    public void setPairSeatId(Integer pairSeatId) { this.pairSeatId = pairSeatId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isMaintenance() { return "Maintenance".equals(status); }

    /** Nhãn ghế, ví dụ "A1". */
    public String getLabel() { return (rowLabel == null ? "" : rowLabel) + seatNumber; }
}
