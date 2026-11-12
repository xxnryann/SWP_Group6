package com.cinema.controller.manager;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.PriceAdminDAO;
import com.cinema.dao.PriceAdminDAO.PriceChange;
import com.cinema.dao.PriceAdminDAO.SlotEdit;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Quản lý giá vé (Manager/Admin). URL: /manager/prices?tab=gia|le|khung|lichsu
 *
 * <ul>
 *   <li>Bảng giá loại ghế × khung giờ × loại ngày — áp dụng ngay hoặc lên lịch theo ngày chiếu</li>
 *   <li>Ngày lễ (theo khoảng ngày, lặp hằng năm), có báo số suất / vé bị ảnh hưởng</li>
 *   <li>Khung giờ giá và phụ thu theo loại phòng</li>
 *   <li>Nhật ký thay đổi; tính thử giá (GET ?ajax=calc), ảnh hưởng ngày lễ (GET ?ajax=impact)</li>
 * </ul>
 */
@WebServlet("/manager/prices")
public class PriceManageServlet extends BaseServlet {

    private static final String[] DAY_TYPES = PriceAdminDAO.DAY_TYPES;
    private static final BigDecimal MAX_PRICE = BigDecimal.valueOf(5_000_000);
    private static final BigDecimal MAX_SURCHARGE = BigDecimal.valueOf(1_000_000);
    private static final BigDecimal STEP = BigDecimal.valueOf(1000);
    private static final String UNASSIGNED = "Unassigned";
    private static final int MAX_HOLIDAY_SPAN = 31;
    private static final Set<String> TABS = Set.of("gia", "le", "khung", "lichsu");
    private static final DateTimeFormatter DATE_VN = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final String[] WEEKDAY_VN = {"Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật"};

    private final PriceAdminDAO dao = new PriceAdminDAO();

