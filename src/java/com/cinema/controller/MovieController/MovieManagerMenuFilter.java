package com.cinema.controller.MovieController;

import com.cinema.controller.BaseServlet;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class MovieManagerMenuFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpSession session = httpRequest.getSession(false);
        User user = session == null ? null : (User) session.getAttribute(BaseServlet.SESSION_USER);
        boolean canManageMovies = user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole());
        httpRequest.setAttribute("isManager", canManageMovies);
        httpRequest.setAttribute("canManageMovies", canManageMovies);
        String path = httpRequest.getServletPath();
        // Trang chủ được ánh xạ cho cả "/home" và chuỗi rỗng (url "/").
        // Với chuỗi rỗng, getServletPath() trả về "" nên phải kiểm tra riêng.
        boolean isHome = path.isEmpty() || path.startsWith("/home");
        httpRequest.setAttribute("movieModule", path.startsWith("/movies")
                || path.startsWith("/showtimes") || path.startsWith("/manage/movies")
                || path.startsWith("/manage/showtimes") || path.startsWith("/dashboard/customer") || isHome);
        // Dashboard theo vai trò: nạp CSS dashboard + gắn cờ cho các trang quản trị.
        boolean isDashboard = path.startsWith("/dashboard/admin")
                || path.startsWith("/dashboard/manager")
                || path.startsWith("/dashboard/staff")
                || path.startsWith("/dashboard/customer");
        httpRequest.setAttribute("dashboardModule", isDashboard || isHome);
        // Khu vực nội bộ theo vai trò (quản trị / quản lý / quầy / khách hàng):
        // các trang này dùng sidebar riêng nên không hiện thanh nav công khai.
        // Trang chủ ("/" hoặc "/home") và các trang công khai vẫn giữ nguyên.
        boolean isRolePage = path.startsWith("/admin")
                || path.startsWith("/manager")
                || path.startsWith("/manage")
                || path.startsWith("/staff")
                || path.startsWith("/customer")
                || path.startsWith("/account");
        httpRequest.setAttribute("roleModule", isRolePage);
        // Đã đăng nhập thì menu dọc (rail) hiện ở mọi trang nội bộ, kể cả khi
        // điều hướng sang trang khác -> không mất menu khi đổi trang.
        // Trang chủ dùng chung giao diện tổng quan customer: khách chưa đăng nhập thấy header công khai.
        boolean signedIn = user != null;
        httpRequest.setAttribute("signedIn", signedIn);
        httpRequest.setAttribute("railModule", signedIn);
        chain.doFilter(request, response);
    }
}
