package com.cinema.controller;

import com.cinema.dao.ComboDAO;
import com.cinema.model.Combo;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import java.util.Set;

/**
 * STT 13 — Quản lý combo bắp nước (Staff).
 * URL: /staff/combo?action=list|add|edit|delete
 *
 * Khớp bảng Combo trong script database của nhóm:
 *  - combo_name (không phải name), status IN ('Active','Hidden')
 *
 * TODO (Đoàn Mạnh Cường): chuyển kiểm tra quyền sang filter phân quyền
 * tập trung khi xong STT "System Authorization".
 */
@WebServlet("/staff/combo")
public class ComboServlet extends BaseServlet {

    private static final Set<String> STATUSES = Set.of("Active", "Hidden");
    private final ComboDAO dao = new ComboDAO();

    private boolean requireStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        String r = u.getRole();
        if (!"STAFF".equals(r) && !"MANAGER".equals(r) && !"ADMIN".equals(r)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ nhân viên được truy cập.");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp)) return;
        String action = req.getParameter("action");
        if (action == null) action = "list";
        try {
            switch (action) {
                case "add":
                    req.setAttribute("pageTitle", "Thêm combo mới");
                    forward(req, resp, "combo/combo-form");
                    break;
                case "edit": {
                    Combo c = dao.findById(safeId(req.getParameter("id")));
                    if (c == null) { resp.sendError(404); return; }
                    req.setAttribute("combo", c);
                    req.setAttribute("pageTitle", "Sửa combo");
                    forward(req, resp, "combo/combo-form");
                    break;
                }
                default: { // list + tìm kiếm theo tên
                    String keyword = Validator.trim(req.getParameter("q"));
                    List<Combo> list = dao.findAll(keyword);
                    req.setAttribute("comboList", list);
                    req.setAttribute("keyword", keyword);
                    req.setAttribute("pageTitle", "Quản lý combo");
                    forward(req, resp, "combo/combo-list");
                }
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp)) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.delete(safeId(req.getParameter("id")));
                flash(req, "success", "Đã xóa combo.");
                resp.sendRedirect(req.getContextPath() + "/staff/combo");
                return;
            }

            String idStr = Validator.trim(req.getParameter("id"));
            String comboName = Validator.trim(req.getParameter("comboName"));
            String description = Validator.trim(req.getParameter("description"));
            String priceStr = Validator.trim(req.getParameter("price"));
            String stockStr = Validator.trim(req.getParameter("stock"));
            String status = Validator.trim(req.getParameter("status"));

            String error = null;
            BigDecimal price = null;
            int stock = 0;
            try {
                price = new BigDecimal(priceStr);
                if (price.compareTo(BigDecimal.ZERO) < 0) error = "Giá không được âm.";
                stock = Integer.parseInt(stockStr);
                if (stock < 0) error = "Tồn kho không được âm.";
            } catch (NumberFormatException e) {
                error = "Giá và tồn kho phải là số hợp lệ.";
            }
            if (comboName.isEmpty()) error = "Tên combo là bắt buộc.";
            if (!STATUSES.contains(status)) error = "Trạng thái không hợp lệ.";

            if (error != null) {
                Combo c = new Combo();
                c.setComboName(comboName); c.setDescription(description);
                c.setPrice(price); c.setStock(stock); c.setStatus(status);
                req.setAttribute("combo", c);
                req.setAttribute("error", error);
                req.setAttribute("pageTitle", idStr.isEmpty() ? "Thêm combo mới" : "Sửa combo");
                forward(req, resp, "combo/combo-form");
                return;
            }

            Combo c = new Combo();
            c.setComboName(comboName);
            c.setDescription(description.isEmpty() ? null : description);
            c.setPrice(price);
            c.setStock(stock);
            c.setStatus(status);

            if (idStr.isEmpty()) {
                dao.insert(c);
                flash(req, "success", "Đã thêm combo mới.");
            } else {
                c.setComboId(safeId(idStr));
                dao.update(c);
                flash(req, "success", "Đã cập nhật combo.");
            }
            resp.sendRedirect(req.getContextPath() + "/staff/combo");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
