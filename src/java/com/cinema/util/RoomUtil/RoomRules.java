package com.cinema.util.RoomUtil;

import java.util.ArrayList;
import java.util.List;
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

    public static final int MAX_ROOM_NAME = 50;
    public static final int MAX_CAPACITY = 500;
    /** row_label là CHAR(1) nên tối đa 26 hàng A–Z. */
    public static final int MAX_ROWS = 26;
    public static final int MAX_COLS = 30;

    private RoomRules() {
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
     * Sinh danh sách ghế cho layout rows x cols. rowTypeIds[i] là loại ghế của hàng i.
     * Hàng ghế đôi phải có số cột chẵn; các ghế được ghép cặp (1-2, 3-4, ...).
     *
     * @throws IllegalArgumentException khi dữ liệu không hợp lệ (message hiển thị được cho người dùng)
     */
    public static List<SeatSpec> buildLayout(int rows, int cols, int[] rowTypeIds, Set<Integer> coupleTypeIds) {
        String err = validateGrid(rows, cols);
        if (err != null) {
            throw new IllegalArgumentException(err);
        }
        if (rowTypeIds == null || rowTypeIds.length != rows) {
            throw new IllegalArgumentException("Thiếu loại ghế cho một số hàng.");
        }
        List<SeatSpec> out = new ArrayList<>(rows * cols);
        for (int r = 0; r < rows; r++) {
            int typeId = rowTypeIds[r];
            boolean couple = coupleTypeIds.contains(typeId);
            if (couple && cols % 2 != 0) {
                throw new IllegalArgumentException("Hàng " + rowLabel(r)
                        + " là ghế đôi nên số ghế mỗi hàng phải là số chẵn.");
            }
            for (int c = 1; c <= cols; c++) {
                out.add(new SeatSpec(rowLabel(r), c, typeId, couple));
            }
        }
        return out;
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
