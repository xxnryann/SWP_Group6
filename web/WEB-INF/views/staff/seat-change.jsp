<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đổi ghế"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><h1>Đổi ghế</h1><p>Đổi sang ghế trống cùng loại trong cùng suất chiếu, giữ nguyên giá vé. Chỉ áp dụng cho vé đã thanh toán và suất chưa bắt đầu.</p></div>
</div>

<div class="split" style="grid-template-columns:minmax(0,1fr) minmax(0,1.2fr)">
  <section class="card">
    <div class="card-head"><div><h2>Tra cứu vé</h2></div></div>
    <div class="card-body stack">
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
      <form method="get" action="${ctx}/staff/seat-change" class="form">
        <div class="field">
          <label for="code">Mã vé</label>
          <div class="input-group">${ic.ticket}<input id="code" name="code" type="text" maxlength="30" autocomplete="off" placeholder="TK4C537F9A2BD3" value="<c:out value='${code}'/>"></div>
        </div>
        <button class="btn btn-primary" type="submit">${ic.search}Tra cứu</button>
      </form>
    </div>
  </section>

  <section class="card">
    <div class="card-head"><div><h2>Thông tin vé</h2></div></div>
    <div class="card-body">
      <c:choose>
        <c:when test="${empty ticket}"><div class="empty" style="padding:24px"><div class="empty-icon">${ic.swap}</div><p>Tra cứu một mã vé để đổi ghế.</p></div></c:when>
        <c:otherwise>
          <div class="cluster between mb-16">
            <h3 style="font-size:19px"><c:out value="${ticket.movie_title}"/></h3>
            <c:choose>
              <c:when test="${ticket.status == 'Booked'}"><span class="badge badge-success badge-dot">Đã thanh toán</span></c:when>
              <c:when test="${ticket.status == 'Used'}"><span class="badge badge-brand badge-dot">Đã sử dụng</span></c:when>
              <c:when test="${ticket.status == 'Cancelled'}"><span class="badge badge-danger badge-dot">Đã hủy</span></c:when>
              <c:when test="${ticket.status == 'Expired'}"><span class="badge badge-dot">Đã hết hạn</span></c:when>
              <c:otherwise><span class="badge badge-warning badge-dot">Đang giữ chỗ</span></c:otherwise>
            </c:choose>
          </div>
          <dl class="dl">
            <dt>Mã vé</dt><dd><span class="voucher-code"><c:out value="${ticket.ticket_code}"/></span></dd>
            <dt>Phòng / Suất</dt><dd><c:out value="${ticket.room_name}"/> · <c:out value="${ticket.start_time}"/></dd>
            <dt>Ghế hiện tại</dt><dd><span class="text-brand"><c:out value="${ticket.seat_label}"/><c:if test="${not empty ticket.pair_label}"> và <c:out value="${ticket.pair_label}"/></c:if></span> <span class="muted">(<c:out value="${ticket.seat_type}"/>)</span></dd>
            <dt>Khách hàng</dt><dd><c:out value="${empty ticket.customer_name ? 'Khách mua tại quầy' : ticket.customer_name}"/></dd>
          </dl>
          <hr class="divider">
          <c:choose>
            <c:when test="${ticket.status != 'Booked'}"><div class="alert alert-info">${ic.info}<span>Chỉ đổi ghế được cho vé đã thanh toán và chưa sử dụng.</span></div></c:when>
            <c:when test="${ticket.changeable != 1}"><div class="alert alert-info">${ic.info}<span>Suất chiếu đã bắt đầu hoặc đã bị hủy nên không thể đổi ghế.</span></div></c:when>
            <c:when test="${empty freeSeats}"><div class="alert alert-warning">${ic.alert}<span>Suất chiếu này không còn <c:out value="${empty ticket.pair_label ? 'ghế' : 'cặp ghế'}"/> <c:out value="${ticket.seat_type}"/> trống để đổi.</span></div></c:when>
            <c:otherwise>
              <form method="post" action="${ctx}/staff/seat-change" class="form" data-loading>
                <input type="hidden" name="_csrf" value="${csrf}">
                <input type="hidden" name="code" value="<c:out value='${ticket.ticket_code}'/>">
                <input type="hidden" name="ticketId" value="${ticket.ticket_id}">
                <div class="field">
                  <label for="newSeatId">Ghế mới<span class="req">*</span></label>
                  <select id="newSeatId" name="newSeatId" required>
                    <option value="">Chọn ghế trống cùng loại</option>
                    <c:forEach var="s" items="${freeSeats}">
                      <option value="${s.seat_id}"><c:out value="${s.row_label}${s.seat_number}"/><c:if test="${not empty s.pair_label}"> và <c:out value="${s.pair_label}"/></c:if> — <c:out value="${s.seat_type}"/></option>
                    </c:forEach>
                  </select>
                </div>
                <div class="field">
                  <label for="reason">Lý do (tùy chọn)</label>
                  <input id="reason" name="reason" type="text" maxlength="200" placeholder="Khách yêu cầu, ghế hỏng...">
                </div>
                <div class="form-actions start"><button class="btn btn-accent" type="submit">${ic.swap}Đổi ghế</button></div>
              </form>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </div>
  </section>
</div>

<section class="card mt-24">
  <div class="card-head"><div><h2>Lịch sử đổi ghế gần đây</h2></div></div>
  <c:choose>
    <c:when test="${empty changes}"><div class="empty"><div class="empty-icon">${ic.list}</div><p>Chưa có lần đổi ghế nào.</p></div></c:when>
    <c:otherwise>
      <div class="table-wrap"><table class="table">
        <thead><tr><th>Thời điểm</th><th>Mã vé</th><th>Ghế cũ</th><th>Ghế mới</th><th>Lý do</th><th>Thực hiện</th></tr></thead>
        <tbody>
        <c:forEach var="h" items="${changes}">
          <tr>
            <td class="muted text-sm nowrap"><c:out value="${h.changed_at}"/></td>
            <td><span class="voucher-code"><c:out value="${h.ticket_code}"/></span></td>
            <td><c:out value="${h.old_seat}"/></td>
            <td class="fw-700 text-brand"><c:out value="${h.new_seat}"/></td>
            <td class="text-sm"><c:out value="${h.reason}"/></td>
            <td><c:out value="${h.changed_by_name}"/></td>
          </tr>
        </c:forEach>
        </tbody>
      </table></div>
    </c:otherwise>
  </c:choose>
</section>
<%@ include file="../layout/bottom.jspf" %>
