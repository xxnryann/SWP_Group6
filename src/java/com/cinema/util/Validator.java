package com.cinema.util;

import java.time.LocalDate;
import java.util.regex.Pattern;

public final class Validator {

    private static final Pattern EMAIL = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PHONE = Pattern.compile("^(0|\\+84)\\d{9}$");

    private Validator() {
    }

    public static boolean isEmail(String s) {
        return s != null && s.length() <= 150 && EMAIL.matcher(s).matches();
    }

    /** CMND (9 số), CCCD (12 số) hoặc hộ chiếu (1 chữ cái + 7 chữ số). */
    public static boolean isIdNumber(String s) {
        return s != null && s.matches("^(\\d{9}|\\d{12}|[A-Za-z]\\d{7})$");
    }

    public static boolean isPhone(String s) {
        return s != null && PHONE.matcher(s).matches();
    }

    public static boolean isFullName(String s) {
        return s != null && s.trim().length() >= 2 && s.length() <= 100;
    }

    /** At least 8 chars, with upper, lower and digit. */
    public static boolean isStrongPassword(String s) {
        return s != null && s.length() >= 8 && s.length() <= 72
                && s.chars().anyMatch(Character::isUpperCase)
                && s.chars().anyMatch(Character::isLowerCase)
                && s.chars().anyMatch(Character::isDigit);
    }

    public static final String PASSWORD_RULE = "Mật khẩu tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.";

    /** Returns null when blank/invalid. */
    public static LocalDate parseDob(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        try {
            LocalDate d = LocalDate.parse(s);
            return d.isAfter(LocalDate.now()) || d.isBefore(LocalDate.of(1900, 1, 1)) ? null : d;
        } catch (Exception e) {
            return null;
        }
    }

    public static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
