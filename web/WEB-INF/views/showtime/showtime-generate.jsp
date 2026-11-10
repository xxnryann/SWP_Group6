<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Sinh lịch chiếu tự động"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedDate"><c:out value="${defaultDate}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/showtimes">${ic.chevronLeft}Lịch chiếu</a><h1>Sinh lịch chiếu tự động</h1><p>Chọn ngày, phòng và phim; hệ thống tự xếp các suất nối tiếp trong giờ mở cửa.</p></div>
</div>

<section class="card mb-24">
  <%-- Đổi ngày thì nạp lại danh sách phim đang phát hành vào đúng ngày đó --%>
  <form class="toolbar" style="border-bottom:0" method="get" action="${ctx}/manage/showtimes">
    <input type="hidden" name="action" value="generate">
    <div class="field" style="flex:0 1 240px"><label for="date-pick">Ngày cần xếp lịch</label><input id="date-pick" type="date" name="date" min="${todayDate}" value="${escapedDate}" required></div>
    <button class="btn" type="submit">${ic.refresh}Tải phim của ngày này</button>
  </form>
</section>

<form class="card" method="post" action="${ctx}/manage/showtimes" data-loading>
  <div class="card-body form-grid">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="generate">
    <input type="hidden" name="showDate" value="${escapedDate}">
    <div class="field">
      <span class="label">Ngày xếp lịch</span>
      <span class="badge badge-brand" style="align-self:flex-start;font-size:14px">${ic.calendar}<c:out value="${defaultDate}"/></span>
    </div>
    <div class="field">
      <label for="openTime">Giờ bắt đầu suất đầu tiên</label>
      <input id="openTime" name="openTime" type="time" step="300" value="${openTime}" min="${openTime}" max="${closeTime}">
    </div>
    <div class="field full">
      <span class="label">Phòng chiếu</span>
      <div class="pill-checks">
        <c:forEach var="room" items="${rooms}">
          <label class="check"><input type="checkbox" name="roomNames" value="<c:out value='${room}'/>" checked><span><c:out value="${room}"/></span></label>
        </c:forEach>
        <c:if test="${empty rooms}"><span class="muted">Chưa có phòng chiếu đang hoạt động.</span></c:if>
      </div>
    </div>
    <div class="field full">
      <span class="label">Phim đang phát hành vào ngày này</span>
      <div class="pill-checks">
        <c:forEach var="movie" items="${movies}">
          <label class="check"><input type="checkbox" name="movieIds" value="<c:out value='${movie.movieId}'/>" checked><span><c:out value="${movie.title}"/> · <c:out value="${movie.durationMinutes}"/>'</span></label>
        </c:forEach>
        <c:if test="${empty movies}"><span class="muted">Không có phim nào đang phát hành vào ngày này.</span></c:if>
      </div>
    </div>
  </div>
  <div class="card-foot">
    <a class="btn" href="${ctx}/manage/showtimes">Hủy</a>
    <button class="btn btn-primary" type="submit" ${empty rooms or empty movies ? 'disabled' : ''}>${ic.sparkles}Sinh lịch</button>
  </div>
</form>
<%@ include file="../layout/bottom.jspf" %>
