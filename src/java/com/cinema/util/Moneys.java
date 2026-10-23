package com.cinema.util;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;

/** Định dạng tiền VNĐ cho tầng hiển thị: 79000 → "79.000". */
public final class Moneys {

    private Moneys() { }

    public static String vnd(BigDecimal value) {
        if (value == null) return "0";
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,###", symbols).format(value);
    }
}
