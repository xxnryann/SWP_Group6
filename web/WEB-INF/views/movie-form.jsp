﻿﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:choose>
  <c:when test="${rescheduleMovie}"><c:set var="pageTitle" value="LÃªn lá»‹ch chiáº¿u láº¡i"/></c:when>
  <c:when test="${movie.movieId == 0}"><c:set var="pageTitle" value="ThÃªm phim"/></c:when>
  <c:otherwise><c:set var="pageTitle" value="Sá»­a phim"/></c:otherwise>
</c:choose>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedMovieId"><c:out value="${movie.movieId}"/></c:set>
<c:set var="escapedTitle"><c:out value="${movie.title}"/></c:set>
<c:set var="escapedOriginalTitle"><c:out value="${movie.originalTitle}"/></c:set>
<c:set var="escapedDirector"><c:out value="${movie.director}"/></c:set>
<c:set var="escapedMainCast"><c:out value="${movie.mainCast}"/></c:set>
<c:set var="escapedDuration"><c:out value="${movie.durationMinutes}"/></c:set>
<c:set var="escapedAgeRating"><c:out value="${movie.ageRating}"/></c:set>
<c:set var="escapedLanguage"><c:out value="${movie.spokenLanguage}"/></c:set>
<c:set var="escapedCountry"><c:out value="${movie.country}"/></c:set>
<c:set var="escapedReleaseDate"><c:out value="${movie.releaseDate}"/></c:set>
<c:set var="escapedEndDate"><c:out value="${movie.endDate}"/></c:set>
<c:set var="escapedPosterUrl"><c:out value="${posterExternalUrl}"/></c:set>
<c:set var="escapedTrailerUrl"><c:out value="${movie.trailerUrl}"/></c:set>
<c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU Vá»°C QUáº¢N LÃ</p>
      <h1><c:out value="${pageTitle}"/></h1>
      <p class="sub"><c:choose>
        <c:when test="${rescheduleMovie}"><strong><c:out value="${movie.title}"/></strong> â€” chá»n ngÃ y báº¯t Ä‘áº§u, ngÃ y káº¿t thÃºc vÃ  tráº¡ng thÃ¡i cho Ä‘á»£t chiáº¿u láº¡i.</c:when>
        <c:otherwise>NgÃ y káº¿t thÃºc máº·c Ä‘á»‹nh sau má»™t thÃ¡ng ká»ƒ tá»« ngÃ y khá»Ÿi chiáº¿u; báº¡n cÃ³ thá»ƒ chá»‰nh sá»­a ngÃ y nÃ y.</c:otherwise>
      </c:choose></p>
    </div>
  </section>
  <form id="movie-form" class="panel movie-form" action="${ctx}/manage/movies" method="post" enctype="multipart/form-data">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="${escapedMovieId}">
    <c:if test="${rescheduleMovie}"><input type="hidden" name="reschedule" value="true"></c:if>

    <div class="movie-form-grid">
      <c:if test="${not rescheduleMovie}">
      <div class="field">
        <label for="title">TÃªn phim *</label>
        <input id="title" name="title" type="text" maxlength="200" required value="${escapedTitle}">
      </div>
      <div class="field">
        <label for="originalTitle">TÃªn gá»‘c</label>
        <input id="originalTitle" name="originalTitle" type="text" maxlength="200" value="${escapedOriginalTitle}">
      </div>
      <div class="field movie-form-full">
        <label for="synopsis">TÃ³m táº¯t ná»™i dung</label>
        <textarea id="synopsis" name="synopsis" rows="5"><c:out value="${movie.synopsis}"/></textarea>
      </div>
      <div class="field">
        <label for="director">Äáº¡o diá»…n</label>
        <input id="director" name="director" type="text" maxlength="100" value="${escapedDirector}">
      </div>
      <div class="field">
        <label for="mainCast">Diá»…n viÃªn chÃ­nh</label>
        <input id="mainCast" name="mainCast" type="text" maxlength="500" value="${escapedMainCast}">
      </div>
      <div class="field">
        <label for="durationMinutes">Thá»i lÆ°á»£ng (phÃºt) *</label>
        <input id="durationMinutes" name="durationMinutes" type="number" min="1" max="150" required value="${escapedDuration}">
      </div>
      <div class="field">
        <label for="ageRating">PhÃ¢n loáº¡i tuá»•i *</label>
        <select id="ageRating" name="ageRating" required>
          <option value="">Chá»n phÃ¢n loáº¡i</option>
          <option value="P" <c:if test="${movie.ageRating == 'P'}">selected</c:if>>P - Phá»• biáº¿n</option>
          <option value="K" <c:if test="${movie.ageRating == 'K'}">selected</c:if>>K - CÃ³ ngÆ°á»i giÃ¡m há»™</option>
          <option value="T13" <c:if test="${movie.ageRating == 'T13'}">selected</c:if>>T13 - Tá»« 13 tuá»•i</option>
          <option value="T16" <c:if test="${movie.ageRating == 'T16'}">selected</c:if>>T16 - Tá»« 16 tuá»•i</option>
          <option value="T18" <c:if test="${movie.ageRating == 'T18'}">selected</c:if>>T18 - Tá»« 18 tuá»•i</option>
        </select>
      </div>
      <div class="field">
        <label for="spokenLanguage">NgÃ´n ngá»¯</label>
        <input id="spokenLanguage" name="spokenLanguage" type="text" maxlength="50" value="${escapedLanguage}">
      </div>
      <div class="field">
        <label for="country">Quá»‘c gia</label>
        <input id="country" name="country" type="text" maxlength="50" value="${escapedCountry}">
      </div>
      </c:if>
      <div class="field">
        <label for="releaseDate"><c:out value="${rescheduleMovie ? 'NgÃ y báº¯t Ä‘áº§u chiáº¿u láº¡i *' : 'NgÃ y khá»Ÿi chiáº¿u *'}"/></label>
        <input id="releaseDate" name="releaseDate" type="date" required value="${escapedReleaseDate}"
               <c:if test="${not empty minReleaseDate}">min="${minReleaseDate}"</c:if>>
      </div>
      <div class="field">
        <label for="endDate"><c:out value="${rescheduleMovie ? 'NgÃ y káº¿t thÃºc Ä‘á»£t chiáº¿u láº¡i *' : 'NgÃ y káº¿t thÃºc'}"/></label>
        <input id="endDate" name="endDate" type="date" value="${escapedEndDate}" <c:if test="${rescheduleMovie}">required</c:if>>
      </div>
      <c:if test="${not rescheduleMovie}">
      <div class="field movie-form-full">
        <span class="field-label">Thá»ƒ loáº¡i</span>
        <div class="genre-checkboxes">
          <c:forEach var="genre" items="${genres}">
            <c:set var="escapedGenreId"><c:out value="${genre.genreId}"/></c:set>
            <label class="check">
              <input type="checkbox" name="genreIds" value="${escapedGenreId}" <c:if test="${genre.selected}">checked</c:if>>
              <span><c:out value="${genre.genreName}"/></span>
            </label>
          </c:forEach>
        </div>
      </div>
      <div class="field">
        <label for="posterUrl">Poster URL (tÃ¹y chá»n)</label>
        <input id="posterUrl" name="posterUrl" type="url" maxlength="500" value="${escapedPosterUrl}" placeholder="https://...">
      </div>
      <div class="field">
        <label for="trailerUrl">Trailer URL ngoÃ i (tÃ¹y chá»n)</label>
        <input id="trailerUrl" name="trailerUrl" type="url" maxlength="500" value="${escapedTrailerUrl}" placeholder="YouTube hoáº·c URL HTTPS">
      </div>
      <div class="field movie-form-full">
        <label for="posterFile">Táº£i poster lÃªn (JPG, JPEG, PNG, WEBP; tá»‘i Ä‘a 5 MB)</label>
        <input id="posterFile" name="posterFile" type="file" accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp" data-max-bytes="5242880">
        <div class="poster-preview-wrap">
          <c:choose>
            <c:when test="${movie.uploadedPoster}"><img id="poster-preview" class="poster-preview" src="${ctx}${posterSrc}" alt="Xem trÆ°á»›c poster" <c:if test="${empty movie.posterDisplayUrl}">hidden</c:if>></c:when>
            <c:otherwise><img id="poster-preview" class="poster-preview" src="${posterSrc}" alt="Xem trÆ°á»›c poster" <c:if test="${empty movie.posterDisplayUrl}">hidden</c:if>></c:otherwise>
          </c:choose>
          <span id="poster-preview-empty" <c:if test="${not empty movie.posterDisplayUrl}">hidden</c:if>>ChÆ°a cÃ³ poster</span>
        </div>
        <c:if test="${not empty movie.posterUrl}">
          <label class="check movie-remove-check"><input type="checkbox" name="deletePoster" value="true"><span>XÃ³a poster hiá»‡n táº¡i</span></label>
        </c:if>
      </div>
      <div class="field movie-form-full">
        <label for="trailerFile">Táº£i video trailer lÃªn (MP4, WEBM; tá»‘i Ä‘a 100 MB)</label>
        <input id="trailerFile" name="trailerFile" type="file" accept=".mp4,.webm,video/mp4,video/webm" data-max-bytes="104857600">
        <c:if test="${not empty movie.trailerFile or not empty movie.trailerUrl}">
          <p class="muted">Video hiá»‡n táº¡i: <c:out value="${movie.trailerFile}"/></p>
          <label class="check movie-remove-check"><input type="checkbox" name="deleteTrailer" value="true"><span>XÃ³a video vÃ  URL trailer hiá»‡n táº¡i</span></label>
        </c:if>
      </div>
      </c:if>
    </div>
    <div class="movie-form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/movies">Há»§y</a>
      <button class="btn btn-primary" type="submit">LÆ°u phim</button>
    </div>
  </form>
    </div>
  </div>
</div></main>
<script src="${ctx}/assets/js/movie-form.js" defer></script>
<%@ include file="_footer.jspf" %>



