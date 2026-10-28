package com.cinema.dao;

import com.cinema.model.PriceRow;
import com.cinema.util.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/** Đọc bảng giá vé (TicketPrice) để hiển thị công khai. */
public class PricingDAO {

    /** Bảng giá theo (khung giờ, loại ghế); mỗi dòng gồm giá ngày thường / cuối tuần / lễ. */
    public List<PriceRow> findPriceTable() throws SQLException {
        List<PriceRow> list = new ArrayList<>();
        String sql = "SELECT ts.slot_name, st.type_name, "
                + "MAX(CASE WHEN tp.day_type = 'Weekday' THEN tp.price END) AS weekday, "
                + "MAX(CASE WHEN tp.day_type = 'Weekend' THEN tp.price END) AS weekend, "
                + "MAX(CASE WHEN tp.day_type = 'Holiday' THEN tp.price END) AS holiday "
                + "FROM TicketPrice tp "
                + "JOIN TimeSlot ts ON ts.slot_id = tp.slot_id "
                + "JOIN SeatType st ON st.seat_type_id = tp.seat_type_id "
                + "GROUP BY ts.slot_id, ts.slot_name, ts.start_time, st.seat_type_id, st.type_name "
                + "ORDER BY ts.start_time, st.seat_type_id";
        try (Connection c = DBContext.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                PriceRow row = new PriceRow();
                row.setSlotName(rs.getString("slot_name"));
                row.setSeatTypeName(rs.getString("type_name"));
                row.setWeekday(rs.getBigDecimal("weekday"));
                row.setWeekend(rs.getBigDecimal("weekend"));
                row.setHoliday(rs.getBigDecimal("holiday"));
                list.add(row);
            }
        }
        return list;
    }
}
