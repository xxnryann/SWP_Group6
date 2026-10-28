package com.cinema.controller;

import com.cinema.dao.VoucherDAO;
import com.cinema.model.User;
import com.cinema.model.Voucher;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@WebServlet("/staff/voucher")
public class VoucherServlet extends BaseServlet {
    private static final Set<String> TYPES = Set.of("Amount", "Percent");
    private static final Set<String> STATUSES = Set.of("Allowed", "Disabled", "Expired", "Used");
    private final VoucherDAO dao = new VoucherDAO();

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
            String action = req.getParameter("action");
            if ("add".equals(action)) {
                req.setAttribute("voucherStatuses", new ArrayList<>(STATUSES));
                req.setAttribute("pageTitle", "Thêm voucher");
                forward(req, resp, "voucher/voucher-form");
            } else if ("edit".equals(action)) {
                Voucher voucher = dao.findById(Integer.parseInt(req.getParameter("id")));
                if (voucher == null) { resp.sendError(404); return; }
                req.setAttribute("voucher", voucher);
                req.setAttribute("voucherStatuses", new ArrayList<>(STATUSES));
                req.setAttribute("pageTitle", "Sửa voucher");
                forward(req, resp, "voucher/voucher-form");
            } else {
                String keyword = Validator.trim(req.getParameter("q"));
                List<Voucher> vouchers = dao.findAll(keyword);
                req.setAttribute("voucherList", vouchers);
                req.setAttribute("keyword", keyword);
                req.setAttribute("pageTitle", "Quản lý voucher");
                forward(req, resp, "voucher/voucher-list");
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp) || !csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.disable(Integer.parseInt(req.getParameter("id")));
                flash(req, "success", "Đã vô hiệu hóa voucher.");
                resp.sendRedirect(req.getContextPath() + "/staff/voucher");
                return;
            }

            Voucher voucher = readVoucher(req);
            String idText = Validator.trim(req.getParameter("id"));
            String error = validate(voucher);
            if (!error.isEmpty() && !idText.isEmpty()) {
                voucher.setVoucherId(Integer.parseInt(idText));
            }
            if (error.isEmpty() && !idText.isEmpty()) {
                int id = Integer.parseInt(idText);
                voucher.setVoucherId(id);
                if (dao.codeExists(voucher.getCode(), id)) error = "Mã voucher đã tồn tại.";
            } else if (error.isEmpty() && dao.codeExists(voucher.getCode(), 0)) {
                error = "Mã voucher đã tồn tại.";
            }
            if (!error.isEmpty()) {
                req.setAttribute("voucher", voucher);
                req.setAttribute("voucherStatuses", new ArrayList<>(STATUSES));
                req.setAttribute("error", error);
                req.setAttribute("pageTitle", idText.isEmpty() ? "Thêm voucher" : "Sửa voucher");
                forward(req, resp, "voucher/voucher-form");
                return;
            }

            if (idText.isEmpty()) {
                int accountId = dao.findAccountIdByEmail(currentUser(req).getEmail());
                if (accountId == 0) throw new ServletException("Không tìm thấy tài khoản staff.");
                dao.insert(voucher, accountId);
                flash(req, "success", "Đã thêm voucher.");
            } else {
                voucher.setVoucherId(Integer.parseInt(idText));
                dao.update(voucher);
                flash(req, "success", "Đã cập nhật voucher.");
            }
            resp.sendRedirect(req.getContextPath() + "/staff/voucher");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private Voucher readVoucher(HttpServletRequest req) {
        Voucher v = new Voucher();
        v.setCode(Validator.trim(req.getParameter("code")).toUpperCase());
        v.setDescription(Validator.trim(req.getParameter("description")));
        v.setDiscountType(Validator.trim(req.getParameter("discountType")));
        v.setStatus(Validator.trim(req.getParameter("status")));
        v.setDiscountValue(decimal(req.getParameter("discountValue")));
        v.setMaxDiscount(decimal(req.getParameter("maxDiscount")));
        v.setMinOrderAmount(decimal(req.getParameter("minOrderAmount")));
        v.setMinCumulativeSpending(decimal(req.getParameter("minCumulativeSpending")));
        v.setUsageLimit(integer(req.getParameter("usageLimit")));
        v.setPerCustomerLimit(integer(req.getParameter("perCustomerLimit")));
        v.setValidFrom(date(req.getParameter("validFrom")));
        v.setValidTo(date(req.getParameter("validTo")));
        return v;
    }

    private String validate(Voucher v) {
        if (v.getCode().isEmpty()) return "Mã voucher là bắt buộc.";
        if (!TYPES.contains(v.getDiscountType())) return "Loại giảm giá không hợp lệ.";
        if (!STATUSES.contains(v.getStatus())) return "Trạng thái không hợp lệ.";
        if (v.getDiscountValue() == null || v.getDiscountValue().signum() <= 0) return "Giá trị giảm phải lớn hơn 0.";
        if ("Percent".equals(v.getDiscountType()) && v.getDiscountValue().compareTo(new BigDecimal("100")) > 0) return "Phần trăm giảm không được vượt quá 100.";
        if (v.getMinOrderAmount() == null || v.getMinOrderAmount().signum() < 0
                || v.getMinCumulativeSpending() == null || v.getMinCumulativeSpending().signum() < 0) return "Điều kiện đơn hàng không hợp lệ.";
        if (v.getUsageLimit() <= 0 || v.getPerCustomerLimit() <= 0) return "Giới hạn sử dụng phải lớn hơn 0.";
        if (v.getValidFrom() == null || v.getValidTo() == null || v.getValidTo().isBefore(v.getValidFrom())) return "Khoảng thời gian voucher không hợp lệ.";
        return "";
    }

    private BigDecimal decimal(String value) {
        try { return value == null || value.trim().isEmpty() ? null : new BigDecimal(value.trim()); }
        catch (NumberFormatException e) { return null; }
    }
    private int integer(String value) {
        try { return Integer.parseInt(value == null ? "" : value.trim()); }
        catch (NumberFormatException e) { return 0; }
    }
    private LocalDate date(String value) {
        try { return value == null || value.trim().isEmpty() ? null : LocalDate.parse(value.trim()); }
        catch (RuntimeException e) { return null; }
    }
}
