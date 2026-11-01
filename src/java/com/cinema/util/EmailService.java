package com.cinema.util;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class EmailService {

    private static final Logger LOG = Logger.getLogger(EmailService.class.getName());

    private EmailService() {
    }

    /**
     * Gửi một email thông báo (vé điện tử, nhắc lịch chiếu...). Nếu chưa cấu hình mail.host thì chỉ ghi log
     * (chế độ dev) và coi như đã gửi.
     */
    public static boolean sendMail(String to, String subject, String body) {
        String host = AppConfig.get("mail.host");
        if (host.isEmpty()) {
            LOG.log(Level.INFO, "[DEV MODE] Email to {0}: {1}\n{2}", new Object[]{to, subject, body});
            return true;
        }
        Properties p = new Properties();
        p.put("mail.smtp.host", host);
        p.put("mail.smtp.port", AppConfig.get("mail.port"));
        p.put("mail.smtp.auth", "true");
        p.put("mail.smtp.starttls.enable", "true");
        Session s = Session.getInstance(p, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(AppConfig.get("mail.user"), AppConfig.get("mail.password"));
            }
        });
        try {
            MimeMessage m = new MimeMessage(s);
            m.setFrom(new InternetAddress(AppConfig.get("mail.from")));
            m.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            m.setSubject(subject, "UTF-8");
            m.setText(body, "UTF-8");
            Transport.send(m);
            return true;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Cannot send notification email to " + to, e);
            return false;
        }
    }

    /** Sends the OTP. If mail.host is empty, prints it to the console instead (dev mode). */
    public static boolean sendOtp(String to, String otp) {
        String host = AppConfig.get("mail.host");
        if (host.isEmpty()) {
            LOG.log(Level.WARNING, "[DEV MODE] OTP for {0}: {1}", new Object[]{to, otp});
            return true;
        }
        Properties p = new Properties();
        p.put("mail.smtp.host", host);
        p.put("mail.smtp.port", AppConfig.get("mail.port"));
        p.put("mail.smtp.auth", "true");
        p.put("mail.smtp.starttls.enable", "true");
        Session s = Session.getInstance(p, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(AppConfig.get("mail.user"), AppConfig.get("mail.password"));
            }
        });
        try {
            MimeMessage m = new MimeMessage(s);
            m.setFrom(new InternetAddress(AppConfig.get("mail.from")));
            m.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            m.setSubject("Mã xác thực tài khoản CineStar Cinemas", "UTF-8");
            m.setText("Mã OTP của bạn là: " + otp + "\nMã có hiệu lực trong "
                    + AppConfig.getInt("otp.ttl.minutes", 5) + " phút. Không chia sẻ mã này với bất kỳ ai.", "UTF-8");
            Transport.send(m);
            return true;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Cannot send OTP email", e);
            return false;
        }
    }
}
