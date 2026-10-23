package com.cinema.util.MovieUtil;

import com.cinema.model.Movie;
import java.net.URI;
import java.time.LocalDate;
import java.util.Set;

public final class MovieValidator {
    private static final Set<String> AGE_RATINGS = Set.of("P", "K", "T13", "T16", "T18");

    private MovieValidator() {
    }

    public static String validate(Movie movie) {
        if (movie.getTitle() == null || movie.getTitle().isBlank()) return "Tên phim không được để trống.";
        if (movie.getTitle().length() > 200) return "Tên phim tối đa 200 ký tự.";
        if (lengthExceeded(movie.getOriginalTitle(), 200)) return "Tên gốc tối đa 200 ký tự.";
        if (lengthExceeded(movie.getDirector(), 100)) return "Tên đạo diễn tối đa 100 ký tự.";
        if (lengthExceeded(movie.getMainCast(), 500)) return "Danh sách diễn viên tối đa 500 ký tự.";
        if (lengthExceeded(movie.getSpokenLanguage(), 50)) return "Ngôn ngữ tối đa 50 ký tự.";
        if (lengthExceeded(movie.getCountry(), 50)) return "Quốc gia tối đa 50 ký tự.";
        if (movie.getDurationMinutes() <= 0) return "Thời lượng phim phải lớn hơn 0.";
        if (movie.getAgeRating() == null || !AGE_RATINGS.contains(movie.getAgeRating())) {
            return "Phân loại tuổi phải là P, K, T13, T16 hoặc T18.";
        }
        if (movie.getReleaseDate() == null) return "Ngày khởi chiếu không được để trống.";
        if (movie.getEndDate() != null && movie.getEndDate().isBefore(movie.getReleaseDate())) {
            return "Ngày kết thúc không được trước ngày khởi chiếu.";
        }
        if (!validOptionalUrl(movie.getTrailerUrl())) return "URL trailer phải là địa chỉ HTTP hoặc HTTPS hợp lệ.";
        if (!validOptionalPosterUrl(movie.getPosterUrl())) return "URL poster phải là địa chỉ HTTP hoặc HTTPS hợp lệ.";
        if (movie.getStatus() == null || !Set.of("Upcoming", "NowShowing", "Stopped").contains(movie.getStatus())) {
            return "Trạng thái phim không hợp lệ.";
        }
        if (movie.getTrailerFile() != null && movie.getTrailerFile().length() > 500) return "Đường dẫn trailer quá dài.";
        return null;
    }

    public static LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) return null;
        return LocalDate.parse(value);
    }

    private static boolean lengthExceeded(String value, int maximum) {
        return value != null && value.length() > maximum;
    }

    private static boolean validOptionalPosterUrl(String value) {
        if (value == null || value.isBlank()) return true;
        if (value.matches("^/media/posters/[0-9a-fA-F-]{36}\\.(jpg|jpeg|png|webp)$")) return true;
        return validOptionalUrl(value);
    }

    private static boolean validOptionalUrl(String value) {
        if (value == null || value.isBlank()) return true;
        if (value.length() > 500) return false;
        try {
            URI uri = URI.create(value);
            return ("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme()))
                    && uri.getHost() != null && !uri.getHost().isBlank();
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
