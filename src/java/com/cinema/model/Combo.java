package com.cinema.model;

import com.cinema.util.Moneys;
import java.math.BigDecimal;

/**
 * Combo bắp nước — STT 13.
 * Khớp 100% bảng Combo trong script database của nhóm.
 */
public class Combo {
    private int comboId;
    private String comboName;
    private String description;
    private BigDecimal price;
    private int stock;
    private String status; // "Active" | "Hidden" (đúng CHECK trong DB)

    public int getComboId() { return comboId; }
    public void setComboId(int comboId) { this.comboId = comboId; }

    public String getComboName() { return comboName; }
    public void setComboName(String comboName) { this.comboName = comboName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    /** Giá dạng hiển thị: "79.000". */
    public String getPriceLabel() { return Moneys.vnd(price); }

    public int getStock() { return stock; }
    public void setStock(int stock) { this.stock = stock; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isActive() { return "Active".equalsIgnoreCase(status); }

    public String getStatusLabel() {
        return isActive() ? "Đang bán" : "Đã ẩn";
    }
}
