package com.cinema.model;

import java.util.ArrayList;
import java.util.List;

public class ShowtimeMovieGroup {
    private final Movie movie;
    private final List<Showtime> showtimes = new ArrayList<>();

    public ShowtimeMovieGroup(Movie movie) {
        this.movie = movie;
    }

    public Movie getMovie() {
        return movie;
    }

    public List<Showtime> getShowtimes() {
        return showtimes;
    }

    public void addShowtime(Showtime showtime) {
        showtimes.add(showtime);
    }
}
