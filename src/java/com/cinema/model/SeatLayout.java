package com.cinema.model;

import java.time.LocalDateTime;

/**
 * Layout ghế trong thư viện (bảng SeatLayout) — Admin tạo một lần, dùng lại khi thêm phòng chiếu.
 * layoutData: mỗi hàng một chuỗi, cách nhau bởi '/'; S = thường, V = VIP, C = ghế đôi (luôn theo cặp "CC").
 */
public class SeatLayout {
    private int layoutId;
    private String layoutName;
    private String roomType;
    private int seatCount;
    private String layoutData;
    private LocalDateTime createdAt;

    public int getLayoutId() { return layoutId; }
    public void setLayoutId(int layoutId) { this.layoutId = layoutId; }

    public String getLayoutName() { return layoutName; }
    public void setLayoutName(String layoutName) { this.layoutName = layoutName; }

    public String getRoomType() { return roomType; }
    public void setRoomType(String roomType) { this.roomType = roomType; }

    public int getSeatCount() { return seatCount; }
    public void setSeatCount(int seatCount) { this.seatCount = seatCount; }

    public String getLayoutData() { return layoutData; }
    public void setLayoutData(String layoutData) { this.layoutData = layoutData; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public int getRowCount() { return layoutData == null || layoutData.isEmpty() ? 0 : layoutData.split("/").length; }
    public int getStandardCount() { return count('S'); }
    public int getVipCount() { return count('V'); }
    /** Số cặp ghế đôi (mỗi cặp là 2 ghế trong DB). */
    public int getCouplePairs() { return count('C') / 2; }

    private int count(char ch) {
        int n = 0;
        if (layoutData != null) {
            for (int i = 0; i < layoutData.length(); i++) {
                if (layoutData.charAt(i) == ch) {
                    n++;
                }
            }
        }
        return n;
    }
}
