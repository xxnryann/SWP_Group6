<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Phim"/>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Danh sách phim</h1>
      <p class="sub">
        <c:choose>
          <c:when test="${showStatusFilter}">Lọc phim theo thể loại và trạng thái phát hành.</c:when>
          <c:otherwise>Danh sách phim đang chiếu và sắp chiếu tại rạp.</c:otherwise>
        </c:choose>
      </p>
    </div>
    <c:if test="${canManageMovies}">
      <a class="btn btn-primary" href="${ctx}/manage/movies">Quản lý phim</a>
    </c:if>
  </section>

  <form class="movie-filters panel" action="${ctx}/movies" method="get">
    <div class="field">
      <label for="movie-genre">Thể loại</label>
      <select id="movie-genre" name="genre">
        <option value="">Tất cả thể loại</option>
        <c:forEach var="genre" items="${genres}">
          <c:set var="escapedGenreId"><c:out value="${genre.genreId}"/></c:set>
          <option value="${escapedGenreId}" <c:if test="${selectedGenre == genre.genreId}">selected</c:if>><c:out value="${genre.genreName}"/></option>
        </c:forEach>
      </select>
    </div>
    <c:if test="${showStatusFilter}">
      <div class="field">
        <label for="movie-status">Trạng thái</label>
        <select id="movie-status" name="status">
          <option value="">Tất cả trạng thái</option>
          <option value="Upcoming" <c:if test="${selectedStatus == 'Upcoming'}">selected</c:if>>Sắp chiếu</option>
          <option value="NowShowing" <c:if test="${selectedStatus == 'NowShowing'}">selected</c:if>>Đang chiếu</option>
          <option value="Stopped" <c:if test="${selectedStatus == 'Stopped'}">selected</c:if>>Ngừng chiếu</option>
        </select>
      </div>
    </c:if>
    <button class="btn btn-primary movie-filter-submit" type="submit">Lọc phim</button>
  </form>

  <p class="movie-result-count">Tìm thấy <strong><c:out value="${moviePage.totalItems}"/></strong> phim.</p>
  <div class="movie-grid">
    <c:forEach var="movie" items="${movies}">
      <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
      <c:url var="editUrl" value="/manage/movies"><c:param name="id" value="${movie.movieId}"/></c:url>
      <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
      <c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
      <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
      <c:set var="escapedMovieTitle"><c:out value="${movie.title}"/></c:set>
      <article class="movie-card">
        <a class="movie-card-main" href="${escapedDetailUrl}">
          <div class="movie-poster">
            <c:choose>
              <c:when test="${not empty movie.posterDisplayUrl}">
                <c:choose>
                  <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${escapedMovieTitle}" loading="lazy"></c:when>
                  <c:otherwise><img src="${posterSrc}" alt="Poster phim ${escapedMovieTitle}" loading="lazy"></c:otherwise>
                </c:choose>
              </c:when>
              <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
            </c:choose>
            <span class="badge"><c:out value="${movie.ageRating}"/></span>
          </div>
          <div class="movie-card-info">
            <h2><c:out value="${movie.title}"/></h2>
            <p><c:out value="${movie.genres}"/></p>
            <p><c:out value="${movie.durationMinutes}"/> phút · <c:out value="${movie.releaseDate}"/></p>
            <span class="chip"><c:choose>
              <c:when test="${movie.status == 'NowShowing'}">Đang chiếu</c:when>
              <c:when test="${movie.status == 'Upcoming'}">Sắp chiếu</c:when>
              <c:otherwise>Ngừng chiếu</c:otherwise>
            </c:choose></span>
          </div>
        </a>
        <c:if test="${canManageMovies}">
          <a class="movie-card-edit" href="${escapedEditUrl}">Sửa phim</a>
        </c:if>
      </article>
    </c:forEach>
  </div>
  <c:if test="${empty movies}">
    <div class="panel movie-empty">Không tìm thấy phim phù hợp.</div>
  </c:if>

  <c:if test="${moviePage.totalPages > 1}">
    <nav class="movie-pagination" aria-label="Phân trang phim">
      <c:forEach var="pageNumber" begin="1" end="${moviePage.totalPages}">
        <c:url var="pageUrl" value="/movies">
          <c:param name="genre" value="${selectedGenre}"/>
          <c:param name="status" value="${selectedStatus}"/>
          <c:param name="page" value="${pageNumber}"/>
        </c:url>
        <c:set var="escapedPageUrl"><c:out value="${pageUrl}"/></c:set>
        <a class="page-number ${pageNumber == moviePage.page ? 'active' : ''}" href="${escapedPageUrl}" aria-current="${pageNumber == moviePage.page ? 'page' : 'false'}"><c:out value="${pageNumber}"/></a>
      </c:forEach>
    </nav>
  </c:if>
</main>

<%@ include file="_footer.jspf" %>
