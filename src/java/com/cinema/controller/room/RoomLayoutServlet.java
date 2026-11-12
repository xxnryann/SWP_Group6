package com.cinema.controller.room;

import com.cinema.dao.RoomDAO;
import com.cinema.dao.SeatDAO;
import com.cinema.dao.SeatLayoutDAO;
import com.cinema.model.Room;
import com.cinema.model.SeatLayout;
import com.cinema.model.User;
import com.cinema.util.Validator;
import com.cinema.util.room.RoomRuleException;
import com.cinema.util.room.RoomRules;
import com.cinema.util.room.SeatLayoutRules;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Thêm phòng chiếu — bước 2: chọn layout ghế (Admin).
 *
 * Bước 1 (/admin/rooms?action=new) lưu thông tin phòng (rạp, tên, loại) vào session; phòng chỉ được tạo ở bước này.
 *
 * URL: /admin/room-layout
 *   GET  ?selected=std|ID          trang chọn layout: layout đề xuất theo loại phòng, thư viện layout, tạo layout mới
 *   POST action=saveLayout         lưu layout vừa tạo vào thư viện (layoutName, layoutData)
 *   POST action=create             tạo phòng với layout đã chọn (layout=std | ID)
 */
@WebServlet("/admin/room-layout")
public class RoomLayoutServlet extends AdminBaseServlet {

    private static final String DRAFT = "roomDraft";
    private static final String STANDARD = "std";

    private final RoomDAO roomDAO = new RoomDAO();
    private final SeatDAO seatDAO = new SeatDAO();
    private final SeatLayoutDAO layoutDAO = new SeatLayoutDAO();

    /** Thông tin phòng đang thêm (bước 1), null nếu chưa có. */
    static Room draft(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return s == null ? null : (Room) s.getAttribute(DRAFT);
    }

