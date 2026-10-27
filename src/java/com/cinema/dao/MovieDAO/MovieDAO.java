package com.cinema.dao.MovieDAO;

import com.cinema.model.Movie;
import com.cinema.util.DBContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class MovieDAO {
    public record MoviePage(List<Movie> movies, int page, int totalPages, int totalItems) {
        public List<Movie> getMovies() {
            return movies;
        }

        public int getPage() {
            return page;
        }

        public int getTotalPages() {
            return totalPages;
        }

        public int getTotalItems() {
            return totalItems;
        }
    }

    private static final String FROM_VIEW = " FROM dbo.vw_MovieDetail d "
            + "WHERE (? IS NULL OR d.title LIKE N'%' + ? + N'%' "
            + "OR d.original_title LIKE N'%' + ? + N'%') "
            + "AND (? IS NULL OR d.status = ?) "
            + "AND (? IS NULL OR EXISTS (SELECT 1 FROM dbo.MovieGenre mg "
            + "WHERE mg.movie_id = d.movie_id AND mg.genre_id = ?)) ";

    public MoviePage search(String keyword, Integer genreId, String status, int requestedPage, int pageSize)
            throws SQLException {
        String cleanKeyword = keyword == null || keyword.isBlank() ? null : keyword.trim();
        String cleanStatus = status == null || status.isBlank() ? null : status;
        int count;
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement("SELECT COUNT(*)" + FROM_VIEW)) {
            bindFilters(statement, cleanKeyword, genreId, cleanStatus);
            try (ResultSet result = statement.executeQuery()) {
                result.next();
                count = result.getInt(1);
            }
        }
        int totalPages = Math.max(1, (int) Math.ceil((double) count / pageSize));
        int page = Math.max(1, Math.min(requestedPage, totalPages));
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT d.*" + FROM_VIEW
                + "ORDER BY d.release_date DESC, d.movie_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            int next = bindFilters(statement, cleanKeyword, genreId, cleanStatus);
            statement.setInt(next++, (page - 1) * pageSize);
            statement.setInt(next, pageSize);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) movies.add(map(result));
            }
        }
        return new MoviePage(movies, page, totalPages, count);
    }

    public Movie findById(int id) throws SQLException {
        String sql = "SELECT * FROM dbo.vw_MovieDetail WHERE movie_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet result = statement.executeQuery()) {
                return result.next() ? map(result) : null;
            }
        }
    }

    public List<Movie> findAllForShowtime() throws SQLException {
        List<Movie> movies = new ArrayList<>();
        String sql = "SELECT * FROM dbo.vw_MovieDetail ORDER BY title";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                movies.add(map(result));
            }
        }
        return movies;
    }

    public int save(Movie movie, String genreIds, int accountId) throws SQLException {
        String sql = "{CALL dbo.sp_SaveMovie(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}";
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall(sql)) {
            if (movie.getMovieId() > 0) statement.setInt(1, movie.getMovieId());
            else statement.setNull(1, Types.INTEGER);
            statement.setString(2, movie.getTitle());
            statement.setString(3, movie.getOriginalTitle());
            statement.setString(4, movie.getSynopsis());
            statement.setString(5, movie.getDirector());
            statement.setString(6, movie.getMainCast());
            statement.setInt(7, movie.getDurationMinutes());
            statement.setString(8, movie.getSpokenLanguage());
            statement.setString(9, movie.getCountry());
            statement.setString(10, movie.getAgeRating());
            statement.setString(11, movie.getTrailerUrl());
            statement.setString(12, movie.getPosterUrl());
            statement.setDate(13, Date.valueOf(movie.getReleaseDate()));
            if (movie.getEndDate() == null) statement.setNull(14, Types.DATE);
            else statement.setDate(14, Date.valueOf(movie.getEndDate()));
            statement.setString(15, movie.getStatus());
            statement.setString(16, genreIds);
            statement.setInt(17, accountId);
            statement.registerOutParameter(18, Types.INTEGER);
            statement.setString(19, movie.getTrailerFile());
            statement.execute();
            return statement.getInt(18);
        }
    }

    public void delete(int id) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_DeleteMovie(?)}")) {
            statement.setInt(1, id);
            statement.execute();
        }
    }

    public void stop(int id) throws SQLException {
        try (Connection connection = DBContext.getConnection();
                CallableStatement statement = connection.prepareCall("{CALL dbo.sp_StopMovie(?)}")) {
            statement.setInt(1, id);
            statement.execute();
        }
    }

    private int bindFilters(PreparedStatement statement, String keyword, Integer genreId, String status)
            throws SQLException {
        int index = 1;
        statement.setString(index++, keyword);
        statement.setString(index++, keyword);
        statement.setString(index++, keyword);
        statement.setString(index++, status);
        statement.setString(index++, status);
        if (genreId == null) statement.setNull(index++, Types.INTEGER);
        else statement.setInt(index++, genreId);
        if (genreId == null) statement.setNull(index++, Types.INTEGER);
        else statement.setInt(index++, genreId);
        return index;
    }

    private Movie map(ResultSet result) throws SQLException {
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
        Date releaseDate = result.getDate("release_date");
        movie.setReleaseDate(releaseDate == null ? null : releaseDate.toLocalDate());
        Date endDate = result.getDate("end_date");
        movie.setEndDate(endDate == null ? null : endDate.toLocalDate());
        movie.setStatus(result.getString("status"));
        var created = result.getTimestamp("created_at");
        movie.setCreatedAt(created == null ? null : created.toLocalDateTime());
        var updated = result.getTimestamp("updated_at");
        movie.setUpdatedAt(updated == null ? null : updated.toLocalDateTime());
        movie.setCreatedBy(result.getInt("created_by"));
        movie.setCreatedByName(result.getString("created_by_name"));
        movie.setGenres(result.getString("genres"));
        movie.setGenreIds(result.getString("genre_ids"));
        return movie;
    }
}
