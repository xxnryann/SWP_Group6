package com.cinema.service;

import com.cinema.util.DBContext;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * STT 26 + STT 27 (Iter3) — Áp voucher & MyPoint khi thanh toán.
 *
 * MỘT hàm duy nhất dùng chung cho cả đặt vé online (STT 25 — Phạm Nam gọi)
 * và bán tại quầy (STT 21 — Long gọi), để hai luồng không tính lệch nhau.
 *
 * Logic giảm giá nằm trong stored procedure của database nhóm:
 *  - sp_ApplyVoucher: kiểm tra mã, trạng thái Allowed, còn hạn, còn lượt,
 *    chi tiêu tích lũy >= min_cumulative_spending, đơn >= min_order_amount.
 *    Áp voucher sẽ reset điểm đã dùng trước đó → LUÔN gọi voucher trước.
 *  - sp_ApplyMyPoint: kiểm tra số dư điểm và trần % giá trị đơn.
 * Lỗi nghiệp vụ được procedure THROW với message tiếng Việt → trả về UI.
 */
public class DiscountService {

    /**
     * @param bookingId   id booking đang ở trạng thái PendingPayment
     * @param voucherCode mã voucher khách nhập (null/rỗng nếu không dùng)
     * @param pointsToUse số điểm muốn dùng (0 nếu không dùng)
     * @return kết quả tính toán; message chứa lỗi tiếng Việt nếu thất bại
     */
    public DiscountResult applyDiscounts(int bookingId, String voucherCode, int pointsToUse) {
        DiscountResult r = new DiscountResult();
        try (Connection c = DBContext.getConnection()) {

            if (voucherCode != null && !voucherCode.trim().isEmpty()) {
                try (CallableStatement cs = c.prepareCall("{call sp_ApplyVoucher(?, ?)}")) {
                    cs.setInt(1, bookingId);
                    cs.setString(2, voucherCode.trim());
                    cs.execute();
                }
            }

            if (pointsToUse > 0) {
                try (CallableStatement cs = c.prepareCall("{call sp_ApplyMyPoint(?, ?)}")) {
                    cs.setInt(1, bookingId);
                    cs.setInt(2, pointsToUse);
                    cs.execute();
                }
            }

            // Đọc lại tổng tiền sau giảm
            String sql = "SELECT ticket_total, combo_total, voucher_discount, " +
                    "points_discount, total_amount, points_used FROM Booking WHERE booking_id = ?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setInt(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        r.setVoucherDiscount(rs.getBigDecimal("voucher_discount"));
                        r.setPointsDiscount(rs.getBigDecimal("points_discount"));
                        r.setTotal(rs.getBigDecimal("total_amount"));
                        r.setPointsUsed(rs.getInt("points_used"));
                        r.setVoucherCode(voucherCode == null || voucherCode.trim().isEmpty()
                                ? null : voucherCode.trim());
                        r.setMessage("Áp dụng giảm giá thành công.");
                    } else {
                        r.setMessage("Không tìm thấy booking.");
                    }
                }
            }
        } catch (SQLException e) {
            // Message từ THROW trong procedure đã là tiếng Việt, hiện trực tiếp cho user
            r.setMessage(e.getMessage());
        }
        return r;
    }
}
