<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đổi ghế"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Đổi ghế cho vé đã thanh toán</h2>
    <p class="sub">Chỉ đổi trong cùng suất chiếu, sang ghế còn trống; giữ nguyên giá vé đã thanh toán. Ghế đôi phải đổi theo cặp nên không hỗ trợ ở đây.</p>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <form method="get" action="${ctx}/staff/seat-change" class="checkin-form">
      <div class="field">
        <label for="code">MÃ VÉ</label>
        <input id="code" name="code" type="text" maxlength="30" autocomplete="off" placeholder="Ví dụ: TK4C537F9A2BD3"
               value="<c:out value='${code}'/>">
      </div>
      <button class="btn btn-primary" type="submit">Tra cứu</button>
    </form>

    <c:if test="${not empty ticket}">
      <div class="checkin-ticket">
        <h3><c:out value="${ticket.movie_title}"/></h3>
        <dl>
          <dt>Mã vé</dt><dd><c:out value="${ticket.ticket_code}"/></dd>
          <dt>Phòng / Suất</dt><dd><c:out value="${ticket.room_name}"/> · <c:out value="${ticket.start_time}"/></dd>
          <dt>Ghế hiện tại</dt><dd><strong><c:out value="${ticket.seat_label}"/></strong> (<c:out value="${ticket.seat_type}"/>)</dd>
          <dt>Khách hàng</dt><dd><c:out value="${empty ticket.customer_name ? 'Khách mua tại quầy' : ticket.customer_name}"/></dd>
          <dt>Trạng thái</dt><dd><c:out value="${ticket.status}"/></dd>
        </dl>

        <c:choose>
          <c:when test="${ticket.status != 'Booked'}">
            <p class="alert alert-info">Chỉ đổi ghế được cho vé đã thanh toán và chưa sử dụng.</p>
          </c:when>
          <c:when test="${empty freeSeats}">
            <p class="alert alert-info">Suất chiếu này không còn ghế đơn trống để đổi.</p>
          </c:when>
          <c:otherwise>
            <form method="post" action="${ctx}/staff/seat-change">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="code" value="<c:out value='${ticket.ticket_code}'/>">
              <input type="hidden" name="ticketId" value="${ticket.ticket_id}">
              <div class="field">
                <label for="newSeatId">GHẾ MỚI</label>
                <select id="newSeatId" name="newSeatId" required>
                  <option value="">-- Chọn ghế trống --</option>
                  <c:forEach var="s" items="${freeSeats}">
                    <option value="${s.seat_id}"><c:out value="${s.row_label}${s.seat_number}"/> — <c:out value="${s.seat_type}"/></option>
                  </c:forEach>
                </select>
              </div>
              <div class="field">
                <label for="reason">LÝ DO (TUỲ CHỌN)</label>
                <input id="reason" name="reason" type="text" maxlength="200" placeholder="Ví dụ: khách yêu cầu, ghế hỏng...">
              </div>
              <button class="btn btn-cta" type="submit">Đổi ghế</button>
            </form>
          </c:otherwise>
        </c:choose>
      </div>
    </c:if>
  </section>

  <section class="panel" style="margin-top:20px">
    <h2>Lịch sử đổi ghế gần đây</h2>
    <c:choose>
      <c:when test="${empty changes}"><p class="sub">Chưa có lần đổi ghế nào.</p></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="data">
          <thead><tr><th>Thời điểm</th><th>Mã vé</th><th>Ghế cũ</th><th>Ghế mới</th><th>Lý do</th><th>Thực hiện</th></tr></thead>
          <tbody>
          <c:forEach var="h" items="${changes}">
            <tr>
              <td><c:out value="${h.changed_at}"/></td><td><c:out value="${h.ticket_code}"/></td>
              <td><c:out value="${h.old_seat}"/></td><td><c:out value="${h.new_seat}"/></td>
              <td><c:out value="${h.reason}"/></td><td><c:out value="${h.changed_by_name}"/></td>
            </tr>
          </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
