package com.cinema.controller;

import com.cinema.dao.UserDAO;
import com.cinema.util.MovieUtil.MediaUploadUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;

/** Tải / lưu ảnh đại diện của người dùng đang đăng nhập. POST /account/avatar (multipart: avatar). */
@WebServlet("/account/avatar")
@MultipartConfig(fileSizeThreshold = 512 * 1024, maxFileSize = 3L * 1024L * 1024L, maxRequestSize = 4L * 1024L * 1024L)
public class AvatarServlet extends BaseServlet {

    private final UserDAO dao = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/account/profile");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // Form multipart nên _csrf nằm trong phần form-data; csrfOk đọc qua getParameter (Tomcat hỗ trợ khi có @MultipartConfig).
        if (!csrfOk(req, resp)) {
            return;
        }
        String back = req.getContextPath() + "/account/profile";
        try {
            Part part = req.getPart("avatar");
            if (part == null || part.getSize() == 0) {
                flash(req, "error", "Vui lòng chọn ảnh trước khi lưu.");
                resp.sendRedirect(back);
                return;
            }
            int id = currentUser(req).getUserId();
            String oldUrl = dao.findById(id).getAvatarUrl();
            String url = MediaUploadUtil.store(part, MediaUploadUtil.MediaType.AVATAR);
            dao.updateAvatar(id, url);
            if (oldUrl != null && !oldUrl.equals(url)) {
                MediaUploadUtil.delete(oldUrl);
            }
            flash(req, "success", "Đã lưu ảnh đại diện.");
        } catch (IllegalArgumentException e) {
            flash(req, "error", e.getMessage());
        } catch (IllegalStateException e) {
            flash(req, "error", "Ảnh vượt quá giới hạn 2 MB.");
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        resp.sendRedirect(back);
    }
}