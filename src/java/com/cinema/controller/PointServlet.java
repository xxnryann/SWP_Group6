package com.cinema.controller;

import com.cinema.dao.PointDAO;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/staff/point")
public class PointServlet extends BaseServlet {
    private final PointDAO dao = new PointDAO();

    private boolean requireStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = currentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        if (!StaffDashboardServlet.isStaff(user)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ nhân viên được truy cập.");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp)) return;
        try {
            String keyword = Validator.trim(req.getParameter("q"));
            req.setAttribute("pointCustomers", dao.findCustomers(keyword));
            req.setAttribute("keyword", keyword);
            req.setAttribute("pageTitle", "Quản lý point");
            forward(req, resp, "point/point-list");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp) || !csrfOk(req, resp)) return;
        try {
            int customerId = Integer.parseInt(Validator.trim(req.getParameter("customerId")));
            int points = Integer.parseInt(Validator.trim(req.getParameter("points")));
            dao.adjust(customerId, points);
            flash(req, "success", "Đã cập nhật điểm khách hàng.");
        } catch (NumberFormatException e) {
            flash(req, "error", "Mã khách hàng và số điểm phải là số hợp lệ.");
        } catch (Exception e) {
            flash(req, "error", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/staff/point");
    }
}
