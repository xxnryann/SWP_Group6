<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý phim"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<style>
  .thumb { width: 46px; height: 68px; border-radius: var(--r-xs); object-fit: cover; background: var(--surface-3); display: grid; place-items: center; color: var(--subtle); flex: none; }
  .thumb svg { width: 20px; height: 20px; }
  .movie-actions { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 6px; }
</style>
<div class="page-head">
  <div><h1>Quản lý phim</h1><p>Thêm phim mới, chỉnh thông tin, ngừng chiếu hoặc hủy phim kèm hoàn tiền.</p></div>
  <div class="cluster">
    <a class="btn" href="${ctx}/manage/genres">${ic.list}Thể loại</a>
    <a class="btn btn-primary" href="${ctx}/manage/movies?action=new">${ic.plus}Thêm phim</a>
  </div>
</div>

<section class="card">
  <form class="toolbar" method="get" action="${ctx}/manage/movies">
    <div class="field">
      <label for="fStatus">Trạng thái</label>
      <select id="fStatus" name="status">
        <option value="">Tất cả trạng thái</option>
        <option value="NowShowing" ${selectedStatus == 'NowShowing' ? 'selected' : ''}>Đang chiếu</option>
        <option value="Upcoming" ${selectedStatus == 'Upcoming' ? 'selected' : ''}>Sắp chiếu</option>
        <option value="Stopped" ${selectedStatus == 'Stopped' ? 'selected' : ''}>Ngừng chiếu</option>
      </select>
    </div>
    <div class="field">
      <label for="fGenre">Thể loại</label>
      <select id="fGenre" name="genre">
        <option value="">Tất cả thể loại</option>
        <c:forEach var="genre" items="${genres}">
          <option value="${genre.genreId}" ${selectedGenre == genre.genreId ? 'selected' : ''}><c:out value="${genre.genreName}"/></option>
        </c:forEach>
      </select>
    </div>
    <button class="btn btn-primary" type="submit">${ic.filter}Lọc</button>
    <c:if test="${not empty selectedStatus or not empty selectedGenre}"><a class="btn btn-ghost" href="${ctx}/manage/movies">Xóa lọc</a></c:if>
  </form>

  <div class="table-wrap">
    <table class="table">
      <thead><tr><th>Phim</th><th>Thời lượng</th><th>Khởi chiếu</th><th>Kết thúc</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
      <tbody>
        <c:forEach var="movie" items="${movies}">
          <c:url var="editUrl" value="/manage/movies"><c:param name="id" value="${movie.movieId}"/></c:url>
          <c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
          <c:set var="escapedMovieId"><c:out value="${movie.movieId}"/></c:set>
          <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
          <tr>
            <td>
              <div class="person">
                <c:choose>
                  <c:when test="${not empty movie.posterDisplayUrl}"><img class="thumb" src="${movie.uploadedPoster ? ctx : ''}${posterSrc}" alt=""></c:when>
                  <c:otherwise><span class="thumb">${ic.film}</span></c:otherwise>
                </c:choose>
                <div style="min-width:0">
                  <a class="cell-main" href="${ctx}/movies/detail?id=${escapedMovieId}" style="color:var(--ink)"><c:out value="${movie.title}"/></a>
                  <span class="cell-sub"><span class="age age-${movie.ageRating}" style="height:18px;min-width:26px;font-size:10px"><c:out value="${movie.ageRating}"/></span> <c:out value="${movie.genres}"/></span>
                </div>
              </div>
            </td>
            <td class="nowrap"><c:out value="${movie.durationMinutes}"/> phút</td>
            <td class="nowrap"><c:out value="${movie.releaseDateLabel}"/></td>
            <td class="nowrap"><c:out value="${movie.endDateLabel}"/></td>
            <td>
              <c:choose>
                <c:when test="${movie.status == 'NowShowing'}"><span class="badge badge-success badge-dot">Đang chiếu</span></c:when>
                <c:when test="${movie.status == 'Upcoming'}"><span class="badge badge-accent badge-dot">Sắp chiếu</span></c:when>
                <c:otherwise><span class="badge badge-dot">Ngừng chiếu</span></c:otherwise>
              </c:choose>
            </td>
            <td>
              <div class="movie-actions">
                <c:if test="${movie.status == 'Stopped'}">
                  <a class="btn btn-xs btn-soft" href="${escapedEditUrl}">${ic.edit}Sửa</a>
                  <a class="btn btn-xs btn-primary" href="${ctx}/manage/movies?action=rerun&id=${escapedMovieId}">${ic.refresh}Chiếu lại</a>
                  <form method="post" action="${ctx}/manage/movies" data-confirm="Xóa phim này? Chỉ xóa được khi không còn suất chiếu hoặc vé liên quan.">
                    <input type="hidden" name="_csrf" value="${escapedCsrf}">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${escapedMovieId}">
                    <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button>
                  </form>
                </c:if>
                <c:if test="${movie.status != 'Stopped'}">
                  <form method="post" action="${ctx}/manage/movies" data-confirm="Ngừng chiếu phim này và hủy các suất tương lai chưa bán?">
                    <input type="hidden" name="_csrf" value="${escapedCsrf}">
                    <input type="hidden" name="action" value="stop">
                    <input type="hidden" name="id" value="${escapedMovieId}">
                    <button class="btn btn-xs" type="submit">Ngừng chiếu</button>
                  </form>
                </c:if>
                <c:if test="${movie.activeTicketCount gt 0}">
                  <a class="btn btn-xs btn-danger" href="${ctx}/manage/movies?action=cancel-preview&id=${escapedMovieId}">Hủy &amp; hoàn tiền</a>
                </c:if>
              </div>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty movies}"><tr><td colspan="6"><div class="empty"><div class="empty-icon">${ic.film}</div><p>Chưa có dữ liệu phim.</p></div></td></tr></c:if>
      </tbody>
    </table>
  </div>
</section>
<c:if test="${moviePage.totalPages > 1}">
  <nav class="pager" aria-label="Phân trang phim">
    <c:forEach var="pageNumber" begin="1" end="${moviePage.totalPages}">
      <c:url var="managePageUrl" value="/manage/movies"><c:param name="page" value="${pageNumber}"/><c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <a class="${pageNumber == moviePage.page ? 'active' : ''}" href="<c:out value='${managePageUrl}'/>"><c:out value="${pageNumber}"/></a>
    </c:forEach>
  </nav>
</c:if>
<%@ include file="../layout/bottom.jspf" %>
