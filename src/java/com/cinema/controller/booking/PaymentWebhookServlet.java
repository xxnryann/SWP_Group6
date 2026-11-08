package com.cinema.controller.booking;

import com.cinema.service.OnlineBookingService;
import com.cinema.util.RequestParams;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

/** Webhook (IPN) của cổng thanh toán VNPAY (API-02). */
@WebServlet("/api/v1/commerce/payment/webhook/vnpay")
public class PaymentWebhookServlet extends HttpServlet {

    /** Mã trả về khi VNPAY đã cập nhật thành công. */
    private static final String RSP_SUCCESS = "00";

    /** Mã trả về khi chữ ký không hợp lệ. */
    private static final String RSP_INVALID_SIGNATURE = "97";

    private final OnlineBookingService service = new OnlineBookingService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        Map<String, String> params = RequestParams.collect(request);
        OnlineBookingService.StepResult result = service.confirmGatewayPayment(params);
        if (result.isSuccess()) {
            writeResponse(response, HttpServletResponse.SC_OK, RSP_SUCCESS, "Success");
            return;
        }
        // Chữ ký sai → không cập nhật gì, không cho VNPAY retry.
        if (result.getOutcome() == OnlineBookingService.Outcome.INVALID_SIGNATURE) {
            writeResponse(response, HttpServletResponse.SC_OK, RSP_INVALID_SIGNATURE,
                    "Chu ky khong hop le");
            return;
        }
        // Giao dịch thất bại / đơn không còn ở trạng thái chờ → coi như đã xử lý xong.
        writeResponse(response, HttpServletResponse.SC_OK, RSP_SUCCESS,
                "Giao dich khong thanh cong");
    }

    /** Trả về JSON cho VNPAY. */
    private void writeResponse(HttpServletResponse response, int status,
            String rspCode, String message) throws IOException {
        response.setStatus(status);
        PrintWriter writer = response.getWriter();
        writer.write("{\"RspCode\":\"" + rspCode
                + "\",\"Message\":\"" + message + "\"}");
        writer.flush();
    }
}
