package com.cinema.util.room;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Quy tắc nghiệp vụ & kiểm tra dữ liệu cho Phòng chiếu / Layout ghế (không phụ thuộc DB, dễ test).
 * Các hằng số khớp CHECK constraint trong script database của nhóm.
 */
public final class RoomRules {

    public static final String ROLE_ADMIN = "ADMIN";

    /** CHECK Room.room_type. */
    public static final List<String> ROOM_TYPES = List.of("2D", "3D", "IMAX", "4DX");
    /** CHECK Room.status. */
    public static final String ROOM_ACTIVE = "Active";
    public static final String ROOM_CLOSED = "Closed";
    /** CHECK Seat.status. */
    public static final String SEAT_ACTIVE = "Active";
    public static final String SEAT_MAINTENANCE = "Maintenance";

    /** Tổng số phòng chiếu tối đa (tính cả phòng đã đóng vì có thể mở lại). */
    public static final int MAX_ROOMS = 13;
    public static final String ROOM_LIMIT_MESSAGE =
            "Số phòng chiếu đã đạt tối đa (" + MAX_ROOMS + " phòng). Không thể thêm phòng mới.";

    public static final int MAX_ROOM_NAME = 50;
    public static final int MAX_CAPACITY = 500;
    /** row_label là CHAR(1) nên tối đa 26 hàng A–Z. */
    public static final int MAX_ROWS = 26;
    public static final int MAX_COLS = 30;

    public static final String ROOM_TYPE_2D = "2D";
    public static final String ROOM_TYPE_IMAX = "IMAX";
    /** Rạp 2D: A–D thường, E–H VIP (14 ghế mỗi hàng), J ghế đôi (6 cặp). Không có hàng I. */
    public static final int FIXED_2D_CAPACITY = 124;
    /** Rạp IMAX: A–B thường, C–D VIP (8 ghế mỗi hàng), E ghế đôi (4 cặp). */
    public static final int FIXED_IMAX_CAPACITY = 40;
    public static final String ROOM_TYPE_3D = "3D";
    /** Rạp 3D: A 12, B 13, C 14 ghế thường; D–G 14 ghế VIP mỗi hàng; H ghế đôi (6 cặp). */
    public static final int FIXED_3D_CAPACITY = 107;
    public static final String ROOM_TYPE_4DX = "4DX";
    /** Rạp 4DX: A 8 ghế thường; B 12 ghế (B5–B8 VIP, còn lại thường); C–E 12 ghế VIP mỗi hàng; F ghế đôi (5 cặp). */
    public static final int FIXED_4DX_CAPACITY = 66;
    private static final int COUPLE_ROW_SEATS = 12;

    private RoomRules() {
    }

    public static boolean isFixedLayout(String roomType) {
        return ROOM_TYPE_2D.equals(roomType) || ROOM_TYPE_IMAX.equals(roomType)
                || ROOM_TYPE_3D.equals(roomType) || ROOM_TYPE_4DX.equals(roomType);
    }

    public static int fixedCapacity(String roomType) {
        if (ROOM_TYPE_IMAX.equals(roomType)) {
            return FIXED_IMAX_CAPACITY;
        }
        if (ROOM_TYPE_4DX.equals(roomType)) {
            return FIXED_4DX_CAPACITY;
        }
        return ROOM_TYPE_3D.equals(roomType) ? FIXED_3D_CAPACITY : FIXED_2D_CAPACITY;
    }

    public static String fixedSummary(String roomType) {
        if (ROOM_TYPE_4DX.equals(roomType)) {
            return FIXED_4DX_CAPACITY + " ghế: hàng A 8 ghế thường, hàng B 12 ghế (B5–B8 là VIP), hàng C–E ghế VIP (12 ghế mỗi hàng), hàng F 5 cặp ghế đôi.";
        }
        if (ROOM_TYPE_IMAX.equals(roomType)) {
            return FIXED_IMAX_CAPACITY + " ghế: hàng A–B ghế thường, hàng C–D ghế VIP (8 ghế mỗi hàng), hàng E 4 cặp ghế đôi.";
        }
        if (ROOM_TYPE_3D.equals(roomType)) {
            return FIXED_3D_CAPACITY + " ghế: hàng A–C ghế thường (12, 13, 14 ghế), hàng D–G ghế VIP (14 ghế mỗi hàng), hàng H 6 cặp ghế đôi.";
        }
        return FIXED_2D_CAPACITY + " ghế: hàng A–D ghế thường, hàng E–H ghế VIP (14 ghế mỗi hàng), hàng J 6 cặp ghế đôi.";
    }

