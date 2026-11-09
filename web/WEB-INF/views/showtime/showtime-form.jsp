<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'Thêm suất chiếu' : 'Sửa suất chiếu'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="showDateValue" value="${empty showtime.inputDate ? defaultDate : showtime.inputDate}"/>
<c:set var="escapedShowDate"><c:out value="${showDateValue}"/></c:set>
<c:set var="escapedShowTime"><c:out value="${showtime.inputTime}"/></c:set>
<%@ include file="../_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1><c:out value="${pageTitle}"/></h1>
    </div>
  </section>
  <form class="panel showtime-form" id="showtime-form" method="post" action="${ctx}/manage/showtimes"
        data-availability-url="${ctx}/manage/showtimes">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <c:if test="${showtime.showtimeId > 0}"><input type="hidden" name="id" value="${escapedId}"></c:if>
    <div class="field">
      <label for="movieId">Phim</label>
      <select id="movieId" name="movieId" required>
        <option value="">Chọn phim</option>
        <c:forEach var="movie" items="${movies}">
          <option value="<c:out value='${movie.movieId}'/>" data-duration="<c:out value='${movie.durationMinutes}'/>" <c:if test="${showtime.movieId == movie.movieId}">selected</c:if>>
            <c:out value="${movie.title}"/> (<c:out value="${movie.durationMinutes}"/> phút)
          </option>
        </c:forEach>
      </select>
    </div>
    <div class="showtime-form-grid">
      <div class="field">
        <span class="field-label">Phòng chiếu *</span>
        <div id="roomName" class="showtime-checkboxes">
          <c:forEach var="room" items="${rooms}">
            <label class="check"><input type="checkbox" name="roomName" value="<c:out value='${room}'/>" <c:if test="${showtime.roomName == room}">checked</c:if>><span><c:out value="${room}"/></span></label>
          </c:forEach>
        </div>
      </div>
      <div class="field">
        <label for="showDate">Ngày chiếu</label>
        <input id="showDate" name="showDate" type="date" min="${todayDate}" value="${escapedShowDate}" required>
      </div>
      <div class="field">
        <span class="field-label">Giờ bắt đầu *</span>
        <div id="showTime" class="showtime-time-checkboxes" data-current-time="${escapedShowTime}">
          <span class="muted">Chọn phim, phòng và ngày trước</span>
        </div>
        <small id="showtime-availability-message" role="status">Đang tải các giờ còn trống theo phòng đã chọn.</small>
        <small id="showtime-estimated-end"></small>
      </div>
    </div>
    <div class="form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/showtimes">Hủy</a>
      <button class="btn btn-primary" type="submit">Lưu suất chiếu</button>
    </div>
  </form>
</main>

<script src="${ctx}/assets/js/showtime-form.js?v=20261109-3" defer></script>
<%@ include file="../_footer.jspf" %>
