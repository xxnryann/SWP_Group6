package com.cinema.util.MovieUtil;

import com.cinema.model.Movie;
import java.time.LocalDate;

public final class MovieSchedule {

    private MovieSchedule() {
    }

    public static String statusFor(Movie movie) {
        if ("Stopped".equals(movie.getStatus())) return "Stopped";
        LocalDate today = LocalDate.now();
        if (movie.getReleaseDate() != null && movie.getReleaseDate().isAfter(today)) return "Upcoming";
        if (movie.getEndDate() != null && movie.getEndDate().isBefore(today)) return "Stopped";
        return "NowShowing";
    }
}
