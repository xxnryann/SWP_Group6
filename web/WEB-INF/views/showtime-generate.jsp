<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Sinh lịch chiếu tự động"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedDate"><c:out value="${defaultDate}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1>Sinh lịch chiếu tự động</h1>
      <p class="sub">Chọn ngày, phòng và phim; hệ thống tự xếp suất liên tiếp cho từng phòng (giờ mở cửa
        <c:out value="${openTime}"/>, suất cuối kết thúc trước <c:out value="${closeTime}"/>, nghỉ
        <c:out value="${turnoverMinutes}"/> phút giữa các suất). Các suất đã có trong ngày được giữ nguyên.</p>
    </div>
  </section>

  <%-- Đổi ngày thì nạp lại danh sách phim đang phát hành vào đúng ngày đó --%>
  <form class="panel showtime-filters" method="get" action="${ctx}/manage/showtimes">
    <input type="hidden" name="action" value="generate">
    <div class="field">
      <label for="date-pick">Ngày cần xếp lịch</label>
      <input id="date-pick" type="date" name="date" min="${todayDate}" value="${escapedDate}" required>
    </div>
    <button class="btn btn-outline" type="submit">Tải phim của ngày này</button>
  </form>

  <form class="panel movie-form" method="post" action="${ctx}/manage/showtimes">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="generate">
    <input type="hidden" name="showDate" value="${escapedDate}">

    <div class="movie-form-grid">
      <div class="field">
        <label for="openTime">Giờ bắt đầu suất đầu tiên</label>
        <input id="openTime" name="openTime" type="time" step="900" value="${openTime}"
               min="${openTime}" max="${closeTime}">
      </div>
      <div class="field">
        <span class="field-label">Ngày xếp lịch</span>
        <p><strong><c:out value="${defaultDate}"/></strong></p>
      </div>

      <div class="field movie-form-full">
        <span class="field-label">Phòng chiếu</span>
        <div class="genre-checkboxes">
          <c:forEach var="room" items="${rooms}">
            <label class="check">
              <input type="checkbox" name="roomNames" value="<c:out value='${room}'/>" checked>
              <span><c:out value="${room}"/></span>
            </label>
          </c:forEach>
          <c:if test="${empty rooms}"><span class="muted">Chưa có phòng chiếu đang hoạt động.</span></c:if>
        </div>
      </div>

      <div class="field movie-form-full">
        <span class="field-label">Phim (đang phát hành vào ngày này)</span>
        <div class="genre-checkboxes">
          <c:forEach var="movie" items="${movies}">
            <label class="check">
              <input type="checkbox" name="movieIds" value="<c:out value='${movie.movieId}'/>" checked>
              <span><c:out value="${movie.title}"/> (<c:out value="${movie.durationMinutes}"/> phút)</span>
            </label>
          </c:forEach>
          <c:if test="${empty movies}"><span class="muted">Không có phim nào đang phát hành vào ngày này.</span></c:if>
        </div>
      </div>
    </div>

    <div class="form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/showtimes">Hủy</a>
      <button class="btn btn-primary" type="submit" <c:if test="${empty rooms or empty movies}">disabled</c:if>>Sinh lịch</button>
    </div>
  </form>
</main>
<%@ include file="_footer.jspf" %>
