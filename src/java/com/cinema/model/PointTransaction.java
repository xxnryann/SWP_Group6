package com.cinema.model;

import java.time.LocalDateTime;

public class PointTransaction {

    private int txId;
    private int points;
    private String reason;
    private LocalDateTime createdAt;

    public int getTxId() { return txId; }
    public void setTxId(int txId) { this.txId = txId; }
    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
