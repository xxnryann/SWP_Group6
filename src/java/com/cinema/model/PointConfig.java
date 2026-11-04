package com.cinema.model;

import java.math.BigDecimal;

/**
 * Cấu hình quy đổi MyPoint đang có hiệu lực (bảng MyPointConfig).
 * Dùng chung cho luồng đặt vé online và bán tại quầy để nhân viên /
 * khách hàng thấy cùng một thông số quy đổi.
 */
public class PointConfig {
    private BigDecimal earnRatePercent;
    private int pointValueVnd;
    private BigDecimal maxRedeemPercent;

    public BigDecimal getEarnRatePercent() { return earnRatePercent; }
    public void setEarnRatePercent(BigDecimal earnRatePercent) { this.earnRatePercent = earnRatePercent; }

    public int getPointValueVnd() { return pointValueVnd; }
    public void setPointValueVnd(int pointValueVnd) { this.pointValueVnd = pointValueVnd; }

    public BigDecimal getMaxRedeemPercent() { return maxRedeemPercent; }
    public void setMaxRedeemPercent(BigDecimal maxRedeemPercent) {
        this.maxRedeemPercent = maxRedeemPercent;
    }

    /** Quy đổi điểm theo số tiền còn phải thanh toán sau các khoản giảm giá. */
    public String getRuleLabel() {
        String value = pointValueVnd <= 0 ? "0" : new java.text.DecimalFormat("#,###").format(pointValueVnd);
        return "1 điểm = " + value + " VNĐ, dùng toàn bộ điểm, tối đa bằng số tiền còn phải thanh toán.";
    }
}
