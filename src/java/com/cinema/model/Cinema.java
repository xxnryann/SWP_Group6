package com.cinema.model;

/** Rạp chiếu (bảng Cinema) — chỉ dùng để chọn rạp khi tạo phòng chiếu. */
public class Cinema {
    private int cinemaId;
    private String cinemaName;

    public int getCinemaId() { return cinemaId; }
    public void setCinemaId(int cinemaId) { this.cinemaId = cinemaId; }

    public String getCinemaName() { return cinemaName; }
    public void setCinemaName(String cinemaName) { this.cinemaName = cinemaName; }
}
