package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.AppConfig;
import com.cinema.util.EmailService;
import com.cinema.util.SecurityUtil;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/** BF01 – Guest registers: validate → create account (PENDING) → email OTP. */
@WebServlet("/register")
public class RegisterServlet extends BaseServlet {

    private static final Set<String> GENDERS = Set.of("MALE", "FEMALE", "OTHER");
    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (currentUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }
        forward(req, resp, "register");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String fullName = Validator.trim(req.getParameter("fullName"));
        String email = Validator.trim(req.getParameter("email")).toLowerCase();
        String phone = Validator.trim(req.getParameter("phone"));
        String password = req.getParameter("password");
        String confirm = req.getParameter("confirmPassword");
        String dobStr = Validator.trim(req.getParameter("dob"));
        String gender = Validator.trim(req.getParameter("gender"));

        Map<String, String> errors = new LinkedHashMap<>();
        if (!Validator.isFullName(fullName)) {
            errors.put("fullName", "Họ tên phải từ 2 đến 100 ký tự.");
        }
        if (!Validator.isEmail(email)) {
            errors.put("email", "Email không hợp lệ.");
        }
        if (!Validator.isPhone(phone)) {
            errors.put("phone", "Số điện thoại phải gồm 10 số (bắt đầu 0) hoặc +84.");
        }
        if (!Validator.isStrongPassword(password)) {
            errors.put("password", Validator.PASSWORD_RULE);
        } else if (!password.equals(confirm)) {
            errors.put("confirmPassword", "Mật khẩu xác nhận không khớp.");
        }
        LocalDate dob = Validator.parseDob(dobStr);
        if (!dobStr.isEmpty() && dob == null) {
            errors.put("dob", "Ngày sinh không hợp lệ.");
        }
        if (!gender.isEmpty() && !GENDERS.contains(gender)) {
            gender = "";
        }

        try {
            if (!errors.containsKey("email")) {
                User existing = dao.findByEmail(email);
                if (existing != null && "PENDING".equals(existing.getStatus())) {
                    // abandoned registration: re-send OTP so the owner can finish verification
                    sendNewOtp(existing);
                    req.getSession().setAttribute("pendingEmail", email);
                    flash(req, "info", "Email này đã đăng ký nhưng chưa xác thực. Chúng tôi đã gửi lại mã OTP.");
                    resp.sendRedirect(req.getContextPath() + "/verify-otp");
                    return;
                }
                if (existing != null) {
                    errors.put("email", "Email đã được sử dụng.");
                }
            }
            if (!errors.containsKey("phone") && dao.phoneExists(phone, 0)) {
                errors.put("phone", "Số điện thoại đã được sử dụng.");
            }

            if (!errors.isEmpty()) {
                req.setAttribute("errors", errors);
                req.setAttribute("form", Map.of("fullName", fullName, "email", email, "phone", phone,
                        "dob", dobStr, "gender", gender));
                forward(req, resp, "register");
                return;
            }

            User u = new User();
            u.setFullName(fullName);
            u.setEmail(email);
            u.setPhone(phone);
            u.setPasswordHash(SecurityUtil.hashPassword(password));
            u.setDateOfBirth(dob);
            u.setGender(gender.isEmpty() ? null : gender);

            String otp = SecurityUtil.generateOtp();
            LocalDateTime expiry = LocalDateTime.now().plusMinutes(AppConfig.getInt("otp.ttl.minutes", 5));
            dao.insertPending(u, SecurityUtil.sha256(otp), expiry);
            boolean sent = EmailService.sendOtp(email, otp);

            req.getSession().setAttribute("pendingEmail", email);
            flash(req, sent ? "success" : "error", sent
                    ? "Đăng ký thành công. Mã OTP đã được gửi tới " + email + "."
                    : "Tạo tài khoản thành công nhưng chưa gửi được email. Hãy bấm “Gửi lại mã”.");
            resp.sendRedirect(req.getContextPath() + "/verify-otp");
        } catch (SQLException e) {
            // unique-constraint race (SQL Server error 2627/2601) is reported as a normal duplicate
            if (e.getErrorCode() == 2627 || e.getErrorCode() == 2601) {
                errors.put("email", "Email hoặc số điện thoại đã được sử dụng.");
                req.setAttribute("errors", errors);
                forward(req, resp, "register");
                return;
            }
            throw new ServletException(e);
        }
    }

    static void sendNewOtp(User u) throws SQLException {
        String otp = SecurityUtil.generateOtp();
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(AppConfig.getInt("otp.ttl.minutes", 5));
        new UserDAO().saveOtp(u.getUserId(), SecurityUtil.sha256(otp), expiry);
        EmailService.sendOtp(u.getEmail(), otp);
    }
}
