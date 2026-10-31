<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hộp thư"/>
<%@ include file="_header.jspf" %>
<style>
  .inbox-list { display: flex; flex-direction: column; gap: 12px; margin-top: 16px; }
  .inbox-item { padding: 16px 20px; border: 1px solid #e2e8f0; border-left: 4px solid #1d4ed8; border-radius: 10px; background: #fff; }
  .inbox-item.is-success { border-left-color: #059669; }
  .inbox-item.is-danger { border-left-color: #dc2626; }
  .inbox-item.is-reminder { border-left-color: #f59e0b; }
  .inbox-head { display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
  .inbox-head h3 { margin: 0; font-size: 16px; }
  .inbox-time { color: #64748b; font-size: 13px; }
  .inbox-item p { margin: 8px 0 0; }
  .inbox-meta { color: #64748b; font-size: 14px; }
</style>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Hộp thư</h2>

    <c:choose>
      <c:when test="${empty notifications}"><p class="sub">Bạn chưa có thông báo nào.</p></c:when>
      <c:otherwise>
        <div class="inbox-list">
          <c:forEach var="n" items="${notifications}">
            <c:choose>
              <c:when test="${n.notif_type == 'ETicket'}">
                <c:set var="itemClass" value="is-success"/>
                <c:set var="itemTitle" value="Đặt vé thành công"/>
              </c:when>
              <c:when test="${n.notif_type == 'TicketCancelled'}">
                <c:set var="itemClass" value="is-danger"/>
                <c:set var="itemTitle" value="${n.subject}"/>
              </c:when>
              <c:when test="${n.notif_type == 'MovieCancelled'}">
                <c:set var="itemClass" value="is-danger"/>
                <c:set var="itemTitle" value="Phim bị hủy, bạn sẽ được hoàn tiền"/>
              </c:when>
              <c:otherwise>
                <c:set var="itemClass" value="is-reminder"/>
                <c:set var="itemTitle" value="Sắp đến giờ chiếu"/>
              </c:otherwise>
            </c:choose>
            <article class="inbox-item ${itemClass}">
              <div class="inbox-head">
                <h3><c:out value="${itemTitle}"/></h3>
                <span class="inbox-time"><c:out value="${n.created_at}"/></span>
              </div>
              <c:choose>
                <c:when test="${empty n.title}"><p><c:out value="${n.body}"/></p></c:when>
                <c:when test="${n.notif_type == 'TicketCancelled'}">
                  <p><c:out value="${n.body}"/> Phim: <strong><c:out value="${n.title}"/></strong>.</p>
                </c:when>
                <c:when test="${n.notif_type == 'ETicket'}">
                  <p>Bạn đã đặt vé thành công phim <strong><c:out value="${n.title}"/></strong>.</p>
                </c:when>
                <c:when test="${n.notif_type == 'MovieCancelled'}">
                  <p>Phim <strong><c:out value="${n.title}"/></strong> bạn đã đặt bị hủy. Tiền vé sẽ được hoàn lại cho bạn.</p>
                </c:when>
                <c:otherwise>
                  <p>Phim <strong><c:out value="${n.title}"/></strong> sắp chiếu. Vui lòng đến trước giờ chiếu để soát vé.</p>
                </c:otherwise>
              </c:choose>
              <c:if test="${not empty n.start_time}">
                <p class="inbox-meta">
                  Suất chiếu: <c:out value="${n.start_time}"/>
                  <c:if test="${not empty n.room_name}"> · <c:out value="${n.room_name}"/></c:if>
                  <c:if test="${not empty n.booking_code}"> · Mã đơn: <c:out value="${n.booking_code}"/></c:if>
                </p>
              </c:if>
            </article>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="_footer.jspf" %>
