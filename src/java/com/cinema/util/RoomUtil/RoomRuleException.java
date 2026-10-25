package com.cinema.util.RoomUtil;

/**
 * Vi phạm quy tắc nghiệp vụ khi thao tác phòng chiếu/ghế (ví dụ: ghế đang có vé, phòng còn suất chiếu).
 * Message là tiếng Việt, hiển thị trực tiếp cho Admin.
 */
public class RoomRuleException extends Exception {
    public RoomRuleException(String message) {
        super(message);
    }
}
