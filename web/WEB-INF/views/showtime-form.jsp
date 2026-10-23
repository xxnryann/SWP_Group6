<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'Thêm suất chiếu' : 'Sửa suất chiếu'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="escapedRoom"><c:out value="${showtime.roomName}"/></c:set>
<c:set var="escapedStartsAt"><c:out value="${showtime.inputDateTime}"/></c:set>
<c:set var="escapedPrice"><c:out value="${showtime.ticketPrice}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1><c:out value="${pageTitle}"/></h1>
      <p class="sub">Giờ chiếu kết thúc được tính theo thời lượng phim.</p>
    </div>
  </section>
  <form class="panel showtime-form" method="post" action="${ctx}/manage/showtimes">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <c:if test="${showtime.showtimeId > 0}"><input type="hidden" name="id" value="${escapedId}"></c:if>
    <div class="field">
      <label for="movieId">Phim</label>
      <select id="movieId" name="movieId" required>
        <option value="">Chọn phim</option>
        <c:forEach var="movie" items="${movies}">
          <option value="<c:out value='${movie.movieId}'/>" <c:if test="${showtime.movieId == movie.movieId}">selected</c:if>>
            <c:out value="${movie.title}"/> (<c:out value="${movie.durationMinutes}"/> phút)
          </option>
        </c:forEach>
      </select>
    </div>
    <div class="showtime-form-grid">
      <div class="field">
        <label for="roomName">Phòng chiếu</label>
        <input id="roomName" name="roomName" type="text" maxlength="50" value="${escapedRoom}" required>
      </div>
      <div class="field">
        <label for="startsAt">Ngày và giờ bắt đầu</label>
        <input id="startsAt" name="startsAt" type="datetime-local" value="${escapedStartsAt}" required>
      </div>
      <div class="field">
        <label for="ticketPrice">Giá vé (VNĐ)</label>
        <input id="ticketPrice" name="ticketPrice" type="number" min="0" max="99999999.99" step="1000" value="${escapedPrice}" required>
      </div>
      <div class="field">
        <label for="status">Trạng thái</label>
        <select id="status" name="status">
          <option value="Scheduled" <c:if test="${showtime.status == 'Scheduled'}">selected</c:if>>Đang mở</option>
          <option value="Cancelled" <c:if test="${showtime.status == 'Cancelled'}">selected</c:if>>Đã hủy</option>
        </select>
      </div>
    </div>
    <div class="form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/showtimes">Hủy</a>
      <button class="btn btn-primary" type="submit">Lưu suất chiếu</button>
    </div>
  </form>
</main>

<%@ include file="_footer.jspf" %>
