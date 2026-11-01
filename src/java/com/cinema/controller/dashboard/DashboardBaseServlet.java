package com.cinema.controller.dashboard;

import com.cinema.controller.BaseServlet;
import com.cinema.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Base servlet cho tất cả các dashboard (Admin, Manager, Staff, Customer).
 * Cung cấp các phương thức chung như xác thực, forward, flash messages.
 */
public abstract class DashboardBaseServlet extends BaseServlet {
    
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("authUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        // Thiết lập cờ để header biết đây là trang dashboard
        req.setAttribute("dashboardModule", true);
        req.setAttribute("railModule", true);
        super.doGet(req, resp);
    }
}
