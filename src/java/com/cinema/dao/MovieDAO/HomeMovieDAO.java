package com.cinema.dao.MovieDAO;

import com.cinema.model.Movie;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO để lấy danh sách phim đang chiếu và sắp chiếu cho trang home và dashboard.
 */
public class HomeMovieDAO {
    
    /**
     * Model để hiển thị phim kèm thông tin suất chiếu gần nhất.
     */
    public static class HomeMovieItem {
        private final Movie movie;
        private final boolean hasShowtime;
        private final String nextShowtimeLabel;
        
        public HomeMovieItem(Movie movie, boolean hasShowtime, String nextShowtimeLabel) {
            this.movie = movie;
            this.hasShowtime = hasShowtime;
            this.nextShowtimeLabel = nextShowtimeLabel;
        }
        
        public Movie getMovie() { return movie; }
        public boolean isHasShowtime() { return hasShowtime; }
        public String getNextShowtimeLabel() { return nextShowtimeLabel; }
    }
    
    /**
     * Lấy danh sách phim đang chiếu kèm thông tin suất chiếu gần nhất.
     */
    public List<HomeMovieItem> findNowShowing() throws SQLException {
        List<HomeMovieItem> items = new ArrayList<>();
        
        String sql = "SELECT DISTINCT "
                + "  m.movie_id, m.title, m.original_title, m.synopsis, m.director, "
                + "  m.main_cast, m.duration_minutes, m.spoken_language, m.country, "
                + "  m.age_rating, m.trailer_url, m.trailer_file, m.poster_url, "
                + "  m.release_date, m.end_date, m.status, m.created_at, m.updated_at, "
                + "  mg.genre_ids, "
                + "  (SELECT STRING_AGG(g.genre_name, ', ') "
                + "   FROM Genre g WHERE g.genre_id IN (SELECT value FROM STRING_SPLIT(mg.genre_ids, ','))) as genres, "
                + "  (SELECT MIN(ts.slot_name) FROM Showtime s "
                + "   JOIN TimeSlot ts ON ts.slot_id = s.slot_id "
                + "   WHERE s.movie_id = m.movie_id AND s.start_time >= GETDATE()) as next_showtime "
                + "FROM Movie m "
                + "LEFT JOIN (SELECT movie_id, STRING_AGG(CAST(genre_id AS VARCHAR(10)), ',') as genre_ids "
                + "           FROM MovieGenre GROUP BY movie_id) mg ON m.movie_id = mg.movie_id "
                + "WHERE m.release_date <= CAST(GETDATE() AS DATE) "
                + "AND (m.end_date IS NULL OR m.end_date >= CAST(GETDATE() AS DATE)) "
                + "AND m.status <> 'Stopped' "
                + "ORDER BY m.created_at DESC, m.movie_id DESC";
        
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                Movie movie = mapMovie(result);
                String nextShowtime = result.getString("next_showtime");
                boolean hasShowtime = nextShowtime != null && !nextShowtime.isEmpty();
                items.add(new HomeMovieItem(movie, hasShowtime, nextShowtime));
            }
        }
        
        return items;
    }
    
    /**
     * Lấy danh sách phim sắp chiếu.
     */
    public List<HomeMovieItem> findUpcoming() throws SQLException {
        List<HomeMovieItem> items = new ArrayList<>();
        
        String sql = "SELECT DISTINCT "
                + "  m.movie_id, m.title, m.original_title, m.synopsis, m.director, "
                + "  m.main_cast, m.duration_minutes, m.spoken_language, m.country, "
                + "  m.age_rating, m.trailer_url, m.trailer_file, m.poster_url, "
                + "  m.release_date, m.end_date, m.status, m.created_at, m.updated_at, "
                + "  mg.genre_ids, "
                + "  (SELECT STRING_AGG(g.genre_name, ', ') "
                + "   FROM Genre g WHERE g.genre_id IN (SELECT value FROM STRING_SPLIT(mg.genre_ids, ','))) as genres, "
                + "  NULL as next_showtime "
                + "FROM Movie m "
                + "LEFT JOIN (SELECT movie_id, STRING_AGG(CAST(genre_id AS VARCHAR(10)), ',') as genre_ids "
                + "           FROM MovieGenre GROUP BY movie_id) mg ON m.movie_id = mg.movie_id "
                + "WHERE m.release_date > CAST(GETDATE() AS DATE) "
                + "ORDER BY m.release_date ASC, m.movie_id DESC";
        
        try (Connection connection = DBContext.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                Movie movie = mapMovie(result);
                items.add(new HomeMovieItem(movie, false, null));
            }
        }
        
        return items;
    }
    
    private Movie mapMovie(ResultSet result) throws SQLException {
        Movie movie = new Movie();
        movie.setMovieId(result.getInt("movie_id"));
        movie.setTitle(result.getString("title"));
        movie.setOriginalTitle(result.getString("original_title"));
        movie.setSynopsis(result.getString("synopsis"));
        movie.setDirector(result.getString("director"));
        movie.setMainCast(result.getString("main_cast"));
        movie.setDurationMinutes(result.getInt("duration_minutes"));
        movie.setSpokenLanguage(result.getString("spoken_language"));
        movie.setCountry(result.getString("country"));
        movie.setAgeRating(result.getString("age_rating"));
        movie.setTrailerUrl(result.getString("trailer_url"));
        movie.setTrailerFile(result.getString("trailer_file"));
        movie.setPosterUrl(result.getString("poster_url"));
        
        java.sql.Date releaseDate = result.getDate("release_date");
        movie.setReleaseDate(releaseDate == null ? null : releaseDate.toLocalDate());
        java.sql.Date endDate = result.getDate("end_date");
        movie.setEndDate(endDate == null ? null : endDate.toLocalDate());
        
        movie.setStatus(result.getString("status"));
        
        java.sql.Timestamp created = result.getTimestamp("created_at");
        movie.setCreatedAt(created == null ? null : created.toLocalDateTime());
        java.sql.Timestamp updated = result.getTimestamp("updated_at");
        movie.setUpdatedAt(updated == null ? null : updated.toLocalDateTime());
        
        movie.setGenres(result.getString("genres"));
        movie.setGenreIds(result.getString("genre_ids"));
        
        return movie;
    }
}