    public static List<SeatSpec> fixedLayout(String roomType, int standardTypeId, int vipTypeId, int coupleTypeId) {
        List<SeatSpec> out = new ArrayList<>(fixedCapacity(roomType));
        if (ROOM_TYPE_4DX.equals(roomType)) {
            addRows(out, new String[] {"A"}, 8, standardTypeId, false);
            for (int n = 1; n <= 12; n++) {
                out.add(new SeatSpec("B", n, n >= 5 && n <= 8 ? vipTypeId : standardTypeId, false));
            }
            addRows(out, new String[] {"C", "D", "E"}, 12, vipTypeId, false);
            addRows(out, new String[] {"F"}, 10, coupleTypeId, true);
        } else if (ROOM_TYPE_IMAX.equals(roomType)) {
            addRows(out, new String[] {"A", "B"}, 8, standardTypeId, false);
            addRows(out, new String[] {"C", "D"}, 8, vipTypeId, false);
            addRows(out, new String[] {"E"}, 8, coupleTypeId, true);
        } else if (ROOM_TYPE_3D.equals(roomType)) {
            addRows(out, new String[] {"A"}, 12, standardTypeId, false);
            addRows(out, new String[] {"B"}, 13, standardTypeId, false);
            addRows(out, new String[] {"C"}, 14, standardTypeId, false);
            addRows(out, new String[] {"D", "E", "F", "G"}, 14, vipTypeId, false);
            addRows(out, new String[] {"H"}, COUPLE_ROW_SEATS, coupleTypeId, true);
        } else {
            addRows(out, new String[] {"A", "B", "C", "D"}, 14, standardTypeId, false);
            addRows(out, new String[] {"E", "F", "G", "H"}, 14, vipTypeId, false);
            addRows(out, new String[] {"J"}, COUPLE_ROW_SEATS, coupleTypeId, true);
        }
        return out;
    }

    /** Số ghế đứng ngay trước dải hành lang ở hàng ghế đôi; chỉ IMAX chia hàng đôi bằng hành lang. */
    public static Set<Integer> coupleAisles(String roomType) {
        return ROOM_TYPE_IMAX.equals(roomType) ? Set.of(2) : Set.of();
    }

    /** Hành lang đầu hàng ghế đơn nằm sau ghế số này. */
    public static int aisleFromStart(String roomType) {
        if (ROOM_TYPE_4DX.equals(roomType)) {
            return 4;
        }
        return ROOM_TYPE_IMAX.equals(roomType) ? 2 : 3;
    }

    /** Hành lang cuối hàng ghế đơn cách cuối hàng bao nhiêu ghế; 0 là không có. */
    public static int aisleFromEnd(String roomType) {
        if (ROOM_TYPE_4DX.equals(roomType)) {
            return 4;
        }
        return ROOM_TYPE_IMAX.equals(roomType) ? 0 : 3;
    }

    public static String planVariant(String roomType) {
        if (ROOM_TYPE_IMAX.equals(roomType)) {
            return "imax";
        }
        if (ROOM_TYPE_4DX.equals(roomType)) {
            return "4dx";
        }
        return ROOM_TYPE_3D.equals(roomType) ? "3d" : "";
    }

    /** Ghế có màu nhấn riêng, theo nhãn ghế: "core" là cụm giữa hàng VIP IMAX, "king" là các ghế tâm điểm. */
    public static Map<String, String> seatZones(String roomType) {
        Map<String, String> zones = new HashMap<>();
        if (ROOM_TYPE_IMAX.equals(roomType)) {
            for (String row : new String[] {"C", "D"}) {
                for (int n = 3; n <= 8; n++) {
                    zones.put(row + n, "core");
                }
            }
            zones.put("C5", "king");
            zones.put("C6", "king");
        } else if (ROOM_TYPE_4DX.equals(roomType)) {
            for (String row : new String[] {"C", "D", "E"}) {
                for (int n = 5; n <= 8; n++) {
                    zones.put(row + n, "core");
                }
            }
            zones.put("F5", "core");
            zones.put("F6", "core");
        } else if (ROOM_TYPE_3D.equals(roomType)) {
            for (String label : new String[] {"E7", "E8", "F7", "F8"}) {
                zones.put(label, "king");
            }
        }
        return zones;
    }

    private static void addRows(List<SeatSpec> out, String[] rows, int seats, int typeId, boolean couple) {
        for (String row : rows) {
            for (int n = 1; n <= seats; n++) {
                out.add(new SeatSpec(row, n, typeId, couple));
            }
        }
    }

