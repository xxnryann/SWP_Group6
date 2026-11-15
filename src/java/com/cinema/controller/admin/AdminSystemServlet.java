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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Quản lý hệ thống (Admin): cấu hình tham số, sao lưu dữ liệu và nhật ký hệ thống. URL: /admin/system */
@WebServlet("/admin/system")
public class AdminSystemServlet extends BaseServlet {

    private static final int LOG_LIMIT = 200;

    private final SystemDAO dao = new SystemDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "ADMIN")) return;
        String tabParam = Validator.trim(req.getParameter("tab"));
        String tab = "logs".equals(tabParam) || "config".equals(tabParam) ? tabParam : "backup";
        try {
            if ("config".equals(tab)) {
                List<Map<String, Object>> configs = dao.configs();
                for (Map<String, Object> row : configs) {
                    int[] r = range(String.valueOf(row.get("config_key")));
                    row.put("min", r[0]);
                    row.put("max", r[1]);
                }
                req.setAttribute("configs", configs);
            } else if ("logs".equals(tab)) {
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
        if ("saveConfig".equals(action)) {
            saveConfig(req);
            resp.sendRedirect(req.getContextPath() + "/admin/system?tab=config");
            return;
        }
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

    /** Khoảng hợp lệ {min, max} của từng tham số (đơn vị theo tên khóa). Khóa chưa khai báo: số nguyên 0–10000. */
    private static final Map<String, int[]> RANGES = Map.of(
            "BOOKING_SESSION_MINUTES", new int[] {5, 60},
            "CANCEL_BEFORE_HOURS", new int[] {0, 72},
            "CHECKIN_EARLY_MINUTES", new int[] {0, 180},
            "PAYMENT_WINDOW_MINUTES", new int[] {1, 30},
            "REMINDER_HOURS_BEFORE", new int[] {1, 48});

    private static int[] range(String key) {
        return RANGES.getOrDefault(key, new int[] {0, 10000});
    }

    /**
     * Lưu tab Cấu hình. Chỉ nhận các khóa ĐÃ CÓ trong bảng SystemConfig (khóa lạ bị bỏ qua).
     * Một giá trị sai ⇒ không lưu khóa nào. Nhật ký (AuditFilter) ghi giá trị cũ → mới của khóa đã đổi.
     */
    private void saveConfig(HttpServletRequest req) throws ServletException {
        try {
            Map<String, String> changed = new LinkedHashMap<>();
            List<String> errors = new ArrayList<>();
            StringBuilder detail = new StringBuilder();
            for (Map<String, Object> row : dao.configs()) {
                String key = String.valueOf(row.get("config_key"));
                String old = String.valueOf(row.get("config_value")).trim();
                String raw = req.getParameter(key);
                if (raw == null) continue; // không gửi ⇒ giữ nguyên
                raw = raw.trim();
                int[] r = range(key);
                int value;
                try {
                    value = Integer.parseInt(raw);
                } catch (NumberFormatException e) {
                    errors.add(key + " phải là số nguyên");
                    continue;
                }
                if (value < r[0] || value > r[1]) {
                    errors.add(key + " phải trong khoảng " + r[0] + "–" + r[1]);
                    continue;
                }
                String v = String.valueOf(value);
                if (!v.equals(old)) {
                    changed.put(key, v);
                    detail.append(detail.length() == 0 ? "" : ", ").append(key).append(": ").append(old).append(" → ").append(v);
                }
            }
            if (!errors.isEmpty()) {
                req.setAttribute(AuditFilter.DETAIL_ATTR, String.join("; ", errors));
                flash(req, "error", "Chưa lưu cấu hình: " + String.join("; ", errors) + ".");
                return;
            }
            if (changed.isEmpty()) {
                flash(req, "success", "Không có thay đổi nào.");
                return;
            }
            dao.updateConfigs(changed);
            req.setAttribute(AuditFilter.DETAIL_ATTR, detail.toString());
            flash(req, "success", "Đã lưu cấu hình: " + detail + ".");
        } catch (SQLException e) {
            getServletContext().log("Save config failed", e);
            flash(req, "error", "Không thể lưu cấu hình: " + e.getMessage());
        }
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
