﻿﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${movie.title}"/>
<c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
<c:set var="escapedMovieTitle"><c:out value="${movie.title}"/></c:set>
<c:set var="trailerSrc"><c:out value="${movie.trailerFileDisplayUrl}"/></c:set>
<c:set var="trailerEmbedSrc"><c:out value="${movie.trailerEmbedUrl}"/></c:set>
<c:set var="trailerLinkSrc"><c:out value="${movie.trailerLinkUrl}"/></c:set>
<c:url var="editUrl" value="/manage/movies"><c:param name="id" value="${movie.movieId}"/></c:url>
<c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
<c:set var="trailerMimeType"><c:out value="${movie.trailerMimeType}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <article class="movie-detail panel">
    <div class="movie-detail-top">
      <div class="movie-detail-poster">
        <c:choose>
          <c:when test="${not empty movie.posterDisplayUrl}">
            <c:choose>
              <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${escapedMovieTitle}"></c:when>
              <c:otherwise><img src="${posterSrc}" alt="Poster phim ${escapedMovieTitle}"></c:otherwise>
            </c:choose>
          </c:when>
          <c:otherwise><div class="poster-placeholder">ChÆ°a cÃ³ poster</div></c:otherwise>
        </c:choose>
      </div>
      <div class="movie-detail-copy">
        <p class="eyebrow">CHI TIáº¾T PHIM</p>
        <h1><c:out value="${movie.title}"/></h1>
        <c:if test="${not empty movie.originalTitle}"><p class="movie-original-title"><c:out value="${movie.originalTitle}"/></p></c:if>
        <div class="movie-detail-badges">
          <span class="badge"><c:out value="${movie.ageRating}"/></span>
          <span class="chip"><c:choose>
            <c:when test="${movie.status == 'NowShowing'}">Äang chiáº¿u</c:when>
            <c:when test="${movie.status == 'Upcoming'}">Sáº¯p chiáº¿u</c:when>
            <c:otherwise>Ngá»«ng chiáº¿u</c:otherwise>
          </c:choose></span>
        </div>
        <dl class="movie-metadata">
          <dt>MÃ£ phim</dt><dd><c:out value="${movie.movieId}"/></dd>
          <dt>Thá»ƒ loáº¡i</dt><dd><c:out value="${movie.genres}"/></dd>
          <dt>Thá»i lÆ°á»£ng</dt><dd><c:out value="${movie.durationMinutes}"/> phÃºt</dd>
          <dt>Äáº¡o diá»…n</dt><dd><c:out value="${movie.director}"/></dd>
          <dt>Diá»…n viÃªn</dt><dd><c:out value="${movie.mainCast}"/></dd>
          <dt>NgÃ´n ngá»¯</dt><dd><c:out value="${movie.spokenLanguage}"/></dd>
          <dt>Quá»‘c gia</dt><dd><c:out value="${movie.country}"/></dd>
          <dt>NgÃ y khá»Ÿi chiáº¿u</dt><dd><c:out value="${movie.releaseDate}"/></dd>
          <dt>NgÃ y káº¿t thÃºc</dt><dd><c:out value="${movie.endDate}"/></dd>
          <dt>PhÃ¢n loáº¡i tuá»•i</dt><dd><c:out value="${movie.ageRating}"/></dd>
          <dt>Tráº¡ng thÃ¡i</dt><dd><c:out value="${movie.status}"/></dd>
          <dt>NgÃ y táº¡o</dt><dd><c:out value="${movie.createdAt}"/></dd>
          <dt>Cáº­p nháº­t</dt><dd><c:out value="${movie.updatedAt}"/></dd>
          <dt>URL trailer</dt><dd><c:out value="${movie.trailerUrl}"/></dd>
          <dt>Tá»‡p trailer</dt><dd><c:out value="${movie.trailerFile}"/></dd>
          <dt>URL poster</dt><dd><c:out value="${movie.posterUrl}"/></dd>
        </dl>
        <c:if test="${not empty movie.synopsis}">
          <section class="movie-synopsis">
            <h2>Ná»™i dung phim</h2>
            <p><c:out value="${movie.synopsis}"/></p>
          </section>
        </c:if>
      </div>
    </div>

    <section class="movie-trailer">
      <h2>Trailer</h2>
      <c:choose>
        <c:when test="${not empty movie.trailerFileDisplayUrl}">
          <video controls preload="metadata" playsinline>
            <source src="${ctx}${trailerSrc}" type="${trailerMimeType}">
            TrÃ¬nh duyá»‡t cá»§a báº¡n khÃ´ng há»— trá»£ video.
          </video>
        </c:when>
        <c:when test="${not empty movie.trailerEmbedUrl}">
          <div class="movie-embed">
            <iframe src="${trailerEmbedSrc}" title="Trailer ${escapedMovieTitle}" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
          </div>
        </c:when>
        <c:when test="${not empty movie.trailerLinkUrl}">
          <a class="btn btn-outline" href="${trailerLinkSrc}" target="_blank" rel="noopener noreferrer">Má»Ÿ trailer trong tab má»›i</a>
        </c:when>
        <c:otherwise><p>ChÆ°a cÃ³ trailer</p></c:otherwise>
      </c:choose>
    </section>
    <div class="movie-detail-actions">
      <a class="btn btn-outline" href="${ctx}/movies">Quay láº¡i danh sÃ¡ch</a>
      <c:if test="${canManageMovies}"><a class="btn btn-primary" href="${escapedEditUrl}">Sá»­a phim</a></c:if>
    </div>
  </article>
</main>

<%@ include file="_footer.jspf" %>



