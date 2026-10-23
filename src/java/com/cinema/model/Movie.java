package com.cinema.model;

import java.net.URI;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Movie {
    private static final Pattern MEDIA_POSTER = Pattern.compile("^/media/posters/[0-9a-fA-F-]{36}\\.(jpg|jpeg|png|webp)$");
    private static final Pattern MEDIA_TRAILER = Pattern.compile("^/media/trailers/[0-9a-fA-F-]{36}\\.(mp4|webm)$");
    private int movieId;
    private String title;
    private String originalTitle;
    private String synopsis;
    private String director;
    private String mainCast;
    private int durationMinutes;
    private String spokenLanguage;
    private String country;
    private String ageRating;
    private String trailerUrl;
    private String trailerFile;
    private String posterUrl;
    private LocalDate releaseDate;
    private LocalDate endDate;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private int createdBy;
    private String createdByName;
    private String genres;
    private String genreIds;

    public int getMovieId() { return movieId; }
    public void setMovieId(int movieId) { this.movieId = movieId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getOriginalTitle() { return originalTitle; }
    public void setOriginalTitle(String originalTitle) { this.originalTitle = originalTitle; }
    public String getSynopsis() { return synopsis; }
    public void setSynopsis(String synopsis) { this.synopsis = synopsis; }
    public String getDirector() { return director; }
    public void setDirector(String director) { this.director = director; }
    public String getMainCast() { return mainCast; }
    public void setMainCast(String mainCast) { this.mainCast = mainCast; }
    public int getDurationMinutes() { return durationMinutes; }
    public void setDurationMinutes(int durationMinutes) { this.durationMinutes = durationMinutes; }
    public String getSpokenLanguage() { return spokenLanguage; }
    public void setSpokenLanguage(String spokenLanguage) { this.spokenLanguage = spokenLanguage; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getAgeRating() { return ageRating; }
    public void setAgeRating(String ageRating) { this.ageRating = ageRating; }
    public String getTrailerUrl() { return trailerUrl; }
    public void setTrailerUrl(String trailerUrl) { this.trailerUrl = trailerUrl; }
    public String getTrailerFile() { return trailerFile; }
    public void setTrailerFile(String trailerFile) { this.trailerFile = trailerFile; }
    public String getPosterUrl() { return posterUrl; }
    public void setPosterUrl(String posterUrl) { this.posterUrl = posterUrl; }
    public LocalDate getReleaseDate() { return releaseDate; }
    public void setReleaseDate(LocalDate releaseDate) { this.releaseDate = releaseDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public int getCreatedBy() { return createdBy; }
    public void setCreatedBy(int createdBy) { this.createdBy = createdBy; }
    public String getCreatedByName() { return createdByName; }
    public void setCreatedByName(String createdByName) { this.createdByName = createdByName; }
    public String getGenres() { return genres; }
    public void setGenres(String genres) { this.genres = genres; }
    public String getGenreIds() { return genreIds; }
    public void setGenreIds(String genreIds) { this.genreIds = genreIds; }

    public String getPosterDisplayUrl() {
        if (posterUrl == null || posterUrl.isBlank()) return null;
        if (MEDIA_POSTER.matcher(posterUrl).matches()) return posterUrl;
        return isHttpUrl(posterUrl) ? posterUrl : null;
    }

    public boolean isUploadedPoster() {
        return posterUrl != null && MEDIA_POSTER.matcher(posterUrl).matches();
    }

    public String getTrailerFileDisplayUrl() {
        return trailerFile != null && MEDIA_TRAILER.matcher(trailerFile).matches() ? trailerFile : null;
    }

    public String getTrailerMimeType() {
        return trailerFile != null && trailerFile.endsWith(".webm") ? "video/webm" : "video/mp4";
    }

    public String getTrailerLinkUrl() {
        return isHttpUrl(trailerUrl) ? trailerUrl : null;
    }

    public String getTrailerEmbedUrl() {
        if (!isHttpUrl(trailerUrl)) return null;
        try {
            URI uri = URI.create(trailerUrl);
            String host = uri.getHost().toLowerCase();
            String id = null;
            if ("youtu.be".equals(host) || "www.youtu.be".equals(host)) {
                id = uri.getPath().replaceFirst("^/", "");
            } else if ("youtube.com".equals(host) || "www.youtube.com".equals(host)
                    || "m.youtube.com".equals(host) || "youtube-nocookie.com".equals(host)
                    || "www.youtube-nocookie.com".equals(host)) {
                if ("/watch".equals(uri.getPath())) {
                    for (String pair : uri.getRawQuery() == null ? new String[0] : uri.getRawQuery().split("&")) {
                        String[] keyValue = pair.split("=", 2);
                        if (keyValue.length == 2 && "v".equals(keyValue[0])) id = keyValue[1];
                    }
                } else if (uri.getPath().startsWith("/embed/")) {
                    id = uri.getPath().substring("/embed/".length());
                } else if (uri.getPath().startsWith("/shorts/")) {
                    id = uri.getPath().substring("/shorts/".length());
                }
            }
            if (id == null || !id.matches("[A-Za-z0-9_-]{6,20}")) return null;
            return "https://www.youtube-nocookie.com/embed/" + id;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static boolean isHttpUrl(String value) {
        try {
            URI uri = URI.create(value);
            return ("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme()))
                    && uri.getHost() != null && !uri.getHost().isBlank();
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
