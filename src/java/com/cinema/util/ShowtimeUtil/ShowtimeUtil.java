package com.cinema.util.ShowtimeUtil;

public final class ShowtimeUtil {
    private ShowtimeUtil() {
    }

    public static String requiredText(String value, String message, int maxLength) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.isEmpty() || trimmed.length() > maxLength) {
            throw new IllegalArgumentException(message);
        }
        return trimmed;
    }

    public static int parseId(String value) {
        try {
            int id = Integer.parseInt(value);
            if (id > 0) {
                return id;
            }
        } catch (NumberFormatException | NullPointerException e) {
            throw new IllegalArgumentException("Mã suất chiếu hoặc phim không hợp lệ.");
        }
        throw new IllegalArgumentException("Mã suất chiếu hoặc phim không hợp lệ.");
    }
}
