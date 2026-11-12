<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Bán vé tại quầy"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .show-row { display: grid; grid-template-columns: 112px minmax(0, 1fr) auto; gap: 18px; align-items: center; padding: 16px 20px; }
  .show-time { padding: 12px 8px; border-radius: var(--r-md); background: var(--brand-50); color: var(--brand-700); text-align: center; }
  .show-time strong { display: block; font-size: 22px; font-weight: 800; letter-spacing: -.02em; line-height: 1.1; }
  .show-time span { font-size: 12px; color: var(--muted); }
  @media (max-width: 760px) { .show-row { grid-template-columns: 90px minmax(0, 1fr); } .show-row > :last-child { grid-column: 1 / -1; } }
</style>
<div class="page-head"><div><h1>Bán vé tại quầy</h1><p>Chọn suất chiếu sắp diễn ra để bán vé cho khách tại quầy.</p></div></div>
<nav class="stepper" aria-label="Các bước bán vé">
  <span class="step active" aria-current="step"><b>1</b>Chọn suất chiếu</span><span class="bar"></span>
  <span class="step"><b>2</b>Chọn ghế</span><span class="bar"></span>
  <span class="step"><b>3</b>Thanh toán</span>
</nav>

<c:choose>
  <c:when test="${empty showtimeList}">
    <div class="card empty"><div class="empty-icon">${ic.calendar}</div><h3>Không có suất chiếu sắp diễn ra</h3></div>
  </c:when>
  <c:otherwise>
    <div class="stack" style="--gap:12px">
      <c:forEach var="s" items="${showtimeList}">
        <article class="card show-row">
          <div class="show-time"><strong>${s.startHourLabel}</strong><span>${s.startDayLabel}</span></div>
          <div>
            <h3 style="font-size:17px"><c:out value="${s.title}"/></h3>
            <div class="cluster mt-8" style="--gap:8px">
              <span class="badge">${ic.door}<c:out value="${s.roomName}"/></span>
              <span class="badge">${ic.clock}<c:out value="${s.timeRangeLabel}"/></span>
              <c:if test="${not empty s.languageShort}"><span class="badge badge-accent">${ic.message}<c:out value="${s.languageShort}"/></span></c:if>
              <c:choose>
                <c:when test="${s.availableSeats == 0}"><span class="badge badge-danger">Hết ghế</span></c:when>
                <c:when test="${s.availableSeats <= 10}"><span class="badge badge-warning">Sắp hết · còn ${s.availableSeats} ghế</span></c:when>
                <c:otherwise><span class="badge badge-success">Còn ${s.availableSeats} ghế trống</span></c:otherwise>
              </c:choose>
            </div>
          </div>
          <div>
            <c:choose>
              <c:when test="${s.availableSeats > 0}"><a class="btn btn-primary" href="${ctx}/staff/counter?action=seats&showtimeId=${s.showtimeId}">Chọn ghế ${ic.arrowRight}</a></c:when>
              <c:otherwise><button class="btn" type="button" disabled>Hết ghế</button></c:otherwise>
            </c:choose>
          </div>
        </article>
      </c:forEach>
    </div>
  </c:otherwise>
</c:choose>
<%@ include file="../layout/bottom.jspf" %>
