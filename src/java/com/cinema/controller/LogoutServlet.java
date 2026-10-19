package com.cinema.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/logout")
public class LogoutServlet extends BaseServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!csrfOk(req, resp)) {
            return;
        }
        HttpSession s = req.getSession(false);
        if (s != null) {
            s.invalidate();
        }
        flash(req, "info", "Bạn đã đăng xuất.");
        resp.sendRedirect(req.getContextPath() + "/login");
    }
}
