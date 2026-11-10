<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'Thêm suất chiếu' : 'Sửa suất chiếu'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="showDateValue" value="${empty showtime.inputDate ? defaultDate : showtime.inputDate}"/>
<c:set var="escapedShowDate"><c:out value="${showDateValue}"/></c:set>
<c:set var="escapedShowTime"><c:out value="${showtime.inputTime}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/showtimes">${ic.chevronLeft}Lịch chiếu</a><h1><c:out value="${pageTitle}"/></h1><p>Suất chiếu trong khung 07:00 – 23:55; giữa 2 suất cùng phòng nghỉ tối thiểu 15 phút để dọn phòng (làm tròn lên mốc 5 phút).</p></div>
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
      <span class="label">Giờ bắt đầu theo từng phòng<span class="req">*</span></span>
      <c:set var="escapedCurrentRoom"><c:out value="${showtime.roomName}"/></c:set>
      <div id="showTime" class="showtime-room-times" data-current-time="${escapedShowTime}" data-current-room="${escapedCurrentRoom}">
        <p class="muted">Chọn phim, phòng và ngày để xem giờ trống của từng phòng.</p>
      </div>
      <span class="hint" id="showtime-availability-message" role="status"></span>
    </div>
    <section class="room-schedule full" id="room-schedule" aria-labelledby="room-schedule-title">
      <div class="room-schedule-head">
        <h2 id="room-schedule-title">Lịch các phòng <span id="room-schedule-date"></span></h2>
        <ul class="room-schedule-legend">
          <li><i class="tl-swatch tl-busy"></i>Đã có suất</li>
          <li><i class="tl-swatch tl-free"></i>Trống</li>
          <li><i class="tl-swatch tl-past-show"></i>Suất đã qua</li>
          <li><i class="tl-swatch tl-past"></i>Giờ đã qua</li>
          <li><i class="tl-swatch tl-candidate-swatch"></i>Suất đang chọn</li>
        </ul>
      </div>
      <p class="muted" id="room-schedule-status">Đang tải lịch phòng…</p>
      <div class="room-schedule-scroll"><div class="room-schedule-board" id="room-schedule-board"></div></div>
    </section>
  </div>
  <div class="card-foot">
    <a class="btn" href="${ctx}/manage/showtimes">Hủy</a>
    <button class="btn btn-primary" type="submit">${ic.check}Lưu suất chiếu</button>
  </div>
</form>
<link rel="stylesheet" href="${ctx}/assets/css/room-schedule.css?v=20261110-3">
<link rel="stylesheet" href="${ctx}/assets/css/showtime-form.css?v=20261110-5">
<script src="${ctx}/assets/js/room-schedule.js?v=20261110-1" defer></script>
<script src="${ctx}/assets/js/showtime-form.js?v=20261110-11" defer></script>
<%@ include file="../layout/bottom.jspf" %>
