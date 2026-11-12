package com.cinema.dao;

import com.cinema.util.DBContext;
import com.cinema.util.Rows;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Quản lý giá vé cho Manager: bảng giá có phiên bản theo ngày áp dụng (lịch đổi giá), ngày lễ,
 * khung giờ, phụ thu theo loại phòng và nhật ký thay đổi (PriceChangeLog).
 *
 * <p>Mọi thao tác ghi chạy trong một transaction. Lưu bảng giá kiểm tra giá gốc mà người dùng
 * đã thấy (expected) — nếu ai khác đổi trước thì từ chối thay vì ghi đè.</p>
 *
 * <p>Người thao tác được nhận diện bằng email (Users.UserId khác Account.account_id).</p>
 */
public class PriceAdminDAO {

    public static final String[] DAY_TYPES = {"Weekday", "Weekend", "Holiday"};
    private static final LocalDate BASE_DATE = LocalDate.of(2000, 1, 1);
    private static final DateTimeFormatter DMY = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /** Một ô giá cần ghi: expected = giá đang áp dụng mà người dùng thấy lúc mở trang (null = trống). */
    public record PriceChange(int seatTypeId, int slotId, String dayType, BigDecimal expected, BigDecimal price) {}

    /** Một khung giờ khi sửa hàng loạt. */
    public record SlotEdit(int slotId, String name, LocalTime start) {}

    public static String dayLabel(String dayType) {
        return switch (dayType) {
            case "Weekday" -> "Ngày thường";
            case "Weekend" -> "Cuối tuần";
            case "Holiday" -> "Ngày lễ";
            default -> dayType;
        };
    }

    public static String money(BigDecimal v) {
        if (v == null) return null;
        DecimalFormat f = new DecimalFormat("#,##0", DecimalFormatSymbols.getInstance(new Locale("vi", "VN")));
        return f.format(v) + "đ";
    }

    /* ======================= Đọc ======================= */

