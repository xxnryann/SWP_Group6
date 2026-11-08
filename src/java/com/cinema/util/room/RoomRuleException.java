package com.cinema.util.room;

/** Vi phạm quy tắc nghiệp vụ khi thao tác phòng chiếu/ghế (ví dụ: ghế đang có vé, phòng còn suất chiếu). */
public class RoomRuleException extends Exception {
    public RoomRuleException(String message) {
        super(message);
    }
}
