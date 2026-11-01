package com.cinema.model;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.Locale;

/**
 * Loại ghế kèm giá vé của một suất chiếu, dùng cho phần chú thích ở màn hình chọn ghế.
 * {@code price} là {@code null} khi chưa cấu hình giá cho (loại ghế, khung giờ, loại ngày).
 */
public class SeatTypeInfo {
    private int seatTypeId;
    private String typeName;
    private boolean couple;
    private String description;
    private BigDecimal price;

    public int getSeatTypeId() { return seatTypeId; }
    public void setSeatTypeId(int seatTypeId) { this.seatTypeId = seatTypeId; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }

    public boolean isCouple() { return couple; }
    public void setCouple(boolean couple) { this.couple = couple; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public boolean isPriceConfigured() { return price != null; }

    /** Giá làm tròn về số nguyên (đồng) cho JS phía client; 0 nếu chưa cấu hình. */
    public long getPriceInt() { return price == null ? 0L : price.longValue(); }

    /** Giá dạng "95.000đ", hoặc "—" khi chưa cấu hình. */
    public String getPriceLabel() { return formatPrice(price); }

    public String getTypeLabel() { return typeName == null ? "" : typeName; }

    public String getDescriptionLabel() { return description == null ? "" : description; }

    static String formatPrice(BigDecimal value) {
        if (value == null) {
            return "—";
        }
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.ROOT);
        symbols.setGroupingSeparator('.');
        return new DecimalFormat("#,##0", symbols).format(value) + "đ";
    }
}
