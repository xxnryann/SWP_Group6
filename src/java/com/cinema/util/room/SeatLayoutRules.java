package com.cinema.util.room;

import com.cinema.util.room.RoomRules.SeatSpec;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Quy tắc cho layout ghế trong thư viện (bảng SeatLayout), không phụ thuộc DB.
 *
 * Định dạng layout_data: các hàng cách nhau bởi '/', mỗi ký tự là một ghế trong DB:
 *   S = ghế thường, V = ghế VIP, C = ghế đôi. Ghế đôi luôn đi theo cặp liền nhau ("CC"),
 *   ghép từ trái sang phải; vì vậy mỗi đoạn C liên tiếp phải có độ dài chẵn.
 * Ghế đã xóa không có ký tự nào (các ghế còn lại dồn sát nhau), số ghế được đánh lại 1..n theo hàng.
 */
public final class SeatLayoutRules {

    public static final int MAX_NAME = 100;
    /** Tối đa 30 cột lưới: ghế đôi chiếm 2 cột nên mỗi hàng tối đa 30 ghế trong DB. */
    public static final int MAX_SEATS_PER_ROW = RoomRules.MAX_COLS;

    private SeatLayoutRules() {
    }

    /** Kiểm tra layout_data; trả về thông báo lỗi hoặc null nếu hợp lệ. */
    public static String validate(String data) {
        if (data == null || data.isBlank()) {
            return "Layout chưa có ghế nào.";
        }
        String[] rows = data.split("/", -1);
        if (rows.length > RoomRules.MAX_ROWS) {
            return "Layout tối đa " + RoomRules.MAX_ROWS + " hàng (A–Z).";
        }
        int total = 0;
        for (int r = 0; r < rows.length; r++) {
            String row = rows[r];
            String label = RoomRules.rowLabel(r);
            if (row.isEmpty()) {
                return "Hàng " + label + " không có ghế nào.";
            }
            if (row.length() > MAX_SEATS_PER_ROW) {
                return "Hàng " + label + " vượt quá " + MAX_SEATS_PER_ROW + " ghế.";
            }
            int run = 0;
            for (int i = 0; i <= row.length(); i++) {
                char ch = i < row.length() ? row.charAt(i) : '.';
                if (i < row.length() && ch != 'S' && ch != 'V' && ch != 'C') {
                    return "Hàng " + label + " có ghế chưa gán loại hoặc loại ghế không hợp lệ.";
                }
                if (ch == 'C') {
                    run++;
                } else {
                    if (run % 2 != 0) {
                        return "Hàng " + label + " có ghế đôi bị lẻ (ghế đôi phải đi theo cặp).";
                    }
                    run = 0;
                }
            }
            total += row.length();
        }
        if (total > RoomRules.MAX_CAPACITY) {
            return "Layout tối đa " + RoomRules.MAX_CAPACITY + " ghế (đang có " + total + ").";
        }
        return null;
    }

    /** Kiểm tra tên layout (chưa kiểm tra trùng); trả về lỗi hoặc null. */
    public static String validateName(String name) {
        if (name == null || name.isBlank()) {
            return "Vui lòng đặt tên cho layout.";
        }
        if (name.trim().length() > MAX_NAME) {
            return "Tên layout tối đa " + MAX_NAME + " ký tự.";
        }
        return null;
    }

    public static int seatCount(String data) {
        return data == null ? 0 : data.replace("/", "").length();
    }

    /** Sinh danh sách ghế (đã kiểm tra hợp lệ trước) theo seat_type_id thực tế. */
    public static List<SeatSpec> toSpecs(String data, int standardTypeId, int vipTypeId, int coupleTypeId) {
        List<SeatSpec> out = new ArrayList<>();
        String[] rows = data.split("/");
        for (int r = 0; r < rows.length; r++) {
            String row = rows[r];
            for (int i = 0; i < row.length(); i++) {
                char ch = row.charAt(i);
                int type = ch == 'V' ? vipTypeId : ch == 'C' ? coupleTypeId : standardTypeId;
                out.add(new SeatSpec(RoomRules.rowLabel(r), i + 1, type, ch == 'C'));
            }
        }
        return out;
    }

    /**
     * Chuỗi xem trước của layout chuẩn theo loại phòng (cùng định dạng layout_data), có thêm '_' tại vị trí
     * hành lang giữa các khối ghế để bản thu nhỏ giống sơ đồ thật.
     */
    public static String standardPreview(String roomType) {
        Map<String, List<SeatSpec>> rows = new LinkedHashMap<>();
        for (SeatSpec sp : RoomRules.fixedLayout(roomType, 1, 2, 3)) {
            rows.computeIfAbsent(sp.rowLabel, k -> new ArrayList<>()).add(sp);
        }
        Set<Integer> coupleAisles = RoomRules.coupleAisles(roomType);
        int fromStart = RoomRules.aisleFromStart(roomType);
        int fromEnd = RoomRules.aisleFromEnd(roomType);
        StringBuilder sb = new StringBuilder();
        for (List<SeatSpec> row : rows.values()) {
            if (sb.length() > 0) {
                sb.append('/');
            }
            int size = row.size();
            for (SeatSpec s : row) {
                sb.append(s.seatTypeId == 2 ? 'V' : s.couple ? 'C' : 'S');
                boolean aisle = s.couple ? coupleAisles.contains(s.seatNumber)
                        : s.seatNumber == fromStart || (fromEnd > 0 && s.seatNumber == size - fromEnd);
                if (aisle && s.seatNumber < size) {
                    sb.append('_');
                }
            }
        }
        return sb.toString();
    }
}
