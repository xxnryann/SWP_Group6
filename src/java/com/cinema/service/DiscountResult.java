package com.cinema.service;

import java.math.BigDecimal;

/**
 * Kết quả tính giảm giá dùng chung.
 * Dùng cho: STT 25 (thanh toán online — Phạm Nam), STT 21 (bán tại quầy — Long).
 */
public class DiscountResult {
    private BigDecimal subtotal;        // tiền trước giảm
    private BigDecimal voucherDiscount; // tiền giảm từ voucher
    private BigDecimal pointsDiscount;  // tiền giảm từ MyPoint
    private BigDecimal total;           // tiền cuối cùng phải trả
    private int pointsUsed;             // số điểm thực tế đã trừ
    private String voucherCode;         // mã voucher đã áp (null nếu không)
    private String message;             // thông báo cho UI

    public BigDecimal getSubtotal() { return subtotal; }
    public void setSubtotal(BigDecimal subtotal) { this.subtotal = subtotal; }

    public BigDecimal getVoucherDiscount() { return voucherDiscount; }
    public void setVoucherDiscount(BigDecimal voucherDiscount) { this.voucherDiscount = voucherDiscount; }

    public BigDecimal getPointsDiscount() { return pointsDiscount; }
    public void setPointsDiscount(BigDecimal pointsDiscount) { this.pointsDiscount = pointsDiscount; }

    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }

    public int getPointsUsed() { return pointsUsed; }
    public void setPointsUsed(int pointsUsed) { this.pointsUsed = pointsUsed; }

    public String getVoucherCode() { return voucherCode; }
    public void setVoucherCode(String voucherCode) { this.voucherCode = voucherCode; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
