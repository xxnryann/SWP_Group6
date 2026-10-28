package com.cinema.controller;

import com.cinema.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/staff")
public class StaffDashboardServlet extends BaseServlet {
    static boolean isStaff(User user) {
        if (user == null) return false;
        String role = user.getRole() == null ? "" : user.getRole().trim();
        return "STAFF".equalsIgnoreCase(role)
                || "MANAGER".equalsIgnoreCase(role)
                || "ADMIN".equalsIgnoreCase(role);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        if (!isStaff(user)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ nhân viên được truy cập.");
            return;
        }
        req.setAttribute("pageTitle", "Staff Dashboard");
        forward(req, resp, "staff/dashboard");
    }
}
