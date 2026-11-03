package com.cinema.dao;

import com.cinema.model.Genre;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.HashSet;

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

    public int create(String name, String description) throws SQLException {
        String sql = "INSERT INTO dbo.Genre (genre_name, description) VALUES (?, ?)";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql,
                        java.sql.Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, name);
            statement.setString(2, description);
            statement.executeUpdate();
            try (ResultSet keys = statement.getGeneratedKeys()) {
                if (keys.next()) return keys.getInt(1);
            }
        }
        throw new SQLException("Không thể tạo thể loại.");
    }

    public void update(int id, String name, String description) throws SQLException {
        String sql = "UPDATE dbo.Genre SET genre_name = ?, description = ? WHERE genre_id = ?";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, name);
            statement.setString(2, description);
            statement.setInt(3, id);
            if (statement.executeUpdate() == 0) throw new SQLException("Không tìm thấy thể loại.");
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM dbo.Genre WHERE genre_id = ? "
                + "AND NOT EXISTS (SELECT 1 FROM dbo.MovieGenre WHERE genre_id = ?)";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            statement.setInt(2, id);
            if (statement.executeUpdate() == 0) {
                throw new IllegalStateException("Không thể xóa thể loại đang được sử dụng bởi phim.");
            }
        }
    }

    public Set<Integer> findExistingIds(int[] ids) throws SQLException {
        Set<Integer> existing = new HashSet<>();
        if (ids == null || ids.length == 0) return existing;
        String sql = "SELECT genre_id FROM dbo.Genre WHERE genre_id IN ("
                + String.join(",", java.util.Collections.nCopies(ids.length, "?")) + ")";
        try (Connection connection = DBContext.getConnection();
                PreparedStatement statement = connection.prepareStatement(sql)) {
            for (int i = 0; i < ids.length; i++) statement.setInt(i + 1, ids[i]);
            try (ResultSet result = statement.executeQuery()) {
                while (result.next()) existing.add(result.getInt(1));
            }
        }
        return existing;
    }
}
