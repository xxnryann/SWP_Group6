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
          <c:otherwise>Danh sách phim đang chiếu tại rạp.</c:otherwise>
        </c:choose>
      </p>
    </div>
    <c:if test="${canManageMovies}">
      <a class="btn btn-primary" href="${ctx}/manage/movies">Quản lý phim</a>
    </c:if>
  </section>

  <c:if test="${showStatusFilter}">
    <form class="panel movie-filters" method="get" action="${ctx}/movies">
      <div class="field">
        <label for="status-filter">Trạng thái</label>
        <select id="status-filter" name="status">
          <option value="">Tất cả</option>
          <option value="NOW_SHOWING" <c:if test="${selectedStatus == 'NOW_SHOWING'}">selected</c:if>>Đang chiếu</option>
          <option value="UPCOMING" <c:if test="${selectedStatus == 'UPCOMING'}">selected</c:if>>Sắp chiếu</option>
          <option value="ENDED" <c:if test="${selectedStatus == 'ENDED'}">selected</c:if>>Đã kết thúc</option>
        </select>
      </div>
      <div class="field">
        <label for="genre-filter">Thể loại</label>
        <select id="genre-filter" name="genre">
          <option value="">Tất cả</option>
          <c:forEach var="genre" items="${genres}">
            <option value="${genre.genreId}" <c:if test="${selectedGenre == genre.genreId}">selected</c:if>><c:out value="${genre.name}"/></option>
          </c:forEach>
        </select>
      </div>
      <button class="btn btn-cta" type="submit">Lọc</button>
    </form>
  </c:if>

  <c:choose>
    <c:when test="${empty movies}">
      <div class="movie-list-empty">
        <p>Không có phim nào.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="movie-list">
        <c:forEach var="movie" items="${movies}">
          <c:url var="detailUrl" value="/movies/detail">
            <c:param name="id" value="${movie.movieId}"/>
          </c:url>
          <article class="movie-card">
            <a href="${detailUrl}" class="movie-card-poster">
              <c:choose>
                <c:when test="${not empty movie.posterUrl}">
                  <img src="${movie.posterUrl}" alt="Poster phim ${movie.title}" loading="lazy">
                </c:when>
                <c:otherwise>
                  <div class="poster-placeholder">Chưa có poster</div>
                </c:otherwise>
              </c:choose>
              <span class="badge"><c:out value="${movie.ageRating}"/></span>
            </a>
            <div class="movie-card-content">
              <h3><a href="${detailUrl}"><c:out value="${movie.title}"/></a></h3>
              <p class="meta">
                <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/> · </c:if>
                <c:out value="${movie.durationMinutes}"/> phút
              </p>
              <c:choose>
                <c:when test="${movie.status == 'NOW_SHOWING'}">
                  <p class="status status-now"><strong>Đang chiếu</strong></p>
                </c:when>
                <c:when test="${movie.status == 'UPCOMING'}">
                  <p class="status status-upcoming"><strong>Sắp chiếu</strong></p>
                </c:when>
                <c:otherwise>
                  <p class="status status-ended"><strong>Đã kết thúc</strong></p>
                </c:otherwise>
              </c:choose>
              <a class="btn btn-primary btn-sm" href="${detailUrl}">Xem chi tiết</a>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="_footer.jspf" %>