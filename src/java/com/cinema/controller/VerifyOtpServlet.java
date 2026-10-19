package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.AppConfig;
import com.cinema.util.SecurityUtil;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.SQLException;
import java.time.Duration;
import java.time.LocalDateTime;

/** BF01 – verify the emailed OTP and set Status = ACTIVE. */
@WebServlet("/verify-otp")
public class VerifyOtpServlet extends BaseServlet {

    private static final int RESEND_COOLDOWN_SECONDS = 60;
    private final UserDAO dao = new UserDAO();

    private String pendingEmail(HttpServletRequest req) {
        var s = req.getSession(false);
        return s == null ? null : (String) s.getAttribute("pendingEmail");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String email = pendingEmail(req);
        if (email == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.setAttribute("email", email);
        forward(req, resp, "verify-otp");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        String email = pendingEmail(req);
        if (email == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        try {
            User u = dao.findByEmail(email);
            if (u == null || !"PENDING".equals(u.getStatus())) {
                req.getSession().removeAttribute("pendingEmail");
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            if ("resend".equals(req.getParameter("action"))) {
                resend(req, resp, u);
            } else {
                verify(req, resp, u);
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void resend(HttpServletRequest req, HttpServletResponse resp, User u)
            throws SQLException, IOException {
        int ttl = AppConfig.getInt("otp.ttl.minutes", 5);
        if (u.getOtpExpiry() != null) {
            LocalDateTime lastSent = u.getOtpExpiry().minusMinutes(ttl);
            long since = Duration.between(lastSent, LocalDateTime.now()).getSeconds();
            if (since < RESEND_COOLDOWN_SECONDS) {
                flash(req, "error", "Vui lòng đợi " + (RESEND_COOLDOWN_SECONDS - since) + " giây trước khi gửi lại.");
                resp.sendRedirect(req.getContextPath() + "/verify-otp");
                return;
            }
        }
        RegisterServlet.sendNewOtp(u);
        flash(req, "success", "Đã gửi lại mã OTP.");
        resp.sendRedirect(req.getContextPath() + "/verify-otp");
    }

    private void verify(HttpServletRequest req, HttpServletResponse resp, User u)
            throws SQLException, ServletException, IOException {
        String code = Validator.trim(req.getParameter("otp"));
        String error = null;
        if (u.getOtpHash() == null || u.getOtpExpiry() == null || u.getOtpExpiry().isBefore(LocalDateTime.now())) {
            error = "Mã OTP đã hết hạn. Hãy bấm “Gửi lại mã”.";
        } else if (u.getOtpAttempts() >= AppConfig.getInt("otp.max.attempts", 5)) {
            error = "Bạn đã nhập sai quá nhiều lần. Hãy bấm “Gửi lại mã” để nhận mã mới.";
        } else if (!code.matches("\\d{6}")
                || !MessageDigest.isEqual(SecurityUtil.sha256(code).getBytes(StandardCharsets.UTF_8),
                        u.getOtpHash().getBytes(StandardCharsets.UTF_8))) {
            dao.incrementOtpAttempts(u.getUserId());
            error = "Mã OTP không đúng.";
        }
        if (error != null) {
            req.setAttribute("error", error);
            req.setAttribute("email", u.getEmail());
            forward(req, resp, "verify-otp");
            return;
        }
        dao.activate(u.getUserId());
        req.getSession().removeAttribute("pendingEmail");
        flash(req, "success", "Xác thực thành công. Hãy đăng nhập.");
        resp.sendRedirect(req.getContextPath() + "/login");
    }
}
