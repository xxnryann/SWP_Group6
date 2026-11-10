<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thanh toán không thành công"/>
<%@ include file="../layout/top.jspf" %>
<div class="container container-sm">
  <div class="card empty" style="margin:40px 0;padding:48px 28px">
    <div class="empty-icon" style="background:var(--danger-50);color:var(--danger)">${ic.x}</div>
    <h3>Thanh toán không thành công</h3>
    <p>
      <c:choose>
        <c:when test="${not empty flashMsg}"><c:out value="${flashMsg}"/></c:when>
        <c:otherwise>Đơn đặt vé của bạn đã được hủy và ghế đã được trả lại.</c:otherwise>
      </c:choose>
    </p>
    <div class="cluster mt-8" style="justify-content:center">
      <a class="btn btn-primary" href="${ctx}/showtimes">${ic.calendar}Chọn suất chiếu khác</a>
      <a class="btn" href="${ctx}/account/tickets">${ic.ticket}Vé của tôi</a>
    </div>
  </div>
</div>
<%@ include file="../layout/bottom.jspf" %>
