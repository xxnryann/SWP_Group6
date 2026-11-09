package com.cinema.controller.room;

import com.cinema.controller.BaseServlet;
import com.cinema.model.User;
import com.cinema.util.room.RoomRules;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/** Nền chung cho các màn hình Admin của module Phòng chiếu / Ghế. */
abstract class AdminBaseServlet extends BaseServlet {


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
