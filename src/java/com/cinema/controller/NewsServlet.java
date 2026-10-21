package com.cinema.controller;

import com.cinema.dao.NewsDAO;
import com.cinema.model.News;
import com.cinema.model.User;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Set;

/**
 * STT 12 — Quản lý tin tức (Cinema Manager).
 * URL: /manager/news?action=list|add|edit|delete|view
 *
 * Khớp bảng News trong script database của nhóm:
 *  - status IN ('Draft','Published','Hidden')
 *  - created_by NOT NULL REFERENCES Account(account_id) → tra theo email user đăng nhập
 *
 * TODO (Đoàn Mạnh Cường): chuyển kiểm tra quyền sang filter phân quyền
 * tập trung khi xong STT "System Authorization".
 * TODO (nhóm DB): bảng Users (khung đăng nhập) và bảng Account (script DB)
 * đang song song — cần thống nhất để created_by luôn tìm được.
 */
@WebServlet("/manager/news")
public class NewsServlet extends BaseServlet {

    private static final Set<String> STATUSES = Set.of("Draft", "Published", "Hidden");
    private final NewsDAO dao = new NewsDAO();

    private boolean requireManager(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User u = currentUser(req);
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        if (!"MANAGER".equals(u.getRole()) && !"ADMIN".equals(u.getRole())) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ quản lý rạp được truy cập.");
            return false;
        }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireManager(req, resp)) return;
        String action = req.getParameter("action");
        if (action == null) action = "list";
        try {
            switch (action) {
                case "add":
                    req.setAttribute("pageTitle", "Đăng tin mới");
                    forward(req, resp, "news/news-form");
                    break;
                case "edit": {
                    News n = dao.findById(Integer.parseInt(req.getParameter("id")));
                    if (n == null) { resp.sendError(404); return; }
                    req.setAttribute("news", n);
                    req.setAttribute("pageTitle", "Sửa tin tức");
                    forward(req, resp, "news/news-form");
                    break;
                }
                case "view": {
                    News n = dao.findById(Integer.parseInt(req.getParameter("id")));
                    if (n == null) { resp.sendError(404); return; }
                    req.setAttribute("news", n);
                    req.setAttribute("pageTitle", n.getTitle());
                    forward(req, resp, "news/news-detail");
                    break;
                }
                default: { // list + tab lọc trạng thái + tìm kiếm (theo mockup)
                    String statusFilter = Validator.trim(req.getParameter("status"));
                    String keyword = Validator.trim(req.getParameter("q"));
                    List<News> list = dao.findAll(
                            STATUSES.contains(statusFilter) ? statusFilter : "", keyword);
                    req.setAttribute("newsList", list);
                    req.setAttribute("statusFilter", statusFilter);
                    req.setAttribute("keyword", keyword);
                    req.setAttribute("pageTitle", "Quản lý tin tức");
                    forward(req, resp, "news/news-list");
                }
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!requireManager(req, resp)) return;
        if (!csrfOk(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("id")));
                flash(req, "success", "Đã xóa tin tức.");
                resp.sendRedirect(req.getContextPath() + "/manager/news");
                return;
            }

            String idStr = Validator.trim(req.getParameter("id"));
            String title = Validator.trim(req.getParameter("title"));
            String content = Validator.trim(req.getParameter("content"));
            String thumbnailUrl = Validator.trim(req.getParameter("thumbnailUrl"));
            String status = Validator.trim(req.getParameter("status"));

            if (title.isEmpty() || content.isEmpty() || !STATUSES.contains(status)) {
                News n = new News();
                n.setTitle(title); n.setContent(content);
                n.setThumbnailUrl(thumbnailUrl); n.setStatus(status);
                req.setAttribute("news", n);
                req.setAttribute("error", "Tiêu đề, nội dung và trạng thái hợp lệ là bắt buộc.");
                req.setAttribute("pageTitle", idStr.isEmpty() ? "Đăng tin mới" : "Sửa tin tức");
                forward(req, resp, "news/news-form");
                return;
            }

            // created_by: tra account_id theo email của user đang đăng nhập
            int accountId = dao.findAccountIdByEmail(currentUser(req).getEmail());
            if (accountId == 0) {
                req.setAttribute("error", "Email " + currentUser(req).getEmail()
                        + " chưa có trong bảng Account — báo nhóm DB đồng bộ tài khoản.");
                req.setAttribute("pageTitle", "Đăng tin mới");
                forward(req, resp, "news/news-form");
                return;
            }

            News n = new News();
            n.setTitle(title);
            n.setContent(content);
            n.setThumbnailUrl(thumbnailUrl.isEmpty() ? null : thumbnailUrl);
            n.setStatus(status);
            n.setCreatedBy(accountId);

            if (idStr.isEmpty()) {
                dao.insert(n);
                flash(req, "success", "Đã đăng tin tức mới.");
            } else {
                n.setNewsId(Integer.parseInt(idStr));
                dao.update(n);
                flash(req, "success", "Đã cập nhật tin tức.");
            }
            resp.sendRedirect(req.getContextPath() + "/manager/news");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
