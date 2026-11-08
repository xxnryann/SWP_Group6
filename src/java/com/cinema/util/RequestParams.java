package com.cinema.util;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.Map;

/** Gom tham so cua request thanh mot map de xu ly. */
public final class RequestParams {

    private RequestParams() {
    }

    /** Gom toan bo tham so (khong rong) cua request vao map, giu nguyen thu tu. */
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
