<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý phim"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1>Quản lý phim</h1>
      <p class="sub">Thêm, cập nhật, ngừng chiếu hoặc xóa phim.</p>
    </div>
    <a class="btn btn-primary" href="${ctx}/manage/movies?action=new">Thêm phim</a>
  </section>
  <div class="table-wrap">
    <table class="data movie-manage-table">
      <thead>
        <tr><th>Poster</th><th>Phim</th><th>Thời lượng</th><th>Khởi chiếu</th><th>Trạng thái</th><th>Thao tác</th></tr>
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
            <td><c:out value="${movie.releaseDate}"/></td>
            <td><c:out value="${movie.status}"/></td>
            <td class="movie-actions">
              <a class="btn btn-soft btn-small" href="${escapedEditUrl}">Sửa</a>
              <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Bạn có chắc muốn xóa phim này? Phim có suất chiếu sẽ không thể xóa.');">
                <input type="hidden" name="_csrf" value="${escapedCsrf}">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${escapedMovieId}">
                <button class="btn btn-danger btn-small" type="submit">Xóa</button>
              </form>
              <c:if test="${movie.status != 'Stopped'}">
                <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Ngừng chiếu phim này và hủy các suất tương lai chưa bán?');">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}">
                  <input type="hidden" name="action" value="stop">
                  <input type="hidden" name="id" value="${escapedMovieId}">
                  <button class="btn btn-outline btn-small" type="submit">Ngừng chiếu</button>
                </form>
              </c:if>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty movies}"><tr><td colspan="6">Chưa có dữ liệu phim.</td></tr></c:if>
      </tbody>
    </table>
  </div>
  <c:if test="${moviePage.totalPages > 1}">
    <nav class="movie-pagination" aria-label="Phân trang phim quản lý">
      <c:forEach var="pageNumber" begin="1" end="${moviePage.totalPages}">
        <c:url var="managePageUrl" value="/manage/movies"><c:param name="page" value="${pageNumber}"/></c:url>
        <c:set var="escapedManagePageUrl"><c:out value="${managePageUrl}"/></c:set>
        <a class="page-number ${pageNumber == moviePage.page ? 'active' : ''}" href="${escapedManagePageUrl}"><c:out value="${pageNumber}"/></a>
      </c:forEach>
    </nav>
  </c:if>
    </div>
  </div>
</div></main>

<%@ include file="_footer.jspf" %>
