package com.cinema.integration.vnpay;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Kết quả thanh toán do VNPAY trả về qua Return URL hoặc IPN.
 */
public class VNPayCallback {

    /** Mã tham chiếu giao dịch gửi sang VNPAY (vnp_TxnRef). */
    private String txnRef;

    /** Mã giao dịch ghi nhận tại VNPAY (vnp_TransactionNo). */
    private String transactionNo;

    /** Mã phản hồi kết quả thanh toán (vnp_ResponseCode). */
    private String responseCode;

    /** Trạng thái giao dịch tại VNPAY (vnp_TransactionStatus). */
    private String transactionStatus;

    /** Số tiền VNPAY phản hồi, đã chia 100 về đơn vị tiền. */
    private BigDecimal amount;

    /** Mã ngân hàng/phương thức thanh toán (vnp_BankCode). */
    private String bankCode;

    /** Mã giao dịch tại ngân hàng (vnp_BankTranNo). */
    private String bankTranNo;

    /** Thời điểm thanh toán (vnp_PayDate). */
    private String payDate;

    /** Chữ ký do VNPAY gửi kèm. */
    private String secureHash;

    /**
     * Đọc kết quả thanh toán từ tập tham số nhận được.
     *
     * @param params các tham số do VNPAY gửi về
     * @return kết quả thanh toán
     */
    public static VNPayCallback from(Map<String, String> params) {
        VNPayCallback callback = new VNPayCallback();
        callback.txnRef = params.get("vnp_TxnRef");
        callback.transactionNo = params.get("vnp_TransactionNo");
        callback.responseCode = params.get("vnp_ResponseCode");
        callback.transactionStatus = params.get("vnp_TransactionStatus");
        callback.bankCode = params.get("vnp_BankCode");
        callback.bankTranNo = params.get("vnp_BankTranNo");
        callback.payDate = params.get("vnp_PayDate");
        callback.secureHash = params.get(VNPaySigner.SECURE_HASH_PARAM);

        String rawAmount = params.get("vnp_Amount");
        if (rawAmount != null && !rawAmount.trim().isEmpty()) {
            try {
                // VNPAY gửi số tiền nhân 100, quy lại về đơn vị tiền.
                callback.amount = new BigDecimal(rawAmount.trim())
                        .divide(new BigDecimal("100"),
                                2, java.math.RoundingMode.DOWN);
            } catch (NumberFormatException exception) {
                callback.amount = BigDecimal.ZERO;
            }
        } else {
            callback.amount = BigDecimal.ZERO;
        }
        return callback;
    }

    /**
     * Giao dịch có thành công hay không.
     *
     * <p>VNPAY trả về mã {@code 00} cho giao dịch thành công. Trường
     * {@code vnp_TransactionStatus} chỉ xuất hiện từ phiên bản 2.1.0
     * nên được kiểm tra khi có mặt.</p>
     *
     * @return true nếu giao dịch thành công
     */
    public boolean isSuccess() {
        if (!"00".equals(responseCode)) {
            return false;
        }
        return transactionStatus == null
                || transactionStatus.isEmpty()
                || "00".equals(transactionStatus);
    }

    public String getTxnRef() {
        return txnRef;
    }

    public void setTxnRef(String txnRef) {
        this.txnRef = txnRef;
    }

    public String getTransactionNo() {
        return transactionNo;
    }

    public void setTransactionNo(String transactionNo) {
        this.transactionNo = transactionNo;
    }

    public String getResponseCode() {
        return responseCode;
    }

    public void setResponseCode(String responseCode) {
        this.responseCode = responseCode;
    }

    public String getTransactionStatus() {
        return transactionStatus;
    }

    public void setTransactionStatus(String transactionStatus) {
        this.transactionStatus = transactionStatus;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getBankCode() {
        return bankCode;
    }

    public void setBankCode(String bankCode) {
        this.bankCode = bankCode;
    }

    public String getBankTranNo() {
        return bankTranNo;
    }

    public void setBankTranNo(String bankTranNo) {
        this.bankTranNo = bankTranNo;
    }

    public String getPayDate() {
        return payDate;
    }

    public void setPayDate(String payDate) {
        this.payDate = payDate;
    }

    public String getSecureHash() {
        return secureHash;
    }

    public void setSecureHash(String secureHash) {
        this.secureHash = secureHash;
    }
}

