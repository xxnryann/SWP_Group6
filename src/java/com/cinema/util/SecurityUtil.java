package com.cinema.util;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import org.mindrot.jbcrypt.BCrypt;

public final class SecurityUtil {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String CSRF_KEY = "csrfToken";

    private SecurityUtil() {
    }

    // ---- passwords ----
    public static String hashPassword(String raw) {
        return BCrypt.hashpw(raw, BCrypt.gensalt(10));
    }

    public static boolean checkPassword(String raw, String hash) {
        try {
            return hash != null && BCrypt.checkpw(raw, hash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    // ---- OTP ----
    public static String generateOtp() {
        return String.format("%06d", RANDOM.nextInt(1_000_000));
    }

    public static String sha256(String s) {
        try {
            byte[] d = MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : d) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    // ---- CSRF ----
    public static String csrfToken(HttpSession session) {
        String t = (String) session.getAttribute(CSRF_KEY);
        if (t == null) {
            byte[] b = new byte[24];
            RANDOM.nextBytes(b);
            t = Base64.getUrlEncoder().withoutPadding().encodeToString(b);
            session.setAttribute(CSRF_KEY, t);
        }
        return t;
    }

    public static boolean csrfValid(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) {
            return false;
        }
        String expected = (String) s.getAttribute(CSRF_KEY);
        String actual = req.getParameter("_csrf");
        return expected != null && actual != null
                && MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                        actual.getBytes(StandardCharsets.UTF_8));
    }
}
