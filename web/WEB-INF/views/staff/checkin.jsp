<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Soát vé"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Soát vé tại cửa phòng chiếu</h2>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>
    <c:if test="${not empty success}"><p class="alert alert-success"><c:out value="${success}"/></p></c:if>

    <form method="post" action="${ctx}/staff/checkin" class="checkin-form">
      <input type="hidden" name="_csrf" value="${csrf}">
      <div class="field">
        <label for="ticketCode">MÃ VÉ</label>
        <input id="ticketCode" name="ticketCode" type="text" maxlength="30" autocomplete="off" autofocus
               placeholder="Ví dụ: TK4C537F9A2BD3" value="<c:out value='${param.ticketCode}'/>">
      </div>
      <button class="btn btn-primary" type="submit">Soát vé</button>
    </form>

    <c:if test="${not empty ticket}">
      <div class="checkin-ticket">
        <h3><c:out value="${ticket.movie_title}"/></h3>
        <dl>
          <dt>Mã vé</dt><dd><c:out value="${ticket.ticket_code}"/></dd>
          <dt>Phòng / Ghế</dt><dd><c:out value="${ticket.room_name}"/> · <strong><c:out value="${ticket.seat_label}"/></strong></dd>
          <dt>Suất chiếu</dt><dd><c:out value="${ticket.start_time}"/> – <c:out value="${ticket.end_time}"/></dd>
          <dt>Khách hàng</dt><dd><c:out value="${empty ticket.customer_name ? 'Khách mua tại quầy' : ticket.customer_name}"/></dd>
          <dt>Trạng thái vé</dt>
          <dd>
            <c:choose>
              <c:when test="${ticket.status == 'Used'}"><span class="chip chip-success">Đã soát</span></c:when>
              <c:when test="${ticket.status == 'Booked'}"><span class="chip">Hợp lệ</span></c:when>
              <c:otherwise><span class="chip"><c:out value="${ticket.status}"/></span></c:otherwise>
            </c:choose>
          </dd>
        </dl>
      </div>
    </c:if>
  </section>

  <section class="panel" style="margin-top:20px">
    <h2>Vé soát gần đây</h2>
    <c:choose>
      <c:when test="${empty recent}"><p class="sub">Chưa có vé nào được soát.</p></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="data">
          <thead><tr><th>Mã vé</th><th>Phim</th><th>Phòng</th><th>Ghế</th><th>Thời điểm</th><th>Nhân viên</th></tr></thead>
          <tbody>
          <c:forEach var="r" items="${recent}">
            <tr>
              <td><c:out value="${r.ticket_code}"/></td>
              <td><c:out value="${r.movie_title}"/></td>
              <td><c:out value="${r.room_name}"/></td>
              <td><c:out value="${r.seat_label}"/></td>
              <td><c:out value="${r.checked_in_at}"/></td>
              <td><c:out value="${r.staff_name}"/></td>
            </tr>
          </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
