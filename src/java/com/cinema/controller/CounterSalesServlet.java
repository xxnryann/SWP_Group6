package com.cinema.controller;

import com.cinema.controller.booking.BookingSession;
import com.cinema.dao.CounterSaleDAO;
import com.cinema.model.BookingSummary;
import com.cinema.model.ShowtimeInfo;
import com.cinema.model.User;
import com.cinema.service.DiscountResult;
import com.cinema.service.DiscountService;
import com.cinema.service.OnlineBookingService;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
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
 * Lưu ý: phiên giữ ghế chỉ tồn tại 15 phút (SystemConfig BOOKING_SESSION_MINUTES).
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

    private BigDecimal parseMoney(String s) {
        try {
            return new BigDecimal(Validator.trim(s).replace(".", "").replace(",", "."));
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

    /** Bước 2: sơ đồ ghế của một suất chiếu. */
    private void showSeats(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException, SQLException {
        int showtimeId = parseIntSafe(req.getParameter("showtimeId"), 0);
        ShowtimeInfo show = showtimeId > 0 ? dao.findShowtimeById(showtimeId) : null;
        if (show == null) {
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
            flash(req, "error", "Phiên giữ ghế đã hết hạn (tối đa 15 phút). Vui lòng chọn ghế lại.");
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
        req.setAttribute("comboQty", comboQty);
        req.setAttribute("pointConfig", dao.getPointConfig());
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
        req.setAttribute("cashReceived", cash);
        req.setAttribute("change", change);
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
                case "applyDiscount": doApplyDiscount(req, resp); break;
                case "pay": doPay(req, resp); break;
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

    /** Áp voucher + MyPoint (chỉ có tác dụng khi đơn đã gắn khách hàng đã đăng ký). */
    private void doApplyDiscount(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Integer bookingId = sessionBookingId(req);
        if (bookingId == null) {
            resp.sendRedirect(req.getContextPath() + "/staff/counter");
            return;
        }
        String code = Validator.trim(req.getParameter("voucherCode"));
        int points = Math.max(0, parseIntSafe(req.getParameter("points"), 0));
        DiscountResult r = discountService.applyDiscounts(bookingId, code, points);
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
            flash(req, "error", "Tiền khách đưa chưa đủ. Tổng phải thu: " + total + " VNĐ.");
            resp.sendRedirect(checkoutUrl(req));
            return;
        }
        dao.confirmCashPayment(bookingId);
        HttpSession session = req.getSession();
        session.setAttribute("counterCash", cash);
        session.setAttribute("counterChange", cash.subtract(total));
        resp.sendRedirect(req.getContextPath() + "/staff/counter?action=success");
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
