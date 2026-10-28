﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Dashboard - KhÃ¡ch hÃ ng"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <h1>Dashboard KhÃ¡ch hÃ ng</h1>

    <section class="dashboard-section">
      <h2>Phim Ä‘ang chiáº¿u</h2>
      <c:choose>
        <c:when test="${empty nowShowingMovies}">
          <div class="dashboard-empty">
            <p>KhÃ´ng cÃ³ phim Ä‘ang chiáº¿u lÃºc nÃ y.</p>
          </div>
        </c:when>
        <c:otherwise>
          <div class="dashboard-movie-grid">
            <c:forEach var="item" items="${nowShowingMovies}">
              <c:set var="movie" value="${item.movie}"/>
              <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
              <c:set var="movieTitle"><c:out value="${movie.title}"/></c:set>
              <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
              <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
              <article class="dashboard-movie-card">
                <a class="dashboard-movie-card-main" href="${escapedDetailUrl}">
                  <div class="dashboard-movie-poster">
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
                  <div class="dashboard-movie-info">
                    <h3><c:out value="${movie.title}"/></h3>
                    <p class="dashboard-movie-meta">
                      <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                      <c:if test="${not empty movie.genres}"> Â· </c:if>
                      <c:out value="${movie.durationMinutes}"/> phÃºt
                    </p>
                    <c:choose>
                      <c:when test="${not empty item.nextShowtimeLabel}">
                        <p class="dashboard-movie-showtime">Suáº¥t gáº§n nháº¥t: <strong><c:out value="${item.nextShowtimeLabel}"/></strong></p>
                      </c:when>
                      <c:otherwise>
                        <p class="dashboard-movie-showtime is-muted">ChÆ°a cÃ³ lá»‹ch chiáº¿u</p>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </a>
                <a class="btn btn-primary dashboard-movie-buy" href="${ctx}/showtimes">Mua vÃ©</a>
              </article>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </section>

    <section class="dashboard-section">
      <h2>TÃ i khoáº£n cá»§a tÃ´i</h2>
      <nav class="dashboard-links">
        <a href="${ctx}/account/profile">ThÃ´ng tin cÃ¡ nhÃ¢n</a>
        <a href="${ctx}/account/password">Äá»•i máº­t kháº©u</a>
        <a href="${ctx}/tickets">Lá»‹ch sá»­ vÃ©</a>
        <a href="${ctx}/points">Äiá»ƒm thÃ nh viÃªn</a>
      </nav>
    </section>
  </div>
</main>
<%@ include file="../_footer.jspf" %>

