package com.cinema.model;

import java.math.BigDecimal;

/**
 * Cấu hình quy đổi MyPoint đang có hiệu lực (bảng MyPointConfig).
 * Dùng chung cho luồng đặt vé online và bán tại quầy để nhân viên /
 * khách hàng thấy cùng một thông số quy đổi.
 */
public class PointConfig {
    private int pointValueVnd;
    private BigDecimal maxRedeemPercent;

    public int getPointValueVnd() { return pointValueVnd; }
    public void setPointValueVnd(int pointValueVnd) { this.pointValueVnd = pointValueVnd; }

    public BigDecimal getMaxRedeemPercent() { return maxRedeemPercent; }
    public void setMaxRedeemPercent(BigDecimal maxRedeemPercent) {
        this.maxRedeemPercent = maxRedeemPercent;
    }

    /** "1 điểm = 1.000 VNĐ, dùng tối đa 20% giá trị đơn" */
    public String getRuleLabel() {
        String value = pointValueVnd <= 0 ? "0" : new java.text.DecimalFormat("#,###").format(pointValueVnd);
        String percent = maxRedeemPercent == null ? "0" : maxRedeemPercent.stripTrailingZeros().toPlainString();
        return "1 điểm = " + value + " VNĐ, dùng tối đa " + percent + "% giá trị đơn.";
    }
}
