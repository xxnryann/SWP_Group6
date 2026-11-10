package com.cinema.model;

/**
 * Phòng chiếu — Screening Room Management (Admin).
 * Khớp bảng Room: room_type IN ('2D','3D','IMAX','4DX'), status IN ('Active','Closed'), capacity > 0.
 * Các trường seatCount/maintenanceCount/upcomingShowtimes là số liệu tổng hợp chỉ để hiển thị.
 */
public class Room {
    private int roomId;
    private int cinemaId;
    private String cinemaName;
    private String roomName;
    private String roomType;
    private int capacity;
    private String status;

    // thống kê hiển thị
    private int seatCount;
    private int maintenanceCount;
    private int upcomingShowtimes;

    public int getRoomId() { return roomId; }
    public void setRoomId(int roomId) { this.roomId = roomId; }

    public int getCinemaId() { return cinemaId; }
    public void setCinemaId(int cinemaId) { this.cinemaId = cinemaId; }

    public String getCinemaName() { return cinemaName; }
    public void setCinemaName(String cinemaName) { this.cinemaName = cinemaName; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }

    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getSeatCount() { return seatCount; }
    public void setSeatCount(int seatCount) { this.seatCount = seatCount; }

    public int getMaintenanceCount() { return maintenanceCount; }
    public void setMaintenanceCount(int maintenanceCount) { this.maintenanceCount = maintenanceCount; }

    public int getUpcomingShowtimes() { return upcomingShowtimes; }
    public void setUpcomingShowtimes(int upcomingShowtimes) { this.upcomingShowtimes = upcomingShowtimes; }

    public boolean isActive() { return "Active".equals(status); }

    public String getStatusLabel() { return isActive() ? "Đang hoạt động" : "Đã đóng"; }

    /** Số ghế dùng được (đã có layout và không bảo trì). */
    public int getUsableSeats() { return seatCount - maintenanceCount; }

    /** Đã thiết lập layout ghế chưa. */
    public boolean isHasLayout() { return seatCount > 0; }
}
