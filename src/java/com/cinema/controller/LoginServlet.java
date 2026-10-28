package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.SecurityUtil;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** BF01 – sign in with email or phone + password. */
@WebServlet("/login")
public class LoginServlet extends BaseServlet {

    private static final int MAX_FAILS = 5;
    private static final long LOCK_SECONDS = 300;
    private static final String BAD_CREDENTIALS = "Email/số điện thoại hoặc mật khẩu không đúng.";

    /** identifier -> {failCount, lockedUntilEpochSecond}; in-memory brute-force throttle. */
    private final Map<String, long[]> failures = new ConcurrentHashMap<>();
    private static final String DUMMY_HASH = SecurityUtil.hashPassword("dummy-password-for-timing");
    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (currentUser(req) != null) {
            resp.sendRedirect(req.getContextPath()
                    + (StaffDashboardServlet.isStaff(currentUser(req)) ? "/staff" : "/home"));
            return;
        }
        forward(req, resp, "login");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        String id = Validator.trim(req.getParameter("identifier")).toLowerCase();
        String password = req.getParameter("password");
        req.setAttribute("identifier", id);

        long[] f = failures.get(id);
        if (f != null && f[1] > Instant.now().getEpochSecond()) {
            fail(req, resp, "Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau vài phút.");
            return;
        }
        try {
            User u = id.isEmpty() || password == null ? null : dao.findByIdentifier(id);
            // always run a BCrypt check so timing does not reveal whether the account exists
            boolean ok = SecurityUtil.checkPassword(password == null ? "" : password,
                    u == null ? DUMMY_HASH : u.getPasswordHash())
                    && u != null;
            if (!ok) {
                long[] cur = failures.computeIfAbsent(id, k -> new long[2]);
                if (++cur[0] >= MAX_FAILS) {
                    cur[0] = 0;
                    cur[1] = Instant.now().getEpochSecond() + LOCK_SECONDS;
                }
                fail(req, resp, BAD_CREDENTIALS);
                return;
            }
            failures.remove(id);

            if ("PENDING".equals(u.getStatus())) {
                req.getSession().setAttribute("pendingEmail", u.getEmail());
                flash(req, "info", "Tài khoản chưa được xác thực. Nhập mã OTP gửi tới email của bạn.");
                resp.sendRedirect(req.getContextPath() + "/verify-otp");
                return;
            }
            if (!"ACTIVE".equals(u.getStatus())) {
                fail(req, resp, "Tài khoản đã bị khóa. Vui lòng liên hệ rạp để được hỗ trợ.");
                return;
            }

            req.changeSessionId(); // prevent session fixation
            var session = req.getSession();
            session.setAttribute(SESSION_USER, sessionCopy(u));
            String role = u.getRole() == null ? "" : u.getRole().trim();
            if ("STAFF".equalsIgnoreCase(role)
                    || "MANAGER".equalsIgnoreCase(role)
                    || "ADMIN".equalsIgnoreCase(role)) {
                resp.sendRedirect(req.getContextPath() + "/staff");
                return;
            }
            session.removeAttribute("afterLogin");
            resp.sendRedirect(req.getContextPath() + "/home");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        forward(req, resp, "login");
    }
}
