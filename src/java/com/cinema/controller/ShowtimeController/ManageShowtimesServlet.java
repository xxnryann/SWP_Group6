package com.cinema.controller.ShowtimeController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO.MovieDAO;
import com.cinema.dao.ShowtimeDAO.ShowtimeDAO;
import com.cinema.model.Movie;
import com.cinema.model.Showtime;
import com.cinema.model.User;
import com.cinema.util.MovieUtil.MovieAccess;
import com.cinema.util.ShowtimeUtil.ShowtimePlanner;
import com.cinema.util.ShowtimeUtil.ShowtimeRules;
import com.cinema.util.ShowtimeUtil.ShowtimeUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

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

    /** Lọc danh sách theo ngày, khoảng giờ bắt đầu và từ khoá tên phim (tham số rỗng/không hợp lệ thì bỏ qua). */
    private static List<Showtime> filterShowtimes(HttpServletRequest request, List<Showtime> all) {
        LocalDate date = parseDate(request.getParameter("date"));
        LocalTime from = parseTime(request.getParameter("timeFrom"));
        LocalTime to = parseTime(request.getParameter("timeTo"));
        String keyword = normalize(request.getParameter("q"));
        request.setAttribute("filterDate", date == null ? "" : date.toString());
        request.setAttribute("filterTimeFrom", from == null ? "" : from.toString());
        request.setAttribute("filterTimeTo", to == null ? "" : to.toString());
        String rawQ = request.getParameter("q");
        request.setAttribute("filterQ", rawQ == null ? "" : rawQ.trim());
        boolean filtered = date != null || from != null || to != null || !keyword.isEmpty();
        request.setAttribute("isFiltered", filtered);
        if (!filtered) {
            return all;
        }
        List<Showtime> result = new ArrayList<>();
        for (Showtime s : all) {
            LocalDateTime start = s.getStartsAt();
            if (start == null) {
                continue;
            }
            if (date != null && !start.toLocalDate().equals(date)) {
                continue;
            }
            LocalTime t = start.toLocalTime();
            if (from != null && t.isBefore(from)) {
                continue;
            }
            if (to != null && t.isAfter(to)) {
                continue;
            }
            if (!keyword.isEmpty() && !normalize(s.getMovieTitle()).contains(keyword)) {
                continue;
            }
            result.add(s);
        }
        return result;
    }

    private static LocalDate parseDate(String value) {
        try {
            return value == null || value.isBlank() ? null : LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static LocalTime parseTime(String value) {
        try {
            return value == null || value.isBlank() ? null : LocalTime.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** Chữ thường, bỏ dấu tiếng Việt để tìm "thanh pho" khớp "Thành Phố". */
    private static String normalize(String value) {
        if (value == null) {
            return "";
        }
        String n = java.text.Normalizer.normalize(value.trim().toLowerCase(java.util.Locale.ROOT),
                java.text.Normalizer.Form.NFD);
        return n.replaceAll("\\p{M}+", "").replace('đ', 'd');
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isManager(request)) {
            if (currentUser(request) == null) {
                response.sendRedirect(request.getContextPath() + "/login");
            } else {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
            }
            return;
        }
        if ("available-times".equals(request.getParameter("action"))) {
            writeAvailableTimes(request, response);
            return;
        }
        if ("generate".equals(request.getParameter("action"))) {
            showGenerateForm(request, response);
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
                request.setAttribute("rooms", showtimeDAO.findActiveRoomNames());
                request.setAttribute("defaultDate", showtime.getStartsAt() == null
                        ? LocalDate.now() : showtime.getStartsAt().toLocalDate());
                request.setAttribute("todayDate", LocalDate.now());
                request.setAttribute("pageTitle", idValue == null ? "Thêm suất chiếu" : "Sửa suất chiếu");
                forward(request, response, "showtime-form");
                return;
            }
            request.setAttribute("showtimes", filterShowtimes(request, showtimeDAO.findAllForManagement()));
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
            if (currentUser(request) == null) {
                response.sendRedirect(request.getContextPath() + "/login");
            } else {
                response.sendError(HttpServletResponse.SC_FORBIDDEN);
            }
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
            } else if ("generate".equals(action)) {
                int created = generateSchedule(request);
                flash(request, "success", "Đã tạo " + created + " suất chiếu.");
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
            getServletContext().log("Unable to save, generate or delete showtime.", e);
            // 2601 / 2627: vi phạm khoá duy nhất (phòng đã có suất bắt đầu đúng giờ này) -> báo bằng tiếng Việt thay vì lỗi SQL.
            String reason = e.getErrorCode() == 2601 || e.getErrorCode() == 2627
                    ? "Phòng đã có suất chiếu bắt đầu đúng giờ này." : e.getMessage();
            flash(request, "error", "Không thể cập nhật lịch chiếu: " + reason);
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
        String showDate = request.getParameter("showDate");
        String showTime = request.getParameter("showTime");
        if (showDate == null || showDate.isBlank() || showTime == null || showTime.isBlank()) {
            throw new IllegalArgumentException("Vui lòng chọn ngày và giờ chiếu.");
        }
        LocalDateTime start;
        try {
            start = LocalDate.parse(showDate).atTime(LocalTime.parse(showTime));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Ngày hoặc giờ chiếu không hợp lệ.");
        }
        if (!start.isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("Giờ chiếu phải ở trong tương lai.");
        }
        if (!ShowtimeRules.onGrid(start)) {
            throw new IllegalArgumentException("Giờ chiếu phải nằm trên mốc 15 phút (ví dụ 14:00, 14:15, 14:30).");
        }
        showtime.setStartsAt(start);
        showtime.setStatus("Scheduled");
        return showtime;
    }

    /** Mở form sinh lịch tự động cho một ngày. */
    private void showGenerateForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            LocalDate defaultDate = LocalDate.now().plusDays(1);
            String dateValue = request.getParameter("date");
            if (dateValue != null && !dateValue.isBlank()) {
                defaultDate = LocalDate.parse(dateValue);
            }
            request.setAttribute("rooms", showtimeDAO.findActiveRoomNames());
            request.setAttribute("movies", movieDAO.findAllForDate(defaultDate));
            request.setAttribute("defaultDate", defaultDate);
            request.setAttribute("todayDate", LocalDate.now());
            request.setAttribute("openTime", ShowtimeRules.OPEN_TIME);
            request.setAttribute("closeTime", ShowtimeRules.CLOSE_TIME);
            request.setAttribute("turnoverMinutes", ShowtimeRules.TURNOVER_MINUTES);
            request.setAttribute("pageTitle", "Sinh lịch chiếu tự động");
            forward(request, response, "showtime-generate");
        } catch (DateTimeParseException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ngày không hợp lệ.");
        } catch (SQLException e) {
            getServletContext().log("Unable to load showtime generator form.", e);
            flash(request, "error", "Không thể tải dữ liệu lịch chiếu: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/manage/showtimes");
        }
    }

    /**
     * Sinh lịch chiếu tự động cho ngày được chọn.
     *
     * <p>Mỗi phòng được xếp suất liên tục: suất sau bắt đầu 15 phút sau khi
     * suất trước kết thúc, phim xoay vòn và lệch nhau giữa các phòng nên cùng
     * một phim xuất hiện ở nhiều phòng với các giờ khác nhau.</p>
     */
    private int generateSchedule(HttpServletRequest request) throws SQLException {
        LocalDate date = LocalDate.parse(ShowtimeUtil.requiredText(
                request.getParameter("showDate"), "Ngày chiếu không hợp lệ.", 10));
        if (date.isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("Ngày chiếu không được nằm trong quá khứ.");
        }
        LocalTime openTime = ShowtimeRules.OPEN_TIME;
        String openValue = request.getParameter("openTime");
        if (openValue != null && !openValue.isBlank()) {
            openTime = LocalTime.parse(openValue);
            if (openTime.isBefore(ShowtimeRules.OPEN_TIME) || openTime.isAfter(ShowtimeRules.CLOSE_TIME)) {
                throw new IllegalArgumentException("Giờ mở cửa phải nằm trong khoảng "
                        + ShowtimeRules.OPEN_TIME + " – " + ShowtimeRules.CLOSE_TIME + ".");
            }
        }

        List<String> rooms = readSelectedValues(request, "roomNames");
        if (rooms.isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn ít nhất một phòng chiếu.");
        }
        List<Integer> movieIds = new ArrayList<>();
        for (String value : readSelectedValues(request, "movieIds")) {
            movieIds.add(ShowtimeUtil.parseId(value));
        }
        if (movieIds.isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn ít nhất một phim.");
        }

        List<Movie> available = movieDAO.findAllForDate(date);
        List<Movie> selected = new ArrayList<>();
        for (Movie movie : available) {
            if (movieIds.contains(movie.getMovieId())) {
                selected.add(movie);
            }
        }
        if (selected.isEmpty()) {
            throw new IllegalArgumentException("Không có phim nào đang phát hành phù hợp với ngày đã chọn.");
        }

        List<Showtime> planned = ShowtimePlanner.plan(date, openTime, rooms, selected,
                showtimeDAO.findOccupiedSlots(date));
        if (planned.isEmpty()) {
            throw new IllegalArgumentException("Không thể xếp lịch: các phòng đã kín suất trong ngày.");
        }
        return showtimeDAO.insertBatch(planned);
    }

    /** Đọc các giá trị đã chọn của một nhóm checkbox. */
    private List<String> readSelectedValues(HttpServletRequest request, String name) {
        String[] raw = request.getParameterValues(name);
        List<String> values = new ArrayList<>();
        if (raw == null) {
            return values;
        }
        for (String value : raw) {
            if (value != null && !value.isBlank()) {
                values.add(value.trim());
            }
        }
        return values;
    }

    private void writeAvailableTimes(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        try {
            LocalDate date = LocalDate.parse(ShowtimeUtil.requiredText(
                    request.getParameter("date"), "Ngày chiếu không hợp lệ.", 10));
            int movieId = ShowtimeUtil.parseId(request.getParameter("movieId"));
            String roomName = ShowtimeUtil.requiredText(request.getParameter("roomName"),
                    "Vui lòng chọn phòng chiếu.", 50);
            String excludedId = request.getParameter("id");
            int excludedShowtimeId = excludedId == null || excludedId.isBlank()
                    ? 0 : ShowtimeUtil.parseId(excludedId);
            List<LocalTime> availableTimes = showtimeDAO.findAvailableStartTimes(
                    date, roomName, movieId, excludedShowtimeId);
            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < availableTimes.size(); i++) {
                if (i > 0) {
                    json.append(',');
                }
                json.append('"').append(availableTimes.get(i)).append('"');
            }
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(json.append(']').toString());
        } catch (IllegalArgumentException | DateTimeParseException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thông tin ngày, phim hoặc phòng không hợp lệ.");
        } catch (SQLException e) {
            getServletContext().log("Unable to find available showtime slots.", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Không thể kiểm tra giờ chiếu còn trống.");
        }
    }

    private boolean isManager(HttpServletRequest request) {
        User user = currentUser(request);
        return user != null && MovieAccess.ROLE_MANAGER.equals(user.getRole());
    }
}
