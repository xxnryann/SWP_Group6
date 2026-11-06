<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý phim"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../_header.jspf" %>

<main class="page"><div class="container">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1>Quản lý phim</h1>
    </div>
    <div>
      <a class="btn btn-primary" href="${ctx}/manage/movies?action=new">Thêm phim</a>
      <a class="btn btn-outline" href="${ctx}/manage/genres">Quản lý thể loại</a>
    </div>
  </section>
  <form class="panel movie-manage-filters" method="get" action="${ctx}/manage/movies">
    <label>Trạng thái
      <select name="status">
        <option value="">Tất cả</option>
        <option value="NowShowing" ${selectedStatus == 'NowShowing' ? 'selected' : ''}>Đang chiếu</option>
        <option value="Upcoming" ${selectedStatus == 'Upcoming' ? 'selected' : ''}>Sắp chiếu</option>
        <option value="Stopped" ${selectedStatus == 'Stopped' ? 'selected' : ''}>Ngừng chiếu</option>
      </select>
    </label>
    <label>Thể loại
      <select name="genre">
        <option value="">Tất cả</option>
        <c:forEach var="genre" items="${genres}">
          <option value="${genre.genreId}" ${selectedGenre == genre.genreId ? 'selected' : ''}><c:out value="${genre.genreName}"/></option>
        </c:forEach>
      </select>
    </label>
    <button class="btn btn-primary btn-small" type="submit">Lọc</button>
    <a class="btn btn-outline btn-small" href="${ctx}/manage/movies">Xóa lọc</a>
  </form>
  <div class="dash-layout">
    <div>
  <div class="table-wrap">
    <table class="data movie-manage-table">
      <thead>
        <tr><th>Poster</th><th>Phim</th><th>Thời lượng</th><th>Khởi chiếu</th><th>Kết thúc</th><th>Trạng thái</th><th>Thao tác</th></tr>
      </thead>
      <tbody>
        <c:forEach var="movie" items="${movies}">
          <c:url var="editUrl" value="/manage/movies"><c:param name="id" value="${movie.movieId}"/></c:url>
          <c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
          <c:set var="escapedMovieId"><c:out value="${movie.movieId}"/></c:set>
          <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
          <c:set var="escapedMovieTitle"><c:out value="${movie.title}"/></c:set>
          <tr>
            <td>
              <c:choose>
                <c:when test="${not empty movie.posterDisplayUrl}">
                  <c:choose>
                    <c:when test="${movie.uploadedPoster}"><img class="movie-table-poster" src="${ctx}${posterSrc}" alt="Poster ${escapedMovieTitle}"></c:when>
                    <c:otherwise><img class="movie-table-poster" src="${posterSrc}" alt="Poster ${escapedMovieTitle}"></c:otherwise>
                  </c:choose>
                </c:when>
                <c:otherwise><span class="poster-placeholder compact">Chưa có poster</span></c:otherwise>
              </c:choose>
            </td>
            <td><strong><c:out value="${movie.title}"/></strong><br><span class="muted"><c:out value="${movie.genres}"/></span></td>
            <td><c:out value="${movie.durationMinutes}"/> phút</td>
            <td class="movie-date"><c:out value="${movie.releaseDateLabel}"/></td>
            <td class="movie-date"><c:out value="${movie.endDateLabel}"/></td>
            <td>
              <c:choose>
                <c:when test="${movie.status == 'NowShowing'}"><span class="movie-status movie-status-now">Đang chiếu</span></c:when>
                <c:when test="${movie.status == 'Upcoming'}"><span class="movie-status movie-status-soon">Sắp chiếu</span></c:when>
                <c:otherwise><span class="movie-status movie-status-stopped">Ngừng chiếu</span></c:otherwise>
              </c:choose>
            </td>
            <td class="movie-actions">
              <c:if test="${movie.status == 'Stopped'}">
                <a class="btn btn-soft btn-small" href="${escapedEditUrl}">Sửa</a>
              </c:if>
              <c:if test="${movie.status == 'Stopped'}">
                <a class="btn btn-cta btn-small" href="${ctx}/manage/movies?action=rerun&id=${escapedMovieId}">Chiếu lại</a>
              </c:if>
              <c:if test="${movie.status == 'Stopped'}">
                <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Xóa phim này? Chỉ xóa được khi không còn suất chiếu hoặc vé liên quan.');">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}">
                  <input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${escapedMovieId}">
                  <button class="btn btn-danger btn-small" type="submit">Xóa</button>
                </form>
              </c:if>
              <c:if test="${movie.status != 'Stopped'}">
                <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Ngừng chiếu phim này và hủy các suất tương lai chưa bán?');">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}">
                  <input type="hidden" name="action" value="stop">
                  <input type="hidden" name="id" value="${escapedMovieId}">
                  <button class="btn btn-outline btn-small" type="submit">Ngừng chiếu</button>
                </form>
              </c:if>
              <c:if test="${movie.activeTicketCount gt 0}">
                <a class="btn btn-danger btn-small" href="${ctx}/manage/movies?action=cancel-preview&id=${escapedMovieId}">Hủy &amp; hoàn tiền</a>
              </c:if>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty movies}"><tr><td colspan="7">Chưa có dữ liệu phim.</td></tr></c:if>
      </tbody>
    </table>
  </div>
  <c:if test="${moviePage.totalPages > 1}">
    <nav class="movie-pagination" aria-label="Phân trang phim quản lý">
      <c:forEach var="pageNumber" begin="1" end="${moviePage.totalPages}">
        <c:url var="managePageUrl" value="/manage/movies"><c:param name="page" value="${pageNumber}"/><c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
        <c:set var="escapedManagePageUrl"><c:out value="${managePageUrl}"/></c:set>
        <a class="page-number ${pageNumber == moviePage.page ? 'active' : ''}" href="${escapedManagePageUrl}"><c:out value="${pageNumber}"/></a>
      </c:forEach>
    </nav>
  </c:if>
    </div>
  </div>
</div></main>

<%@ include file="../_footer.jspf" %>
