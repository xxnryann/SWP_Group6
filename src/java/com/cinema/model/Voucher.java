package com.cinema.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public class Voucher {
    private int voucherId;
    private String code;
    private String description;
    private String discountType;
    private BigDecimal discountValue;
    private BigDecimal maxDiscount;
    private BigDecimal minOrderAmount;
    private BigDecimal minCumulativeSpending;
    private int usageLimit;
    private int usedCount;
    private int perCustomerLimit;
    private LocalDate validFrom;
    private LocalDate validTo;
    private String status;

    public int getVoucherId() { return voucherId; }
    public void setVoucherId(int voucherId) { this.voucherId = voucherId; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getDiscountType() { return discountType; }
    public void setDiscountType(String discountType) { this.discountType = discountType; }
    public BigDecimal getDiscountValue() { return discountValue; }
    public void setDiscountValue(BigDecimal discountValue) { this.discountValue = discountValue; }
    public BigDecimal getMaxDiscount() { return maxDiscount; }
    public void setMaxDiscount(BigDecimal maxDiscount) { this.maxDiscount = maxDiscount; }
    public BigDecimal getMinOrderAmount() { return minOrderAmount; }
    public void setMinOrderAmount(BigDecimal minOrderAmount) { this.minOrderAmount = minOrderAmount; }
    public BigDecimal getMinCumulativeSpending() { return minCumulativeSpending; }
    public void setMinCumulativeSpending(BigDecimal minCumulativeSpending) { this.minCumulativeSpending = minCumulativeSpending; }
    public int getUsageLimit() { return usageLimit; }
    public void setUsageLimit(int usageLimit) { this.usageLimit = usageLimit; }
    public int getUsedCount() { return usedCount; }
    public void setUsedCount(int usedCount) { this.usedCount = usedCount; }
    public int getPerCustomerLimit() { return perCustomerLimit; }
    public void setPerCustomerLimit(int perCustomerLimit) { this.perCustomerLimit = perCustomerLimit; }
    public LocalDate getValidFrom() { return validFrom; }
    public void setValidFrom(LocalDate validFrom) { this.validFrom = validFrom; }
    public LocalDate getValidTo() { return validTo; }
    public void setValidTo(LocalDate validTo) { this.validTo = validTo; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public boolean isAllowed() { return "Allowed".equalsIgnoreCase(status); }
}
