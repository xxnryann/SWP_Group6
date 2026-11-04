package com.cinema.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public final class AppConfig {

    private static final Properties PROPS = new Properties();

    static {
        try (InputStream in = AppConfig.class.getClassLoader().getResourceAsStream("app.properties")) {
            if (in != null) {
                PROPS.load(in);
            }
        } catch (IOException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private AppConfig() {
    }

    public static String get(String key) {
        String v = PROPS.getProperty(key);
        return v == null ? "" : v.trim();
    }

    /**
     * Đọc cấu hình theo thứ tự ưu tiên:
     * {@code -Dkey=value} (system property) → biến môi trường {@code KEY}
     * → {@code app.properties} → chuỗi rỗng.
     *
     * <p>Dùng cho các giá trị có thể cần ghi đè lúc chạy (vd địa chỉ
     * công khai khi deploy qua tunnel) mà không phải sửa file cấu hình.</p>
     *
     * @param key tên khóa, vd {@code vnpay.publicBaseUrl}
     * @return giá trị đã cắt khoảng trắng, rỗng nếu không có
     */
    public static String resolve(String key) {
        String value = System.getProperty(key);
        if (value == null || value.trim().isEmpty()) {
            value = System.getenv(key.replace('.', '_').toUpperCase());
        }
        if (value == null || value.trim().isEmpty()) {
            value = get(key);
        }
        return value == null ? "" : value.trim();
    }

    public static int getInt(String key, int def) {
        try {
            return Integer.parseInt(get(key));
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
