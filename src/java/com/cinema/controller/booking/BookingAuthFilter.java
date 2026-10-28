package com.cinema.controller.booking;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.UserDAO;
import com.cinema.model.User;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Phân quyền cho luồng đặt vé online (/booking/*).
 *
 * <p>Quy tắc: đặt vé online bắt buộc phải đăng nhập (UC12) và chỉ khách
 * hàng (role CUSTOMER) được dùng. Nhân viên quầy dùng luồng riêng
 * (/staff/counter).</p>
 *
 * <ul>
 *   <li>Chưa đăng nhập → chuyển về /login (nhớ URL để quay lại sau khi đăng nhập)</li>
 *   <li>Đã đăng nhập nhưng sai vai trò → 403</li>
 *   <li>Tài khoản bị khoá / không còn ACTIVE → đăng xuất, chuyển về /login</li>
 * </ul>
 *
 * <p><b>Phạm vi filter có chủ đích:</b> chỉ bọc các bước khách hàng chủ động
 * mở ({@code /booking/seats}, {@code /booking/extras}, {@code /booking/payment},
 * {@code /booking/cancel-result}). Endpoint {@code /booking/payment/return} là
 * nơi <b>cổng thanh toán</b> chuyển khách về — nó phải truy cập được mà không
 * cần phiên đăng nhập (cổng gọi bằng GET, có thể không kèm cookie).</p>
 */
@WebFilter("/booking/*")
public class BookingAuthFilter implements Filter {

    /** Đường dẫn cổng thanh toán gọi vào — bỏ qua kiểm tra đăng nhập. */
    private static final String GATEWAY_RETURN_PATH = "/booking/payment/return";

    private final UserDAO dao = new UserDAO();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        String path = req.getServletPath();
        if (GATEWAY_RETURN_PATH.equals(path)) {
            // Cổng thanh toán gọi server-side, không mang phiên khách.
            // Việc tra cứu đơn dựa trên vnp_TxnRef (= mã đơn) chứ không dựa
            // vào session, nên endpoint này vẫn an toàn.
            chain.doFilter(request, response);
            return;
        }
        HttpSession s = req.getSession(false);
        if (s == null || s.getAttribute(BaseServlet.SESSION_USER) == null) {
            if ("GET".equals(req.getMethod())) {
                req.getSession().setAttribute("afterLogin", req.getServletPath()
                        + (req.getQueryString() == null ? "" : "?" + req.getQueryString()));
            }
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        try {
            User sessionUser = (User) s.getAttribute(BaseServlet.SESSION_USER);
            User u = dao.findById(sessionUser.getUserId());
            if (u == null || !"ACTIVE".equals(u.getStatus())) {
                s.invalidate();
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            sessionUser.setRole(u.getRole());
            if (!"CUSTOMER".equals(u.getRole())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN,
                        "Chỉ khách hàng mới đặt vé online được.");
                return;
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        resp.setHeader("Cache-Control", "no-store");
        chain.doFilter(request, response);
    }
}
