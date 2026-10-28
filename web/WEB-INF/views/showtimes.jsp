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
      <input id="showtime-date" name="date" type="date" value="<c:out value='${selectedDate}'/>" required>
    </div>
    <button class="btn btn-primary" type="submit">Xem lịch</button>
  </form>

  <section class="panel showtime-rule" aria-labelledby="showtime-rule-title">
    <div>
      <p class="eyebrow">QUY TẮC LỊCH CHIẾU</p>
      <h2 id="showtime-rule-title">Lịch chiếu linh hoạt theo từng phòng</h2>
    </div>
    <div class="showtime-rule-slots">
      <span>Suất cách nhau 15 phút</span>
      <i aria-hidden="true">|</i>
      <span>Kết thúc = Bắt đầu + Thời lượng phim</span>
      <i aria-hidden="true">|</i>
      <span>Một phim có nhiều suất ở các phòng khác nhau</span>
    </div>
  </section>

  <nav class="showtime-day-nav" aria-label="Chọn ngày">
    <c:url var="previousUrl" value="/showtimes"><c:param name="date" value="${previousDate}"/></c:url>
    <c:url var="nextUrl" value="/showtimes"><c:param name="date" value="${nextDate}"/></c:url>
    <a class="btn btn-outline" href="<c:out value='${previousUrl}'/>">Ngày trước</a>
    <strong><c:out value="${selectedDate}"/></strong>
    <a class="btn btn-outline" href="<c:out value='${nextUrl}'/>">Ngày sau</a>
  </nav>

  <c:choose>
    <c:when test="${empty showtimeGroups}">
      <div class="panel movie-empty">
        <h2>Chưa có suất chiếu</h2>
        <p>Không tìm thấy lịch chiếu cho ngày đã chọn.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="showtime-list">
        <c:forEach var="schedule" items="${showtimeGroups}">
          <c:set var="posterSrc"><c:out value="${schedule.movie.posterDisplayUrl}"/></c:set>
          <c:set var="movieTitle"><c:out value="${schedule.movie.title}"/></c:set>
          <article class="panel showtime-movie-row">
            <div class="showtime-poster">
              <c:choose>
                <c:when test="${not empty schedule.movie.posterDisplayUrl}">
                  <c:choose>
                    <c:when test="${schedule.movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:when>
                    <c:otherwise><img src="${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:otherwise>
                  </c:choose>
                </c:when>
                <c:otherwise><span>Chưa có poster</span></c:otherwise>
              </c:choose>
              <span class="showtime-age-rating"><c:out value="${schedule.movie.ageRating}"/></span>
            </div>
            <div class="showtime-movie-details">
              <h2><c:out value="${schedule.movie.title}"/></h2>
              <p class="showtime-original-title"><c:out value="${schedule.movie.originalTitle}"/> · <c:out value="${schedule.movie.durationMinutes}"/> phút</p>
              <c:if test="${not empty schedule.movie.genres}"><p class="showtime-genres"><c:out value="${schedule.movie.genres}"/></p></c:if>
              <div class="showtime-slots" aria-label="Các giờ chiếu">
                <c:forEach var="showtime" items="${schedule.showtimes}">
                  <a class="showtime-slot" href="${ctx}/booking/seats?showtimeId=${showtime.showtimeId}"
                     data-showtime-info
                     data-movie="<c:out value='${schedule.movie.title}'/>"
                     data-start="<c:out value='${showtime.startTimeOnly}'/>"
                     data-end="<c:out value='${showtime.endTimeOnly}'/>"
                     data-room="<c:out value='${showtime.roomName}'/>">
                    <c:out value="${showtime.startTimeOnly}"/>–<c:out value="${showtime.endTimeOnly}"/>
                    <span><c:out value="${showtime.roomName}"/></span>
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

<script src="${ctx}/assets/js/showtimes.js" defer></script>
<%@ include file="_footer.jspf" %>
