﻿﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Trang chá»§"/>
<%@ include file="_header.jspf" %>
<main>
  <section class="hero-home">
    <div class="container">
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Äáº·t vÃ© xem phim<br>nhanh chÃ³ng, tiá»‡n lá»£i</h1>
      <p class="lead">Chá»n ráº¡p, chá»n suáº¥t chiáº¿u vÃ  táº­n hÆ°á»Ÿng nhá»¯ng bá»™ phim bom táº¥n vá»›i Ã¢m thanh Dolby Atmos.</p>
      <c:if test="${empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/register">ÄÄƒng kÃ½ thÃ nh viÃªn</a>
        <a class="btn btn-outline" href="${pageContext.request.contextPath}/login">ÄÄƒng nháº­p</a>
      </c:if>
      <c:if test="${not empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/account/profile">TÃ i khoáº£n cá»§a tÃ´i</a>
      </c:if>
    </div>
  </section>

  <%-- Danh sÃ¡ch phim láº¥y trá»±c tiáº¿p tá»« database: Ä‘ang chiáº¿u vÃ  sáº¯p chiáº¿u. --%>
  <section class="page home-movies">
    <div class="container">
      <div class="home-movies-heading">
        <div>
          <p class="eyebrow">CINESTAR CINEMAS</p>
          <h2>Lá»‹ch phim táº¡i ráº¡p</h2>
        </div>
        <a class="btn btn-outline" href="${ctx}/showtimes">Xem lá»‹ch chiáº¿u</a>
      </div>

      <div class="home-movie-tabs" role="tablist" aria-label="Phim theo tráº¡ng thÃ¡i phÃ¡t hÃ nh">
        <button type="button" class="home-movie-tab is-active" role="tab" id="tab-now-showing"
                aria-controls="panel-now-showing" aria-selected="true" data-tab-target="panel-now-showing">
          Phim Ä‘ang chiáº¿u
        </button>
        <button type="button" class="home-movie-tab" role="tab" id="tab-upcoming"
                aria-controls="panel-upcoming" aria-selected="false" tabindex="-1" data-tab-target="panel-upcoming">
          Phim sáº¯p chiáº¿u
        </button>
      </div>

      <div class="home-movie-panel is-active" role="tabpanel" id="panel-now-showing"
           aria-labelledby="tab-now-showing" tabindex="0">
        <c:choose>
          <c:when test="${empty nowShowingMovies}">
            <div class="panel movie-empty">
              <h3>ChÆ°a cÃ³ phim Ä‘ang chiáº¿u</h3>
              <p>Hiá»‡n ráº¡p chÆ°a cÃ³ phim nÃ o Ä‘ang Ä‘Æ°á»£c phÃ¡t hÃ nh.</p>
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
                        <c:otherwise><div class="poster-placeholder">ChÆ°a cÃ³ poster</div></c:otherwise>
                      </c:choose>
                      <span class="badge"><c:out value="${movie.ageRating}"/></span>
                    </div>
                    <div class="home-movie-info">
                      <h3><c:out value="${movie.title}"/></h3>
                      <p class="home-movie-meta">
                        <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                        <c:if test="${not empty movie.genres}"> Â· </c:if>
                        <c:out value="${movie.durationMinutes}"/> phÃºt
                      </p>
                      <c:choose>
                        <c:when test="${item.hasShowtime}">
                          <p class="home-movie-showtime">Suáº¥t gáº§n nháº¥t: <strong><c:out value="${item.nextShowtimeLabel}"/></strong></p>
                        </c:when>
                        <c:otherwise>
                          <p class="home-movie-showtime is-muted">ChÆ°a cÃ³ lá»‹ch chiáº¿u</p>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </a>
                  <a class="btn btn-primary home-movie-buy" href="${ctx}/showtimes">Mua vÃ©</a>
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
              <h3>ChÆ°a cÃ³ phim sáº¯p chiáº¿u</h3>
              <p>ChÆ°a cÃ³ phim nÃ o Ä‘Æ°á»£c cÃ´ng bá»‘ lá»‹ch phÃ¡t hÃ nh.</p>
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
                        <c:otherwise><div class="poster-placeholder">ChÆ°a cÃ³ poster</div></c:otherwise>
                      </c:choose>
                      <span class="badge"><c:out value="${movie.ageRating}"/></span>
                    </div>
                    <div class="home-movie-info">
                      <h3><c:out value="${movie.title}"/></h3>
                      <p class="home-movie-meta">
                        <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                        <c:if test="${not empty movie.genres}"> Â· </c:if>
                        <c:out value="${movie.durationMinutes}"/> phÃºt
                      </p>
                      <p class="home-movie-showtime">Khá»Ÿi chiáº¿u: <strong><c:out value="${movie.releaseDate}"/></strong></p>
                    </div>
                  </a>
                  <a class="btn btn-primary home-movie-buy" href="${ctx}/showtimes">Mua vÃ©</a>
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
        <div class="feature"><div class="ico">ðŸŽ¬</div><h3>Phim bom táº¥n</h3><p>Cáº­p nháº­t suáº¥t chiáº¿u má»›i nháº¥t táº¡i ráº¡p CineStar.</p></div>
        <div class="feature"><div class="ico">ðŸ”Š</div><h3>Cháº¥t lÆ°á»£ng Ä‘á»‰nh cao</h3><p>PhÃ²ng chiáº¿u 2D, 3D, IMAX vÃ  Dolby Atmos cho tráº£i nghiá»‡m trá»n váº¹n.</p></div>
        <div class="feature"><div class="ico">ðŸŽ</div><h3>Æ¯u Ä‘Ã£i thÃ nh viÃªn</h3><p>TÃ­ch Ä‘iá»ƒm má»—i láº§n mua vÃ© vÃ  nháº­n khuyáº¿n mÃ£i dÃ nh riÃªng cho há»™i viÃªn.</p></div>
      </div>
    </div>
  </section>
</main>
<script src="${ctx}/assets/js/home-movies.js" defer></script>
<%@ include file="_footer.jspf" %>



