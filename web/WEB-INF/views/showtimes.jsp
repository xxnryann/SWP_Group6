<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
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

  <nav class="showtime-day-nav" aria-label="Chọn ngày">
    <c:url var="previousUrl" value="/showtimes"><c:param name="date" value="${previousDate}"/></c:url>
    <c:url var="nextUrl" value="/showtimes"><c:param name="date" value="${nextDate}"/></c:url>
    <a class="btn btn-outline" href="<c:out value='${previousUrl}'/>">Ngày trước</a>
    <strong><c:out value="${selectedDate}"/></strong>
    <a class="btn btn-outline" href="<c:out value='${nextUrl}'/>">Ngày sau</a>
  </nav>

  <c:choose>
    <c:when test="${empty showtimes}">
      <div class="panel movie-empty">
        <h2>Chưa có suất chiếu</h2>
        <p>Không tìm thấy lịch chiếu cho ngày đã chọn.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="showtime-list">
        <c:forEach var="showtime" items="${showtimes}">
          <article class="panel showtime-card">
            <div class="showtime-time">
              <strong><c:out value="${showtime.startTimeOnly}"/></strong>
              <span>Kết thúc khoảng <c:out value="${showtime.endTimeOnly}"/></span>
            </div>
            <div class="showtime-info">
              <h2><c:out value="${showtime.movieTitle}"/></h2>
              <p>Phòng <c:out value="${showtime.roomName}"/></p>
              <p><c:out value="${showtime.movieDurationMinutes}"/> phút</p>
            </div>
            <div class="showtime-price">
              <strong><fmt:formatNumber value="${showtime.ticketPrice}" type="number" maxFractionDigits="0"/> đ</strong>
              <span>Giá vé từ</span>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="_footer.jspf" %>
