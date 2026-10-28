<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'Thêm suất chiếu' : 'Sửa suất chiếu'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="showDateValue" value="${empty showtime.inputDate ? defaultDate : showtime.inputDate}"/>
<c:set var="escapedShowDate"><c:out value="${showDateValue}"/></c:set>
<c:set var="escapedStartTime"><c:out value="${showtime.inputTime}"/></c:set>
<c:set var="escapedEndTime"><c:out value="${showtime.inputEndTime}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1><c:out value="${pageTitle}"/></h1>
      <p class="sub">Chọn giờ bắt đầu và kết thúc trong khoảng 07:00–24:00. Thời gian phải theo mốc 5 phút, đủ thời lượng phim và không trùng lịch trong phòng.</p>
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
        <label for="roomName">Phòng chiếu</label>
        <select id="roomName" name="roomName" required>
          <option value="">Chọn phòng</option>
          <c:forEach var="room" items="${rooms}">
            <option value="<c:out value='${room}'/>" <c:if test="${showtime.roomName == room}">selected</c:if>><c:out value="${room}"/></option>
          </c:forEach>
        </select>
      </div>
      <div class="field">
        <label for="showDate">Ngày chiếu</label>
        <input id="showDate" name="showDate" type="date" min="${todayDate}" value="${escapedShowDate}" required>
      </div>
      <div class="field">
        <label for="startTime">Thời gian bắt đầu</label>
        <select id="startTime" name="startTime" required data-current-time="${escapedStartTime}">
          <option value="">Chọn phim, phòng và ngày trước</option>
        </select>
        <small id="showtime-availability-message" role="status">Chọn phim, phòng và ngày để tải giờ còn trống.</small>
      </div>
      <div class="field">
        <label for="endTime">Thời gian kết thúc</label>
        <select id="endTime" name="endTime" required data-current-time="${escapedEndTime}">
          <option value="">Chọn giờ bắt đầu trước</option>
        </select>
        <small id="showtime-duration-message"></small>
      </div>
    </div>
    <div class="form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/showtimes">Hủy</a>
      <button class="btn btn-primary" type="submit">Lưu suất chiếu</button>
    </div>
  </form>
</main>

<script src="${ctx}/assets/js/showtime-form.js" defer></script>
<%@ include file="_footer.jspf" %>
