<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Bán vé tại quầy"/>
<%@ include file="../layout/top.jspf" %>
<nav class="stepper" aria-label="Các bước bán vé">
  <span class="step done"><b>${ic.check}</b>Chọn suất chiếu</span><span class="bar done"></span>
  <span class="step active" aria-current="step"><b>2</b>Chọn ghế</span><span class="bar"></span>
  <span class="step"><b>3</b>Thanh toán</span>
</nav>

<div class="booking-head">
  <h1><c:out value="${showtime.title}"/></h1>
  <span class="badge badge-brand">${ic.door}<c:out value="${showtime.roomName}"/></span>
  <span class="badge">${ic.clock}${showtime.startTimeLabel}</span>
  <a class="btn btn-ghost btn-sm" href="${ctx}/staff/counter" style="margin-left:auto">${ic.chevronLeft}Đổi suất chiếu</a>
</div>

<c:if test="${not empty error}"><div class="alert alert-error mb-16" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
<c:if test="${reselectWarning}"><div class="alert alert-warning mb-16">${ic.info}<span>Đơn hiện tại đã giữ ghế của suất này. Nếu chọn lại, đơn cũ sẽ bị hủy và tạo đơn mới (ghế cũ được nhả lại).</span></div></c:if>

<%@ include file="../booking/_seat-picker.jspf" %>

<form method="post" action="${ctx}/staff/counter" onsubmit="return checkSeats()">
  <input type="hidden" name="_csrf" value="${csrf}">
  <input type="hidden" name="action" value="hold">
  <input type="hidden" name="showtimeId" value="${showtime.showtimeId}">
  <input type="hidden" id="seatIds" name="seatIds" value="">
  <div class="checkout-bar">
    <div><span class="label">Ghế đã chọn</span><strong><span id="selCount" class="seats-picked">0</span> ghế</strong></div>
    <div class="grow"><span class="label">Tạm tính</span><strong><span id="selTotal">0</span> đ</strong></div>
    <button class="btn btn-accent btn-lg" type="submit">Giữ ghế &amp; thanh toán ${ic.arrowRight}</button>
  </div>
</form>
<%@ include file="../booking/_seat-picker-script.jspf" %>
<%@ include file="../layout/bottom.jspf" %>
