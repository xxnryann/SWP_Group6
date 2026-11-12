package com.cinema.controller.showtime;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.MovieDAO;
import com.cinema.dao.ShowtimeDAO;
import com.cinema.model.Showtime;
import com.cinema.model.User;
import com.cinema.util.movie.MovieAccess;
import com.cinema.util.showtime.ShowtimeRules;
import com.cinema.util.showtime.ShowtimeUtil;
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
            if ("available-times".equals(request.getParameter("action"))
                    || "room-schedule".equals(request.getParameter("action"))) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED,
                        "Phiên đăng nhập quản lý đã hết hạn. Vui lòng đăng nhập lại.");
                return;
            }
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
        if ("room-schedule".equals(request.getParameter("action"))) {
            writeRoomSchedule(request, response);
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
                if (showtime.getShowtimeId() > 0 && showtime.isStarted()) {
                    flash(request, "error", "Suất chiếu đã bắt đầu hoặc đã diễn ra, không thể sửa.");
                    response.sendRedirect(request.getContextPath() + "/manage/showtimes");
                    return;
                }
                if (showtime.getShowtimeId() > 0 && showtime.isLockedByPurchasedTickets()) {
                    flash(request, "error", "Suất chiếu đã có vé được mua, không thể sửa để bảo toàn thông tin vé.");
                    response.sendRedirect(request.getContextPath() + "/manage/showtimes");
                    return;
                }
                request.setAttribute("showtime", showtime);
                request.setAttribute("movies", movieDAO.findAllForShowtime());
                request.setAttribute("rooms", showtimeDAO.findActiveRoomNames());
                request.setAttribute("defaultDate", showtime.getStartsAt() == null
                        ? LocalDate.now() : showtime.getStartsAt().toLocalDate());
                request.setAttribute("todayDate", LocalDate.now());
                request.setAttribute("pageTitle", idValue == null ? "Thêm suất chiếu" : "Sửa suất chiếu");
                forward(request, response, "showtime/showtime-form");
                return;
            }
            // Chỉ hiện suất chưa tới giờ chiếu: suất đã bắt đầu không còn sửa/xóa được nên ẩn khỏi danh sách.
            List<Showtime> upcoming = new ArrayList<>();
            for (Showtime s : showtimeDAO.findAllForManagement()) {
                // Suất đã hủy (ngừng chiếu / hủy phim / hủy suất) không còn hiện trong danh sách.
                if (!s.isStarted() && !"Cancelled".equals(s.getStatus())) {
                    upcoming.add(s);
                }
            }
            request.setAttribute("showtimes", filterShowtimes(request, upcoming));
            request.setAttribute("pageTitle", "Quản lý lịch chiếu");
            forward(request, response, "showtime/manage-showtimes");
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
                // Mỗi giờ gắn với đúng phòng của nó: slot = "Tên phòng|HH:mm" (giờ gợi ý + giờ nhập tay theo phòng).
                java.util.LinkedHashSet<String> slots = new java.util.LinkedHashSet<>();
                for (String raw : request.getParameterValues("slot") == null
                        ? new String[0] : request.getParameterValues("slot")) {
                    if (raw != null && raw.contains("|") && !raw.trim().endsWith("|")) {
                        slots.add(raw.trim());
                    }
                }
                if (slots.isEmpty()) {
                    throw new IllegalArgumentException("Vui lòng chọn ít nhất một phòng và một giờ chiếu cho phòng đó.");
                }
                if (!"Orig".equals(request.getParameter("languageMode")) && !"Sub".equals(request.getParameter("languageMode")) && !"Dub".equals(request.getParameter("languageMode"))) {
                    throw new IllegalArgumentException("Vui lòng chọn hình thức: nguyên bản, phụ đề hoặc lồng tiếng.");
                }
                if (request.getParameter("language") == null || request.getParameter("language").isBlank()) {
                    throw new IllegalArgumentException("Vui lòng chọn ngôn ngữ cho suất chiếu.");
                }
                String id = request.getParameter("id");
                if (id != null && !id.isBlank()) {
                    if (slots.size() != 1) {
                        throw new IllegalArgumentException("Khi sửa, chỉ chọn một phòng và một giờ chiếu.");
                    }
                    String[] slot = slots.iterator().next().split("\\|", 2);
                    requireNotStarted(ShowtimeUtil.parseId(id), "sửa");
                    showtimeDAO.save(readShowtime(request, slot[0], slot[1], id));
                    flash(request, "success", "Đã lưu suất chiếu.");
                } else {
                    int created = 0;
                    List<String> failures = new ArrayList<>();
                    for (String value : slots) {
                        String[] slot = value.split("\\|", 2);
                        try {
                            showtimeDAO.save(readShowtime(request, slot[0], slot[1], null));
                            created++;
                        } catch (IllegalArgumentException | SQLException e) {
                            String reason = e instanceof SQLException
                                    && (((SQLException) e).getErrorCode() == 2601 || ((SQLException) e).getErrorCode() == 2627)
                                    ? "Phòng đã có suất chiếu bắt đầu đúng giờ này." : e.getMessage();
                            failures.add(slot[0] + " " + slot[1] + ": " + reason);
                        }
                    }
                    if (failures.isEmpty()) {
                        flash(request, "success", "Đã tạo " + created + " suất chiếu.");
                    } else {
                        flash(request, "error", (created > 0 ? "Đã tạo " + created
                                + " suất chiếu. " : "") + "Không tạo được: " + String.join("; ", failures));
                    }
                }
            } else if ("delete".equals(action)) {
                int deleteId = ShowtimeUtil.parseId(request.getParameter("id"));
                requireNotStarted(deleteId, "xóa");
                if (showtimeDAO.hasBookings(deleteId)) {
                    // Suất đã có đơn: không xóa dữ liệu mà hủy suất + hoàn MyPoint và voucher đền bù như hủy phim.
                    String reason = request.getParameter("reason") == null ? "" : request.getParameter("reason").trim();
                    int paid = showtimeDAO.countPaidBookings(deleteId);
                    // Chỉ có đơn chưa thanh toán (đang giữ ghế): không ai cần hoàn tiền -> lý do mặc định.
                    if (reason.isEmpty() && paid == 0) reason = "Quản lý hủy suất chiếu";
                    if (reason.isEmpty()) {
                        throw new IllegalArgumentException("Suất chiếu đã có đơn đặt vé: vui lòng nhập lý do hủy để hoàn MyPoint và voucher đền bù cho khách.");
                    }
                    if (reason.length() > 500) {
                        throw new IllegalArgumentException("Lý do hủy tối đa 500 ký tự.");
                    }
                    int managerId = new com.cinema.dao.AccountDAO().findAccountIdByEmail(currentUser(request).getEmail());
                    if (managerId == 0) {
                        throw new IllegalArgumentException("Không tìm thấy tài khoản quản lý.");
                    }
                    showtimeDAO.cancel(deleteId, managerId, reason);
                    flash(request, "success", "Đã hủy suất chiếu" + (paid > 0
                            ? ". " + paid + " đơn đã được hoàn MyPoint, tặng voucher đền bù và nhận thông báo kèm lý do."
                            : "."));
                } else {
                    showtimeDAO.delete(deleteId);
                    flash(request, "success", "Đã xóa suất chiếu.");
                }
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }
        } catch (IllegalArgumentException | DateTimeParseException e) {
            flash(request, "error", e.getMessage());
        } catch (SQLException e) {
            getServletContext().log("Unable to save or delete showtime.", e);
            // 2601 / 2627: vi phạm khoá duy nhất (phòng đã có suất bắt đầu đúng giờ này) -> báo bằng tiếng Việt thay vì lỗi SQL.
            String reason = e.getErrorCode() == 2601 || e.getErrorCode() == 2627
                    ? "Phòng đã có suất chiếu bắt đầu đúng giờ này." : e.getMessage();
            flash(request, "error", "Không thể cập nhật lịch chiếu: " + reason);
        }
        response.sendRedirect(request.getContextPath() + "/manage/showtimes");
    }

    private Showtime readShowtime(HttpServletRequest request, String roomName, String showTime, String id) {
        Showtime showtime = new Showtime();
        showtime.setShowtimeId(id == null || id.isBlank() ? 0 : ShowtimeUtil.parseId(id));
        showtime.setMovieId(ShowtimeUtil.parseId(request.getParameter("movieId")));
        showtime.setRoomName(ShowtimeUtil.requiredText(roomName,
                "Tên phòng không được để trống.", 50));
        String showDate = request.getParameter("showDate");
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
            throw new IllegalArgumentException("Giờ chiếu phải nằm trên mốc 5 phút (ví dụ 14:00, 14:05, 14:10).");
        }
        showtime.setStartsAt(start);
        showtime.setStatus("Scheduled");
        String mode = request.getParameter("languageMode");
        if (!"Orig".equals(mode) && !"Sub".equals(mode) && !"Dub".equals(mode)) {
            throw new IllegalArgumentException("Vui lòng chọn hình thức: nguyên bản, phụ đề hoặc lồng tiếng.");
        }
        String language = request.getParameter("language");
        if (language == null || language.isBlank()) {
            throw new IllegalArgumentException("Vui lòng chọn ngôn ngữ cho suất chiếu.");
        }
        showtime.setLanguageMode(mode);
        showtime.setLanguage(language.trim());
        return showtime;
    }

    /** Chặn sửa/xóa suất đã bắt đầu (tính theo cả giờ, phút) — chỉ suất trong tương lai mới được thay đổi. */
    private void requireNotStarted(int showtimeId, String verb) throws SQLException {
        Showtime existing = showtimeDAO.findById(showtimeId);
        if (existing == null) {
            throw new IllegalArgumentException("Không tìm thấy suất chiếu.");
        }
        if (existing.isStarted()) {
            throw new IllegalArgumentException("Suất chiếu đã bắt đầu hoặc đã diễn ra, không thể " + verb + ".");
        }
    }

    /**
     * Lịch các phòng trong một ngày (JSON) để form thêm/sửa suất chiếu vẽ timeline:
     * {"open":"07:00","close":"23:55","rooms":[{"room":"Phòng 1","shows":[{"id":1,"title":"...",
     * "start":"09:15","end":"10:55","slotEnd":"11:10"}]}]}. slotEnd = kết thúc phim + dọn phòng.
     */
    private void writeRoomSchedule(HttpServletRequest request, HttpServletResponse response) throws IOException {
        LocalDate date = parseDate(request.getParameter("date"));
        if (date == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ngày chiếu không hợp lệ.");
            return;
        }
        try {
            String body = com.cinema.util.showtime.RoomScheduleJson.build(showtimeDAO, date);
            response.setContentType("application/json;charset=UTF-8");
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.getWriter().write(body);
        } catch (SQLException e) {
            getServletContext().log("Unable to load room schedule.", e);
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Không thể tải lịch phòng.");
        }
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
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.setHeader("Pragma", "no-cache");
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
