package com.cinema.controller;

import com.cinema.dao.NewsDAO;
import com.cinema.model.News;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * STT 16 — Xem tin tức (Guest, Customer: không cần đăng nhập).
 * URL: /news        -> danh sách tin đã xuất bản
 * URL: /news?id=... -> chi tiết tin (chỉ tin published)
 */
@WebServlet("/news")
public class PublicNewsServlet extends BaseServlet {

    private final NewsDAO dao = new NewsDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            String idStr = req.getParameter("id");
            if (idStr != null && !idStr.isEmpty()) {
                News n = dao.findById(Integer.parseInt(idStr));
                if (n == null || !n.isPublished()) {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }
                req.setAttribute("news", n);
                req.setAttribute("pageTitle", n.getTitle());
                forward(req, resp, "news/news-detail");
            } else {
                List<News> list = dao.findPublished();
                req.setAttribute("newsList", list);
                req.setAttribute("pageTitle", "Tin tức");
                forward(req, resp, "news/public-list");
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
