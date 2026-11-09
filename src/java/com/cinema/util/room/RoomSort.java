package com.cinema.util.room;

import com.cinema.model.Room;
import java.text.Collator;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Lọc và sắp xếp danh sách phòng chiếu theo các dropdown ở màn hình quản lý phòng.
 * Các dropdown dùng cùng lúc được:
 *   type     chỉ giữ phòng thuộc loại đó (2D, 3D, IMAX, 4DX)
 *   status   chỉ giữ phòng có trạng thái đó (Active, Closed)
 *   capacity asc | desc  sức chứa
 *   upcoming asc | desc  số suất sắp tới
 *   room     name_asc | name_desc | number_asc | number_desc  tên hoặc số phòng
 * Thứ tự ưu tiên khi sắp xếp: capacity, rồi upcoming, rồi room. Room đứng cuối vì tên phòng
 * không trùng nhau, đứng trước thì các tiêu chí sau không còn tác dụng.
 * Giá trị rỗng hoặc không hợp lệ thì bỏ qua tiêu chí đó.
 */
public final class RoomSort {

    private static final Pattern FIRST_NUMBER = Pattern.compile("\\d{1,9}");
    private static final Comparator<Room> BY_NAME = nameComparator();

    /** Phòng không có số trong tên luôn nằm cuối, dù sắp xếp chiều nào. */
    private static final Comparator<Room> BY_NUMBER_ASC = Comparator
            .comparing(RoomSort::numberOf, Comparator.nullsLast(Comparator.<Integer>naturalOrder()))
            .thenComparing(BY_NAME);
    private static final Comparator<Room> BY_NUMBER_DESC = Comparator
            .comparing(RoomSort::numberOf, Comparator.nullsLast(Comparator.<Integer>reverseOrder()))
            .thenComparing(BY_NAME);

    private static final Map<String, Comparator<Room>> ROOM_ORDERS = Map.of(
            "name_asc", BY_NAME,
            "name_desc", BY_NAME.reversed(),
            "number_asc", BY_NUMBER_ASC,
            "number_desc", BY_NUMBER_DESC);

    private RoomSort() {
    }

    public static List<Room> apply(List<Room> rooms, String room, String type, String capacity,
            String upcoming, String status) {
        Comparator<Room> order = room == null ? BY_NUMBER_ASC : ROOM_ORDERS.getOrDefault(room, BY_NUMBER_ASC);
        order = prepend(Comparator.comparingInt(Room::getUpcomingShowtimes), upcoming, order);
        order = prepend(Comparator.comparingInt(Room::getCapacity), capacity, order);

        boolean byType = type != null && RoomRules.ROOM_TYPES.contains(type);
        boolean byStatus = RoomRules.ROOM_ACTIVE.equals(status) || RoomRules.ROOM_CLOSED.equals(status);
        return rooms.stream()
                .filter(r -> !byType || type.equals(r.getRoomType()))
                .filter(r -> !byStatus || status.equals(r.getStatus()))
                .sorted(order)
                .collect(Collectors.toList());
    }

    /** Đặt tiêu chí lên trước order nếu direction là asc/desc; ngược lại giữ nguyên order. */
    private static Comparator<Room> prepend(Comparator<Room> criterion, String direction, Comparator<Room> order) {
        if ("asc".equals(direction)) {
            return criterion.thenComparing(order);
        }
        if ("desc".equals(direction)) {
            return criterion.reversed().thenComparing(order);
        }
        return order;
    }

    private static Integer numberOf(Room room) {
        Matcher m = FIRST_NUMBER.matcher(room.getRoomName());
        return m.find() ? Integer.valueOf(m.group()) : null;
    }

    /** So sánh theo tiếng Việt, không phân biệt hoa thường. */
    private static Comparator<Room> nameComparator() {
        Collator collator = Collator.getInstance(new Locale("vi"));
        collator.setStrength(Collator.SECONDARY);
        return Comparator.comparing(Room::getRoomName, collator);
    }
}
