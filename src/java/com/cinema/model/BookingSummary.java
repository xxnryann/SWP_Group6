package com.cinema.model;

import com.cinema.util.Moneys;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * STT 21 — Bán vé tại quầy. Tóm tắt một booking để hiển thị ở màn hình
 * thanh toán và in hóa đơn: tiền vé, tiền combo, các khoản giảm, mã vé.
 */
public class BookingSummary {
    private int bookingId;
    private String bookingCode;
    private String status;
    private BigDecimal ticketTotal = BigDecimal.ZERO;
    private BigDecimal comboTotal = BigDecimal.ZERO;
    private BigDecimal voucherDiscount = BigDecimal.ZERO;
    private BigDecimal pointsDiscount = BigDecimal.ZERO;
    private BigDecimal totalAmount = BigDecimal.ZERO;
    private int pointsUsed;
    private String customerName; // null = khách vãng lai (mua tại quầy, không tài khoản)
    private final List<String> ticketCodes = new ArrayList<>();
    private final List<Integer> ticketIds = new ArrayList<>();
    private final List<ComboLine> comboLines = new ArrayList<>();

    public static class ComboLine {
        private int comboId;
        private String comboName;
        private int quantity;
        private BigDecimal unitPrice = BigDecimal.ZERO;

        public int getComboId() { return comboId; }
        public void setComboId(int comboId) { this.comboId = comboId; }
        public String getComboName() { return comboName; }
        public void setComboName(String comboName) { this.comboName = comboName; }
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
        public BigDecimal getUnitPrice() { return unitPrice; }
        public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
        public BigDecimal getLineTotal() { return unitPrice.multiply(BigDecimal.valueOf(quantity)); }
        public String getLineTotalLabel() { return Moneys.vnd(getLineTotal()); }
        public String getUnitPriceLabel() { return Moneys.vnd(unitPrice); }
    }

    public int getBookingId() { return bookingId; }
    public void setBookingId(int bookingId) { this.bookingId = bookingId; }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isPendingPayment() { return "PendingPayment".equals(status); }

    public BigDecimal getTicketTotal() { return ticketTotal; }
    public void setTicketTotal(BigDecimal ticketTotal) {
        this.ticketTotal = ticketTotal == null ? BigDecimal.ZERO : ticketTotal;
    }

    public BigDecimal getComboTotal() { return comboTotal; }
    public void setComboTotal(BigDecimal comboTotal) {
        this.comboTotal = comboTotal == null ? BigDecimal.ZERO : comboTotal;
    }

    public BigDecimal getVoucherDiscount() { return voucherDiscount; }
    public void setVoucherDiscount(BigDecimal voucherDiscount) {
        this.voucherDiscount = voucherDiscount == null ? BigDecimal.ZERO : voucherDiscount;
    }

    public BigDecimal getPointsDiscount() { return pointsDiscount; }
    public void setPointsDiscount(BigDecimal pointsDiscount) {
        this.pointsDiscount = pointsDiscount == null ? BigDecimal.ZERO : pointsDiscount;
    }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount == null ? BigDecimal.ZERO : totalAmount;
    }

    public int getPointsUsed() { return pointsUsed; }
    public void setPointsUsed(int pointsUsed) { this.pointsUsed = pointsUsed; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public boolean hasCustomer() { return customerName != null && !customerName.isEmpty(); }
    /** Accessor chuẩn cho EL ${summary.hasCustomer} (EL chỉ nhận getX()/isX()). */
    public boolean isHasCustomer() { return hasCustomer(); }

    public List<String> getTicketCodes() { return ticketCodes; }

    /** Id của từng vé (để dựng URL ảnh QR). Song song với {@link #getTicketCodes()}. */
    public List<Integer> getTicketIds() { return ticketIds; }

    public List<ComboLine> getComboLines() { return comboLines; }

    /* ---------- hiển thị tiền (79.000) ---------- */
    public String getTicketTotalLabel() { return Moneys.vnd(ticketTotal); }
    public String getComboTotalLabel() { return Moneys.vnd(comboTotal); }
    public String getVoucherDiscountLabel() { return Moneys.vnd(voucherDiscount); }
    public String getPointsDiscountLabel() { return Moneys.vnd(pointsDiscount); }
    public String getTotalAmountLabel() { return Moneys.vnd(totalAmount); }
}
