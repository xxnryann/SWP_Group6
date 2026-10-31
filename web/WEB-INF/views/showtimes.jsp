<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<%@ include file="_header.jspf" %>

<c:set var="canBook" value="${empty sessionScope.authUser or sessionScope.authUser.role == 'CUSTOMER'}"/>
<c:set var="showtimeCount" value="0"/>
<c:forEach var="group" items="${showtimeGroups}"><c:set var="showtimeCount" value="${showtimeCount + fn:length(group.showtimes)}"/></c:forEach>

<main class="st-page" data-date="${selectedDate}">
  <section class="st-hero">
    <div class="container st-hero-inner">
      <div>
        <h1 class="st-title">Lịch chiếu</h1>
        <p class="st-summary">
          <c:forEach var="t" items="${dateTabs}"><c:if test="${t.active}"><c:out value="${t.weekday}"/>, <c:out value="${t.label}"/></c:if></c:forEach>
          · ${fn:length(showtimeGroups)} phim · ${showtimeCount} suất chiếu
        </p>
      </div>
      <c:if test="${isManager}">
        <a class="btn st-manage" href="${ctx}/manage/showtimes">Quản lý lịch chiếu</a>
      </c:if>
    </div>
  </section>

  <div class="container st-body">
    <nav class="st-dates" aria-label="Chọn ngày chiếu">
      <c:forEach var="t" items="${dateTabs}">
        <a class="st-date ${t.active ? 'is-active' : ''}" href="${ctx}/showtimes?date=${t.iso}" ${t.active ? 'aria-current="date"' : ''}>
          <strong><c:out value="${t.label}"/></strong>
          <span><c:out value="${t.weekday}"/></span>
        </a>
      </c:forEach>
    </nav>

    <c:choose>
      <c:when test="${empty showtimeGroups}">
        <div class="st-empty">
          <h2>Chưa có suất chiếu</h2>
          <p>Ngày này chưa có suất nào. Hãy chọn một ngày khác ở trên.</p>
        </div>
      </c:when>
      <c:otherwise>
        <c:if test="${canBook}"><p class="st-hint">Bấm vào giờ chiếu để chọn ghế và đặt vé.</p></c:if>
        <div class="st-grid">
          <c:forEach var="group" items="${showtimeGroups}">
            <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${group.movie.movieId}"/></c:url>
            <article class="st-movie">
              <a class="st-poster" href="${detailUrl}">
                <c:choose>
                  <c:when test="${not empty group.movie.posterDisplayUrl}">
                    <img src="${group.movie.uploadedPoster ? ctx : ''}${group.movie.posterDisplayUrl}" alt="Poster phim ${group.movie.title}" loading="lazy">
                  </c:when>
                  <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
                </c:choose>
                <span class="badge"><c:out value="${group.movie.ageRating}"/></span>
              </a>
              <div class="st-info">
                <h2><a href="${detailUrl}"><c:out value="${group.movie.title}"/></a></h2>
                <p class="st-meta">
                  <c:if test="${not empty group.movie.genres}"><span><c:out value="${group.movie.genres}"/></span></c:if>
                  <span><c:out value="${group.movie.durationMinutes}"/> phút</span>
                </p>
                <div class="st-times">
                  <c:forEach var="showtime" items="${group.showtimes}">
                    <c:choose>
                      <c:when test="${canBook}">
                        <c:url var="bookingUrl" value="/booking/seats">
                          <c:param name="showtimeId" value="${showtime.showtimeId}"/>
                        </c:url>
                        <a class="st-time" href="${bookingUrl}" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                          <strong><c:out value="${showtime.startTimeOnly}"/></strong>
                          <small><c:out value="${showtime.roomName}"/></small>
                        </a>
                      </c:when>
                      <c:otherwise>
                        <span class="st-time" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                          <strong><c:out value="${showtime.startTimeOnly}"/></strong>
                          <small><c:out value="${showtime.roomName}"/></small>
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
</main>

<script src="${ctx}/assets/js/showtimes.js"></script>

<%@ include file="_footer.jspf" %>
