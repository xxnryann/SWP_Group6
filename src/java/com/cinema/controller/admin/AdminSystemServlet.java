package com.cinema.controller.admin;

import com.cinema.controller.BaseServlet;
import com.cinema.controller.filter.AuditFilter;
import com.cinema.dao.SystemDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/** Quản lý hệ thống (Admin): sao lưu dữ liệu và nhật ký hệ thống. URL: /admin/system */
@WebServlet("/admin/system")
public class AdminSystemServlet extends BaseServlet {

    private static final int LOG_LIMIT = 200;

    private final SystemDAO dao = new SystemDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "ADMIN")) return;
        String tab = "logs".equals(Validator.trim(req.getParameter("tab"))) ? "logs" : "backup";
        try {
            if ("logs".equals(tab)) {
                String q = Validator.trim(req.getParameter("q"));
                LocalDate from = date(req.getParameter("from"));
                LocalDate to = date(req.getParameter("to"));
                req.setAttribute("logs", dao.logs(q, from, to, LOG_LIMIT));
                req.setAttribute("q", q);
                req.setAttribute("from", from);
                req.setAttribute("to", to);
                req.setAttribute("logLimit", LOG_LIMIT);
            } else {
                req.setAttribute("backups", dao.backups(20));
            }
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải dữ liệu: " + e.getMessage());
        }
        req.setAttribute("tab", tab);
        req.setAttribute("pageTitle", "Quản lý hệ thống");
        forward(req, resp, "admin/admin-system");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        String action = Validator.trim(req.getParameter("action"));
        if (!"backup".equals(action)) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }
        try {
            String path = dao.backup();
            req.setAttribute(AuditFilter.DETAIL_ATTR, "file=" + path);
            flash(req, "success", "Đã sao lưu CSDL vào " + path);
        } catch (SQLException e) {
            getServletContext().log("System management action failed: " + action, e);
            flash(req, "error", "Không thể thực hiện: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/system?tab=backup");
    }

    private static LocalDate date(String value) {
        try {
            if (value == null || value.isBlank()) return null;
            LocalDate date = LocalDate.parse(value.trim());
            // Bộ lọc "đến ngày" cộng thêm 1 ngày, năm ngoài khoảng của SQL Server sẽ làm truy vấn lỗi.
            return date.getYear() >= 1 && date.getYear() < 9999 ? date : null;
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}