    /** Kiểm tra thông tin phòng; trả về thông báo lỗi hoặc null nếu hợp lệ. */
    public static String validateRoom(String name, String type, String capacityStr, String status) {
        if (name == null || name.isBlank()) {
            return "Tên phòng chiếu là bắt buộc.";
        }
        if (name.trim().length() > MAX_ROOM_NAME) {
            return "Tên phòng tối đa " + MAX_ROOM_NAME + " ký tự.";
        }
        if (!ROOM_TYPES.contains(type)) {
            return "Loại phòng không hợp lệ (2D, 3D, IMAX hoặc 4DX).";
        }
        Integer cap = parseInt(capacityStr);
        if (cap == null || cap < 1 || cap > MAX_CAPACITY) {
            return "Sức chứa phải là số nguyên từ 1 đến " + MAX_CAPACITY + ".";
        }
        if (!ROOM_ACTIVE.equals(status) && !ROOM_CLOSED.equals(status)) {
            return "Trạng thái phòng không hợp lệ.";
        }
        return null;
    }

    /**
     * Một ghế sẽ được tạo ra từ layout. Ghế đôi (couple = true) được ghép cặp theo số ghế trong hàng:
     * 1-2, 3-4, 5-6, ... (DAO gán pair_seat_id sau khi insert).
     */
    public static final class SeatSpec {
        public final String rowLabel;
        public final int seatNumber;
        public final int seatTypeId;
        public final boolean couple;

        public SeatSpec(String rowLabel, int seatNumber, int seatTypeId, boolean couple) {
            this.rowLabel = rowLabel;
            this.seatNumber = seatNumber;
            this.seatTypeId = seatTypeId;
            this.couple = couple;
        }
    }

    /** Nhãn hàng: 0 → A, 1 → B, ... */
    public static String rowLabel(int index) {
        return String.valueOf((char) ('A' + index));
    }

    /** Kiểm tra số hàng/cột; trả về lỗi hoặc null. */
    public static String validateGrid(int rows, int cols) {
        if (rows < 1 || rows > MAX_ROWS) {
            return "Số hàng phải từ 1 đến " + MAX_ROWS + " (A–Z).";
        }
        if (cols < 1 || cols > MAX_COLS) {
            return "Số ghế mỗi hàng phải từ 1 đến " + MAX_COLS + ".";
        }
        return null;
    }

    /**
     * Kiểm tra layout rows x cols có xếp vừa đúng total ghế không: các hàng đầu đủ cols ghế, hàng cuối nhận
     * phần còn lại (1..cols ghế). Trả về lỗi kèm gợi ý cụ thể, hoặc null nếu hợp lệ.
     */
    public static String validateLayout(int rows, int cols, int total) {
        String err = validateGrid(rows, cols);
        if (err != null) {
            return err;
        }
        if (total < 1 || total > MAX_CAPACITY) {
            return "Tổng số ghế phải từ 1 đến " + MAX_CAPACITY + ".";
        }
        int fit = rows * cols;
        if (fit < total) {
            int needRows = (total + cols - 1) / cols;
            int needCols = (total + rows - 1) / rows;
            StringBuilder hint = new StringBuilder();
            if (needRows <= MAX_ROWS) {
                hint.append("tăng lên ").append(needRows).append(" hàng").append(lastRowNote(needRows, cols, total));
            }
            if (needCols <= MAX_COLS) {
                if (hint.length() > 0) hint.append(", hoặc ");
                hint.append("tăng lên ").append(needCols).append(" ghế mỗi hàng").append(lastRowNote(rows, needCols, total));
            }
            return "Layout " + rows + " hàng × " + cols + " ghế chỉ chứa " + fit + " ghế, thiếu " + (total - fit)
                    + " ghế so với tổng " + total + "."
                    + (hint.length() > 0 ? " Hãy " + hint + "." : "")
                    + " Hoặc giảm tổng số ghế xuống " + fit + ".";
        }
        if ((rows - 1) * cols >= total) {
            int needRows = (total + cols - 1) / cols;
            return "Với " + total + " ghế và " + cols + " ghế mỗi hàng chỉ cần " + needRows + " hàng"
                    + lastRowNote(needRows, cols, total) + "; hàng " + rowLabel(rows - 1)
                    + " sẽ không có ghế nào. Hãy giảm số hàng xuống " + needRows + ".";
        }
        return null;
    }

    /** " (hàng E có 6 ghế)" khi hàng cuối thiếu ghế, rỗng khi các hàng đều đủ. */
    private static String lastRowNote(int rows, int cols, int total) {
        int last = total - (rows - 1) * cols;
        return last < cols ? " (hàng " + rowLabel(rows - 1) + " có " + last + " ghế)" : "";
    }

