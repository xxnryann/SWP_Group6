package com.cinema.controller.RoomController;

import com.cinema.controller.BaseServlet;
import com.cinema.model.User;
import com.cinema.util.RoomUtil.RoomRules;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Nền chung cho các màn hình Admin của module Phòng chiếu / Ghế.
 * Chỉ tài khoản có role ADMIN được truy cập.
 *
 * TODO (Đoàn Mạnh Cường): chuyển sang filter phân quyền tập trung khi xong "System Authorization".
 */
abstract class AdminBaseServlet extends BaseServlet {

    /** @return true nếu là ADMIN; ngược lại đã chuyển hướng/trả lỗi và servlet phải dừng. */
    protected boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) {
            if ("GET".equals(req.getMethod())) {
                req.getSession().setAttribute("afterLogin", req.getServletPath()
                        + (req.getQueryString() == null ? "" : "?" + req.getQueryString()));
            }
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        if (!RoomRules.ROLE_ADMIN.equals(u.getRole())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ quản trị viên được truy cập.");
            return false;
        }
        return true;
    }

    /** Parse số nguyên dương từ tham số; trả về null nếu thiếu/sai. */
    protected Integer intParam(HttpServletRequest req, String name) {
        Integer v = RoomRules.parseInt(req.getParameter(name));
        return v == null || v < 1 ? null : v;
    }
}
