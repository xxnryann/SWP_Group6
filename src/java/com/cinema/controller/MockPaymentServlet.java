package com.cinema.controller;

import com.cinema.integration.vnpay.MockPaymentGateway;
import com.cinema.integration.vnpay.VNPayGateway;
import com.cinema.integration.vnpay.VNPayProperties;
import com.cinema.integration.vnpay.VNPaySigner;
import com.cinema.util.RequestParams;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Trang thanh toán giả lập, chỉ dùng cho môi trường dev (UC15).
 *
 * <p>Đóng vai cổng VNPAY để chạy và kiểm thử trọn luồng thanh toán khi chưa
 * có {@code vnpay.secretKey} hợp lệ. Trang này hiển thị đúng thông tin giao
 * dịch, cho khách chọn "Thanh toán" hoặc "Huỷ", rồi chuyển hồi kết quả về
 * {@code vnp_ReturnUrl} — cùng đường dẫn mà cổng thật dùng, kèm chữ ký
 * HMAC-SHA512 hợp lệ.</p>
 *
 * <p>Không được phép dùng ở môi trường thật: mọi giao dịch đi qua đây đều
 * không có giá trị tiền thật. Trang tự từ chối khi cấu hình không bật cổng
 * giả lập.</p>
 */
@WebServlet("/mock/payment")
public class MockPaymentServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Múi giờ dùng cho mốc thời gian, khớp cổng thật. */
    private static final ZoneId VNPAY_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    /** Định dạng thời gian của cổng thanh toán. */
    private static final DateTimeFormatter VNPAY_TIME
            = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        if (!VNPayProperties.load().isGatewayMock()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        Map<String, String> params = RequestParams.collect(request);
        request.setAttribute("params", params);
        // vnp_Amount dùng đơn vị ×100 của VNPAY (17900000 = 179.000 ₫)
        // nên phải quy về đơn vị tiền trước khi hiển thị cho khách.
        BigDecimal amount = VNPayGateway.fromVnpAmount(params.get("vnp_Amount"));
        request.setAttribute("amount", amount == null
                ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP) : amount);
        request.setAttribute("txnRef", params.get("vnp_TxnRef"));
        request.setAttribute("orderInfo", params.get("vnp_OrderInfo"));
        request.getRequestDispatcher("/WEB-INF/views/booking/mock-payment.jsp")
                .forward(request, response);
    }

    /**
     * Nhận lựa chọn của khách và chuyển hồi kết quả về cổng thật.
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        if (!VNPayProperties.load().isGatewayMock()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        Map<String, String> params = RequestParams.collect(request);
        String returnUrl = params.get("vnp_ReturnUrl");
        String txnRef = params.get("vnp_TxnRef");
        if (returnUrl == null || returnUrl.trim().isEmpty()
                || txnRef == null || txnRef.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        // Cổng thật chặn giao dịch quá hạn (vnp_ExpireDate). Cổng giả lập
        // cũng phải hành xử giống hệt, nếu không luồng kiểm thử sẽ không
        // bắt được lỗi "webhook đến sau khi ghế đã giải phóng" (GBR-01).
        if (MockPaymentGateway.isExpired(params.get("vnp_CreateDate"),
                params.get("vnp_ExpireDate"))) {
            response.sendError(HttpServletResponse.SC_GONE,
                    "Giao dịch đã hết thời hạn thanh toán. Vui lòng đặt vé lại.");
            return;
        }

        boolean succeeded = "success".equalsIgnoreCase(request.getParameter("decision"));

        // Chỉ giữ lại các tham số nghiệp vụ, bỏ tham số kỹ thuật của cổng
        // giả lập để giống hệt tập tham số cổng thật gửi về.
        Map<String, String> result = new LinkedHashMap<String, String>();
        result.put("vnp_Version", VNPayProperties.API_VERSION);
        result.put("vnp_Command", "pay");
        result.put("vnp_TmnCode", VNPayProperties.mockPartnerCode());
        result.put("vnp_Amount", params.get("vnp_Amount"));
        result.put("vnp_CurrCode", VNPayProperties.CURRENCY_CODE);
        result.put("vnp_TxnRef", txnRef);
        result.put("vnp_OrderInfo", params.get("vnp_OrderInfo"));
        result.put("vnp_OrderType", "other");
        result.put("vnp_Locale", "vn");
        result.put("vnp_TransactionNo", MockPaymentGateway.generateTransactionNo());
        result.put("vnp_ResponseCode", succeeded
                ? MockPaymentGateway.RESPONSE_SUCCESS : MockPaymentGateway.RESPONSE_CANCELLED);
        result.put("vnp_TransactionStatus", "00");
        result.put("vnp_BankCode", "MOCKQR");
        result.put("vnp_BankTranNo", "MOCK" + txnRef);
        result.put("vnp_PayDate", LocalDateTime.now(VNPAY_ZONE).format(VNPAY_TIME));

        result.put(VNPaySigner.SECURE_HASH_PARAM, MockPaymentGateway.signParams(result));

        response.sendRedirect(returnUrl + "?" + toQueryString(result));
    }

    /**
     * Ghép tham số thành query string đã mã hoá.
     */
    private static String toQueryString(Map<String, String> params) {
        StringBuilder builder = new StringBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            if (builder.length() > 0) {
                builder.append('&');
            }
            builder.append(encode(entry.getKey()))
                    .append('=')
                    .append(encode(entry.getValue()));
        }
        return builder.toString();
    }

    private static String encode(String value) {
        try {
            return URLEncoder.encode(value, StandardCharsets.UTF_8.name());
        } catch (java.io.UnsupportedEncodingException exception) {
            throw new IllegalStateException("Không thể mã hoá tham số thanh toán.", exception);
        }
    }
}