    /**
     * Gợi ý số hàng × số ghế mỗi hàng cho total ghế: ưu tiên chia hết (mọi hàng đủ ghế) với hàng dài khoảng gấp
     * đôi số hàng như phòng chiếu thường gặp (50 → 5 × 10, 55 → 5 × 11, 44 → 4 × 11); không chia hết thì hàng
     * cuối ngắn hơn (53 → 6 × 10, hàng F có 3 ghế).
     *
     * @return {rows, cols}
     */
    public static int[] suggestGrid(int total) {
        total = Math.max(1, Math.min(MAX_CAPACITY, total));
        int minCols = Math.max(1, (total + MAX_ROWS - 1) / MAX_ROWS);
        int[] best = null;
        int bestScore = Integer.MAX_VALUE;
        for (int cols = Math.max(minCols, 6); cols <= Math.min(MAX_COLS, 20); cols++) {
            if (total % cols != 0) continue;
            int rows = total / cols;
            int score = Math.abs(cols - 2 * rows);
            if (score < bestScore) {
                bestScore = score;
                best = new int[] {rows, cols};
            }
        }
        if (best != null) {
            return best;
        }
        int cols = (int) Math.round(Math.sqrt(total * 2.0));
        cols = Math.max(minCols, Math.min(Math.min(MAX_COLS, 20), Math.max(Math.min(total, 6), cols)));
        return new int[] {(total + cols - 1) / cols, cols};
    }

    /**
     * Sinh danh sách ghế cho layout rows x cols, đủ đúng total ghế: các hàng đầu cols ghế, hàng cuối nhận phần còn
     * lại. rowTypeIds[i] là loại ghế của hàng i. Hàng ghế đôi phải có số ghế chẵn; các ghế được ghép cặp (1-2, 3-4, ...).
     *
     * @throws IllegalArgumentException khi dữ liệu không hợp lệ (message hiển thị được cho người dùng)
     */
    public static List<SeatSpec> buildLayout(int rows, int cols, int total, int[] rowTypeIds, Set<Integer> coupleTypeIds) {
        String err = validateLayout(rows, cols, total);
        if (err != null) {
            throw new IllegalArgumentException(err);
        }
        if (rowTypeIds == null || rowTypeIds.length != rows) {
            throw new IllegalArgumentException("Thiếu loại ghế cho một số hàng.");
        }
        List<SeatSpec> out = new ArrayList<>(total);
        for (int r = 0; r < rows; r++) {
            int typeId = rowTypeIds[r];
            boolean couple = coupleTypeIds.contains(typeId);
            int seats = r < rows - 1 ? cols : total - (rows - 1) * cols;
            if (couple && seats % 2 != 0) {
                throw new IllegalArgumentException("Hàng " + rowLabel(r) + " là ghế đôi nên phải có số ghế chẵn"
                        + " (đang có " + seats + " ghế).");
            }
            for (int c = 1; c <= seats; c++) {
                out.add(new SeatSpec(rowLabel(r), c, typeId, couple));
            }
        }
        return out;
    }

    /** Layout đủ hàng đủ cột (rows x cols ghế). */
    public static List<SeatSpec> buildLayout(int rows, int cols, int[] rowTypeIds, Set<Integer> coupleTypeIds) {
        return buildLayout(rows, cols, rows * cols, rowTypeIds, coupleTypeIds);
    }

    /** Parse "1,1,2,3" → {1,1,2,3}; ném IllegalArgumentException nếu sai định dạng. */
    public static int[] parseRowTypes(String csv, int rows) {
        if (csv == null || csv.isBlank()) {
            throw new IllegalArgumentException("Chưa chọn loại ghế cho các hàng.");
        }
        String[] parts = csv.split(",");
        if (parts.length != rows) {
            throw new IllegalArgumentException("Số loại ghế không khớp số hàng.");
        }
        int[] ids = new int[rows];
        for (int i = 0; i < rows; i++) {
            Integer v = parseInt(parts[i].trim());
            if (v == null) {
                throw new IllegalArgumentException("Loại ghế không hợp lệ.");
            }
            ids[i] = v;
        }
        return ids;
    }

    public static Integer parseInt(String s) {
        if (s == null) {
            return null;
        }
        try {
            return Integer.valueOf(s.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** true nếu nhãn hàng là một chữ cái A–Z. */
    public static boolean isRowLabel(String s) {
        return s != null && s.length() == 1 && s.charAt(0) >= 'A' && s.charAt(0) <= 'Z';
    }
}
