<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Trang chủ"/>
<%@ include file="_header.jspf" %>
<main>
  <section class="hero-home">
    <div class="container">
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Đặt vé xem phim<br>nhanh chóng, tiện lợi</h1>
      <p class="lead">Chọn rạp, chọn suất chiếu và tận hưởng những bộ phim bom tấn với âm thanh Dolby Atmos.</p>
      <c:if test="${empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/register">Đăng ký thành viên</a>
        <a class="btn btn-outline" href="${pageContext.request.contextPath}/login">Đăng nhập</a>
      </c:if>
      <c:if test="${not empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/account/profile">Tài khoản của tôi</a>
      </c:if>
    </div>
  </section>

  <%-- Danh sách phim lấy trực tiếp từ database: đang chiếu và sắp chiếu. --%>
  <section class="page home-movies">
    <div class="container">
      <div class="home-movies-heading">
        <div>
          <p class="eyebrow">CINESTAR CINEMAS</p>
          <h2>Lịch phim tại rạp</h2>
        </div>
        <a class="btn btn-outline" href="${ctx}/showtimes">Xem lịch chiếu</a>
      </div>

      <div class="home-movie-tabs" role="tablist" aria-label="Phim theo trạng thái phát hành">
        <button type="button" class="home-movie-tab is-active" role="tab" id="tab-now-showing"
                aria-controls="panel-now-showing" aria-selected="true" data-tab-target="panel-now-showing">
          Phim đang chiếu
        </button>
        <button type="button" class="home-movie-tab" role="tab" id="tab-upcoming"
                aria-controls="panel-upcoming" aria-selected="false" tabindex="-1" data-tab-target="panel-upcoming">
          Phim sắp chiếu
        </button>
      </div>

      <div class="home-movie-panel is-active" role="tabpanel" id="panel-now-showing"
           aria-labelledby="tab-now-showing" tabindex="0">
        <c:choose>
          <c:when test="${empty nowShowingMovies}">
            <div class="panel movie-empty">
              <h3>Chưa có phim đang chiếu</h3>
              <p>Hiện rạp chưa có phim nào đang được phát hành.</p>
            </div>
          </c:when>
          <c:otherwise>
            <div class="home-movie-grid">
              <c:forEach var="item" items="${nowShowingMovies}">
                <c:set var="movie" value="${item.movie}"/>
                <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
                <c:set var="movieTitle"><c:out value="${movie.title}"/></c:set>
                <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
                <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
                <article class="home-movie-card">
                  <a class="home-movie-card-main" href="${escapedDetailUrl}">
                    <div class="home-movie-poster">
                      <c:choose>
                        <c:when test="${not empty movie.posterDisplayUrl}">
                          <c:choose>
                            <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:when>
                            <c:otherwise><img src="${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:otherwise>
                          </c:choose>
                        </c:when>
                        <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
                      </c:choose>
                      <span class="badge"><c:out value="${movie.ageRating}"/></span>
                    </div>
                    <div class="home-movie-info">
                      <h3><c:out value="${movie.title}"/></h3>
                      <p class="home-movie-meta">
                        <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                        <c:if test="${not empty movie.genres}"> · </c:if>
                        <c:out value="${movie.durationMinutes}"/> phút
                      </p>
                      <c:choose>
                        <c:when test="${item.hasShowtime}">
                          <p class="home-movie-showtime">Suất gần nhất: <strong><c:out value="${item.nextShowtimeLabel}"/></strong></p>
                        </c:when>
                        <c:otherwise>
                          <p class="home-movie-showtime is-muted">Chưa có lịch chiếu</p>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </a>
                  <a class="btn btn-primary home-movie-buy" href="${ctx}/showtimes">Mua vé</a>
                </article>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>

      <div class="home-movie-panel" role="tabpanel" id="panel-upcoming"
           aria-labelledby="tab-upcoming" tabindex="0" hidden>
        <c:choose>
          <c:when test="${empty upcomingMovies}">
            <div class="panel movie-empty">
              <h3>Chưa có phim sắp chiếu</h3>
              <p>Chưa có phim nào được công bố lịch phát hành.</p>
            </div>
          </c:when>
          <c:otherwise>
            <div class="home-movie-grid">
              <c:forEach var="item" items="${upcomingMovies}">
                <c:set var="movie" value="${item.movie}"/>
                <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
                <c:set var="movieTitle"><c:out value="${movie.title}"/></c:set>
                <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
                <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
                <article class="home-movie-card">
                  <a class="home-movie-card-main" href="${escapedDetailUrl}">
                    <div class="home-movie-poster">
                      <c:choose>
                        <c:when test="${not empty movie.posterDisplayUrl}">
                          <c:choose>
                            <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:when>
                            <c:otherwise><img src="${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:otherwise>
                          </c:choose>
                        </c:when>
                        <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
                      </c:choose>
                      <span class="badge"><c:out value="${movie.ageRating}"/></span>
                    </div>
                    <div class="home-movie-info">
                      <h3><c:out value="${movie.title}"/></h3>
                      <p class="home-movie-meta">
                        <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                        <c:if test="${not empty movie.genres}"> · </c:if>
                        <c:out value="${movie.durationMinutes}"/> phút
                      </p>
                      <p class="home-movie-showtime">Khởi chiếu: <strong><c:out value="${movie.releaseDate}"/></strong></p>
                    </div>
                  </a>
                  <a class="btn btn-primary home-movie-buy" href="${ctx}/showtimes">Mua vé</a>
                </article>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <section class="page">
    <div class="container">
      <div class="feature-grid">
        <div class="feature"><div class="ico">🎬</div><h3>Phim bom tấn</h3><p>Cập nhật suất chiếu mới nhất tại rạp CineStar.</p></div>
        <div class="feature"><div class="ico">🔊</div><h3>Chất lượng đỉnh cao</h3><p>Phòng chiếu 2D, 3D, IMAX và Dolby Atmos cho trải nghiệm trọn vẹn.</p></div>
        <div class="feature"><div class="ico">🎁</div><h3>Ưu đãi thành viên</h3><p>Tích điểm mỗi lần mua vé và nhận khuyến mãi dành riêng cho hội viên.</p></div>
      </div>
    </div>
  </section>
</main>
<script src="${ctx}/assets/js/home-movies.js" defer></script>
<%@ include file="_footer.jspf" %>
