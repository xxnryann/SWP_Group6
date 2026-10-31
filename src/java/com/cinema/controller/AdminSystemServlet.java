package com.cinema.controller;

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
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.StringJoiner;

/**
 * Quản lý hệ thống (Admin). URL: /admin/system
 *   GET ?tab=config|backup|logs   xem cấu hình, lịch sử sao lưu, nhật ký
 *   POST saveConfig               lưu cấu hình chung
 *   POST backup                   sao lưu CSDL
 */
@WebServlet("/admin/system")
public class AdminSystemServlet extends BaseServlet {

    /** Khóa cấu hình được phép sửa và khoảng giá trị hợp lệ {min, max}. */
    private static final Map<String, int[]> CONFIG_RANGES = Map.of(
            "BOOKING_SESSION_MINUTES", new int[] {5, 60},
            "CANCEL_BEFORE_HOURS", new int[] {0, 72},
            "CHECKIN_EARLY_MINUTES", new int[] {0, 180},
            "PAYMENT_WINDOW_MINUTES", new int[] {1, 30});
    private static final int LOG_LIMIT = 200;

    private final SystemDAO dao = new SystemDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "ADMIN")) return;
        String tab = Validator.trim(req.getParameter("tab"));
        if (!"backup".equals(tab) && !"logs".equals(tab)) tab = "config";
        try {
            switch (tab) {
                case "backup" -> req.setAttribute("backups", dao.backups(20));
                case "logs" -> {
                    String q = Validator.trim(req.getParameter("q"));
                    LocalDate from = date(req.getParameter("from"));
                    LocalDate to = date(req.getParameter("to"));
                    req.setAttribute("logs", dao.logs(q, from, to, LOG_LIMIT));
                    req.setAttribute("q", q);
                    req.setAttribute("from", from);
                    req.setAttribute("to", to);
                    req.setAttribute("logLimit", LOG_LIMIT);
                }
                default -> {
                    req.setAttribute("configs", dao.configs());
                    req.setAttribute("configRanges", CONFIG_RANGES);
                }
            }
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải dữ liệu: " + e.getMessage());
        }
        req.setAttribute("tab", tab);
        req.setAttribute("pageTitle", "Quản lý hệ thống");
        forward(req, resp, "admin-system");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        String action = Validator.trim(req.getParameter("action"));
        String tab = "config";
        try {
            if ("saveConfig".equals(action)) {
                saveConfig(req);
            } else if ("backup".equals(action)) {
                tab = "backup";
                String path = dao.backup();
                req.setAttribute(AuditFilter.DETAIL_ATTR, "file=" + path);
                flash(req, "success", "Đã sao lưu CSDL vào " + path);
            } else {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (IllegalArgumentException e) {
            flash(req, "error", e.getMessage());
        } catch (SQLException e) {
            getServletContext().log("System management action failed: " + action, e);
            flash(req, "error", "Không thể thực hiện: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/system?tab=" + tab);
    }

    /** Kiểm tra toàn bộ trước khi ghi, chỉ lưu các khóa có thay đổi và ghi lại giá trị cũ/mới vào nhật ký. */
    private void saveConfig(HttpServletRequest req) throws SQLException {
        Map<String, String> changed = new LinkedHashMap<>();
        StringJoiner audit = new StringJoiner(", ");
        for (Map<String, Object> row : dao.configs()) {
            String key = (String) row.get("config_key");
            int[] range = CONFIG_RANGES.get(key);
            String input = req.getParameter(key);
            if (range == null || input == null) continue;
            int value = parse(input.trim(), range, (String) row.get("description"));
            String current = String.valueOf(row.get("config_value"));
            if (!String.valueOf(value).equals(current)) {
                changed.put(key, String.valueOf(value));
                audit.add(key + ": " + current + " -> " + value);
            }
        }
        if (changed.isEmpty()) {
            flash(req, "info", "Cấu hình không có thay đổi.");
            return;
        }
        dao.updateConfigs(changed);
        req.setAttribute(AuditFilter.DETAIL_ATTR, audit.toString());
        flash(req, "success", "Đã lưu cấu hình hệ thống.");
    }

    private static int parse(String input, int[] range, String label) {
        try {
            int value = Integer.parseInt(input);
            if (value >= range[0] && value <= range[1]) return value;
        } catch (NumberFormatException e) {
            // báo lỗi chung bên dưới
        }
        throw new IllegalArgumentException(label + ": giá trị phải là số nguyên từ " + range[0] + " đến " + range[1] + ".");
    }

    private static LocalDate date(String value) {
        try {
            return value == null || value.isBlank() ? null : LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}
