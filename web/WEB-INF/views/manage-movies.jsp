﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quáº£n lÃ½ phim"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU Vá»°C QUáº¢N LÃ</p>
      <h1>Quáº£n lÃ½ phim</h1>
      <p class="sub">ThÃªm, cáº­p nháº­t, ngá»«ng chiáº¿u hoáº·c xÃ³a phim.</p>
    </div>
    <a class="btn btn-primary" href="${ctx}/manage/movies?action=new">ThÃªm phim</a>
  </section>
  <div class="table-wrap">
    <table class="data movie-manage-table">
      <thead>
        <tr><th>Poster</th><th>Phim</th><th>Thá»i lÆ°á»£ng</th><th>Khá»Ÿi chiáº¿u</th><th>Tráº¡ng thÃ¡i</th><th>Thao tÃ¡c</th></tr>
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
                <c:otherwise><span class="poster-placeholder compact">ChÆ°a cÃ³ poster</span></c:otherwise>
              </c:choose>
            </td>
            <td><strong><c:out value="${movie.title}"/></strong><br><span class="muted"><c:out value="${movie.genres}"/></span></td>
            <td><c:out value="${movie.durationMinutes}"/> phÃºt</td>
            <td><c:out value="${movie.releaseDate}"/></td>
            <td><c:out value="${movie.status}"/></td>
            <td class="movie-actions">
              <a class="btn btn-soft btn-small" href="${escapedEditUrl}">Sá»­a</a>
              <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Báº¡n cÃ³ cháº¯c muá»‘n xÃ³a phim nÃ y? Phim cÃ³ suáº¥t chiáº¿u sáº½ khÃ´ng thá»ƒ xÃ³a.');">
                <input type="hidden" name="_csrf" value="${escapedCsrf}">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${escapedMovieId}">
                <button class="btn btn-danger btn-small" type="submit">XÃ³a</button>
              </form>
              <c:if test="${movie.status != 'Stopped'}">
                <form method="post" action="${ctx}/manage/movies" onsubmit="return confirm('Ngá»«ng chiáº¿u phim nÃ y vÃ  há»§y cÃ¡c suáº¥t tÆ°Æ¡ng lai chÆ°a bÃ¡n?');">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}">
                  <input type="hidden" name="action" value="stop">
                  <input type="hidden" name="id" value="${escapedMovieId}">
                  <button class="btn btn-outline btn-small" type="submit">Ngá»«ng chiáº¿u</button>
                </form>
              </c:if>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty movies}"><tr><td colspan="6">ChÆ°a cÃ³ dá»¯ liá»‡u phim.</td></tr></c:if>
      </tbody>
    </table>
  </div>
  <c:if test="${moviePage.totalPages > 1}">
    <nav class="movie-pagination" aria-label="PhÃ¢n trang phim quáº£n lÃ½">
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


