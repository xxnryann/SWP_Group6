package com.cinema.util.movie;

import java.text.Collator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Danh mục quốc gia và ngôn ngữ cho phim — chỉ cho chọn giá trị có thật, không nhập tự do.
 *
 * <p>Quốc gia: toàn bộ mã ISO 3166 của JDK, tên tiếng Việt (một số tên đổi về cách gọi quen thuộc
 * như "Mỹ", "Anh"). Ngôn ngữ: danh sách ngôn ngữ phim phổ biến, tên tiếng Việt.
 * Phim lưu nhiều ngôn ngữ dạng "Tiếng Anh, Tiếng Việt" (theo thứ tự trong danh mục).</p>
 */
public final class MovieLocales {

    public static final String LANGUAGE_SEPARATOR = ", ";

    private static final Locale VI = Locale.forLanguageTag("vi");

    /** Tên gọi quen thuộc ở Việt Nam thay cho tên dài trong dữ liệu JDK. */
    private static final Map<String, String> COUNTRY_OVERRIDES = Map.of(
            "US", "Mỹ",
            "GB", "Anh",
            "HK", "Hồng Kông",
            "MO", "Ma Cao",
            "IT", "Ý",
            "AU", "Úc",
            "KP", "Triều Tiên");

    private static final String[] LANGUAGE_CODES = {
        "vi", "en", "zh", "yue", "ko", "ja", "th", "fr", "de", "es", "it", "ru", "pt", "hi",
        "id", "ms", "fil", "km", "lo", "my", "ar", "tr", "fa", "he", "nl", "sv", "da", "no",
        "fi", "pl", "uk", "cs", "hu", "el", "ta", "te", "bn"
    };

    private static final List<String> COUNTRIES;
    private static final List<String> LANGUAGES;

    static {
        Set<String> names = new LinkedHashSet<>();
        for (String code : Locale.getISOCountries()) {
            String name = COUNTRY_OVERRIDES.getOrDefault(code, new Locale("", code).getDisplayCountry(VI));
            if (name != null && !name.isBlank() && !name.equals(code)) names.add(name);
        }
        List<String> countries = new ArrayList<>(names);
        Collator collator = Collator.getInstance(VI);
        countries.sort(collator);
        COUNTRIES = Collections.unmodifiableList(countries);

        List<String> languages = new ArrayList<>();
        for (String code : LANGUAGE_CODES) {
            String name = "yue".equals(code) ? "Tiếng Quảng Đông"
                    : "it".equals(code) ? "Tiếng Ý"
                    : "fil".equals(code) ? "Tiếng Philippines"
                    : Locale.forLanguageTag(code).getDisplayLanguage(VI);
            if (name == null || name.isBlank() || name.equals(code)) continue;
            name = Character.toUpperCase(name.charAt(0)) + name.substring(1);
            if (!name.startsWith("Tiếng ")) name = "Tiếng " + name;
            if (!languages.contains(name)) languages.add(name);
        }
        LANGUAGES = Collections.unmodifiableList(languages);
    }

    private MovieLocales() {
    }

    public static List<String> countries() {
        return COUNTRIES;
    }

    public static List<String> languages() {
        return LANGUAGES;
    }

    public static boolean isCountry(String value) {
        return value != null && COUNTRIES.contains(value.trim());
    }

    public static boolean isLanguage(String value) {
        return value != null && LANGUAGES.contains(value.trim());
    }

    /** Các ngôn ngữ đã chọn (đúng danh mục, bỏ trùng) nối thành chuỗi lưu DB; null nếu không chọn gì. */
    public static String joinLanguages(String[] values) {
        if (values == null) return null;
        Set<String> picked = new LinkedHashSet<>();
        for (String v : values) {
            if (v != null && !v.isBlank()) picked.add(v.trim());
        }
        List<String> ordered = new ArrayList<>();
        for (String lang : LANGUAGES) {
            if (picked.remove(lang)) ordered.add(lang);
        }
        ordered.addAll(picked); // giá trị lạ giữ lại để validator báo lỗi
        return ordered.isEmpty() ? null : String.join(LANGUAGE_SEPARATOR, ordered);
    }

    /** Tách chuỗi ngôn ngữ của phim thành danh sách. */
    public static List<String> splitLanguages(String stored) {
        if (stored == null || stored.isBlank()) return List.of();
        List<String> out = new ArrayList<>();
        for (String part : stored.split(",")) {
            String s = part.trim();
            if (!s.isEmpty() && !out.contains(s)) out.add(s);
        }
        return out;
    }

    /** Thông báo lỗi nếu chuỗi ngôn ngữ có giá trị ngoài danh mục; null nếu hợp lệ. */
    public static String invalidLanguage(String stored) {
        for (String s : splitLanguages(stored)) {
            if (!isLanguage(s)) return s;
        }
        return null;
    }
}
