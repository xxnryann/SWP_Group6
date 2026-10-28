package com.cinema.util;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Gom tham so cua request thanh mot map de xu ly.
 *
 * <p>Dung chung cho luong thanh toan: cung gia tra ve (GET query) va webhook
 * IPN (POST form-encoded) deu gui tham so theo dang {@code name=value}.
 * Tham so rong/null bi bo qua de khong lam nhieu chu ky hoac so tien rong.</p>
 */
public final class RequestParams {

    private RequestParams() {
    }

    /**
     * Gom toan bo tham so (khong rong) cua request vao map, giu nguyen thu tu.
     *
     * @param req request hien tai
     * @return map tham so khong null, khong rong
     */
    public static Map<String, String> collect(HttpServletRequest req) {
        Map<String, String> params = new LinkedHashMap<String, String>();
        Enumeration<String> names = req.getParameterNames();
        while (names != null && names.hasMoreElements()) {
            String name = names.nextElement();
            String value = req.getParameter(name);
            if (value != null && !value.isEmpty()) {
                params.put(name, value);
            }
        }
        return params;
    }
}
