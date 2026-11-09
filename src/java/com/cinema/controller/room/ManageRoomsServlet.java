package com.cinema.controller.room;

import com.cinema.dao.RoomDAO;
import com.cinema.dao.SeatDAO;
import com.cinema.model.Room;
import com.cinema.util.room.RoomRuleException;
import com.cinema.util.room.RoomRules;
import com.cinema.util.room.RoomSort;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/**
 * Screening Room Management (Admin) — tạo phòng chiếu và thiết lập thông tin phòng (tên, loại phòng, sức chứa).
 *
 * URL: /admin/rooms
 *   GET  (không action)        danh sách phòng, tìm theo tên (?q=), sắp xếp/lọc (?room, type, capacity, upcoming, status, xem RoomSort)
 *   GET  ?action=new           form thêm phòng
 *   GET  ?action=edit&id=N     form sửa phòng
 *   POST action=save           thêm/sửa phòng
 *   POST action=toggle         đóng/mở phòng
 *   POST action=delete         xóa phòng (chỉ khi chưa có suất chiếu/vé)
 */
@WebServlet("/admin/rooms")
public class ManageRoomsServlet extends AdminBaseServlet {

    private final RoomDAO roomDAO = new RoomDAO();
    private final SeatDAO seatDAO = new SeatDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                if (roomDAO.countAll() >= RoomRules.MAX_ROOMS) {
                    redirectRoomLimit(req, resp);
                    return;
                }
                Room r = new Room();
                r.setRoomType("2D");
                r.setCapacity(RoomRules.FIXED_2D_CAPACITY);
                r.setStatus(RoomRules.ROOM_ACTIVE);
                showForm(req, resp, r);
            } else if ("edit".equals(action)) {
                Integer id = intParam(req, "id");
                Room r = id == null ? null : roomDAO.findById(id);
                if (r == null) {
                    resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
                    return;
                }
                showForm(req, resp, r);
            } else {
                String keyword = Validator.trim(req.getParameter("q"));
                req.setAttribute("rooms", RoomSort.apply(roomDAO.findAll(keyword), req.getParameter("room"),
                        req.getParameter("type"), req.getParameter("capacity"),
                        req.getParameter("upcoming"), req.getParameter("status")));
                req.setAttribute("roomTypes", RoomRules.ROOM_TYPES);
                req.setAttribute("keyword", keyword);
                boolean limitReached = roomDAO.countAll() >= RoomRules.MAX_ROOMS;
                req.setAttribute("roomLimitReached", limitReached);
                req.setAttribute("showRoomLimit", limitReached && "full".equals(req.getParameter("limit")));
                req.setAttribute("roomLimitMessage", RoomRules.ROOM_LIMIT_MESSAGE);
                req.setAttribute("pageTitle", "Quản lý phòng chiếu");
                forward(req, resp, "room/room-list");
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireAdmin(req, resp) || !csrfOk(req, resp)) {
            return;
        }
        req.setCharacterEncoding("UTF-8");
        String action = Validator.trim(req.getParameter("action"));
        try {
            switch (action) {
                case "save":
                    save(req, resp);
                    break;
                case "toggle":
                    toggle(req, resp);
                    break;
                case "delete":
                    delete(req, resp);
                    break;
                default:
                    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    // ---------- actions ----------

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        Integer id = RoomRules.parseInt(req.getParameter("id"));
        boolean editing = id != null && id > 0;
        Room existing = null;
        if (editing) {
            existing = roomDAO.findById(id);
            if (existing == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
                return;
            }
        }

        String name = Validator.trim(req.getParameter("roomName"));
        String type = Validator.trim(req.getParameter("roomType"));
        String capacityStr = Validator.trim(req.getParameter("capacity"));
        String status = editing ? Validator.trim(req.getParameter("status")) : RoomRules.ROOM_ACTIVE;
        Integer cinemaId = RoomRules.parseInt(req.getParameter("cinemaId"));

        // Phòng đã có layout: sức chứa luôn bằng số ghế thực tế, không cho nhập tay.
        boolean capacityLocked = editing && existing.isHasLayout();
        if (capacityLocked) {
            capacityStr = String.valueOf(existing.getSeatCount());
        } else if (RoomRules.isFixedLayout(type)) {
            capacityStr = String.valueOf(RoomRules.fixedCapacity(type));
        }

        String error = RoomRules.validateRoom(name, type, capacityStr, status);
        if (error == null && (cinemaId == null || !roomDAO.cinemaExists(cinemaId))) {
            error = "Vui lòng chọn rạp hợp lệ.";
        }
        if (error == null && roomDAO.nameExists(cinemaId, name, editing ? id : 0)) {
            error = "Rạp này đã có phòng tên \"" + name + "\".";
        }
        if (error == null && editing && existing.isActive() && RoomRules.ROOM_CLOSED.equals(status)
                && roomDAO.countUpcomingShowtimes(id) > 0) {
            error = "Phòng còn suất chiếu sắp tới, không thể đóng. Hãy hủy hoặc dời các suất chiếu trước.";
        }

        Room r = editing ? existing : new Room();
        r.setRoomName(name);
        r.setRoomType(type);
        r.setStatus(status);
        r.setCinemaId(cinemaId == null ? 0 : cinemaId);
        Integer cap = RoomRules.parseInt(capacityStr);
        r.setCapacity(cap == null ? 0 : cap);

        if (error != null) {
            req.setAttribute("error", error);
            showForm(req, resp, r);
            return;
        }

        try {
            if (editing) {
                roomDAO.update(r);
                if (RoomRules.isFixedLayout(type) && !capacityLocked) {
                    applyFixedLayout(req, id, type, "Đã cập nhật phòng \"" + name + "\" với layout chuẩn " + type + ".");
                } else {
                    flash(req, "success", "Đã cập nhật phòng \"" + name + "\".");
                }
                resp.sendRedirect(req.getContextPath() + "/admin/rooms");
            } else {
                int newId = roomDAO.insert(r);
                if (RoomRules.isFixedLayout(type)) {
                    applyFixedLayout(req, newId, type, "Đã tạo phòng \"" + name + "\" với layout chuẩn " + type + " ("
                            + RoomRules.fixedCapacity(type) + " ghế).");
                } else {
                    flash(req, "success", "Đã tạo phòng \"" + name + "\". Hãy thiết lập layout ghế cho phòng.");
                }
                resp.sendRedirect(req.getContextPath() + "/admin/seats?roomId=" + newId);
            }
        } catch (RoomRuleException e) {
            redirectRoomLimit(req, resp);
        } catch (SQLException e) {
            if (e.getErrorCode() == 2601 || e.getErrorCode() == 2627) { // trùng UNIQUE (cinema_id, room_name)
                req.setAttribute("error", "Rạp này đã có phòng tên \"" + name + "\".");
                showForm(req, resp, r);
            } else {
                throw e;
            }
        }
    }

    private void applyFixedLayout(HttpServletRequest req, int roomId, String roomType, String successMessage)
            throws SQLException {
        try {
            seatDAO.applyLayoutKeepingSeats(roomId, seatDAO.fixedSpecs(roomType));
            flash(req, "success", successMessage);
        } catch (RoomRuleException e) {
            flash(req, "error", e.getMessage());
        }
    }

    private void toggle(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        Integer id = intParam(req, "id");
        Room r = id == null ? null : roomDAO.findById(id);
        if (r == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
            return;
        }
        String next = r.isActive() ? RoomRules.ROOM_CLOSED : RoomRules.ROOM_ACTIVE;
        try {
            roomDAO.setStatus(id, next);
            flash(req, "success", (r.isActive() ? "Đã đóng" : "Đã mở lại") + " phòng \"" + r.getRoomName() + "\".");
        } catch (RoomRuleException e) {
            flash(req, "error", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/rooms");
    }

    private void delete(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        Integer id = intParam(req, "id");
        Room r = id == null ? null : roomDAO.findById(id);
        if (r == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
            return;
        }
        try {
            roomDAO.delete(id);
            flash(req, "success", "Đã xóa phòng \"" + r.getRoomName() + "\".");
        } catch (RoomRuleException e) {
            flash(req, "error", e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/rooms");
    }

    /** Quay về danh sách và mở pop-up báo đã đạt số phòng tối đa. */
    private void redirectRoomLimit(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/admin/rooms?limit=full");
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Room room)
            throws SQLException, ServletException, IOException {
        req.setAttribute("room", room);
        req.setAttribute("cinemas", roomDAO.findCinemas());
        req.setAttribute("roomTypes", RoomRules.ROOM_TYPES);
        req.setAttribute("capacityLocked", room.getRoomId() > 0 && room.isHasLayout());
        req.setAttribute("fixedCapacity2d", RoomRules.FIXED_2D_CAPACITY);
        req.setAttribute("fixedCapacityImax", RoomRules.FIXED_IMAX_CAPACITY);
        req.setAttribute("fixedSummary2d", RoomRules.fixedSummary(RoomRules.ROOM_TYPE_2D));
        req.setAttribute("fixedSummaryImax", RoomRules.fixedSummary(RoomRules.ROOM_TYPE_IMAX));
        req.setAttribute("fixedCapacity3d", RoomRules.FIXED_3D_CAPACITY);
        req.setAttribute("fixedSummary3d", RoomRules.fixedSummary(RoomRules.ROOM_TYPE_3D));
        req.setAttribute("fixedCapacity4dx", RoomRules.FIXED_4DX_CAPACITY);
        req.setAttribute("fixedSummary4dx", RoomRules.fixedSummary(RoomRules.ROOM_TYPE_4DX));
        req.setAttribute("pageTitle", room.getRoomId() > 0 ? "Sửa phòng chiếu" : "Thêm phòng chiếu");
        req.setAttribute("parentTitle", "Quản lý phòng chiếu");
        req.setAttribute("parentUrl", req.getContextPath() + "/admin/rooms");
        forward(req, resp, "room/room-form");
    }
}
