package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/** Manage Personal Account – view / edit profile (email is read-only). */
@WebServlet("/account/profile")
public class ProfileServlet extends BaseServlet {

    private static final Set<String> GENDERS = Set.of("MALE", "FEMALE", "OTHER");
    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        try {
            User u = dao.findById(currentUser(req).getUserId());
            if (u == null) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            req.setAttribute("profile", u);
            forward(req, resp, "profile");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        int id = currentUser(req).getUserId();
        String fullName = Validator.trim(req.getParameter("fullName"));
        String phone = Validator.trim(req.getParameter("phone"));
        String dobStr = Validator.trim(req.getParameter("dob"));
        String gender = Validator.trim(req.getParameter("gender"));

        Map<String, String> errors = new LinkedHashMap<>();
        if (!Validator.isFullName(fullName)) {
            errors.put("fullName", "Họ tên phải từ 2 đến 100 ký tự.");
        }
        if (!Validator.isPhone(phone)) {
            errors.put("phone", "Số điện thoại phải gồm 10 số (bắt đầu 0) hoặc +84.");
        }
        LocalDate dob = Validator.parseDob(dobStr);
        if (!dobStr.isEmpty() && dob == null) {
            errors.put("dob", "Ngày sinh không hợp lệ.");
        }
        try {
            if (!errors.containsKey("phone") && dao.phoneExists(phone, id)) {
                errors.put("phone", "Số điện thoại đã được sử dụng.");
            }
            if (!errors.isEmpty()) {
                User u = dao.findById(id);
                u.setFullName(fullName);
                u.setPhone(phone);
                u.setGender(gender);
                u.setDateOfBirth(dob);
                req.setAttribute("profile", u);
                req.setAttribute("errors", errors);
                forward(req, resp, "profile");
                return;
            }
            dao.updateProfile(id, fullName, phone, dob, GENDERS.contains(gender) ? gender : null);
            User fresh = dao.findById(id);
            req.getSession().setAttribute(SESSION_USER, sessionCopy(fresh));
            flash(req, "success", "Đã cập nhật thông tin cá nhân.");
            resp.sendRedirect(req.getContextPath() + "/account/profile");
        } catch (SQLException e) {
            if (e.getErrorCode() == 2627 || e.getErrorCode() == 2601) {
                errors.put("phone", "Số điện thoại đã được sử dụng.");
                req.setAttribute("errors", errors);
                doGet(req, resp);
                return;
            }
            throw new ServletException(e);
        }
    }
}
