package com.cinema.service;

import com.cinema.dao.EmailOutboxDAO;
import com.cinema.util.EmailService;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Gửi các thư đang chờ trong EmailNotification, dựng nội dung chi tiết theo loại thư. */
public class EmailDispatcher {

    private static final Logger LOG = Logger.getLogger(EmailDispatcher.class.getName());
    private static final Object LOCK = new Object();

    private final EmailOutboxDAO dao = new EmailOutboxDAO();

    /** Gửi tối đa {@code batch} thư; trả về số thư gửi thành công. */
    public int dispatchPending(int batch) {
        synchronized (LOCK) {
            int sent = 0;
            try {
                for (Map<String, Object> mail : dao.pending(batch)) {
                    int id = ((Number) mail.get("notif_id")).intValue();
                    boolean ok = EmailService.sendMail((String) mail.get("email"),
                            (String) mail.get("subject"), compose(mail));
                    if (ok) {
                        dao.markSent(id);
                        sent++;
                    } else {
                        dao.markFailed(id);
                    }
                }
            } catch (SQLException e) {
                LOG.log(Level.SEVERE, "Cannot dispatch pending emails", e);
            }
            return sent;
        }
    }

    private String compose(Map<String, Object> mail) throws SQLException {
        StringBuilder sb = new StringBuilder();
        sb.append("Xin chào ").append(mail.get("full_name")).append(",\n\n");
        String type = (String) mail.get("notif_type");
        Number bookingId = (Number) mail.get("booking_id");
        Number showtimeId = (Number) mail.get("showtime_id");
        if ("ETicket".equals(type) && bookingId != null) {
            List<Map<String, Object>> tickets = dao.ticketsOfBooking(bookingId.intValue());
            sb.append("Cảm ơn bạn đã đặt vé tại CineStar Cinemas. Thông tin vé của bạn:\n");
            for (Map<String, Object> t : tickets) {
                sb.append("\n• ").append(t.get("title")).append(" — ").append(t.get("start_time"))
                        .append(" — ").append(t.get("room_name")).append(", ghế ").append(t.get("seat_label"))
                        .append("\n  Mã vé (đưa cho nhân viên soát vé): ").append(t.get("ticket_code"));
            }
            if (!tickets.isEmpty()) sb.append("\n\nMã đơn: ").append(tickets.get(0).get("booking_code"));
        } else if ("ShowtimeReminder".equals(type) && showtimeId != null) {
            Map<String, Object> st = dao.showtimeInfo(showtimeId.intValue());
            sb.append("Suất chiếu của bạn sắp bắt đầu");
            if (st != null) {
                sb.append(": ").append(st.get("title")).append(" lúc ").append(st.get("start_time"))
                        .append(" tại ").append(st.get("room_name"));
            }
            sb.append(".\nVui lòng đến trước giờ chiếu để soát vé.");
        } else {
            sb.append(mail.get("body") == null ? mail.get("subject") : mail.get("body"));
        }
        sb.append("\n\nTrân trọng,\nCineStar Cinemas");
        return sb.toString();
    }
}
