package com.cinema.controller;

import com.cinema.dao.AccountDAO;
import com.cinema.dao.PromoDAO;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;
import java.util.Set;

/**
 * Quản lý voucher (Manager/Admin). URL: /manager/vouchers
 *   GET            danh sách + form thêm/sửa (?edit=id)
 *   POST save      thêm hoặc cập nhật
 *   POST toggle    bật/tắt voucher
 *   POST delete    xóa voucher chưa từng được dùng
 */
@WebServlet("/manager/vouchers")
public class VoucherServlet extends BaseServlet {

    private static final Set<String> TYPES = Set.of("Percent", "Amount");
    private static final Set<String> STATUSES = Set.of("Allowed", "Disabled");
    private final PromoDAO dao = new PromoDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        try {
            int editId = safeId(req.getParameter("edit"));
            if (editId > 0) {
                Map<String, Object> v = dao.voucher(editId);
                if (v == null) {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }
                req.setAttribute("form", v);
            } else if ("new".equals(req.getParameter("action"))) {
                req.setAttribute("form", Map.of("status", "Allowed", "discount_type", "Percent",
                        "usage_limit", 100, "per_customer_limit", 1, "min_order_amount", 0, "min_cumulative_spending", 0));
            }
            req.setAttribute("vouchers", dao.vouchers());
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải voucher: " + e.getMessage());
        }
        req.setAttribute("pageTitle", "Quản lý voucher");
        forward(req, resp, "manager/vouchers");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String action = Validator.trim(req.getParameter("action"));
        try {
            switch (action) {
                case "toggle" -> {
                    String status = Validator.trim(req.getParameter("status"));
                    if (!STATUSES.contains(status)) throw new IllegalArgumentException("Trạng thái không hợp lệ.");
                    dao.setVoucherStatus(safeId(req.getParameter("id")), status);
                    flash(req, "success", "Đã cập nhật trạng thái voucher.");
                }
                case "delete" -> {
                    if (dao.deleteVoucher(safeId(req.getParameter("id")))) {
                        flash(req, "success", "Đã xóa voucher.");
                    } else {
                        flash(req, "error", "Voucher đã được dùng nên không thể xóa. Hãy tắt voucher thay vì xóa.");
                    }
                }
                case "save" -> {
                    save(req);
                    resp.sendRedirect(req.getContextPath() + "/manager/vouchers");
                    return;
                }
                default -> resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            }
        } catch (IllegalArgumentException e) {
            flash(req, "error", e.getMessage());
            if ("save".equals(action)) {
                String id = Validator.trim(req.getParameter("id"));
                resp.sendRedirect(req.getContextPath() + "/manager/vouchers"
                        + (id.isEmpty() || "0".equals(id) ? "?action=new" : "?edit=" + safeId(id)));
                return;
            }
        } catch (SQLException e) {
            flash(req, "error", "Không thể lưu voucher: " + e.getMessage());
        }
        if (!resp.isCommitted() && resp.getStatus() < 400) {
            resp.sendRedirect(req.getContextPath() + "/manager/vouchers");
        }
    }

    private void save(HttpServletRequest req) throws SQLException {
        int id = Math.max(0, safeId(req.getParameter("id")));
        String code = Validator.trim(req.getParameter("code")).toUpperCase();
        if (!code.matches("[A-Z0-9_-]{3,30}")) {
            throw new IllegalArgumentException("Mã voucher gồm 3–30 ký tự chữ hoa, số, gạch ngang hoặc gạch dưới.");
        }
        String type = Validator.trim(req.getParameter("discountType"));
        if (!TYPES.contains(type)) throw new IllegalArgumentException("Loại giảm giá không hợp lệ.");
        BigDecimal value = money(req.getParameter("discountValue"), "Giá trị giảm");
        if (value.signum() <= 0) throw new IllegalArgumentException("Giá trị giảm phải lớn hơn 0.");
        if ("Percent".equals(type) && value.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException("Giảm theo phần trăm tối đa 100%.");
        }
        String maxText = Validator.trim(req.getParameter("maxDiscount"));
        BigDecimal maxDiscount = maxText.isEmpty() ? null : money(maxText, "Giảm tối đa");
        BigDecimal minOrder = money(orZero(req.getParameter("minOrderAmount")), "Đơn tối thiểu");
        BigDecimal minSpent = money(orZero(req.getParameter("minCumulativeSpending")), "Chi tiêu tích lũy tối thiểu");
        int usageLimit = positiveInt(req.getParameter("usageLimit"), "Số lượt sử dụng tối đa");
        int perCustomer = positiveInt(req.getParameter("perCustomerLimit"), "Số lượt mỗi khách");
        LocalDate from;
        LocalDate to;
        try {
            from = LocalDate.parse(Validator.trim(req.getParameter("validFrom")));
            to = LocalDate.parse(Validator.trim(req.getParameter("validTo")));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Vui lòng chọn ngày hiệu lực hợp lệ.");
        }
        if (to.isBefore(from)) throw new IllegalArgumentException("Ngày hết hạn không được trước ngày bắt đầu.");
        String status = Validator.trim(req.getParameter("status"));
        if (!STATUSES.contains(status)) throw new IllegalArgumentException("Trạng thái không hợp lệ.");
        String description = Validator.trim(req.getParameter("description"));
        if (description.length() > 200) throw new IllegalArgumentException("Mô tả tối đa 200 ký tự.");
        if (dao.voucherCodeExists(code, id)) throw new IllegalArgumentException("Mã voucher đã tồn tại.");

        int creator = accountDAO.findAccountIdByEmail(currentUser(req).getEmail());
        dao.saveVoucher(id, code, description, type, value, maxDiscount, minOrder, minSpent, usageLimit,
                perCustomer, from, to, status, creator == 0 ? 2 : creator);
        flash(req, "success", id == 0 ? "Đã thêm voucher " + code + "." : "Đã cập nhật voucher " + code + ".");
    }

    private static String orZero(String s) {
        return s == null || s.isBlank() ? "0" : s;
    }

    private static BigDecimal money(String text, String label) {
        try {
            BigDecimal v = new BigDecimal(Validator.trim(text));
            if (v.signum() < 0) throw new IllegalArgumentException(label + " không được âm.");
            return v;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(label + " phải là số.");
        }
    }

    private static int positiveInt(String text, String label) {
        try {
            int v = Integer.parseInt(Validator.trim(text));
            if (v <= 0) throw new IllegalArgumentException(label + " phải lớn hơn 0.");
            return v;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(label + " phải là số nguyên.");
        }
    }
}
