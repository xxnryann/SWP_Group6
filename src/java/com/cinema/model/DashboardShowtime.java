package com.cinema.model;

import java.time.LocalDate;

/**
 * Model để hiển thị thông tin phim và suất chiếu trong dashboard.
 */
public class DashboardShowtime {
    private Movie movie;
    private LocalDate nextShowDate;
    private String nextShowtimeLabel;
    
    public DashboardShowtime() {}
    
    public DashboardShowtime(Movie movie, LocalDate nextShowDate, String nextShowtimeLabel) {
        this.movie = movie;
        this.nextShowDate = nextShowDate;
        this.nextShowtimeLabel = nextShowtimeLabel;
    }
    
    public Movie getMovie() { return movie; }
    public void setMovie(Movie movie) { this.movie = movie; }
    
    public LocalDate getNextShowDate() { return nextShowDate; }
    public void setNextShowDate(LocalDate nextShowDate) { this.nextShowDate = nextShowDate; }
    
    public String getNextShowtimeLabel() { return nextShowtimeLabel; }
    public void setNextShowtimeLabel(String nextShowtimeLabel) { this.nextShowtimeLabel = nextShowtimeLabel; }
}
