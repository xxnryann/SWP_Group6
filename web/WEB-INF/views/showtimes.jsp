<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<%@ include file="_header.jspf" %>

<main class="container page st-page">
  <h1 class="st-title">Lịch chiếu</h1>
  <c:if test="${isManager}">
    <p class="st-manage"><a class="btn btn-primary" href="${ctx}/manage/showtimes">Quản lý lịch chiếu</a></p>
  </c:if>

  <nav class="st-dates" aria-label="Chọn ngày chiếu">
    <c:forEach var="t" items="${dateTabs}">
      <a class="st-date ${t.active ? 'is-active' : ''}" href="${ctx}/showtimes?date=${t.iso}">
        <strong><c:out value="${t.label}"/></strong>
        <span><c:out value="${t.weekday}"/></span>
      </a>
    </c:forEach>
  </nav>

  <c:choose>
    <c:when test="${empty showtimeGroups}">
      <div class="movie-list-empty">
        <p>Không có suất chiếu nào cho ngày này.</p>
      </div>
    </c:when>
    <c:otherwise>
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
              <c:if test="${not empty group.movie.genres}"><span>Thể loại: <strong><c:out value="${group.movie.genres}"/></strong></span></c:if>
              <span>Thời lượng: <strong><c:out value="${group.movie.durationMinutes}"/> phút</strong></span>
            </p>
            <div class="st-times">
              <c:forEach var="showtime" items="${group.showtimes}">
                <c:choose>
                  <c:when test="${empty sessionScope.authUser or sessionScope.authUser.role == 'CUSTOMER'}">
                    <c:url var="bookingUrl" value="/booking/seats">
                      <c:param name="showtimeId" value="${showtime.showtimeId}"/>
                    </c:url>
                    <a class="st-time" href="${bookingUrl}" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                      <strong><c:out value="${showtime.startTimeOnly}"/></strong>
                      <small><c:out value="${showtime.roomName}"/></small>
                    </a>
                  </c:when>
                  <c:otherwise>
                    <span class="st-time">
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
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="_footer.jspf" %>
