package com.cinema.controller.staff;

import com.cinema.controller.BaseServlet;
import com.cinema.controller.booking.BookingSession;
import com.cinema.dao.CounterSaleDAO;
import com.cinema.model.BookingSummary;
import com.cinema.model.OnlineBooking;
import com.cinema.model.ShowtimeInfo;
import com.cinema.model.User;
import com.cinema.service.DiscountResult;
import com.cinema.service.DiscountService;
import com.cinema.service.GatewayPaymentService;
import com.cinema.service.OnlineBookingService;
import com.cinema.controller.site.PromotionsServlet;
import com.cinema.util.Moneys;
import com.cinema.util.Validator;
import com.cinema.util.WebUrls;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * STT 21 — Bán vé tại quầy (Staff).
 * URL: /staff/counter?action=showtimes|seats|checkout|success
 * Quyền: STAFF / MANAGER / ADMIN.
 *
 * Luồng 3 bước (booking_id giữ trong session giữa các bước):
 *  1. Chọn suất chiếu  → danh sách suất sắp chiếu còn ghế trống
 *  2. Chọn ghế         → sơ đồ ghế từ vw_SeatMap, giữ ghế bằng sp_HoldSeats
 *  3. Thanh toán       → thêm combo (sp_AddCombo), gắn khách hàng (nếu có),
 *                        áp voucher/MyPoint (qua DiscountService — chỉ khi có
 *                        khách hàng đã đăng ký, vì sp_ApplyVoucher từ chối
 *                        khách vãng lai), thu tiền mặt (sp_ConfirmPayment 'Cash')
 *
 * Lưu ý: phiên giữ ghế có thời hạn (SystemConfig BOOKING_SESSION_MINUTES, PAYMENT_WINDOW_MINUTES).
 * Nếu hết hạn giữa chừng, servlet tự tạo booking mới khi giữ ghế lại.
 *
 * NỢ KỸ THUẬT (đã biết, xem README mục "Nợ kỹ thuật"): phân quyền hiện kiểm tra ngay trong servlet này (đang đúng);
 * mục tiêu dài hạn là gom về filter phân quyền tập trung.
 */
@WebServlet("/staff/counter")
public class CounterSalesServlet extends BaseServlet {

    private static final String SESSION_BOOKING = "counterBookingId";
    private static final String SESSION_SHOWTIME = "counterShowtimeId";

    private final CounterSaleDAO dao = new CounterSaleDAO();
    private final DiscountService discountService = new DiscountService();
    private final OnlineBookingService bookingService = new OnlineBookingService();
    private final GatewayPaymentService paymentService = new GatewayPaymentService();

