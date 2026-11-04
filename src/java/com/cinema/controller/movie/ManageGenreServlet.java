package com.cinema.controller.movie;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.GenreDAO;
import com.cinema.model.Genre;
import com.cinema.util.movie.MovieAccess;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/manage/genres")
public class ManageGenreServlet extends BaseServlet {
    private final GenreDAO genreDAO;

    public ManageGenreServlet() {
        this(new GenreDAO());
    }

    ManageGenreServlet(GenreDAO genreDAO) {
        this.genreDAO = genreDAO;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!requireRole(request, response, MovieAccess.ROLE_MANAGER)) return;
        try {
            String idValue = request.getParameter("id");
            if (idValue != null && !idValue.isBlank()) {
                int id = safeId(idValue);
                if (id < 1) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                    return;
                }
                for (Genre genre : genreDAO.findAll()) {
                    if (genre.getGenreId() == id) {
                        request.setAttribute("editGenre", genre);
                        break;
                    }
                }
            }
            request.setAttribute("genres", genreDAO.findAll());
            request.setAttribute("pageTitle", "Quản lý thể loại");
            forward(request, response, "movie/manage-genres");
        } catch (SQLException e) {
            throw new ServletException("Không thể tải thể loại.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {
        if (!requireRole(request, response, MovieAccess.ROLE_MANAGER)) return;
        if (!csrfOk(request, response)) return;
        try {
            String action = request.getParameter("action");
            if ("delete".equals(action)) {
                genreDAO.delete(safeId(request.getParameter("id")));
                flash(request, "success", "Đã xóa thể loại thành công.");
            } else if ("save".equals(action)) {
                String name = trimToNull(request.getParameter("genreName"));
                String description = trimToNull(request.getParameter("description"));
                validate(name, description);
                int id = safeId(request.getParameter("id"));
                if (id > 0) {
                    genreDAO.update(id, name, description);
                    flash(request, "success", "Đã cập nhật thể loại thành công.");
                } else {
                    genreDAO.create(name, description);
                    flash(request, "success", "Đã thêm thể loại thành công.");
                }
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (IllegalArgumentException | IllegalStateException e) {
            flash(request, "error", e.getMessage());
        } catch (SQLException e) {
            String message = e.getErrorCode() == 2601 || e.getErrorCode() == 2627
                    ? "Tên thể loại đã tồn tại." : "Không thể lưu thể loại.";
            getServletContext().log("Genre operation failed", e);
            flash(request, "error", message);
        }
        response.sendRedirect(request.getContextPath() + "/manage/genres");
    }

    private void validate(String name, String description) {
        if (name == null || name.length() < 2) throw new IllegalArgumentException("Tên thể loại phải có từ 2 ký tự.");
        if (name.length() > 50) throw new IllegalArgumentException("Tên thể loại tối đa 50 ký tự.");
        if (!name.matches("[\\p{L}\\p{N}][\\p{L}\\p{N} &'().,/+-]*")) {
            throw new IllegalArgumentException("Tên thể loại chứa ký tự không hợp lệ.");
        }
        if (description != null && description.length() > 200) {
            throw new IllegalArgumentException("Mô tả thể loại tối đa 200 ký tự.");
        }
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
