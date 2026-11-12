package com.cinema.model;

import jakarta.servlet.http.HttpServletRequest;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/**
 * Bộ lọc doanh thu dùng chung cho dashboard Admin/Manager và trang chi tiết doanh thu.
 *
 * <p>Chỉ tính đơn đã thanh toán (Booking.status = 'Paid'); đơn bị hủy/hoàn điểm không được tính.
 * Ngày lọc theo thời điểm thanh toán (paid_at).</p>
 *
 * <ul>
 *   <li>{@code actual}  — Thực thu: vé + bỏng nước − voucher − MyPoint (= total_amount)</li>
 *   <li>{@code gross}   — Tổng giá trị: vé + bỏng nước, chưa trừ voucher/MyPoint</li>
 *   <li>{@code tickets} — Chỉ tiền vé phim (giá gốc)</li>
 *   <li>{@code combo}   — Chỉ tiền bỏng nước (combo)</li>
 * </ul>
 */
public class RevenueFilter {

    public static final String ACTUAL = "actual";
    public static final String GROSS = "gross";
    public static final String TICKETS = "tickets";
    public static final String COMBO = "combo";

    private LocalDate from;
    private LocalDate to;
    private String type = ACTUAL;
    private String channel = "";

    public static RevenueFilter from(HttpServletRequest req) {
        RevenueFilter f = new RevenueFilter();
        f.from = parseDate(req.getParameter("from"));
        f.to = parseDate(req.getParameter("to"));
        if (f.from != null && f.to != null && f.to.isBefore(f.from)) {
            LocalDate t = f.from;
            f.from = f.to;
            f.to = t;
        }
        String type = req.getParameter("type");
        if (GROSS.equals(type) || TICKETS.equals(type) || COMBO.equals(type)) {
            f.type = type;
        }
        String channel = req.getParameter("channel");
        if ("Online".equals(channel) || "Counter".equals(channel)) {
            f.channel = channel;
        }
        return f;
    }

    private static LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** Biểu thức SQL tính doanh thu của một đơn (bí danh bảng Booking là {@code b}). */
    public String amountExpr() {
        switch (type) {
            case GROSS: return "(b.ticket_total + b.combo_total)";
            case TICKETS: return "b.ticket_total";
            case COMBO: return "b.combo_total";
            default: return "b.total_amount";
        }
    }

    /** Điều kiện WHERE (không gồm chữ WHERE) — tham số theo thứ tự: from, to nếu có. */
    public String whereSql() {
        StringBuilder sb = new StringBuilder("b.status = 'Paid'");
        if (from != null) sb.append(" AND b.paid_at >= ?");
        if (to != null) sb.append(" AND b.paid_at < ?");
        if (!channel.isEmpty()) sb.append(" AND b.channel = '").append(channel).append("'");
        if (TICKETS.equals(type)) sb.append(" AND b.ticket_total > 0");
        if (COMBO.equals(type)) sb.append(" AND b.combo_total > 0");
        return sb.toString();
    }

    /** Gán tham số ngày cho câu lệnh, bắt đầu từ vị trí {@code index}; trả về vị trí kế tiếp. */
    public int bind(java.sql.PreparedStatement ps, int index) throws java.sql.SQLException {
        if (from != null) ps.setTimestamp(index++, java.sql.Timestamp.valueOf(from.atStartOfDay()));
        if (to != null) ps.setTimestamp(index++, java.sql.Timestamp.valueOf(to.plusDays(1).atStartOfDay()));
        return index;
    }

    public boolean isFiltered() {
        return from != null || to != null || !ACTUAL.equals(type) || !channel.isEmpty();
    }

    /** Chuỗi query (không có dấu ?) để giữ bộ lọc khi chuyển sang trang chi tiết. */
    public String getQuery() {
        StringBuilder sb = new StringBuilder("type=").append(type);
        if (from != null) sb.append("&from=").append(from);
        if (to != null) sb.append("&to=").append(to);
        if (!channel.isEmpty()) sb.append("&channel=").append(URLEncoder.encode(channel, StandardCharsets.UTF_8));
        return sb.toString();
    }

    public String getTypeLabel() {
        switch (type) {
            case GROSS: return "Tổng giá trị (vé + bỏng nước)";
            case TICKETS: return "Chỉ vé phim";
            case COMBO: return "Chỉ bỏng nước";
            default: return "Thực thu";
        }
    }

    public String getTypeNote() {
        switch (type) {
            case GROSS: return "Giá vé + bỏng nước, chưa trừ voucher và MyPoint";
            case TICKETS: return "Tiền vé phim theo giá gốc, không gồm bỏng nước";
            case COMBO: return "Tiền bỏng nước / combo theo giá gốc";
            default: return "Vé + bỏng nước − voucher − MyPoint (tiền khách thực trả)";
        }
    }

    /** Mô tả khoảng thời gian đang xem, ví dụ "01/11/2026 – 12/11/2026" hoặc "Toàn thời gian". */
    public String getPeriodLabel() {
        java.time.format.DateTimeFormatter fmt = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
        if (from == null && to == null) return "Toàn thời gian";
        if (from != null && to != null) return from.equals(to) ? from.format(fmt) : from.format(fmt) + " – " + to.format(fmt);
        return from != null ? "Từ " + from.format(fmt) : "Đến " + to.format(fmt);
    }

    public String getFrom() { return from == null ? "" : from.toString(); }
    public String getTo() { return to == null ? "" : to.toString(); }
    public String getType() { return type; }
    public String getChannel() { return channel; }
}
