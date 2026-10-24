package com.cinema.controller.RoomController;

import com.cinema.dao.RoomDAO.RoomDAO;
import com.cinema.dao.RoomDAO.SeatDAO;
import com.cinema.model.Room;
import com.cinema.model.Seat;
import com.cinema.model.SeatType;
import com.cinema.util.RoomUtil.RoomRuleException;
import com.cinema.util.RoomUtil.RoomRules;
import com.cinema.util.RoomUtil.RoomRules.SeatSpec;
import com.cinema.util.Validator;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Seat Layout & Seat Type Setup + Seat Maintenance (Admin).
 *
 * URL: /admin/seats?roomId=N
 *   GET                         sơ đồ ghế của phòng + form thiết lập layout + thao tác bảo trì
 *   POST action=generate        dựng/dựng lại layout (rows, cols, rowTypes="1,1,2,3,...")
 *   POST action=rowType         đổi loại ghế cả một hàng (row, typeId)
 *   POST action=maintain        đánh dấu bảo trì các ghế đã chọn (seatIds)
 *   POST action=reopen          mở lại các ghế đã chọn (seatIds)
 *
 * Quy tắc: ghế đôi luôn đi theo cặp; ghế đang bảo trì không thể được khách đặt
 * (vw_SeatMap hiển thị GREY, sp_HoldSeats từ chối); ghế đang có vé còn hiệu lực không được bảo trì.
 */
@WebServlet("/admin/seats")
public class ManageSeatsServlet extends AdminBaseServlet {

    private final RoomDAO roomDAO = new RoomDAO();
    private final SeatDAO seatDAO = new SeatDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        if (!requireAdmin(req, resp)) {
            return;
        }
        try {
            Room room = loadRoom(req, resp);
            if (room == null) {
                return;
            }
            List<SeatType> types = seatDAO.findSeatTypes();
            List<Seat> seats = seatDAO.findByRoom(room.getRoomId());

            Map<String, List<Seat>> rows = new LinkedHashMap<>();
            for (Seat s : seats) {
                rows.computeIfAbsent(s.getRowLabel(), k -> new ArrayList<>()).add(s);
            }

            // Giá trị khởi tạo cho form layout: lấy từ layout hiện có, hoặc mặc định 5 x 10.
            int layoutRows = rows.isEmpty() ? 5 : rows.size();
            int layoutCols = rows.isEmpty() ? 10 : rows.values().iterator().next().size();
            List<Integer> rowTypeIds = new ArrayList<>();
            if (rows.isEmpty()) {
                for (int i = 0; i < layoutRows; i++) {
                    rowTypeIds.add(defaultTypeIdForRow(types, i, layoutRows));
                }
            } else {
                for (List<Seat> rowSeats : rows.values()) {
                    rowTypeIds.add(rowSeats.get(0).getSeatTypeId());
                }
            }

            req.setAttribute("room", room);
            req.setAttribute("seatTypes", types);
            req.setAttribute("seatRows", rows);
            req.setAttribute("seatTotal", seats.size());
            req.setAttribute("layoutRows", layoutRows);
            req.setAttribute("layoutCols", layoutCols);
            req.setAttribute("layoutRowTypes", rowTypeIds.stream().map(String::valueOf)
                    .collect(Collectors.joining(",")));
            req.setAttribute("pageTitle", "Layout ghế · " + room.getRoomName());
            req.setAttribute("parentTitle", "Quản lý phòng chiếu");
            req.setAttribute("parentUrl", req.getContextPath() + "/admin/rooms");
            forward(req, resp, "room/seat-layout");
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
        try {
            Room room = loadRoom(req, resp);
            if (room == null) {
                return;
            }
            String action = Validator.trim(req.getParameter("action"));
            try {
                switch (action) {
                    case "generate":
                        generate(req, room);
                        break;
                    case "rowType":
                        rowType(req, room);
                        break;
                    case "maintain":
                        maintenance(req, room, true);
                        break;
                    case "reopen":
                        maintenance(req, room, false);
                        break;
                    default:
                        resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
                        return;
                }
            } catch (RoomRuleException | IllegalArgumentException e) {
                flash(req, "error", e.getMessage());
            }
            resp.sendRedirect(req.getContextPath() + "/admin/seats?roomId=" + room.getRoomId());
        } catch (SQLException e) {
            throw new ServletException(e);
        }
    }

