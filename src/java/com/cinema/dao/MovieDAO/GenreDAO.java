package com.cinema.dao.MovieDAO;

import com.cinema.model.Genre;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class GenreDAO {
    public List<Genre> findAll() throws SQLException {
        List<Genre> genres = new ArrayList<>();
        String sql = "SELECT genre_id, genre_name, description FROM dbo.Genre ORDER BY genre_name";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql);
                ResultSet result = statement.executeQuery()) {
            while (result.next()) {
                Genre genre = new Genre();
                genre.setGenreId(result.getInt("genre_id"));
                genre.setGenreName(result.getString("genre_name"));
                genre.setDescription(result.getString("description"));
                genres.add(genre);
            }
        }
        return genres;
    }
}
