package com.cinema.model;

public class Genre {
    private int genreId;
    private String genreName;
    private String description;
    private int movieCount;
    private boolean selected;

    public int getGenreId() { return genreId; }
    public void setGenreId(int genreId) { this.genreId = genreId; }
    public String getGenreName() { return genreName; }
    public void setGenreName(String genreName) { this.genreName = genreName; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public int getMovieCount() { return movieCount; }
    public void setMovieCount(int movieCount) { this.movieCount = movieCount; }
    public boolean isSelected() { return selected; }
    public void setSelected(boolean selected) { this.selected = selected; }
}
