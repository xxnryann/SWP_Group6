<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'Thêm suất chiếu' : 'Sửa suất chiếu'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="showDateValue" value="${empty showtime.inputDate ? defaultDate : showtime.inputDate}"/>
<c:set var="escapedShowDate"><c:out value="${showDateValue}"/></c:set>
<c:set var="escapedShowTime"><c:out value="${showtime.inputTime}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/showtimes">${ic.chevronLeft}Lịch chiếu</a><h1><c:out value="${pageTitle}"/></h1><p>Chọn phim, phòng và ngày; hệ thống chỉ hiện các giờ còn trống trong khung 09:00 – 23:00.</p></div>
</div>
<form class="card" id="showtime-form" method="post" action="${ctx}/manage/showtimes" data-availability-url="${ctx}/manage/showtimes">
  <div class="card-body form-grid">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <c:if test="${showtime.showtimeId > 0}"><input type="hidden" name="id" value="${escapedId}"></c:if>
    <div class="field">
      <label for="movieId">Phim<span class="req">*</span></label>
      <select id="movieId" name="movieId" required>
        <option value="">Chọn phim</option>
        <c:forEach var="movie" items="${movies}">
          <option value="<c:out value='${movie.movieId}'/>" data-duration="<c:out value='${movie.durationMinutes}'/>" ${showtime.movieId == movie.movieId ? 'selected' : ''}><c:out value="${movie.title}"/> (<c:out value="${movie.durationMinutes}"/> phút)</option>
        </c:forEach>
      </select>
    </div>
    <div class="field">
      <label for="showDate">Ngày chiếu<span class="req">*</span></label>
      <input id="showDate" name="showDate" type="date" min="${todayDate}" value="${escapedShowDate}" required>
    </div>
    <div class="field full">
      <span class="label">Phòng chiếu<span class="req">*</span></span>
      <div id="roomName" class="pill-checks">
        <c:forEach var="room" items="${rooms}">
          <label class="check"><input type="checkbox" name="roomName" value="<c:out value='${room}'/>" ${showtime.roomName == room ? 'checked' : ''}><span><c:out value="${room}"/></span></label>
        </c:forEach>
      </div>
    </div>
    <div class="field full">
      <span class="label">Giờ bắt đầu<span class="req">*</span></span>
      <div id="showTime" class="pill-checks" data-current-time="${escapedShowTime}"><span class="muted">Chọn phim, phòng và ngày trước</span></div>
      <span class="hint" id="showtime-availability-message" role="status">Đang tải các giờ còn trống theo phòng đã chọn.</span>
      <span class="hint fw-600" id="showtime-estimated-end"></span>
    </div>
  </div>
  <div class="card-foot">
    <a class="btn" href="${ctx}/manage/showtimes">Hủy</a>
    <button class="btn btn-primary" type="submit">${ic.check}Lưu suất chiếu</button>
  </div>
</form>
<script src="${ctx}/assets/js/showtime-form.js?v=20261109-3" defer></script>
<%@ include file="../layout/bottom.jspf" %>