    // ---------- actions (ném RoomRuleException/IllegalArgumentException khi dữ liệu không hợp lệ) ----------

    private void generate(HttpServletRequest req, Room room) throws SQLException, RoomRuleException {
        Integer rows = RoomRules.parseInt(req.getParameter("rows"));
        Integer cols = RoomRules.parseInt(req.getParameter("cols"));
        if (rows == null || cols == null) {
            throw new IllegalArgumentException("Số hàng và số ghế mỗi hàng phải là số nguyên.");
        }
        int[] rowTypes = RoomRules.parseRowTypes(req.getParameter("rowTypes"), rows);

        List<SeatType> types = seatDAO.findSeatTypes();
        Set<Integer> validIds = types.stream().map(SeatType::getSeatTypeId).collect(Collectors.toSet());
        Set<Integer> coupleIds = types.stream().filter(SeatType::isCouple)
                .map(SeatType::getSeatTypeId).collect(Collectors.toSet());
        for (int id : rowTypes) {
            if (!validIds.contains(id)) {
                throw new IllegalArgumentException("Loại ghế không tồn tại.");
            }
        }

        List<SeatSpec> specs = RoomRules.buildLayout(rows, cols, rowTypes, coupleIds);
        seatDAO.replaceLayout(room.getRoomId(), specs);
        flash(req, "success", "Đã thiết lập layout " + rows + " hàng × " + cols + " ghế ("
                + specs.size() + " ghế) cho " + room.getRoomName() + ".");
    }

    private void rowType(HttpServletRequest req, Room room) throws SQLException, RoomRuleException {
        String row = Validator.trim(req.getParameter("row")).toUpperCase();
        Integer typeId = intParam(req, "typeId");
        if (typeId == null) {
            throw new IllegalArgumentException("Chưa chọn loại ghế.");
        }
        seatDAO.changeRowType(room.getRoomId(), row, typeId);
        flash(req, "success", "Đã đổi loại ghế của hàng " + row + ".");
    }

    private void maintenance(HttpServletRequest req, Room room, boolean maintain)
            throws SQLException, RoomRuleException {
        String[] raw = req.getParameterValues("seatIds");
        List<Integer> ids = new ArrayList<>();
        if (raw != null) {
            for (String s : raw) {
                Integer id = RoomRules.parseInt(s);
                if (id == null) {
                    throw new IllegalArgumentException("Mã ghế không hợp lệ.");
                }
                ids.add(id);
            }
        }
        int changed = seatDAO.setMaintenance(room.getRoomId(), ids, maintain);
        if (changed == 0) {
            flash(req, "info", maintain ? "Các ghế đã chọn đã ở trạng thái bảo trì."
                    : "Các ghế đã chọn đang hoạt động bình thường.");
        } else {
            flash(req, "success", maintain
                    ? "Đã chuyển " + changed + " ghế sang bảo trì (ghế đôi được xử lý cả cặp). Khách không thể đặt các ghế này."
                    : "Đã mở lại " + changed + " ghế (ghế đôi được xử lý cả cặp).");
        }
    }

    // ---------- helpers ----------

    private Room loadRoom(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        Integer id = intParam(req, "roomId");
        Room room = id == null ? null : roomDAO.findById(id);
        if (room == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy phòng chiếu.");
        }
        return room;
    }

    /** Mặc định: các hàng đầu Standard, gần cuối VIP, hàng cuối Couple (nếu có đủ các loại). */
    private int defaultTypeIdForRow(List<SeatType> types, int index, int totalRows) {
        Integer standard = null, vip = null, couple = null;
        for (SeatType t : types) {
            if ("Standard".equalsIgnoreCase(t.getTypeName())) standard = t.getSeatTypeId();
            else if ("VIP".equalsIgnoreCase(t.getTypeName())) vip = t.getSeatTypeId();
            else if (t.isCouple()) couple = t.getSeatTypeId();
        }
        int fallback = types.isEmpty() ? 1 : types.get(0).getSeatTypeId();
        if (standard == null) standard = fallback;
        if (index == totalRows - 1 && couple != null && totalRows >= 3) return couple;
        if (index == totalRows - 2 && vip != null && totalRows >= 4) return vip;
        return standard;
    }
}
