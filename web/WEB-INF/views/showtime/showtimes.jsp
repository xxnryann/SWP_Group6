<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>
<c:set var="canBook" value="${empty sessionScope.authUser or sessionScope.authUser.role == 'CUSTOMER'}"/>
<c:set var="showtimeCount" value="0"/>
<c:forEach var="group" items="${showtimeGroups}"><c:set var="showtimeCount" value="${showtimeCount + fn:length(group.showtimes)}"/></c:forEach>

<%-- Marker cho showtimes.js: class + data-date nằm ngay trong markup để hoạt động
     ở cả khung sidebar (app-content) lẫn trang công khai (main). --%>
<section class="hero-band st-page" data-date="<c:out value='${selectedDate}'/>" style="padding-bottom:64px">
  <div class="container">
    <div class="cluster between" style="align-items:flex-end">
      <div>
        <span class="eyebrow">Đặt vé trong vài bước</span>
        <h1>Lịch chiếu</h1>
        <p>
          <c:forEach var="t" items="${dateTabs}"><c:if test="${t.active}"><c:out value="${t.weekday}"/>, <c:out value="${t.label}"/></c:if></c:forEach>
          · ${fn:length(showtimeGroups)} phim · ${showtimeCount} suất chiếu
        </p>
      </div>
      <c:if test="${isManager}"><a class="btn btn-primary" href="${ctx}/manage/showtimes">${ic.settings}Quản lý lịch chiếu</a></c:if>
    </div>
  </div>
</section>

<div class="container">
  <nav class="date-strip" aria-label="Chọn ngày chiếu">
    <c:forEach var="t" items="${dateTabs}">
      <a class="${t.active ? 'active' : ''}" href="${ctx}/showtimes?date=${t.iso}" ${t.active ? 'aria-current="date"' : ''}>
        <strong><c:out value="${t.label}"/></strong>
        <span><c:out value="${t.weekday}"/></span>
      </a>
    </c:forEach>
  </nav>

  <div class="mt-32">
    <c:choose>
      <c:when test="${empty showtimeGroups}">
        <div class="card empty"><div class="empty-icon">${ic.calendar}</div><h3>Chưa có suất chiếu</h3><p>Ngày này chưa có suất nào. Hãy chọn một ngày khác ở trên.</p></div>
      </c:when>
      <c:otherwise>
        <c:if test="${not canBook}"><div class="alert alert-info mb-16">${ic.info}<span>Bạn đang xem bằng tài khoản nhân viên nên không đặt vé online được. Dùng chức năng bán vé tại quầy.</span></div></c:if>
        <div class="st-list">
          <c:forEach var="group" items="${showtimeGroups}">
            <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${group.movie.movieId}"/></c:url>
            <article class="card st-row">
              <a class="poster" href="${detailUrl}" aria-label="Chi tiết phim <c:out value='${group.movie.title}'/>">
                <c:choose>
                  <c:when test="${not empty group.movie.posterDisplayUrl}"><img src="${group.movie.uploadedPoster ? ctx : ''}<c:out value='${group.movie.posterDisplayUrl}'/>" alt="" loading="lazy"></c:when>
                  <c:otherwise><span class="poster-ph">${ic.film}</span></c:otherwise>
                </c:choose>
                <span class="age age-${group.movie.ageRating}"><c:out value="${group.movie.ageRating}"/></span>
              </a>
              <div>
                <h2><a href="${detailUrl}"><c:out value="${group.movie.title}"/></a></h2>
                <div class="movie-meta mt-4">
                  <span><c:out value="${group.movie.durationMinutes}"/> phút</span>
                  <c:if test="${not empty group.movie.genres}"><span><c:out value="${group.movie.genres}"/></span></c:if>
                </div>
                <div class="st-times">
                  <c:forEach var="showtime" items="${group.showtimes}">
                    <c:choose>
                      <c:when test="${canBook}">
                        <c:url var="bookingUrl" value="/booking/seats"><c:param name="showtimeId" value="${showtime.showtimeId}"/></c:url>
                        <a class="time-chip st-time" href="${bookingUrl}" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                          <strong><c:out value="${showtime.startTimeOnly}"/></strong><span><c:out value="${showtime.roomName}"/></span>
                        </a>
                      </c:when>
                      <c:otherwise>
                        <span class="time-chip st-time" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                          <strong><c:out value="${showtime.startTimeOnly}"/></strong><span><c:out value="${showtime.roomName}"/></span>
                        </span>
                      </c:otherwise>
                    </c:choose>
                  </c:forEach>
                </div>
              </div>
            </article>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </div>
</div>
<div style="height:56px"></div>
<script src="${ctx}/assets/js/showtimes.js"></script>
<%@ include file="../layout/bottom.jspf" %>
