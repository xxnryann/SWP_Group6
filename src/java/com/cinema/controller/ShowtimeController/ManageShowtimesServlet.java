package com.cinema.controller.ShowtimeController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO.MovieDAO;
import com.cinema.dao.ShowtimeDAO.ShowtimeDAO;
import com.cinema.model.Showtime;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import com.cinema.util.ShowtimeUtil.ShowtimeUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;

@WebServlet("/manage/showtimes")
public class ManageShowtimesServlet extends BaseServlet {
    private final ShowtimeDAO showtimeDAO;
    private final MovieDAO movieDAO;

    public ManageShowtimesServlet() {
        this(new ShowtimeDAO(), new MovieDAO());
    }

    ManageShowtimesServlet(ShowtimeDAO showtimeDAO, MovieDAO movieDAO) {
        this.showtimeDAO = showtimeDAO;
        this.movieDAO = movieDAO;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isManager(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        try {
            String idValue = request.getParameter("id");
            if (idValue != null || "new".equals(request.getParameter("action"))) {
                Showtime showtime = idValue == null ? new Showtime() : showtimeDAO.findById(ShowtimeUtil.parseId(idValue));
                if (showtime == null) {
                    response.sendError(HttpServletResponse.SC_NOT_FOUND);
                    return;
                }
                request.setAttribute("showtime", showtime);
                request.setAttribute("movies", movieDAO.findAllForShowtime());
                request.setAttribute("pageTitle", idValue == null ? "Thêm suất chiếu" : "Sửa suất chiếu");
                forward(request, response, "showtime-form");
                return;
            }
            request.setAttribute("showtimes", showtimeDAO.findAllForManagement());
            request.setAttribute("pageTitle", "Quản lý lịch chiếu");
            forward(request, response, "manage-showtimes");
        } catch (IllegalArgumentException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST);
        } catch (SQLException e) {
            getServletContext().log("Unable to load showtime management page.", e);
            flash(request, "error", "Không thể tải dữ liệu lịch chiếu: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isManager(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        if (!csrfOk(request, response)) {
            return;
        }
        try {
            String action = request.getParameter("action");
            if ("save".equals(action)) {
                showtimeDAO.save(readShowtime(request));
                flash(request, "success", "Đã lưu suất chiếu.");
            } else if ("delete".equals(action)) {
                showtimeDAO.delete(ShowtimeUtil.parseId(request.getParameter("id")));
                flash(request, "success", "Đã xóa suất chiếu.");
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (IllegalArgumentException | DateTimeParseException e) {
            flash(request, "error", e.getMessage());
        } catch (SQLException e) {
            getServletContext().log("Unable to save or delete showtime.", e);
            flash(request, "error", "Không thể cập nhật lịch chiếu: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + "/manage/showtimes");
    }

    private Showtime readShowtime(HttpServletRequest request) {
        Showtime showtime = new Showtime();
        String id = request.getParameter("id");
        showtime.setShowtimeId(id == null || id.isBlank() ? 0 : ShowtimeUtil.parseId(id));
        showtime.setMovieId(ShowtimeUtil.parseId(request.getParameter("movieId")));
        showtime.setRoomName(ShowtimeUtil.requiredText(request.getParameter("roomName"),
                "Tên phòng không được để trống.", 50));
        String startsAt = request.getParameter("startsAt");
        if (startsAt == null || startsAt.isBlank()) {
            throw new IllegalArgumentException("Vui lòng chọn ngày và giờ chiếu.");
        }
        LocalDateTime start = LocalDateTime.parse(startsAt);
        if (!start.isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("Giờ chiếu phải ở trong tương lai.");
        }
        showtime.setStartsAt(start);
        String price = request.getParameter("ticketPrice");
        try {
            BigDecimal ticketPrice = new BigDecimal(price);
            if (ticketPrice.signum() < 0 || ticketPrice.scale() > 2 || ticketPrice.precision() > 10) {
                throw new IllegalArgumentException("Giá vé phải từ 0 trở lên và tối đa 2 chữ số thập phân.");
            }
            showtime.setTicketPrice(ticketPrice);
        } catch (NumberFormatException | NullPointerException e) {
            throw new IllegalArgumentException("Giá vé không hợp lệ.");
        }
        String status = request.getParameter("status");
        if (!"Scheduled".equals(status) && !"Cancelled".equals(status)) {
            throw new IllegalArgumentException("Trạng thái suất chiếu không hợp lệ.");
        }
        showtime.setStatus(status);
        return showtime;
    }

    private boolean isManager(HttpServletRequest request) {
        User user = currentUser(request);
        return user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole());
    }
}