    /* ============================== GET ============================== */

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        String ajax = req.getParameter("ajax");
        if (ajax != null) {
            handleAjax(req, resp, ajax);
            return;
        }
        String tab = tab(req.getParameter("tab"));
        req.setAttribute("tab", tab);
        LocalDate today = LocalDate.now();
        try {
            buildPriceView(req, dao.priceMatrix(today));
            buildScheduleView(req, dao.scheduledChanges(today));
            buildHolidayView(req, dao.holidays(), "le".equals(tab));
            req.setAttribute("roomTypes", dao.roomTypes());
            req.setAttribute("timeSlots", dao.timeSlots());
            List<Map<String, Object>> log = dao.changeLog("lichsu".equals(tab) ? 200 : 1);
            req.setAttribute("changeLog", log);
            req.setAttribute("lastChange", log.isEmpty() ? null : log.get(0));
        } catch (SQLException e) {
            req.setAttribute("error", "Không thể tải dữ liệu giá vé: " + e.getMessage());
        }
        req.setAttribute("today", today);
        req.setAttribute("pageTitle", "Quản lý giá vé");
        forward(req, resp, "manager/prices");
    }

    private void handleAjax(HttpServletRequest req, HttpServletResponse resp, String ajax) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        Map<String, Object> out;
        try {
            if ("impact".equals(ajax)) {
                LocalDate from = LocalDate.parse(Validator.trim(req.getParameter("from")));
                String toText = Validator.trim(req.getParameter("to"));
                LocalDate to = toText.isEmpty() ? from : LocalDate.parse(toText);
                if (to.isBefore(from) || ChronoUnit.DAYS.between(from, to) >= MAX_HOLIDAY_SPAN) {
                    throw new IllegalArgumentException("Khoảng ngày không hợp lệ.");
                }
                out = dao.impact(from, to);
            } else if ("calc".equals(ajax)) {
                out = dao.calculate(Integer.parseInt(Validator.trim(req.getParameter("seatType"))),
                        Validator.trim(req.getParameter("roomType")),
                        LocalDate.parse(Validator.trim(req.getParameter("date"))),
                        LocalTime.parse(Validator.trim(req.getParameter("time"))));
            } else {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (DateTimeParseException | NumberFormatException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out = Map.of("error", "Dữ liệu không hợp lệ.");
        } catch (IllegalArgumentException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out = Map.of("error", e.getMessage());
        } catch (SQLException e) {
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out = Map.of("error", "Lỗi CSDL: " + e.getMessage());
        }
        resp.getWriter().write(json(out));
    }

    /**
     * Gom ma trận giá theo loại ghế để JSP hiển thị từng nhóm, kèm thống kê nhanh.
     * Loại "Unassigned" (ghế chưa gán loại) không bán nên không hiện trong bảng giá.
     */
    private void buildPriceView(HttpServletRequest req, List<Map<String, Object>> matrix) {
        Map<Object, Map<String, Object>> groups = new LinkedHashMap<>();
        Map<Object, Map<String, Object>> slots = new LinkedHashMap<>();
        BigDecimal min = null, max = null;
        int missing = 0, cells = 0;
        for (Map<String, Object> row : matrix) {
            if (UNASSIGNED.equalsIgnoreCase(String.valueOf(row.get("type_name")))) continue;
            row.put("slot_range", range(row));
            slots.putIfAbsent(row.get("slot_id"), row);
            Map<String, Object> g = groups.computeIfAbsent(row.get("seat_type_id"), k -> {
                Map<String, Object> m = new HashMap<>();
                m.put("id", row.get("seat_type_id"));
                m.put("name", row.get("type_name"));
                m.put("desc", row.get("type_desc"));
                m.put("couple", Boolean.TRUE.equals(row.get("is_couple")));
                m.put("rows", new ArrayList<Map<String, Object>>());
                return m;
            });
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rows = (List<Map<String, Object>>) g.get("rows");
            rows.add(row);
            for (String d : DAY_TYPES) {
                cells++;
                Object v = row.get(d.toLowerCase());
                if (v == null) { missing++; continue; }
                BigDecimal p = (BigDecimal) v;
                if (min == null || p.compareTo(min) < 0) min = p;
                if (max == null || p.compareTo(max) > 0) max = p;
            }
        }
        req.setAttribute("seatGroups", new ArrayList<>(groups.values()));
        req.setAttribute("slots", new ArrayList<>(slots.values()));
        req.setAttribute("priceMin", min);
        req.setAttribute("priceMax", max);
        req.setAttribute("missingCount", missing);
        req.setAttribute("cellCount", cells);
    }

    /** Gom lịch đổi giá theo ngày áp dụng; đánh dấu ô nào có lịch để hiện gợi ý trên bảng giá. */
    private void buildScheduleView(HttpServletRequest req, List<Map<String, Object>> rows) {
        Map<LocalDate, Map<String, Object>> byDate = new LinkedHashMap<>();
        Map<String, String> cellHints = new HashMap<>();
        for (Map<String, Object> r : rows) {
            LocalDate d = (LocalDate) r.get("effective_from");
            r.put("day_label", PriceAdminDAO.dayLabel(String.valueOf(r.get("day_type"))));
            Map<String, Object> g = byDate.computeIfAbsent(d, k -> {
                Map<String, Object> m = new HashMap<>();
                m.put("date", k);
                m.put("display", k.format(DATE_VN));
                m.put("weekday_name", WEEKDAY_VN[k.getDayOfWeek().getValue() - 1]);
                m.put("days_until", ChronoUnit.DAYS.between(LocalDate.now(), k));
                m.put("items", new ArrayList<Map<String, Object>>());
                return m;
            });
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> items = (List<Map<String, Object>>) g.get("items");
            items.add(r);
            String key = r.get("seat_type_id") + "_" + r.get("slot_id") + "_" + r.get("day_type");
            cellHints.putIfAbsent(key, "Từ " + d.format(DateTimeFormatter.ofPattern("dd/MM")) + ": "
                    + PriceAdminDAO.money((BigDecimal) r.get("price")));
        }
        req.setAttribute("schedules", new ArrayList<>(byDate.values()));
        req.setAttribute("scheduleHints", cellHints);
        req.setAttribute("scheduleCount", rows.size());
    }

    /** Ngày lễ: lần diễn ra kế tiếp (ngày lặp hằng năm), số ngày còn lại, ảnh hưởng tới suất chiếu đã có. */
    private void buildHolidayView(HttpServletRequest req, List<Map<String, Object>> holidays, boolean withImpact)
            throws SQLException {
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> upcoming = new ArrayList<>(), past = new ArrayList<>();
        for (Map<String, Object> h : holidays) {
            LocalDate base = (LocalDate) h.get("holiday_date");
            boolean recurring = Boolean.TRUE.equals(h.get("is_recurring"));
            LocalDate next = base;
            if (recurring && base.isBefore(today)) {
                next = base.withYear(today.getYear());
                if (next.isBefore(today)) next = next.plusYears(1);
            }
            long days = ChronoUnit.DAYS.between(today, next);
            h.put("next_date", next);
            h.put("display", next.format(DATE_VN));
            h.put("base_display", base.format(DATE_VN));
            h.put("weekday_name", WEEKDAY_VN[next.getDayOfWeek().getValue() - 1]);
            h.put("days_until", days);
            if (days < 0) {
                past.add(h);
            } else {
                if (withImpact) {
                    Map<String, Object> imp = dao.impact(next, next);
                    h.put("impact_showtimes", imp.get("showtimes"));
                    h.put("impact_tickets", imp.get("tickets"));
                }
                upcoming.add(h);
            }
        }
        upcoming.sort((a, b) -> ((LocalDate) a.get("next_date")).compareTo((LocalDate) b.get("next_date")));
        java.util.Collections.reverse(past);
        req.setAttribute("upcomingHolidays", upcoming);
        req.setAttribute("pastHolidays", past);
        req.setAttribute("nextHoliday", upcoming.isEmpty() ? null : upcoming.get(0));
    }

    /* ============================== POST ============================== */

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireRole(req, resp, "MANAGER", "ADMIN")) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");
        String action = Validator.trim(req.getParameter("action"));
        String tab = tab(req.getParameter("tab"));
        User u = currentUser(req);
        String email = u == null ? null : u.getEmail();
        try {
            switch (action) {
                case "savePrices" -> savePrices(req, email);
                case "cancelSchedule" -> {
                    LocalDate d = LocalDate.parse(Validator.trim(req.getParameter("date")));
                    int n = dao.cancelSchedule(d, email);
                    flash(req, "success", "Đã hủy lịch đổi giá ngày " + d.format(DATE_VN) + " (" + n + " ô giá).");
                }
                case "addHoliday" -> addHoliday(req, email);
                case "updateHoliday" -> {
                    LocalDate d = LocalDate.parse(Validator.trim(req.getParameter("holidayDate")));
                    dao.updateHoliday(d, holidayName(req), "1".equals(req.getParameter("recurring")), email);
                    flash(req, "success", "Đã cập nhật ngày lễ " + d.format(DATE_VN) + ".");
                }
                case "deleteHoliday" -> {
                    LocalDate d = LocalDate.parse(Validator.trim(req.getParameter("holidayDate")));
                    dao.deleteHoliday(d, email);
                    flash(req, "success", "Đã xóa ngày lễ " + d.format(DATE_VN) + ".");
                }
                case "saveSlots" -> saveSlots(req, email);
                case "saveSurcharges" -> saveSurcharges(req, email);
                default -> {
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                    return;
                }
            }
        } catch (DateTimeParseException e) {
            flash(req, "error", "Ngày hoặc giờ không hợp lệ.");
        } catch (IllegalArgumentException | IllegalStateException e) {
            flash(req, "error", e.getMessage());
        } catch (SQLException e) {
            flash(req, "error", e.getErrorCode() == 2627 || e.getErrorCode() == 2601
                    ? "Dữ liệu bị trùng (tên hoặc giờ đã tồn tại)." : "Không thể lưu: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/manager/prices?tab=" + tab);
    }

    /**
     * Mỗi ô giá có tên p_{seatTypeId}_{slotId}_{dayType}, giá lúc mở trang ở o_…
     * Bắt buộc đủ mọi ô; chỉ ghi ô đã đổi, trong một transaction.
     */
    private void savePrices(HttpServletRequest req, String email) throws SQLException {
        String mode = Validator.trim(req.getParameter("mode"));
        LocalDate effectiveFrom = null;
        if ("schedule".equals(mode)) {
            String d = Validator.trim(req.getParameter("effectiveFrom"));
            if (d.isEmpty()) throw new IllegalArgumentException("Chọn ngày bắt đầu áp dụng giá mới.");
            effectiveFrom = LocalDate.parse(d);
            if (!effectiveFrom.isAfter(LocalDate.now())) {
                throw new IllegalArgumentException("Ngày áp dụng phải sau hôm nay. Muốn đổi ngay hãy chọn \"Áp dụng ngay\".");
            }
        }
        List<Map<String, Object>> matrix = dao.priceMatrix(LocalDate.now());
        List<PriceChange> changes = new ArrayList<>();
        int empty = 0;
        for (Map<String, Object> row : matrix) {
            if (UNASSIGNED.equalsIgnoreCase(String.valueOf(row.get("type_name")))) continue;
            int seatTypeId = ((Number) row.get("seat_type_id")).intValue();
            int slotId = ((Number) row.get("slot_id")).intValue();
            for (String d : DAY_TYPES) {
                String key = seatTypeId + "_" + slotId + "_" + d;
                String text = digits(req.getParameter("p_" + key));
                if (text.isEmpty()) { empty++; continue; }
                BigDecimal price = parseMoney(text, MAX_PRICE, "Giá vé");
                String origText = digits(req.getParameter("o_" + key));
                BigDecimal expected = origText.isEmpty() ? null : new BigDecimal(origText);
                if (expected == null || expected.compareTo(price) != 0) {
                    changes.add(new PriceChange(seatTypeId, slotId, d, expected, price));
                }
            }
        }
        if (empty > 0) {
            throw new IllegalArgumentException("Còn " + empty + " ô giá trống. Mọi ô phải có giá — ô trống sẽ khiến khách không đặt được ghế đó.");
        }
        if (changes.isEmpty()) {
            flash(req, "info", "Không có ô giá nào thay đổi.");
            return;
        }
        dao.savePrices(changes, effectiveFrom, email);
        flash(req, "success", effectiveFrom == null
                ? "Đã cập nhật " + changes.size() + " ô giá, áp dụng ngay."
                : "Đã lên lịch đổi " + changes.size() + " ô giá cho các suất chiếu từ " + effectiveFrom.format(DATE_VN) + ".");
    }

    private void addHoliday(HttpServletRequest req, String email) throws SQLException {
        LocalDate from = LocalDate.parse(Validator.trim(req.getParameter("holidayDate")));
        String toText = Validator.trim(req.getParameter("holidayTo"));
        LocalDate to = toText.isEmpty() ? from : LocalDate.parse(toText);
        if (from.isBefore(LocalDate.now())) throw new IllegalArgumentException("Không thêm ngày lễ trong quá khứ.");
        if (to.isBefore(from)) throw new IllegalArgumentException("\"Đến ngày\" phải sau hoặc bằng \"Từ ngày\".");
        if (ChronoUnit.DAYS.between(from, to) >= MAX_HOLIDAY_SPAN) {
            throw new IllegalArgumentException("Mỗi lần thêm tối đa " + MAX_HOLIDAY_SPAN + " ngày.");
        }
        boolean recurring = "1".equals(req.getParameter("recurring"));
        int[] r = dao.addHolidays(from, to, holidayName(req), recurring, email);
        String msg = "Đã thêm " + r[0] + " ngày lễ" + (recurring ? " (lặp lại hằng năm)" : "") + ".";
        if (r[1] > 0) msg += " Bỏ qua " + r[1] + " ngày đã có sẵn.";
        flash(req, r[0] > 0 ? "success" : "info", msg);
    }

    private void saveSlots(HttpServletRequest req, String email) throws SQLException {
        String[] ids = req.getParameterValues("slotId");
        if (ids == null) throw new IllegalArgumentException("Không có khung giờ nào.");
        List<SlotEdit> edits = new ArrayList<>();
        for (String idText : ids) {
            int id = safeId(idText);
            edits.add(new SlotEdit(id, Validator.trim(req.getParameter("slotName_" + id)),
                    parseTime(req.getParameter("slotStart_" + id))));
        }
        int moved = dao.saveSlots(edits, email);
        flash(req, "success", "Đã lưu khung giờ." + movedText(moved));
    }

    private void saveSurcharges(HttpServletRequest req, String email) throws SQLException {
        Map<String, BigDecimal> values = new LinkedHashMap<>(), expected = new HashMap<>();
        for (Map<String, Object> rt : dao.roomTypes()) {
            String code = String.valueOf(rt.get("type_code"));
            String text = digits(req.getParameter("sc_" + code));
            if (req.getParameter("sc_" + code) == null) continue;
            values.put(code, text.isEmpty() ? BigDecimal.ZERO : parseMoney(text, MAX_SURCHARGE, "Phụ thu"));
            String o = digits(req.getParameter("so_" + code));
            expected.put(code, o.isEmpty() ? BigDecimal.ZERO : new BigDecimal(o));
        }
        int n = dao.saveSurcharges(values, expected, email);
        flash(req, n > 0 ? "success" : "info", n > 0 ? "Đã cập nhật phụ thu cho " + n + " loại phòng." : "Phụ thu không thay đổi.");
    }

    /* ============================== Tiện ích ============================== */

    private static String tab(String t) {
        return t != null && TABS.contains(t) ? t : "gia";
    }

    private static String range(Map<String, Object> row) {
        String to = String.valueOf(row.get("slot_to"));
        return row.get("slot_from") + " – " + ("23:59".equals(to) ? "24:00" : to);
    }

    private static String movedText(int moved) {
        return moved > 0 ? " " + moved + " suất chiếu sắp tới được xếp lại khung giờ." : "";
    }

    private static String holidayName(HttpServletRequest req) {
        String name = Validator.trim(req.getParameter("holidayName"));
        if (name.isEmpty() || name.length() > 100) {
            throw new IllegalArgumentException("Tên ngày lễ không được để trống (tối đa 100 ký tự).");
        }
        return name;
    }

    private static LocalTime parseTime(String text) {
        String t = Validator.trim(text);
        if (t.isEmpty()) throw new IllegalArgumentException("Chưa nhập giờ bắt đầu.");
        return LocalTime.parse(t).withSecond(0).withNano(0);
    }

    /** "85.000" / "85,000 đ" → "85000". */
    private static String digits(String s) {
        return s == null ? "" : s.replaceAll("[^0-9]", "");
    }

    private static BigDecimal parseMoney(String digits, BigDecimal max, String what) {
        if (digits.length() > 9) throw new IllegalArgumentException(what + " quá lớn.");
        BigDecimal v = new BigDecimal(digits);
        if (v.compareTo(max) > 0) {
            throw new IllegalArgumentException(what + " tối đa " + PriceAdminDAO.money(max) + ".");
        }
        if (v.remainder(STEP).signum() != 0) {
            throw new IllegalArgumentException(what + " phải là bội số của 1.000đ (nhận được " + PriceAdminDAO.money(v) + ").");
        }
        return v;
    }

    /** JSON tối giản cho Map phẳng (chuỗi, số, boolean, null). */
    private static String json(Map<String, Object> m) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> e : m.entrySet()) {
            if (!first) sb.append(',');
            first = false;
            sb.append('"').append(esc(e.getKey())).append("\":");
            Object v = e.getValue();
            if (v == null) sb.append("null");
            else if (v instanceof Number || v instanceof Boolean) sb.append(v instanceof BigDecimal b ? b.toPlainString() : v.toString());
            else sb.append('"').append(esc(v.toString())).append('"');
        }
        return sb.append('}').toString();
    }

    private static String esc(String s) {
        StringBuilder sb = new StringBuilder();
        for (char ch : s.toCharArray()) {
            switch (ch) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '<' -> sb.append("\\u003c");
                default -> {
                    if (ch < 0x20) sb.append(String.format("\\u%04x", (int) ch));
                    else sb.append(ch);
                }
            }
        }
        return sb.toString();
    }
}
