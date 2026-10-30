<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý lịch chiếu"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1>Quản lý lịch chiếu</h1>
    </div>
    <div class="movie-actions movie-actions-row">
      <a class="btn btn-primary" href="${ctx}/manage/showtimes?action=new">Thêm suất chiếu</a>
      <a class="btn btn-soft" href="${ctx}/manage/showtimes?action=generate">Sinh lịch tự động</a>
    </div>
  </section>

  <form class="panel st-search" method="get" action="${ctx}/manage/showtimes">
    <div class="field">
      <label for="f-q">Phim</label>
      <input id="f-q" type="search" name="q" value="${filterQ}" placeholder="Tên phim...">
    </div>
    <div class="field">
      <label for="f-date">Ngày chiếu</label>
      <input id="f-date" type="date" name="date" value="${filterDate}">
    </div>
    <div class="field">
      <label for="f-from">Giờ từ</label>
      <input id="f-from" type="time" name="timeFrom" value="${filterTimeFrom}">
    </div>
    <div class="field">
      <label for="f-to">Giờ đến</label>
      <input id="f-to" type="time" name="timeTo" value="${filterTimeTo}">
    </div>
    <div class="st-search-actions">
      <button class="btn btn-primary" type="submit">Tìm kiếm</button>
      <c:if test="${isFiltered}"><a class="btn btn-outline" href="${ctx}/manage/showtimes">Xóa lọc</a></c:if>
    </div>
  </form>
  <c:if test="${isFiltered}"><p class="sub">Tìm thấy <strong>${showtimes.size()}</strong> suất chiếu phù hợp.</p></c:if>

  <div class="table-wrap">
    <table class="data">
      <thead>
        <tr><th>Phim</th><th>Ngày chiếu</th><th>Thời gian lịch chiếu</th><th>Phòng chiếu</th><th>Trạng thái</th><th>Thao tác</th></tr>
      </thead>
      <tbody>
        <c:forEach var="showtime" items="${showtimes}">
          <c:url var="editUrl" value="/manage/showtimes"><c:param name="id" value="${showtime.showtimeId}"/></c:url>
          <c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
          <c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
          <tr>
            <td><strong><c:out value="${showtime.movieTitle}"/></strong></td>
            <td><c:out value="${showtime.scheduleDateDisplay}"/></td>
            <td><c:out value="${showtime.scheduleTimeDisplay}"/></td>
            <td><c:out value="${showtime.roomName}"/></td>
            <td><c:choose>
              <c:when test="${showtime.managementStatus == 'Scheduled'}">Đang mở</c:when>
              <c:when test="${showtime.managementStatus == 'Pending'}">Chờ</c:when>
              <c:when test="${showtime.managementStatus == 'Maintenance'}">Bảo trì</c:when>
              <c:otherwise>Đã hủy</c:otherwise>
            </c:choose></td>
            <td class="movie-actions">
              <a class="btn btn-soft btn-small" href="${escapedEditUrl}">Sửa</a>
              <form method="post" action="${ctx}/manage/showtimes" onsubmit="return confirm('Bạn có chắc muốn xóa suất chiếu này?');">
                <input type="hidden" name="_csrf" value="${escapedCsrf}">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${escapedId}">
                <button class="btn btn-danger btn-small" type="submit">Xóa</button>
              </form>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty showtimes}"><tr><td colspan="6"><c:choose><c:when test="${isFiltered}">Không có suất chiếu nào khớp bộ lọc.</c:when><c:otherwise>Chưa có suất chiếu. Hãy thêm suất chiếu đầu tiên.</c:otherwise></c:choose></td></tr></c:if>
      </tbody>
    </table>
  </div>
    </div>
  </div>
</div></main>

<%@ include file="_footer.jspf" %>


