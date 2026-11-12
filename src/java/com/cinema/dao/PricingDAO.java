package com.cinema.dao;

import com.cinema.util.Rows;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Đọc dữ liệu cho trang bảng giá vé công khai (/pricing).
 * TicketPrice có nhiều phiên bản (effective_from) — luôn lấy phiên bản đang áp dụng hôm nay.
 */
public class PricingDAO {

    /** Giá đang áp dụng theo (loại ghế × khung giờ), mỗi dòng có giá ngày thường / cuối tuần / lễ. */
    public List<Map<String, Object>> priceMatrix() throws SQLException {
        return Rows.query("SELECT st.seat_type_id, st.type_name, st.description AS type_desc, st.is_couple, "
                + "ts.slot_id, ts.slot_name, "
                + "wd.price AS weekday, we.price AS weekend, ho.price AS holiday "
                + "FROM SeatType st CROSS JOIN TimeSlot ts "
                + priceApply("Weekday", "wd") + priceApply("Weekend", "we") + priceApply("Holiday", "ho")
                + "WHERE COALESCE(wd.price, we.price, ho.price) IS NOT NULL "
                + "ORDER BY st.seat_type_id, ts.start_time");
    }

    /** Khung giờ giá, sắp theo giờ bắt đầu (khung cuối có thể vòng qua nửa đêm). */
    public List<Map<String, Object>> timeSlots() throws SQLException {
        return Rows.query("SELECT slot_id, slot_name, CONVERT(varchar(5), start_time, 108) AS slot_from, "
                + "CONVERT(varchar(5), end_time, 108) AS slot_to FROM TimeSlot ORDER BY start_time");
    }

    /** Loại phòng có phòng đang hoạt động (kèm phụ thu mỗi ghế). */
    public List<Map<String, Object>> roomTypes() throws SQLException {
        return Rows.query("SELECT rt.type_code, rt.description, rt.surcharge FROM RoomType rt "
                + "WHERE EXISTS (SELECT 1 FROM Room r WHERE r.room_type = rt.type_code AND r.status = 'Active') "
                + "OR rt.is_builtin = 1 ORDER BY rt.surcharge, rt.type_code");
    }

    public List<Map<String, Object>> holidays() throws SQLException {
        return Rows.query("SELECT holiday_date, holiday_name, is_recurring FROM Holiday ORDER BY holiday_date");
    }

    /** Loại ngày và khung giờ của thời điểm hiện tại (để chọn sẵn trên trang). */
    public Map<String, Object> now() throws SQLException {
        return Rows.query("SELECT dbo.fn_GetDayType(CAST(SYSDATETIME() AS DATE)) AS day_type, "
                + "dbo.fn_GetSlotId(CAST(SYSDATETIME() AS TIME(7))) AS slot_id").get(0);
    }

    private static String priceApply(String dayType, String alias) {
        return "OUTER APPLY (SELECT TOP (1) p.price FROM TicketPrice p WHERE p.seat_type_id = st.seat_type_id "
                + "AND p.slot_id = ts.slot_id AND p.day_type = '" + dayType + "' "
                + "AND p.effective_from <= CAST(SYSDATETIME() AS DATE) ORDER BY p.effective_from DESC) " + alias + " ";
    }
}
