package com.cinema.controller;

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
import java.util.List;
import java.util.Map;

/**
 * Quản lý giá vé theo loại ghế × khung giờ × loại ngày, và danh sách ngày lễ (Manager/Admin).
 * URL: /manager/prices  (POST action=savePrices | addHoliday | deleteHoliday)
 */
@WebServlet("/manager/prices")
public class PriceManageServlet extends BaseServlet {

    private static final String[] DAY_TYPES = {"Weekday", "Weekend", "Holiday"};
    private static final BigDecimal MAX_PRICE = BigDecimal.valueOf(5_000_000);
    private final PromoDAO dao = new PromoDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        try {
            req.setAttribute("matrix", dao.priceMatrix());
            req.setAttribute("holidays", dao.holidays());
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải bảng giá: " + e.getMessage());
        }
        req.setAttribute("pageTitle", "Quản lý giá vé");
        forward(req, resp, "manager/prices");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String action = Validator.trim(req.getParameter("action"));
        try {
            switch (action) {
                case "savePrices" -> savePrices(req);
                case "addHoliday" -> {
                    LocalDate date = LocalDate.parse(Validator.trim(req.getParameter("holidayDate")));
                    String name = Validator.trim(req.getParameter("holidayName"));
                    if (name.isEmpty() || name.length() > 100) {
                        throw new IllegalArgumentException("Tên ngày lễ không được để trống (tối đa 100 ký tự).");
                    }
                    dao.addHoliday(date, name);
                    flash(req, "success", "Đã thêm ngày lễ.");
                }
                case "deleteHoliday" -> {
                    dao.deleteHoliday(LocalDate.parse(Validator.trim(req.getParameter("holidayDate"))));
                    flash(req, "success", "Đã xóa ngày lễ.");
                }
                default -> {
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                    return;
                }
            }
        } catch (DateTimeParseException e) {
            flash(req, "error", "Ngày không hợp lệ.");
        } catch (IllegalArgumentException e) {
            flash(req, "error", e.getMessage());
        } catch (SQLException e) {
            flash(req, "error", e.getErrorCode() == 2627
                    ? "Ngày lễ này đã tồn tại." : "Không thể lưu: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/manager/prices");
    }

    /** Mỗi ô giá có tên p_{seatTypeId}_{slotId}_{dayType}; kiểm tra toàn bộ trước khi ghi. */
    private void savePrices(HttpServletRequest req) throws SQLException {
        List<Map<String, Object>> matrix = dao.priceMatrix();
        BigDecimal[][] values = new BigDecimal[matrix.size()][DAY_TYPES.length];
        for (int i = 0; i < matrix.size(); i++) {
            Map<String, Object> row = matrix.get(i);
            for (int d = 0; d < DAY_TYPES.length; d++) {
                String name = "p_" + row.get("seat_type_id") + "_" + row.get("slot_id") + "_" + DAY_TYPES[d];
                String text = Validator.trim(req.getParameter(name));
                if (text.isEmpty()) continue;
                BigDecimal price;
                try {
                    price = new BigDecimal(text);
                } catch (NumberFormatException e) {
                    throw new IllegalArgumentException("Giá vé \"" + text + "\" không phải là số.");
                }
                if (price.signum() < 0 || price.compareTo(MAX_PRICE) > 0 || price.scale() > 0 && price.stripTrailingZeros().scale() > 0) {
                    throw new IllegalArgumentException("Giá vé phải là số nguyên từ 0 đến 5.000.000 VNĐ.");
                }
                values[i][d] = price.setScale(0, java.math.RoundingMode.UNNECESSARY);
            }
        }
        for (int i = 0; i < matrix.size(); i++) {
            Map<String, Object> row = matrix.get(i);
            for (int d = 0; d < DAY_TYPES.length; d++) {
                if (values[i][d] != null) {
                    dao.savePrice(((Number) row.get("seat_type_id")).intValue(),
                            ((Number) row.get("slot_id")).intValue(), DAY_TYPES[d], values[i][d]);
                }
            }
        }
        flash(req, "success", "Đã cập nhật bảng giá vé.");
    }
}
