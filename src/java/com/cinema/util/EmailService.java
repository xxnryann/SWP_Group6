package com.cinema.util;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Gửi email theo thứ tự ưu tiên cấu hình: mail.api.key (API Brevo) → mail.host (SMTP) → chế độ dev (chỉ ghi log).
 */
public final class EmailService {

    private static final Logger LOG = Logger.getLogger(EmailService.class.getName());
    private static final String DEFAULT_API_URL = "https://api.brevo.com/v3/smtp/email";
    private static final Duration API_TIMEOUT = Duration.ofSeconds(20);
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

    private EmailService() {
    }

    /**
     * Gửi một email thông báo (vé điện tử, nhắc lịch chiếu...). Nếu chưa cấu hình cách gửi thì chỉ ghi log
     * (chế độ dev) và coi như đã gửi.
     */
    public static boolean sendMail(String to, String subject, String body) {
        if (isDevMode()) {
            LOG.log(Level.INFO, "[DEV MODE] Email to {0}: {1}\n{2}", new Object[]{to, subject, body});
            return true;
        }
        return deliver(to, subject, body);
    }

    /** Sends the OTP. If no mail transport is configured, prints it to the console instead (dev mode). */
    public static boolean sendOtp(String to, String otp) {
        if (isDevMode()) {
            LOG.log(Level.WARNING, "[DEV MODE] OTP for {0}: {1}", new Object[]{to, otp});
            return true;
        }
        return deliver(to, "Mã xác thực tài khoản CineStar Cinemas", "Mã OTP của bạn là: " + otp
                + "\nMã có hiệu lực trong " + AppConfig.getInt("otp.ttl.minutes", 5)
                + " phút. Không chia sẻ mã này với bất kỳ ai.");
    }

    private static boolean isDevMode() {
        return AppConfig.get("mail.api.key").isEmpty() && AppConfig.get("mail.host").isEmpty();
    }

    private static boolean deliver(String to, String subject, String body) {
        return AppConfig.get("mail.api.key").isEmpty() ? sendSmtp(to, subject, body) : sendApi(to, subject, body);
    }

    private static boolean sendApi(String to, String subject, String body) {
        String url = AppConfig.get("mail.api.url");
        String json = "{\"sender\":{\"name\":" + json(AppConfig.get("mail.from.name"))
                + ",\"email\":" + json(AppConfig.get("mail.from"))
                + "},\"to\":[{\"email\":" + json(to)
                + "}],\"subject\":" + json(subject)
                + ",\"textContent\":" + json(body) + "}";
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url.isEmpty() ? DEFAULT_API_URL : url))
                    .timeout(API_TIMEOUT)
                    .header("api-key", AppConfig.get("mail.api.key"))
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();
            HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() / 100 == 2) {
                return true;
            }
            LOG.log(Level.SEVERE, "Email API returned {0} for {1}: {2}",
                    new Object[]{response.statusCode(), to, response.body()});
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOG.log(Level.SEVERE, "Interrupted while sending email to " + to, e);
            return false;
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "Cannot call email API for " + to, e);
            return false;
        }
    }

    /** Chuỗi JSON có dấu ngoặc kép; thoát ký tự đặc biệt theo RFC 8259. */
    private static String json(String value) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : (value == null ? "" : value).toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
                }
            }
        }
        return sb.append('"').toString();
    }

    private static boolean sendSmtp(String to, String subject, String body) {
        Properties p = new Properties();
        p.put("mail.smtp.host", AppConfig.get("mail.host"));
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
}
