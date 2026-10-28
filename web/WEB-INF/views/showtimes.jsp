<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Lịch chiếu</h1>
      <p class="sub">Xem các suất chiếu đang mở theo ngày.</p>
    </div>
    <c:if test="${isManager}">
      <a class="btn btn-primary" href="${ctx}/manage/showtimes">Quản lý lịch chiếu</a>
    </c:if>
  </section>

  <form class="panel showtime-filters" method="get" action="${ctx}/showtimes">
    <div class="field">
      <label for="showtime-date">Ngày chiếu</label>
      <input id="showtime-date" type="date" name="date" value="<c:out value='${selectedDate}'/>">
    </div>
    <button class="btn btn-cta" type="submit">Xem lịch</button>
  </form>

  <c:choose>
    <c:when test="${empty showtimes}">
      <div class="movie-list-empty">
        <p>Không có suất chiếu nào cho ngày này.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="movie-list">
        <c:forEach var="group" items="${showtimes}">
          <article class="movie-card">
            <div class="movie-card-poster">
              <c:choose>
                <c:when test="${not empty group.posterUrl}">
                  <img src="${group.posterUrl}" alt="Poster phim ${group.title}" loading="lazy">
                </c:when>
                <c:otherwise>
                  <div class="poster-placeholder">Chưa có poster</div>
                </c:otherwise>
              </c:choose>
            </div>
            <div class="movie-card-content">
              <h3><c:out value="${group.title}"/></h3>
              <p class="meta">
                <c:if test="${not empty group.genres}"><c:out value="${group.genres}"/> · </c:if>
                <c:out value="${group.durationMinutes}"/> phút
              </p>
              <p class="rating">
                <strong><c:out value="${group.ageRating}"/></strong>
              </p>
              <div class="showtimes-list">
                <c:forEach var="showtime" items="${group.showtimes}">
                  <c:url var="bookingUrl" value="/booking/seats">
                    <c:param name="showtimeId" value="${showtime.showtimeId}"/>
                  </c:url>
                  <a class="showtime-btn" href="${bookingUrl}">
                    <c:out value="${showtime.startTime}"/>
                  </a>
                </c:forEach>
              </div>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="_footer.jspf" %>