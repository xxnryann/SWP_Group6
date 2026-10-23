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
import java.time.format.DateTimeParseException;

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
            request.setAttribute("showtimes", showtimeDAO.findForDate(selectedDate));
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
}