    private boolean requireStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        String r = u.getRole();
        if (!"STAFF".equals(r) && !"MANAGER".equals(r) && !"ADMIN".equals(r)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ nhân viên quầy được bán vé.");
            return false;
        }
        return true;
    }

    private int parseIntSafe(String s, int dflt) {
        try {
            return Integer.parseInt(Validator.trim(s));
        } catch (Exception e) {
            return dflt;
        }
    }

    /**
     * Đọc số tiền người dùng nhập theo định dạng hiển thị của hệ thống
     * (140.000 → 140000; 140,5 → 140.5). Chỉ giữ chữ số và dấu phẩy thập phân.
     */
    private BigDecimal parseMoney(String s) {
        String t = Validator.trim(s).replace(".", "").replace(" ", "");
        if (t.isEmpty()) return null;
        // Dấu phẩy chỉ hợp lệ làm dấu thập phân; nhiều dấu phẩy -> giữ dấu cuối.
        int lastComma = t.lastIndexOf(',');
        if (lastComma >= 0) {
            String head = t.substring(0, lastComma).replace(",", "");
            String tail = t.substring(lastComma + 1);
            t = head + "." + tail;
        }
        try {
            return new BigDecimal(t);
        } catch (Exception e) {
            return null;
        }
    }

    /** Chuẩn hóa "41, 42,abc" → "41,42" (chỉ giữ số). */
    private String cleanSeatIds(String raw) {
        StringBuilder sb = new StringBuilder();
        for (String part : Validator.trim(raw).split(",")) {
            String p = part.trim();
            if (p.matches("\\d+")) {
                if (sb.length() > 0) sb.append(',');
                sb.append(p);
            }
        }
        return sb.toString();
    }

    private Integer staffAccountIdOrNull(HttpServletRequest req) throws SQLException {
        int id = dao.findAccountIdByEmail(currentUser(req).getEmail());
        return id == 0 ? null : id;
    }

    /* ================= GET ================= */

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp)) return;
        String action = Validator.trim(req.getParameter("action"));
        if (action.isEmpty()) action = "showtimes";
        try {
            switch (action) {
                case "seats": showSeats(req, resp); break;
                case "checkout": showCheckout(req, resp); break;
                case "success": showSuccess(req, resp); break;
                default: showShowtimes(req, resp);
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    /** Bước 1: danh sách suất chiếu sắp chiếu. */
    private void showShowtimes(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {
        List<ShowtimeInfo> list = dao.findUpcomingShowtimes();
        req.setAttribute("showtimeList", list);
        req.setAttribute("pageTitle", "Bán vé tại quầy — Chọn suất chiếu");
        forward(req, resp, "counter/counter-showtimes");
    }

    /**
     * Suất chiếu còn bán được tại quầy không.
     *
     * <p>Quầy chỉ bán vé cho suất chiếu của ngày hiện tại và chưa bắt đầu:
     * suất đã qua giờ trong ngày và suất của ngày sau đều bị từ chối. Việc
     * kiểm tra này chặn ở tầng servlet để thông báo cho nhân viên rõ ràng;
     * {@code sp_CreateBooking} vẫn là lớp bảo vệ cuối cùng ở DB.</p>
     *
     * @param show suất chiếu cần kiểm tra
     * @return true nếu bán được
     */
    private boolean isSellableToday(ShowtimeInfo show) {
        if (show == null || show.getStartTime() == null) {
            return false;
        }
        LocalDateTime start = show.getStartTime();
        LocalDateTime now = LocalDateTime.now();
        return !start.toLocalDate().isAfter(now.toLocalDate()) && start.isAfter(now);
    }

    /** Bước 2: sơ đồ ghế của một suất chiếu. */
    private void showSeats(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {
        int showtimeId = parseIntSafe(req.getParameter("showtimeId"), 0);
        ShowtimeInfo show = showtimeId > 0 ? dao.findShowtimeById(showtimeId) : null;
        if (show == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        // Suất chiếu đã qua giờ (hoặc thuộc ngày khác) không bán được tại quầy.
        if (!isSellableToday(show)) {
            flash(req, "error", "Suất chiếu này đã qua giờ hoặc không thuộc ngày hôm nay. "
                    + "Vui lòng chọn suất chiếu khác.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        // Sơ đồ ghế + chú thích loại ghế, giá vé: dùng chung với đặt vé online
        BookingSession.applySeatGuide(req, bookingService, showtimeId, dao.getSeatMap(showtimeId));
        // Cảnh báo nếu đơn hiện tại đã giữ ghế của suất này (chọn lại = tạo đơn mới)
        boolean reselectWarning = false;
        HttpSession session = req.getSession(false);
        if (session != null) {
            Integer bId = (Integer) session.getAttribute(SESSION_BOOKING);
            Integer sId = (Integer) session.getAttribute(SESSION_SHOWTIME);
            if (bId != null && sId != null && sId == showtimeId) {
                BookingSummary ex = dao.getBookingSummary(bId);
                reselectWarning = ex != null && "PendingPayment".equals(ex.getStatus());
            }
        }
        req.setAttribute("showtime", show);
        req.setAttribute("reselectWarning", reselectWarning);
        req.setAttribute("pageTitle", "Bán vé tại quầy — Chọn ghế");
        forward(req, resp, "counter/counter-seats");
    }

    /** Bước 3: tóm tắt đơn + combo + khách hàng + giảm giá + thu tiền. */
    private void showCheckout(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {
        HttpSession session = req.getSession(false);
        Integer bookingId = session == null ? null : (Integer) session.getAttribute(SESSION_BOOKING);
        Integer showtimeId = session == null ? null : (Integer) session.getAttribute(SESSION_SHOWTIME);
        BookingSummary s = bookingId == null ? null : dao.getBookingSummary(bookingId);

        if (s == null || !s.isPendingPayment()) {
            if (session != null) {
                session.removeAttribute(SESSION_BOOKING);
                session.removeAttribute(SESSION_SHOWTIME);
            }
            flash(req, "error", "Phiên giữ ghế đã hết hạn. Vui lòng chọn ghế lại.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }

        Map<Integer, Integer> comboQty = new LinkedHashMap<>();
        for (BookingSummary.ComboLine cl : s.getComboLines()) {
            comboQty.put(cl.getComboId(), cl.getQuantity());
        }

        req.setAttribute("summary", s);
        req.setAttribute("showtime", showtimeId == null ? null : dao.findShowtimeById(showtimeId));
        req.setAttribute("combos", dao.findActiveCombos());
        req.setAttribute("pointConfig", dao.getPointConfig());
        req.setAttribute("pointBalance", s.hasCustomer()
                ? dao.getPointBalanceForBooking(bookingId) : 0);
        req.setAttribute("vouchers", PromotionsServlet.activeVouchers());
        req.setAttribute("comboQty", comboQty);
        req.setAttribute("pageTitle", "Bán vé tại quầy — Thanh toán");
        forward(req, resp, "counter/counter-checkout");
    }

    /** Hóa đơn sau khi thu tiền. */
    private void showSuccess(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {
        HttpSession session = req.getSession(false);
        Integer bookingId = session == null ? null : (Integer) session.getAttribute(SESSION_BOOKING);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        BookingSummary s = dao.getBookingSummary(bookingId);
        BigDecimal cash = (BigDecimal) (session == null ? null : session.getAttribute("counterCash"));
        BigDecimal change = (BigDecimal) (session == null ? null : session.getAttribute("counterChange"));

        session.removeAttribute(SESSION_BOOKING);
        session.removeAttribute(SESSION_SHOWTIME);
        session.removeAttribute("counterCash");
        session.removeAttribute("counterChange");

        req.setAttribute("summary", s);
        req.setAttribute("cashReceived", Moneys.vnd(cash));
        req.setAttribute("change", Moneys.vnd(change));
        req.setAttribute("hasChange", change != null && change.compareTo(BigDecimal.ZERO) > 0);
        req.setAttribute("pageTitle", "Bán vé tại quầy — Hóa đơn");
        forward(req, resp, "counter/counter-success");
    }

    /* ================= POST ================= */

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireStaff(req, resp)) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = Validator.trim(req.getParameter("action"));
        try {
            switch (action) {
                case "hold": doHold(req, resp); break;
                case "attachCustomer": doAttachCustomer(req, resp); break;
                case "updateCombos": doUpdateCombos(req, resp); break;
                case "applyVoucher": doApplyVoucher(req, resp); break;
                case "applyPoints": doApplyPoints(req, resp); break;
                case "pay": doPay(req, resp); break;
                case "payGateway": doPayGateway(req, resp); break;
                case "cancelBooking": doCancelBooking(req, resp); break;
                default: resp.sendRedirect(req.getContextPath() + "/staff/counter");
            }
        } catch (SQLException e) {
            getServletContext().log("Counter sale action failed: " + action, e);
            flash(req, "error", "Không thể thực hiện thao tác: " + e.getMessage());
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private Integer sessionBookingId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        return session == null ? null : (Integer) session.getAttribute(SESSION_BOOKING);
    }

    private String checkoutUrl(HttpServletRequest req) {
        return req.getContextPath() + "/staff/counter?action=checkout";
    }

    /** Giữ ghế đã chọn (tạo booking nếu chưa có / booking cũ hết hạn). */
    private void doHold(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException, ServletException {
        int showtimeId = parseIntSafe(req.getParameter("showtimeId"), 0);
        String seatIds = cleanSeatIds(req.getParameter("seatIds"));
        if (showtimeId <= 0 || seatIds.isEmpty()) {
            flash(req, "error", "Vui lòng chọn ít nhất một ghế.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter?action=seats&showtimeId=" + showtimeId);
            return;
        }
        // Chặn giữ ghế cho suất chiếu đã qua giờ hoặc không thuộc ngày hôm nay.
        ShowtimeInfo holdShow = dao.findShowtimeById(showtimeId);
        if (!isSellableToday(holdShow)) {
            flash(req, "error", "Suất chiếu này đã qua giờ hoặc không thuộc ngày hôm nay. "
                    + "Vui lòng chọn suất chiếu khác.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }

        HttpSession session = req.getSession();
        Integer bookingId = (Integer) session.getAttribute(SESSION_BOOKING);
        Integer sessShowtime = (Integer) session.getAttribute(SESSION_SHOWTIME);
        Integer staffAccountId = staffAccountIdOrNull(req);

        // Đơn cũ chỉ tái sử dụng được khi: cùng suất chiếu và chưa giữ ghế lần nào.
        // Các trường hợp khác (đổi suất, đã giữ ghế rồi chọn lại, đơn hết hạn)
        // → hủy đơn cũ, tạo đơn mới.
        if (bookingId != null) {
            BookingSummary existing = dao.getBookingSummary(bookingId);
            boolean reusable = sessShowtime != null && sessShowtime == showtimeId
                    && existing != null && "Selecting".equals(existing.getStatus());
            if (!reusable) {
                if (existing != null) dao.cancelPendingBooking(bookingId);
                bookingId = null;
            }
        }
        if (bookingId == null) {
            bookingId = dao.createCounterBooking(null, staffAccountId, showtimeId);
            session.setAttribute(SESSION_BOOKING, bookingId);
            session.setAttribute(SESSION_SHOWTIME, showtimeId);
        }

        boolean retried = false;
        while (true) {
            try {
                dao.holdSeats(bookingId, seatIds);
                break;
            } catch (SQLException e) {
                // Chỉ tạo đơn mới và thử lại khi phiên cũ đã hết hạn / không còn (50010, 50011).
                // Lỗi thật (ghế vừa bị giữ, ghế đôi tách cặp...) thì huỷ đơn vừa tạo để không để lại đơn rác.
                boolean sessionGone = e.getErrorCode() == 50010 || e.getErrorCode() == 50011;
                if (!retried && sessionGone) {
                    bookingId = dao.createCounterBooking(null, staffAccountId, showtimeId);
                    session.setAttribute(SESSION_BOOKING, bookingId);
                    session.setAttribute(SESSION_SHOWTIME, showtimeId);
                    retried = true;
                    continue;
                }
                try {
                    dao.cancelPendingBooking(bookingId);
                } catch (SQLException ignore) {
                    // don rac se tu het han
                }
                session.removeAttribute(SESSION_BOOKING);
                session.removeAttribute(SESSION_SHOWTIME);
                req.setAttribute("error", e.getMessage());
                showSeats(req, resp);
                return;
            }
        }
        resp.sendRedirect(checkoutUrl(req));
    }

    /** Gắn khách hàng đã đăng ký vào đơn (để dùng voucher / MyPoint). */
    private void doAttachCustomer(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException {
        Integer bookingId = sessionBookingId(req);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        String q = Validator.trim(req.getParameter("q"));
        if (q.isEmpty()) {
            flash(req, "error", "Nhập email hoặc số điện thoại của khách hàng.");
        } else {
            CounterSaleDAO.CustomerInfo ci = dao.findCustomer(q);
            if (ci == null) {
                flash(req, "error", "Không tìm thấy khách hàng với email/SĐT \"" + q + "\".");
            } else {
                dao.attachCustomer(bookingId, ci.getAccountId());
                flash(req, "success", "Đã gắn khách hàng: " + ci.getFullName()
                        + " (số dư " + ci.getPointBalance() + " điểm).");
            }
        }
        resp.sendRedirect(checkoutUrl(req));
    }

    /** Cập nhật combo của đơn (số lượng 0 = bỏ combo). */
    private void doUpdateCombos(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException {
        Integer bookingId = sessionBookingId(req);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        String[] ids = req.getParameterValues("comboId");
        String[] qtys = req.getParameterValues("qty");
        if (ids != null && qtys != null && ids.length == qtys.length) {
            for (int i = 0; i < ids.length; i++) {
                int comboId = parseIntSafe(ids[i], 0);
                int qty = Math.max(0, parseIntSafe(qtys[i], 0));
                if (comboId <= 0) continue;
                try {
                    dao.addCombo(bookingId, comboId, qty);
                } catch (SQLException e) {
                    // Ví dụ: không đủ tồn kho — báo ngay, giữ nguyên các combo đã cập nhật
                    flash(req, "error", e.getMessage());
                    resp.sendRedirect(checkoutUrl(req));
                    return;
                }
            }
            flash(req, "success", "Đã cập nhật combo.");
        }
        resp.sendRedirect(checkoutUrl(req));
    }

    private void doApplyVoucher(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Integer bookingId = sessionBookingId(req);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        String code = Validator.trim(req.getParameter("voucherCode"));
        DiscountResult r = discountService.applyDiscounts(bookingId, code, 0);
        flash(req, r.getTotal() != null ? "success" : "error", r.getMessage());
        resp.sendRedirect(checkoutUrl(req));
    }

    private void doApplyPoints(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Integer bookingId = sessionBookingId(req);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        int points = Math.max(0, parseIntSafe(req.getParameter("points"), 0));
        DiscountResult r = discountService.applyDiscounts(bookingId, null, points);
        // total != null ⇔ procedure chạy thành công; ngược lại message là lỗi tiếng Việt
        flash(req, r.getTotal() != null ? "success" : "error", r.getMessage());
        resp.sendRedirect(checkoutUrl(req));
    }

    /** Thu tiền mặt và hoàn tất đơn. */
    private void doPay(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException {
        Integer bookingId = sessionBookingId(req);
        BookingSummary s = bookingId == null ? null : dao.getBookingSummary(bookingId);
        if (s == null || !s.isPendingPayment()) {
            flash(req, "error", "Đơn đã hết hạn hoặc không còn hiệu lực. Vui lòng bán lại từ đầu.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        BigDecimal total = s.getTotalAmount();
        BigDecimal cash = parseMoney(req.getParameter("cashReceived"));
        if (cash == null || cash.compareTo(total) < 0) {
            flash(req, "error", "Tiền khách đưa chưa đủ. Tổng phải thu: " + Moneys.vnd(total) + " đ.");
            resp.sendRedirect(checkoutUrl(req));
            return;
        }

        BigDecimal change = cash.subtract(total);

        dao.confirmCashPayment(bookingId);
        HttpSession session = req.getSession();
        session.setAttribute("counterCash", cash);
        session.setAttribute("counterChange", change);

        // Thông báo ngay số tiền thối lại cho khách: khi khách đưa thừa thì
        // nhân viên cần nói rõ số tiền phải trả lại, không chỉ hiện trên hóa đơn.
        if (change.compareTo(BigDecimal.ZERO) > 0) {
            flash(req, "success", "Đã thu " + Moneys.vnd(cash) + " đ. Trả lại khách "
                    + Moneys.vnd(change) + " đ.");
        } else {
            flash(req, "success", "Đã thu đúng " + Moneys.vnd(cash) + " đ. Không có tiền thối lại.");
        }
        resp.sendRedirect(req.getContextPath() + "/staff/counter?action=success");
    }

    /**
     * Thu tiền qua cổng thanh toán VNPAY — cùng kênh thanh toán với khách
     * hàng đặt vé online.
     *
     * <p>Luồng: dựng URL cổng (đã ký) → nhân viên/khách thanh toán trên cổng →
     * cổng chuyển về {@code /staff/counter/payment/return} → xác nhận thanh
     * toán và hiện hóa đơn tại quầy.</p>
     *
     * <p>Số tiền gửi lên cổng là tổng của đơn sau khi đã áp combo, voucher và
     * MyPoint — cùng con số mà cổng trả về sẽ được đối soát.</p>
     */
    private void doPayGateway(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException {
        Integer bookingId = sessionBookingId(req);
        OnlineBooking booking = bookingId == null ? null : paymentService.findBooking(bookingId);
        if (booking == null || !booking.isPendingPayment()) {
            flash(req, "error", "Đơn đã hết hạn hoặc không còn hiệu lực. Vui lòng bán lại từ đầu.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        if (booking.getTotalAmount() == null
                || booking.getTotalAmount().compareTo(BigDecimal.ZERO) <= 0) {
            flash(req, "error", "Tổng tiền của đơn không hợp lệ. Vui lòng kiểm tra lại đơn.");
            resp.sendRedirect(checkoutUrl(req));
            return;
        }
        if (booking.isPaymentExpired()) {
            paymentService.releaseExpiredHolds();
            HttpSession session = req.getSession(false);
            if (session != null) {
                session.removeAttribute(SESSION_BOOKING);
                session.removeAttribute(SESSION_SHOWTIME);
            }
            flash(req, "error",
                    "Đơn đã hết thời gian chờ thanh toán. Vui lòng chọn ghế lại.");
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        // URL cổng chuyển về: tuyệt đối (VNPAY yêu cầu) và trỏ về kênh quầy.
        String returnUrl = WebUrls.absoluteBase(req) + "/staff/counter/payment/return";
        String orderInfo = "Thanh toan ve tai quay " + booking.getBookingCode();
        String url = paymentService.buildPaymentUrl(booking, orderInfo,
                WebUrls.clientIp(req), req.getContextPath(), returnUrl);
        resp.sendRedirect(url);
    }

    /** Hủy đơn đang dở, nhả ghế đã giữ. */
    private void doCancelBooking(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, SQLException {
        HttpSession session = req.getSession(false);
        Integer bookingId = sessionBookingId(req);
        if (bookingId != null) {
            dao.cancelPendingBooking(bookingId);
        }
        if (session != null) {
            session.removeAttribute(SESSION_BOOKING);
            session.removeAttribute(SESSION_SHOWTIME);
        }
        flash(req, "success", "Đã hủy đơn, ghế đã được nhả lại.");
        resp.sendRedirect(req.getContextPath() + "/staff/counter");
    }
}