    /** Ma trận giá đang áp dụng tại ngày {@code asOf}: mỗi dòng (loại ghế × khung giờ) có 3 giá. */
    public List<Map<String, Object>> priceMatrix(LocalDate asOf) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT st.seat_type_id, st.type_name, st.is_couple, st.description AS type_desc, "
                + "ts.slot_id, ts.slot_name, CONVERT(varchar(5), ts.start_time, 108) AS slot_from, "
                + "CONVERT(varchar(5), ts.end_time, 108) AS slot_to");
        StringBuilder applies = new StringBuilder();
        for (String d : DAY_TYPES) {
            String a = d.toLowerCase();
            sql.append(", ").append(a).append(".price AS ").append(a);
            applies.append(" OUTER APPLY (SELECT TOP (1) p.price FROM TicketPrice p WHERE p.seat_type_id = st.seat_type_id "
                    + "AND p.slot_id = ts.slot_id AND p.day_type = '").append(d)
                    .append("' AND p.effective_from <= ? ORDER BY p.effective_from DESC) ").append(a);
        }
        sql.append(" FROM SeatType st CROSS JOIN TimeSlot ts").append(applies)
                .append(" ORDER BY st.seat_type_id, ts.start_time");
        return Rows.query(sql.toString(), asOf, asOf, asOf);
    }

    /** Các ô giá đã lên lịch đổi (effective_from sau hôm nay), kèm giá ngay trước đó. */
    public List<Map<String, Object>> scheduledChanges(LocalDate today) throws SQLException {
        return Rows.query("SELECT p.effective_from, p.seat_type_id, p.slot_id, p.day_type, st.type_name, ts.slot_name, "
                + "p.price, prev.price AS old_price, a.full_name AS updated_by_name, p.updated_at "
                + "FROM TicketPrice p JOIN SeatType st ON st.seat_type_id = p.seat_type_id "
                + "JOIN TimeSlot ts ON ts.slot_id = p.slot_id "
                + "OUTER APPLY (SELECT TOP (1) q.price FROM TicketPrice q WHERE q.seat_type_id = p.seat_type_id "
                + "  AND q.slot_id = p.slot_id AND q.day_type = p.day_type AND q.effective_from < p.effective_from "
                + "  ORDER BY q.effective_from DESC) prev "
                + "LEFT JOIN Account a ON a.account_id = p.updated_by "
                + "WHERE p.effective_from > ? "
                + "ORDER BY p.effective_from, st.seat_type_id, ts.start_time, "
                + "CASE p.day_type WHEN 'Weekday' THEN 1 WHEN 'Weekend' THEN 2 ELSE 3 END", today);
    }

    public List<Map<String, Object>> holidays() throws SQLException {
        return Rows.query("SELECT holiday_date, holiday_name, is_recurring FROM Holiday ORDER BY holiday_date");
    }

    /** Số suất chiếu còn hiệu lực và số vé đang giữ / đã bán trong khoảng ngày. */
    public Map<String, Object> impact(LocalDate from, LocalDate to) throws SQLException {
        List<Map<String, Object>> r = Rows.query("SELECT COUNT(DISTINCT s.showtime_id) AS showtimes, COUNT(t.ticket_id) AS tickets "
                + "FROM Showtime s LEFT JOIN Ticket t ON t.showtime_id = s.showtime_id AND t.status IN ('Held','Booked','Used') "
                + "WHERE s.show_date BETWEEN ? AND ? AND s.status <> 'Cancelled'", from, to);
        return r.get(0);
    }

    public List<Map<String, Object>> timeSlots() throws SQLException {
        return Rows.query("SELECT ts.slot_id, ts.slot_name, CONVERT(varchar(5), ts.start_time, 108) AS slot_from, "
                + "CONVERT(varchar(5), ts.end_time, 108) AS slot_to, "
                + "(SELECT COUNT(*) FROM Showtime s WHERE s.slot_id = ts.slot_id AND s.start_time >= SYSDATETIME() "
                + "   AND s.status <> 'Cancelled') AS future_showtimes "
                + "FROM TimeSlot ts ORDER BY ts.start_time");
    }

    public List<Map<String, Object>> roomTypes() throws SQLException {
        return Rows.query("SELECT rt.type_code, rt.description, rt.surcharge, "
                + "(SELECT COUNT(*) FROM Room r WHERE r.room_type = rt.type_code AND r.status = 'Active') AS rooms "
                + "FROM RoomType rt ORDER BY rt.is_builtin DESC, rt.type_code");
    }

    public List<Map<String, Object>> changeLog(int limit) throws SQLException {
        return Rows.query("SELECT TOP (?) l.log_id, l.category, l.item, l.old_value, l.new_value, l.note, l.changed_at, "
                + "a.full_name AS changed_by_name FROM PriceChangeLog l LEFT JOIN Account a ON a.account_id = l.changed_by "
                + "ORDER BY l.changed_at DESC, l.log_id DESC", limit);
    }

    /** Tính thử giá 1 ghế theo đúng hàm CSDL dùng khi đặt vé. */
    public Map<String, Object> calculate(int seatTypeId, String roomType, LocalDate date, LocalTime time) throws SQLException {
        Map<String, Object> out = new LinkedHashMap<>();
        try (Connection c = DBContext.getConnection()) {
            List<Map<String, Object>> slot = Rows.query(c, "SELECT slot_id, slot_name FROM TimeSlot "
                    + "WHERE slot_id = dbo.fn_GetSlotId(CAST(? AS TIME(7)))", time.toString());
            if (slot.isEmpty()) throw new IllegalArgumentException("Giờ chiếu không thuộc khung giờ nào.");
            Object slotId = slot.get(0).get("slot_id");
            Map<String, Object> r = Rows.query(c, "SELECT dbo.fn_GetDayType(?) AS day_type, "
                    + "dbo.fn_GetPriceFor(?, ?, ?, NULL) AS base, "
                    + "ISNULL((SELECT surcharge FROM RoomType WHERE type_code = ?), 0) AS surcharge, "
                    + "(SELECT TOP (1) holiday_name FROM Holiday h WHERE h.holiday_date = ? OR (h.is_recurring = 1 "
                    + "   AND h.holiday_date <= ? AND MONTH(h.holiday_date) = MONTH(?) AND DAY(h.holiday_date) = DAY(?))) AS holiday_name, "
                    + "(SELECT type_name FROM SeatType WHERE seat_type_id = ?) AS seat_type",
                    date, seatTypeId, date, slotId, roomType, date, date, date, date, seatTypeId).get(0);
            out.put("slotName", slot.get(0).get("slot_name"));
            out.put("dayType", r.get("day_type"));
            out.put("dayLabel", dayLabel(String.valueOf(r.get("day_type"))));
            out.put("holidayName", r.get("holiday_name"));
            out.put("seatType", r.get("seat_type"));
            BigDecimal base = (BigDecimal) r.get("base");
            BigDecimal sur = (BigDecimal) r.get("surcharge");
            out.put("base", base);
            out.put("surcharge", sur);
            out.put("total", base == null ? null : base.add(sur == null ? BigDecimal.ZERO : sur));
        }
        return out;
    }

    /* ======================= Bảng giá ======================= */

    /**
     * Ghi các ô giá đã đổi trong một transaction.
     * @param effectiveFrom null = áp dụng ngay (sửa phiên bản đang hiệu lực); ngày tương lai = lên lịch đổi giá
     */
    public void savePrices(List<PriceChange> changes, LocalDate effectiveFrom, String userEmail) throws SQLException {
        LocalDate today = LocalDate.now();
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                Integer uid = accountId(c, userEmail);
                Map<String, String> labels = cellLabels(c);
                for (PriceChange ch : changes) {
                    String label = labels.getOrDefault(ch.seatTypeId() + "_" + ch.slotId(), "?") + " · " + dayLabel(ch.dayType());
                    Integer curId = null;
                    BigDecimal cur = null;
                    try (PreparedStatement ps = c.prepareStatement("SELECT TOP (1) price_id, price FROM TicketPrice WITH (UPDLOCK, HOLDLOCK) "
                            + "WHERE seat_type_id = ? AND slot_id = ? AND day_type = ? AND effective_from <= ? ORDER BY effective_from DESC")) {
                        ps.setInt(1, ch.seatTypeId());
                        ps.setInt(2, ch.slotId());
                        ps.setString(3, ch.dayType());
                        ps.setObject(4, today);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) { curId = rs.getInt(1); cur = rs.getBigDecimal(2); }
                        }
                    }
                    if (!sameMoney(cur, ch.expected())) {
                        throw new IllegalStateException("Bảng giá vừa được người khác cập nhật (ô " + label + ": nay là "
                                + (cur == null ? "trống" : money(cur)) + "). Hãy tải lại trang rồi sửa lại.");
                    }
                    if (effectiveFrom == null) {
                        if (curId != null) {
                            exec(c, "UPDATE TicketPrice SET price = ?, updated_by = ?, updated_at = SYSDATETIME() WHERE price_id = ?",
                                    ch.price(), uid, curId);
                        } else {
                            exec(c, "INSERT INTO TicketPrice(seat_type_id, slot_id, day_type, price, effective_from, updated_by, updated_at) "
                                    + "VALUES (?,?,?,?,?,?,SYSDATETIME())", ch.seatTypeId(), ch.slotId(), ch.dayType(), ch.price(), BASE_DATE, uid);
                        }
                        log(c, "Price", label, money(cur), money(ch.price()), "Áp dụng ngay", uid);
                    } else {
                        int n = exec(c, "UPDATE TicketPrice SET price = ?, updated_by = ?, updated_at = SYSDATETIME() "
                                + "WHERE seat_type_id = ? AND slot_id = ? AND day_type = ? AND effective_from = ?",
                                ch.price(), uid, ch.seatTypeId(), ch.slotId(), ch.dayType(), effectiveFrom);
                        if (n == 0) {
                            exec(c, "INSERT INTO TicketPrice(seat_type_id, slot_id, day_type, price, effective_from, updated_by, updated_at) "
                                    + "VALUES (?,?,?,?,?,?,SYSDATETIME())", ch.seatTypeId(), ch.slotId(), ch.dayType(), ch.price(), effectiveFrom, uid);
                        }
                        log(c, "Schedule", label, money(cur), money(ch.price()),
                                "Áp dụng cho suất chiếu từ " + effectiveFrom.format(DMY), uid);
                    }
                }
                c.commit();
            } catch (SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    /** Hủy toàn bộ lịch đổi giá của một ngày (chỉ ngày trong tương lai). Trả về số ô đã hủy. */
    public int cancelSchedule(LocalDate date, String userEmail) throws SQLException {
        if (!date.isAfter(LocalDate.now())) throw new IllegalArgumentException("Chỉ hủy được lịch đổi giá trong tương lai.");
        return inTx(c -> {
            Integer uid = accountId(c, userEmail);
            int n = exec(c, "DELETE FROM TicketPrice WHERE effective_from = ?", date);
            if (n > 0) log(c, "Schedule", "Lịch đổi giá ngày " + date.format(DMY), n + " ô giá", null, "Đã hủy lịch", uid);
            return n;
        });
    }

    /* ======================= Ngày lễ ======================= */

    /** Thêm ngày lễ cho mọi ngày trong [from, to]; bỏ qua ngày đã có. Trả về {đã thêm, bỏ qua}. */
    public int[] addHolidays(LocalDate from, LocalDate to, String name, boolean recurring, String userEmail) throws SQLException {
        return inTx(c -> {
            Integer uid = accountId(c, userEmail);
            int added = 0, skipped = 0;
            for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                int n = exec(c, "INSERT INTO Holiday(holiday_date, holiday_name, is_recurring) SELECT ?, ?, ? "
                        + "WHERE NOT EXISTS (SELECT 1 FROM Holiday WHERE holiday_date = ?)", d, name, recurring, d);
                if (n > 0) added++; else skipped++;
            }
            String range = from.equals(to) ? from.format(DMY) : from.format(DMY) + " – " + to.format(DMY);
            if (added > 0) log(c, "Holiday", name, null, range, recurring ? "Thêm, lặp lại hằng năm" : "Thêm", uid);
            return new int[]{added, skipped};
        });
    }

    public void updateHoliday(LocalDate date, String name, boolean recurring, String userEmail) throws SQLException {
        inTx(c -> {
            Integer uid = accountId(c, userEmail);
            List<Map<String, Object>> old = Rows.query(c, "SELECT holiday_name, is_recurring FROM Holiday WHERE holiday_date = ?", date);
            if (old.isEmpty()) throw new IllegalArgumentException("Không tìm thấy ngày lễ.");
            exec(c, "UPDATE Holiday SET holiday_name = ?, is_recurring = ? WHERE holiday_date = ?", name, recurring, date);
            String oldText = old.get(0).get("holiday_name") + (Boolean.TRUE.equals(old.get(0).get("is_recurring")) ? " (hằng năm)" : "");
            log(c, "Holiday", date.format(DMY), oldText, name + (recurring ? " (hằng năm)" : ""), "Sửa", uid);
            return null;
        });
    }

    public void deleteHoliday(LocalDate date, String userEmail) throws SQLException {
        inTx(c -> {
            Integer uid = accountId(c, userEmail);
            List<Map<String, Object>> old = Rows.query(c, "SELECT holiday_name FROM Holiday WHERE holiday_date = ?", date);
            if (exec(c, "DELETE FROM Holiday WHERE holiday_date = ?", date) > 0) {
                log(c, "Holiday", String.valueOf(old.get(0).get("holiday_name")), date.format(DMY), null, "Xóa", uid);
            }
            return null;
        });
    }

    /* ======================= Khung giờ ======================= */

    /** Đổi tên / giờ bắt đầu nhiều khung giờ cùng lúc. Trả về số suất chiếu sắp tới được xếp lại khung. */
    public int saveSlots(List<SlotEdit> edits, String userEmail) throws SQLException {
        validateSlots(edits);
        return inTx(c -> {
            Integer uid = accountId(c, userEmail);
            Map<Integer, Map<String, Object>> before = new HashMap<>();
            for (Map<String, Object> r : Rows.query(c, "SELECT slot_id, slot_name, CONVERT(varchar(5), start_time, 108) AS slot_from FROM TimeSlot")) {
                before.put(((Number) r.get("slot_id")).intValue(), r);
            }
            if (before.size() != edits.size()) throw new IllegalStateException("Danh sách khung giờ đã thay đổi. Hãy tải lại trang.");
            // Một câu UPDATE duy nhất để ràng buộc UNIQUE (tên, giờ bắt đầu) chỉ được kiểm tra sau khi đổi xong.
            StringBuilder sql = new StringBuilder("UPDATE ts SET slot_name = v.name, start_time = v.st FROM TimeSlot ts JOIN (VALUES ");
            List<Object> params = new ArrayList<>();
            for (int i = 0; i < edits.size(); i++) {
                SlotEdit e = edits.get(i);
                if (!before.containsKey(e.slotId())) throw new IllegalStateException("Danh sách khung giờ đã thay đổi. Hãy tải lại trang.");
                sql.append(i == 0 ? "" : ",").append("(?, ?, CAST(? AS TIME(7)))");
                params.add(e.slotId());
                params.add(e.name());
                params.add(e.start().toString());
            }
            sql.append(") v(id, name, st) ON v.id = ts.slot_id");
            exec(c, sql.toString(), params.toArray());
            for (SlotEdit e : edits) {
                Map<String, Object> b = before.get(e.slotId());
                String oldText = b.get("slot_name") + " từ " + b.get("slot_from");
                String newText = e.name() + " từ " + e.start();
                if (!oldText.equals(newText)) log(c, "TimeSlot", e.name(), oldText, newText, "Sửa khung giờ", uid);
            }
            recomputeSlotEnds(c);
            return reassignFutureShowtimes(c);
        });
    }

    /**
     * 4 khung giờ cố định phủ kín 24 giờ; khung bắt đầu muộn nhất vòng qua nửa đêm
     * (vd. Khuya 22:00 – 06:00). Chỉ cho đổi tên / giờ bắt đầu, không thêm / xóa khung.
     */
    private static void validateSlots(List<SlotEdit> edits) {
        if (edits.isEmpty()) throw new IllegalArgumentException("Cần ít nhất một khung giờ.");
        List<SlotEdit> sorted = new ArrayList<>(edits);
        sorted.sort((a, b) -> a.start().compareTo(b.start()));
        java.util.Set<String> names = new java.util.HashSet<>();
        for (int i = 0; i < sorted.size(); i++) {
            SlotEdit e = sorted.get(i);
            if (e.name().isEmpty() || e.name().length() > 30) throw new IllegalArgumentException("Tên khung giờ không được trống (tối đa 30 ký tự).");
            if (!names.add(e.name().toLowerCase())) throw new IllegalArgumentException("Tên khung giờ \"" + e.name() + "\" bị trùng.");
            if (i > 0 && !e.start().isAfter(sorted.get(i - 1).start())) {
                throw new IllegalArgumentException("Hai khung giờ không được cùng giờ bắt đầu (" + e.start() + ").");
            }
        }
    }

    /** Giờ kết thúc mỗi khung = giờ bắt đầu khung kế tiếp; khung cuối kết thúc ở giờ bắt đầu khung sớm nhất (qua đêm). */
    private static void recomputeSlotEnds(Connection c) throws SQLException {
        exec(c, "UPDATE ts SET end_time = ISNULL(nx.next_start, (SELECT MIN(start_time) FROM TimeSlot)) FROM TimeSlot ts "
                + "OUTER APPLY (SELECT MIN(n.start_time) AS next_start FROM TimeSlot n WHERE n.start_time > ts.start_time) nx");
    }

    /** Xếp lại khung giờ cho các suất chiếu chưa diễn ra (vé đã bán giữ nguyên giá đã lưu). */
    private static int reassignFutureShowtimes(Connection c) throws SQLException {
        return exec(c, "UPDATE s SET slot_id = dbo.fn_GetSlotId(CONVERT(TIME(7), s.start_time)) FROM Showtime s "
                + "WHERE s.start_time >= SYSDATETIME() AND s.slot_id <> dbo.fn_GetSlotId(CONVERT(TIME(7), s.start_time))");
    }

    /* ======================= Phụ thu loại phòng ======================= */

    /** values / expected: type_code → phụ thu. Trả về số loại phòng đã đổi. */
    public int saveSurcharges(Map<String, BigDecimal> values, Map<String, BigDecimal> expected, String userEmail) throws SQLException {
        return inTx(c -> {
            Integer uid = accountId(c, userEmail);
            int changed = 0;
            for (Map.Entry<String, BigDecimal> e : values.entrySet()) {
                List<Map<String, Object>> cur = Rows.query(c, "SELECT surcharge FROM RoomType WITH (UPDLOCK) WHERE type_code = ?", e.getKey());
                if (cur.isEmpty()) continue;
                BigDecimal now = (BigDecimal) cur.get(0).get("surcharge");
                if (!sameMoney(now, expected.get(e.getKey()))) {
                    throw new IllegalStateException("Phụ thu phòng " + e.getKey() + " vừa được người khác đổi thành " + money(now) + ". Hãy tải lại trang.");
                }
                if (sameMoney(now, e.getValue())) continue;
                exec(c, "UPDATE RoomType SET surcharge = ? WHERE type_code = ?", e.getValue(), e.getKey());
                log(c, "Surcharge", "Phòng " + e.getKey(), money(now), money(e.getValue()), "Phụ thu mỗi ghế", uid);
                changed++;
            }
            return changed;
        });
    }

    /* ======================= Tiện ích ======================= */

    @FunctionalInterface
    private interface TxWork<T> { T run(Connection c) throws SQLException; }

    private static <T> T inTx(TxWork<T> work) throws SQLException {
        try (Connection c = DBContext.getConnection()) {
            c.setAutoCommit(false);
            try {
                T r = work.run(c);
                c.commit();
                return r;
            } catch (SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    private static Integer accountId(Connection c, String email) throws SQLException {
        if (email == null) return null;
        List<Map<String, Object>> r = Rows.query(c, "SELECT account_id FROM Account WHERE email = ?", email);
        return r.isEmpty() ? null : ((Number) r.get(0).get("account_id")).intValue();
    }

    private static Map<String, String> cellLabels(Connection c) throws SQLException {
        Map<String, String> m = new HashMap<>();
        for (Map<String, Object> r : Rows.query(c, "SELECT st.seat_type_id, st.type_name, ts.slot_id, ts.slot_name "
                + "FROM SeatType st CROSS JOIN TimeSlot ts")) {
            m.put(r.get("seat_type_id") + "_" + r.get("slot_id"), r.get("type_name") + " · " + r.get("slot_name"));
        }
        return m;
    }

    private static void log(Connection c, String category, String item, String oldValue, String newValue,
                            String note, Integer uid) throws SQLException {
        exec(c, "INSERT INTO PriceChangeLog(category, item, old_value, new_value, note, changed_by) VALUES (?,?,?,?,?,?)",
                category, item, oldValue, newValue, note, uid);
    }

    private static boolean sameMoney(BigDecimal a, BigDecimal b) {
        return a == null ? b == null : b != null && a.compareTo(b) == 0;
    }

    private static int exec(Connection c, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                Object p = params[i];
                if (p == null) ps.setNull(i + 1, java.sql.Types.VARCHAR);   // SQL Server tự chuyển NULL sang kiểu cột
                else ps.setObject(i + 1, p);
            }
            return ps.executeUpdate();
        }
    }
}
