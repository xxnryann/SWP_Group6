package com.cinema.controller;

import com.cinema.dao.EmailOutboxDAO;
import com.cinema.service.EmailDispatcher;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import java.sql.SQLException;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Các job nền của hệ thống:
 * <ul>
 *   <li>mỗi phút: nhả ghế giữ quá hạn, chuyển vé đã qua giờ chiếu sang Expired, nhắc đánh giá phim, gửi email đang chờ;</li>
 *   <li>mỗi 15 phút: xếp thư nhắc lịch chiếu cho các suất bắt đầu trong 3 giờ tới.</li>
 * </ul>
 */
@WebListener
public class MaintenanceListener implements ServletContextListener {

    private static final Logger LOG = Logger.getLogger(MaintenanceListener.class.getName());
    private static final int REMINDER_HOURS = 3;

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent event) {
        EmailOutboxDAO outbox = new EmailOutboxDAO();
        EmailDispatcher dispatcher = new EmailDispatcher();
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "cinema-maintenance");
            t.setDaemon(true);
            return t;
        });
        scheduler.scheduleWithFixedDelay(() -> safely("minute job", () -> {
            outbox.releaseExpiredHolds();
            outbox.expirePastTickets();
            outbox.queueReviewReminders();
            dispatcher.dispatchPending(20);
        }), 30, 60, TimeUnit.SECONDS);
        scheduler.scheduleWithFixedDelay(() -> safely("reminder job", () -> outbox.queueReminders(REMINDER_HOURS)),
                60, 15 * 60L, TimeUnit.SECONDS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        if (scheduler != null) scheduler.shutdownNow();
    }

    private interface Job {
        void run() throws SQLException;
    }

    private static void safely(String name, Job job) {
        try {
            job.run();
        } catch (SQLException | RuntimeException e) {
            LOG.log(Level.WARNING, "Background " + name + " failed", e);
        }
    }
}
