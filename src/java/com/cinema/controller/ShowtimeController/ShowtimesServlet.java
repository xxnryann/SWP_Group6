package com.cinema.controller.ShowtimeController;

import com.cinema.controller.BaseServlet;
import com.cinema.dao.ShowtimeDAO.ShowtimeDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/showtimes")
public class ShowtimesServlet extends BaseServlet {
    private final ShowtimeDAO showtimeDAO;

    public ShowtimesServlet() {
        this(new ShowtimeDAO());
    }

    ShowtimesServlet(ShowtimeDAO showtimeDAO) {
        this.showtimeDAO = showtimeDAO;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            String dateValue = request.getParameter("date");
            LocalDate selectedDate = dateValue == null || dateValue.isBlank()
                    ? LocalDate.now() : LocalDate.parse(dateValue);
            request.setAttribute("selectedDate", selectedDate);
            request.setAttribute("showtimeGroups", showtimeDAO.findForDate(selectedDate));
            request.setAttribute("dateTabs", dateTabs(selectedDate));
            request.setAttribute("previousDate", selectedDate.minusDays(1));
            request.setAttribute("nextDate", selectedDate.plusDays(1));
            request.setAttribute("pageTitle", "Lịch chiếu");
            forward(request, response, "showtimes");
        } catch (DateTimeParseException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Ngày xem lịch không hợp lệ.");
        } catch (SQLException e) {
            getServletContext().log("Unable to load showtimes.", e);
            flash(request, "error", "Không thể tải lịch chiếu: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/home");
        }
    }

    private static final String[] WEEKDAYS = {"Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật"};

    /** 8 ngày liên tiếp từ hôm nay; nếu ngày đang xem nằm ngoài khoảng đó thì tab bắt đầu từ ngày ấy. */
    private static List<Map<String, Object>> dateTabs(LocalDate selected) {
        LocalDate start = LocalDate.now();
        if (selected.isBefore(start) || selected.isAfter(start.plusDays(7))) start = selected;
        DateTimeFormatter dm = DateTimeFormatter.ofPattern("dd/MM");
        List<Map<String, Object>> tabs = new ArrayList<>();
        for (int i = 0; i < 8; i++) {
            LocalDate d = start.plusDays(i);
            Map<String, Object> tab = new LinkedHashMap<>();
            tab.put("iso", d.toString());
            tab.put("label", dm.format(d));
            tab.put("weekday", WEEKDAYS[d.getDayOfWeek().getValue() - 1]);
            tab.put("active", d.equals(selected));
            tabs.add(tab);
        }
        return tabs;
    }
}
