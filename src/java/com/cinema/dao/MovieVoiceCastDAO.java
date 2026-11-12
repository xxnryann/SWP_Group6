package com.cinema.dao;

import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/** Diễn viên lồng tiếng của phim theo từng ngôn ngữ (bảng MovieVoiceCast). */
public class MovieVoiceCastDAO {

    /** Ngôn ngữ -> danh sách diễn viên lồng tiếng của một phim. */
    public Map<String, String> findByMovie(int movieId) throws SQLException {
        Map<String, String> casts = new LinkedHashMap<>();
        String sql = "SELECT language, voice_cast FROM dbo.MovieVoiceCast WHERE movie_id = ? ORDER BY language";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) casts.put(rs.getString("language"), rs.getString("voice_cast"));
            }
        }
        return casts;
    }

    /** movieId -> (ngôn ngữ -> diễn viên lồng tiếng) của mọi phim, dùng cho form thêm suất chiếu. */
    public Map<Integer, Map<String, String>> findAll() throws SQLException {
        Map<Integer, Map<String, String>> all = new LinkedHashMap<>();
        String sql = "SELECT movie_id, language, voice_cast FROM dbo.MovieVoiceCast ORDER BY movie_id, language";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                all.computeIfAbsent(rs.getInt("movie_id"), k -> new LinkedHashMap<>())
                        .put(rs.getString("language"), rs.getString("voice_cast"));
            }
        }
        return all;
    }

    public String find(int movieId, String language) throws SQLException {
        String sql = "SELECT voice_cast FROM dbo.MovieVoiceCast WHERE movie_id = ? AND language = ?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, movieId);
            ps.setString(2, language);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    /** Thêm mới hoặc cập nhật diễn viên lồng tiếng của phim cho một ngôn ngữ. */
    public void save(int movieId, String language, String voiceCast) throws SQLException {
        String sql = "MERGE dbo.MovieVoiceCast AS t "
                + "USING (SELECT ? AS movie_id, ? AS language, ? AS voice_cast) AS s "
                + "ON t.movie_id = s.movie_id AND t.language = s.language "
                + "WHEN MATCHED THEN UPDATE SET voice_cast = s.voice_cast, updated_at = SYSDATETIME() "
                + "WHEN NOT MATCHED THEN INSERT (movie_id, language, voice_cast) VALUES (s.movie_id, s.language, s.voice_cast);";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, movieId);
            ps.setString(2, language);
            ps.setString(3, voiceCast);
            ps.executeUpdate();
        }
    }

    public void delete(int movieId, String language) throws SQLException {
        String sql = "DELETE FROM dbo.MovieVoiceCast WHERE movie_id = ? AND language = ?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, movieId);
            ps.setString(2, language);
            ps.executeUpdate();
        }
    }

    /** Quốc gia và danh sách ngôn ngữ của phim: [country, spoken_language]; null nếu không có phim. */
    public String[] movieLocale(int movieId) throws SQLException {
        String sql = "SELECT country, spoken_language FROM dbo.Movie WHERE movie_id = ?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? new String[] {rs.getString(1), rs.getString(2)} : null;
            }
        }
    }
}
