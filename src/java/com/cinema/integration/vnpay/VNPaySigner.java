package com.cinema.integration.vnpay;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Tạo và kiểm tra chữ ký (checksum) của VNPAY.
 *
 * <p>Theo tài liệu chính thức của VNPAY phiên bản 2.1.0:</p>
 * <ul>
 *     <li>Thuật toán khuyến nghị: {@code HMAC-SHA512}, khoá là
 *     {@code vnp_HashSecret} dạng raw bytes (không phải Base64).</li>
 *     <li>Chuỗi để ký được tạo từ các tham số {@code vnp_*} sắp xếp
 *     tăng dần theo tên, nối bằng {@code key=value&key=value}.</li>
 *     <li>Giá trị được URL-encode trước khi ký (giống hàm
 *     {@code hashAllFields} trong mẫu C# của VNPAY).</li>
 * </ul>
 */
public final class VNPaySigner {

    /** Thuật toán băm dùng để ký. */
    private static final String HMAC_ALGORITHM = "HmacSHA512";

    /** Tên tham số chứa chữ ký do VNPAY gửi về. */
    public static final String SECURE_HASH_PARAM = "vnp_SecureHash";

    /** Tên tham số chỉ định thuật toán (bản 2.0.x; bản 2.1.0 không dùng). */
    public static final String SECURE_HASH_TYPE_PARAM = "vnp_SecureHashType";

    private VNPaySigner() {
    }

    /**
     * Tạo chữ ký cho tập tham số gửi sang VNPAY.
     *
     * @param params các tham số {@code vnp_*}
     * @param secretKey khoá bí mật của merchant
     * @return chữ ký hex chữ thường
     */
    public static String sign(Map<String, String> params, String secretKey) {
        return hmacSha512Hex(buildHashData(params), secretKey);
    }

    /**
     * Kiểm tra chữ ký do VNPAY gửi về.
     *
     * <p>Các tham số {@code vnp_SecureHash} và {@code vnp_SecureHashType}
     * bị loại khỏi dữ liệu ký theo đúng đặc tả của VNPAY.</p>
     *
     * @param params toàn bộ tham số nhận được
     * @param secretKey khoá bí mật của merchant
     * @return true nếu chữ ký hợp lệ
     */
    public static boolean verify(Map<String, String> params,
            String secretKey) {
        String received = params.get(SECURE_HASH_PARAM);
        if (received == null || received.trim().isEmpty()) {
            return false;
        }
        Map<String, String> signable = new java.util.LinkedHashMap<String, String>();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            String key = entry.getKey();
            if (SECURE_HASH_PARAM.equals(key)
                    || SECURE_HASH_TYPE_PARAM.equals(key)) {
                continue;
            }
            String value = entry.getValue();
            if (value == null || value.isEmpty()) {
                continue;
            }
            signable.put(key, value);
        }
        String expected = sign(signable, secretKey);
        return constantTimeEquals(expected, received.trim());
    }

    /**
     * Dựng chuỗi dữ liệu dùng để ký.
     *
     * <p>Các tham số được sắp xếp tăng dần theo tên, giá trị được
     * URL-encode, nối với nhau bằng dấu {@code &amp;}.</p>
     *
     * @param params các tham số cần ký
     * @return chuỗi dữ liệu để ký
     */
    public static String buildHashData(Map<String, String> params) {
        List<String> names = new ArrayList<String>(params.keySet());
        Collections.sort(names);

        StringBuilder builder = new StringBuilder();
        for (String name : names) {
            String value = params.get(name);
            if (value == null || value.isEmpty()) {
                continue;
            }
            if (builder.length() > 0) {
                builder.append('&');
            }
            builder.append(encode(name)).append('=').append(encode(value));
        }
        return builder.toString();
    }

    /**
     * Tính HMAC-SHA512 trả về chuỗi hex.
     *
     * @param data dữ liệu cần ký
     * @param secretKey khoá bí mật
     * @return chữ ký hex chữ thường
     */
    public static String hmacSha512Hex(String data, String secretKey) {
        try {
            javax.crypto.Mac mac = javax.crypto.Mac
                    .getInstance(HMAC_ALGORITHM);
            mac.init(new javax.crypto.spec.SecretKeySpec(
                    secretKey.getBytes(StandardCharsets.UTF_8),
                    HMAC_ALGORITHM));
            byte[] bytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16));
                hex.append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException | InvalidKeyException exception) {
            throw new IllegalStateException(
                    "Không thể tạo chữ ký thanh toán VNPAY.");
        }
    }

    /**
     * So sánh hai chuỗi không phụ thuộc thời gian thực thi.
     *
     * @param expected chuỗi tính được
     * @param actual chuỗi nhận được
     * @return true nếu hai chuỗi giống nhau
     */
    public static boolean constantTimeEquals(String expected, String actual) {
        if (expected == null || actual == null) {
            return false;
        }
        byte[] left = expected.getBytes(StandardCharsets.UTF_8);
        byte[] right = actual.getBytes(StandardCharsets.UTF_8);
        if (left.length != right.length) {
            return false;
        }
        int diff = 0;
        for (int index = 0; index < left.length; index++) {
            diff |= left[index] ^ right[index];
        }
        return diff == 0;
    }

    /**
     * URL-encode chuỗi theo chuẩn UTF-8.
     *
     * @param value chuỗi cần mã hoá
     * @return chuỗi đã mã hoá
     */
    public static String encode(String value) {
        try {
            return URLEncoder.encode(value, StandardCharsets.UTF_8.name());
        } catch (UnsupportedEncodingException exception) {
            throw new IllegalStateException(
                    "Không thể mã hoá tham số thanh toán VNPAY.");
        }
    }
}

