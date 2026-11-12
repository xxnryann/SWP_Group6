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

    /** Ngôn ngữ gốc theo quốc gia sản xuất (mã ISO quốc gia -> mã ngôn ngữ trong LANGUAGE_CODES). */
    private static final Map<String, String> COUNTRY_LANGUAGE = Map.ofEntries(
            Map.entry("VN", "vi"), Map.entry("US", "en"), Map.entry("GB", "en"), Map.entry("AU", "en"),
            Map.entry("CA", "en"), Map.entry("NZ", "en"), Map.entry("IE", "en"), Map.entry("CN", "zh"),
            Map.entry("TW", "zh"), Map.entry("SG", "zh"), Map.entry("HK", "yue"), Map.entry("MO", "yue"),
            Map.entry("KR", "ko"), Map.entry("KP", "ko"), Map.entry("JP", "ja"), Map.entry("TH", "th"),
            Map.entry("FR", "fr"), Map.entry("BE", "fr"), Map.entry("DE", "de"), Map.entry("AT", "de"),
            Map.entry("CH", "de"), Map.entry("ES", "es"), Map.entry("MX", "es"), Map.entry("AR", "es"),
            Map.entry("CO", "es"), Map.entry("CL", "es"), Map.entry("IT", "it"), Map.entry("RU", "ru"),
            Map.entry("PT", "pt"), Map.entry("BR", "pt"), Map.entry("IN", "hi"), Map.entry("ID", "id"),
            Map.entry("MY", "ms"), Map.entry("PH", "fil"), Map.entry("KH", "km"), Map.entry("LA", "lo"),
            Map.entry("MM", "my"), Map.entry("SA", "ar"), Map.entry("EG", "ar"), Map.entry("AE", "ar"),
            Map.entry("TR", "tr"), Map.entry("IR", "fa"), Map.entry("IL", "he"), Map.entry("NL", "nl"),
            Map.entry("SE", "sv"), Map.entry("DK", "da"), Map.entry("NO", "no"), Map.entry("FI", "fi"),
            Map.entry("PL", "pl"), Map.entry("UA", "uk"), Map.entry("CZ", "cs"), Map.entry("HU", "hu"),
            Map.entry("GR", "el"), Map.entry("BD", "bn"));

    private static final List<String> COUNTRIES;
    private static final List<String> LANGUAGES;
    private static final Map<String, String> COUNTRY_CODE_BY_NAME = new java.util.HashMap<>();
    private static final Map<String, String> LANGUAGE_BY_CODE = new java.util.HashMap<>();

    static {
        Set<String> names = new LinkedHashSet<>();
        for (String code : Locale.getISOCountries()) {
            String name = COUNTRY_OVERRIDES.getOrDefault(code, new Locale("", code).getDisplayCountry(VI));
            if (name != null && !name.isBlank() && !name.equals(code)) {
                names.add(name);
                COUNTRY_CODE_BY_NAME.putIfAbsent(name, code);
            }
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
            LANGUAGE_BY_CODE.put(code, name);
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

    /** Rạp ở Việt Nam: suất chiếu mặc định lồng tiếng Việt và luôn được chọn tiếng Việt. */
    public static final String DEFAULT_SHOWTIME_LANGUAGE = "Tiếng Việt";

    /**
     * Ngôn ngữ âm thanh gốc của phim: ngôn ngữ của quốc gia sản xuất nếu phim có khai báo ngôn ngữ đó;
     * null nếu không xác định được. Chỉ dùng để biết lồng tiếng có cần diễn viên lồng tiếng hay không.
     */
    public static String originalLanguage(String country, String storedLanguages) {
        List<String> langs = splitLanguages(storedLanguages);
        String code = country == null ? null : COUNTRY_CODE_BY_NAME.get(country.trim());
        String byCountry = code == null ? null : LANGUAGE_BY_CODE.get(COUNTRY_LANGUAGE.get(code));
        return byCountry != null && langs.contains(byCountry) ? byCountry : null;
    }

    /** Tên quốc gia -> tên ngôn ngữ của quốc gia đó (chỉ các nước có trong bảng ánh xạ). */
    public static Map<String, String> countryLanguages() {
        Map<String, String> out = new java.util.TreeMap<>();
        for (Map.Entry<String, String> e : COUNTRY_CODE_BY_NAME.entrySet()) {
            String lang = LANGUAGE_BY_CODE.get(COUNTRY_LANGUAGE.get(e.getValue()));
            if (lang != null) out.put(e.getKey(), lang);
        }
        return out;
    }

    /** Ngôn ngữ chọn được cho suất chiếu: tiếng Việt (mặc định) + các ngôn ngữ đã chọn khi tạo phim. */
    public static List<String> showtimeLanguages(String storedLanguages) {
        List<String> out = new ArrayList<>();
        out.add(DEFAULT_SHOWTIME_LANGUAGE);
        for (String l : splitLanguages(storedLanguages)) {
            if (!out.contains(l)) out.add(l);
        }
        return out;
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
