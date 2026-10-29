<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Phim"/>
<%@ include file="_header.jspf" %>

<section class="mv-hero">
  <div class="container">
    <p class="eyebrow">CINESTAR CINEMAS</p>
    <h1>Danh sách phim</h1>
    <p class="mv-hero-sub">Phim đang chiếu và sắp ra mắt tại rạp. Chọn phim, chọn suất chiếu và đặt vé chỉ với vài bước.</p>
    <c:if test="${canManageMovies}">
      <a class="btn btn-cta" href="${ctx}/manage/movies">Quản lý phim</a>
    </c:if>
  </div>
</section>

<main class="container page mv-page">
  <c:if test="${showStatusFilter}">
    <nav class="mv-tabs" aria-label="Trạng thái phim">
      <c:url var="tabAll" value="/movies"><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabNow" value="/movies"><c:param name="status" value="NowShowing"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabSoon" value="/movies"><c:param name="status" value="Upcoming"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabEnded" value="/movies"><c:param name="status" value="Stopped"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <a class="mv-tab ${empty selectedStatus ? 'is-active' : ''}" href="${tabAll}">Tất cả</a>
      <a class="mv-tab ${selectedStatus == 'NowShowing' ? 'is-active' : ''}" href="${tabNow}">Phim đang chiếu</a>
      <a class="mv-tab ${selectedStatus == 'Upcoming' ? 'is-active' : ''}" href="${tabSoon}">Phim sắp chiếu</a>
      <c:if test="${not hideEndedFilter}">
        <a class="mv-tab ${selectedStatus == 'Stopped' ? 'is-active' : ''}" href="${tabEnded}">Đã kết thúc</a>
      </c:if>
    </nav>

    <div class="mv-genres" aria-label="Thể loại">
      <c:url var="genreAll" value="/movies"><c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if></c:url>
      <a class="mv-chip ${empty selectedGenre ? 'is-active' : ''}" href="${genreAll}">Mọi thể loại</a>
      <c:forEach var="genre" items="${genres}">
        <c:url var="genreUrl" value="/movies">
          <c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if>
          <c:param name="genre" value="${genre.genreId}"/>
        </c:url>
        <a class="mv-chip ${selectedGenre == genre.genreId ? 'is-active' : ''}" href="${genreUrl}"><c:out value="${genre.genreName}"/></a>
      </c:forEach>
    </div>
  </c:if>

  <c:choose>
    <c:when test="${empty movies}">
      <div class="movie-list-empty">
        <p>Không có phim nào phù hợp.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="mv-grid">
        <c:forEach var="movie" items="${movies}">
          <c:url var="detailUrl" value="/movies/detail">
            <c:param name="id" value="${movie.movieId}"/>
          </c:url>
          <article class="mv-card">
            <div class="mv-poster">
              <a href="${detailUrl}" class="mv-poster-link" aria-label="Xem chi tiết ${movie.title}">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="${movie.uploadedPoster ? ctx : ''}${movie.posterDisplayUrl}" alt="Poster phim ${movie.title}" loading="lazy">
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">Chưa có poster</div>
                  </c:otherwise>
                </c:choose>
              </a>
              <span class="mv-age"><c:out value="${movie.ageRating}"/></span>
              <c:choose>
                <c:when test="${movie.status == 'NowShowing'}"><span class="mv-flag mv-flag-now">Đang chiếu</span></c:when>
                <c:when test="${movie.status == 'Upcoming'}"><span class="mv-flag mv-flag-soon">Sắp chiếu</span></c:when>
                <c:otherwise><span class="mv-flag mv-flag-ended">Đã kết thúc</span></c:otherwise>
              </c:choose>
              <div class="mv-overlay">
                <a class="btn btn-outline btn-sm" href="${detailUrl}">Xem chi tiết</a>
              </div>
            </div>
            <div class="mv-body">
              <h3><a href="${detailUrl}"><c:out value="${movie.title}"/></a></h3>
              <p class="mv-meta">
                <c:if test="${not empty movie.genres}"><span>Thể loại: <strong><c:out value="${movie.genres}"/></strong></span></c:if>
                <span>Thời lượng: <strong><c:out value="${movie.durationMinutes}"/> phút</strong></span>
                <c:if test="${movie.status == 'Upcoming'}">
                  <span>Khởi chiếu: <strong><c:out value="${movie.releaseDate.dayOfMonth}"/>/<c:out value="${movie.releaseDate.monthValue}"/>/<c:out value="${movie.releaseDate.year}"/></strong></span>
                </c:if>
              </p>
              <c:choose>
                <c:when test="${canBuy and bookableIds.contains(movie.movieId)}">
                  <button type="button" class="btn btn-primary btn-block js-buy-ticket" data-movie-id="${movie.movieId}">Mua vé</button>
                </c:when>
                <c:otherwise>
                  <a class="btn btn-outline btn-block" href="${detailUrl}">Xem chi tiết</a>
                </c:otherwise>
              </c:choose>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</main>

<script src="${ctx}/assets/js/movie-showtimes.js" data-ctx="${ctx}"></script>
<%@ include file="_footer.jspf" %>