    static void saveDraft(HttpServletRequest req, Room r) {
        Room copy = new Room();
        copy.setCinemaId(r.getCinemaId());
        copy.setRoomName(r.getRoomName());
        copy.setRoomType(r.getRoomType());
        copy.setStatus(RoomRules.ROOM_ACTIVE);
        req.getSession().setAttribute(DRAFT, copy);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }
        Room draft = draft(req);
        if (draft == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/rooms?action=new");
            return;
        }
        try {
            show(req, resp, draft, Validator.trim(req.getParameter("selected")));
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
        Room draft = draft(req);
        if (draft == null) {
            flash(req, "error", "Phiên thêm phòng đã hết hạn. Vui lòng nhập lại thông tin phòng.");
            resp.sendRedirect(req.getContextPath() + "/admin/rooms?action=new");
            return;
        }
        String action = Validator.trim(req.getParameter("action"));
        try {
            if ("saveLayout".equals(action)) {
                saveLayout(req, resp, draft);
            } else if ("create".equals(action)) {
                create(req, resp, draft);
            } else {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    // ---------- actions ----------

    private void saveLayout(HttpServletRequest req, HttpServletResponse resp, Room draft)
            throws SQLException, ServletException, IOException {
        String name = Validator.trim(req.getParameter("layoutName"));
        String data = Validator.trim(req.getParameter("layoutData"));
        String error = SeatLayoutRules.validateName(name);
        if (error == null) {
            error = SeatLayoutRules.validate(data);
        }
        if (error == null && layoutDAO.nameExists(name)) {
            error = "Tên layout \"" + name + "\" đã có trong thư viện. Hãy đặt tên khác.";
        }
        if (error != null) {
            // Giữ nguyên sơ đồ đang vẽ để người dùng sửa tiếp.
            req.setAttribute("editorError", error);
            req.setAttribute("editorName", name);
            req.setAttribute("editorData", data);
            show(req, resp, draft, null);
            return;
        }
        SeatLayout l = new SeatLayout();
        l.setLayoutName(name);
        l.setRoomType(draft.getRoomType());
        l.setLayoutData(data);
        l.setSeatCount(SeatLayoutRules.seatCount(data));
        User u = currentUser(req);
        int id;
        try {
            id = layoutDAO.insert(l, u == null ? null : u.getUserId());
        } catch (SQLException e) {
            if (e.getErrorCode() == 2601 || e.getErrorCode() == 2627) {
                req.setAttribute("editorError", "Tên layout \"" + name + "\" đã có trong thư viện. Hãy đặt tên khác.");
                req.setAttribute("editorName", name);
                req.setAttribute("editorData", data);
                show(req, resp, draft, null);
                return;
            }
            throw e;
        }
        flash(req, "success", "Đã lưu layout \"" + name + "\" (" + l.getSeatCount() + " ghế) vào thư viện.");
        resp.sendRedirect(req.getContextPath() + "/admin/room-layout?selected=" + id);
    }

    private void create(HttpServletRequest req, HttpServletResponse resp, Room draft)
            throws SQLException, ServletException, IOException {
        String choice = Validator.trim(req.getParameter("layout"));
        SeatLayout layout = null;
        if (STANDARD.equals(choice) && !RoomRules.isFixedLayout(draft.getRoomType())) {
            req.setAttribute("error", "Loại phòng " + draft.getRoomType()
                    + " chưa có layout chuẩn. Hãy chọn một layout trong thư viện hoặc tạo layout mới.");
            show(req, resp, draft, null);
            return;
        }
        if (!STANDARD.equals(choice)) {
            Integer id = RoomRules.parseInt(choice);
            layout = id == null ? null : layoutDAO.findById(id);
            if (layout == null) {
                req.setAttribute("error", "Vui lòng chọn một layout ghế.");
                show(req, resp, draft, null);
                return;
            }
        }
        String error = null;
        if (roomDAO.countAll() >= RoomRules.MAX_ROOMS) {
            error = RoomRules.ROOM_LIMIT_MESSAGE;
        } else if (!roomDAO.cinemaExists(draft.getCinemaId())) {
            error = "Rạp đã chọn không còn tồn tại. Hãy quay lại bước 1.";
        } else if (roomDAO.nameExists(draft.getCinemaId(), draft.getRoomName(), 0)) {
            error = "Rạp này đã có phòng tên \"" + draft.getRoomName() + "\". Hãy quay lại bước 1 để đổi tên.";
        } else if (layout != null && SeatLayoutRules.validate(layout.getLayoutData()) != null) {
            error = "Layout \"" + layout.getLayoutName() + "\" không hợp lệ: "
                    + SeatLayoutRules.validate(layout.getLayoutData());
        }
        if (error != null) {
            req.setAttribute("error", error);
            show(req, resp, draft, choice);
            return;
        }

        Room r = new Room();
        r.setCinemaId(draft.getCinemaId());
        r.setRoomName(draft.getRoomName());
        r.setRoomType(draft.getRoomType());
        r.setStatus(RoomRules.ROOM_ACTIVE);
        r.setLayoutId(layout == null ? null : layout.getLayoutId());
        r.setCapacity(layout == null ? RoomRules.fixedCapacity(draft.getRoomType()) : layout.getSeatCount());
        int newId;
        try {
            newId = roomDAO.insert(r);
        } catch (RoomRuleException e) {
            req.setAttribute("error", e.getMessage());
            show(req, resp, draft, choice);
            return;
        } catch (SQLException e) {
            if (e.getErrorCode() == 2601 || e.getErrorCode() == 2627) {
                req.setAttribute("error", "Rạp này đã có phòng tên \"" + draft.getRoomName() + "\".");
                show(req, resp, draft, choice);
                return;
            }
            throw e;
        }
        try {
            if (layout == null) {
                seatDAO.applyLayoutKeepingSeats(newId, seatDAO.fixedSpecs(draft.getRoomType()));
                flash(req, "success", "Đã tạo phòng \"" + r.getRoomName() + "\" với layout chuẩn "
                        + draft.getRoomType() + " (" + r.getCapacity() + " ghế).");
            } else {
                seatDAO.replaceLayout(newId, seatDAO.layoutSpecs(layout.getLayoutData()));
                flash(req, "success", "Đã tạo phòng \"" + r.getRoomName() + "\" với layout \""
                        + layout.getLayoutName() + "\" (" + r.getCapacity() + " ghế).");
            }
        } catch (RoomRuleException e) {
            flash(req, "error", "Đã tạo phòng nhưng chưa tạo được ghế: " + e.getMessage());
        }
        req.getSession().removeAttribute(DRAFT);
        resp.sendRedirect(req.getContextPath() + "/admin/seats?roomId=" + newId);
    }

    // ---------- view ----------

    private void show(HttpServletRequest req, HttpServletResponse resp, Room draft, String selected)
            throws SQLException, ServletException, IOException {
        String type = draft.getRoomType();
        List<SeatLayout> layouts = layoutDAO.findAll(type);
        // Loại phòng Admin tự thêm không có layout chuẩn: chỉ chọn trong thư viện hoặc tạo mới.
        boolean hasStandard = RoomRules.isFixedLayout(type);
        boolean found = hasStandard && STANDARD.equals(selected);
        for (SeatLayout l : layouts) {
            found |= String.valueOf(l.getLayoutId()).equals(selected);
        }
        if (!found && !hasStandard) {
            // Mặc định chọn layout cùng loại phòng (thư viện đã xếp loại này lên đầu); không có thì để trống.
            selected = layouts.isEmpty() || !type.equals(layouts.get(0).getRoomType())
                    ? "" : String.valueOf(layouts.get(0).getLayoutId());
            found = true;
        }
        req.setAttribute("hasStandard", hasStandard);
        String cinemaName = "";
        for (var cn : roomDAO.findCinemas()) {
            if (cn.getCinemaId() == draft.getCinemaId()) {
                cinemaName = cn.getCinemaName();
            }
        }
        req.setAttribute("draft", draft);
        req.setAttribute("cinemaName", cinemaName);
        req.setAttribute("layouts", layouts);
        String sel = found ? selected : STANDARD;
        Integer selId = RoomRules.parseInt(sel);
        req.setAttribute("selected", sel);
        req.setAttribute("selectedId", selId == null ? 0 : selId);
        if (hasStandard) {
            req.setAttribute("standardData", SeatLayoutRules.standardPreview(type));
            req.setAttribute("standardCapacity", RoomRules.fixedCapacity(type));
            req.setAttribute("standardSummary", RoomRules.fixedSummary(type));
        }
        req.setAttribute("maxRows", RoomRules.MAX_ROWS);
        req.setAttribute("maxCols", RoomRules.MAX_COLS);
        req.setAttribute("maxSeats", RoomRules.MAX_CAPACITY);
        req.setAttribute("pageTitle", "Chọn layout ghế");
        req.setAttribute("parentTitle", "Quản lý phòng chiếu");
        req.setAttribute("parentUrl", req.getContextPath() + "/admin/rooms");
        forward(req, resp, "room/room-layout");
    }
}
