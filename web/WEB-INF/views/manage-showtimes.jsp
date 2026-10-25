<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý lịch chiếu"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1>Quản lý lịch chiếu</h1>
      <p class="sub">Tạo, cập nhật hoặc xóa suất chiếu theo 5 khung giờ cố định. Mỗi phòng chỉ có một suất trong mỗi khung.</p>
    </div>
    <a class="btn btn-primary" href="${ctx}/manage/showtimes?action=new">Thêm suất chiếu</a>
  </section>

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
        <c:if test="${empty showtimes}"><tr><td colspan="6">Chưa có suất chiếu. Hãy thêm suất chiếu đầu tiên.</td></tr></c:if>
      </tbody>
    </table>
  </div>
</main>

<%@ include file="_footer.jspf" %>
