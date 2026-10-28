<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:choose>
  <c:when test="${rescheduleMovie}"><c:set var="pageTitle" value="Lên lịch chiếu lại"/></c:when>
  <c:when test="${movie.movieId == 0}"><c:set var="pageTitle" value="Thêm phim"/></c:when>
  <c:otherwise><c:set var="pageTitle" value="Sửa phim"/></c:otherwise>
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
      <p class="eyebrow">KHU VỰC QUẢN LÝ</p>
      <h1><c:out value="${pageTitle}"/></h1>
      <p class="sub"><c:choose>
        <c:when test="${rescheduleMovie}"><strong><c:out value="${movie.title}"/></strong> — chọn ngày bắt đầu, ngày kết thúc và trạng thái cho đợt chiếu lại.</c:when>
        <c:otherwise>Ngày kết thúc mặc định sau một tháng kể từ ngày khởi chiếu; bạn có thể chỉnh sửa ngày này.</c:otherwise>
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
        <label for="title">Tên phim *</label>
        <input id="title" name="title" type="text" maxlength="200" required value="${escapedTitle}">
      </div>
      <div class="field">
        <label for="originalTitle">Tên gốc</label>
        <input id="originalTitle" name="originalTitle" type="text" maxlength="200" value="${escapedOriginalTitle}">
      </div>
      <div class="field movie-form-full">
        <label for="synopsis">Tóm tắt nội dung</label>
        <textarea id="synopsis" name="synopsis" rows="5"><c:out value="${movie.synopsis}"/></textarea>
      </div>
      <div class="field">
        <label for="director">Đạo diễn</label>
        <input id="director" name="director" type="text" maxlength="100" value="${escapedDirector}">
      </div>
      <div class="field">
        <label for="mainCast">Diễn viên chính</label>
        <input id="mainCast" name="mainCast" type="text" maxlength="500" value="${escapedMainCast}">
      </div>
      <div class="field">
        <label for="durationMinutes">Thời lượng (phút) *</label>
        <input id="durationMinutes" name="durationMinutes" type="number" min="1" max="150" required value="${escapedDuration}">
      </div>
      <div class="field">
        <label for="ageRating">Phân loại tuổi *</label>
        <select id="ageRating" name="ageRating" required>
          <option value="">Chọn phân loại</option>
          <option value="P" <c:if test="${movie.ageRating == 'P'}">selected</c:if>>P - Phổ biến</option>
          <option value="K" <c:if test="${movie.ageRating == 'K'}">selected</c:if>>K - Có người giám hộ</option>
          <option value="T13" <c:if test="${movie.ageRating == 'T13'}">selected</c:if>>T13 - Từ 13 tuổi</option>
          <option value="T16" <c:if test="${movie.ageRating == 'T16'}">selected</c:if>>T16 - Từ 16 tuổi</option>
          <option value="T18" <c:if test="${movie.ageRating == 'T18'}">selected</c:if>>T18 - Từ 18 tuổi</option>
        </select>
      </div>
      <div class="field">
        <label for="spokenLanguage">Ngôn ngữ</label>
        <input id="spokenLanguage" name="spokenLanguage" type="text" maxlength="50" value="${escapedLanguage}">
      </div>
      <div class="field">
        <label for="country">Quốc gia</label>
        <input id="country" name="country" type="text" maxlength="50" value="${escapedCountry}">
      </div>
      </c:if>
      <div class="field">
        <label for="releaseDate"><c:out value="${rescheduleMovie ? 'Ngày bắt đầu chiếu lại *' : 'Ngày khởi chiếu *'}"/></label>
        <input id="releaseDate" name="releaseDate" type="date" required value="${escapedReleaseDate}"
               <c:if test="${not empty minReleaseDate}">min="${minReleaseDate}"</c:if>>
      </div>
      <div class="field">
        <label for="endDate"><c:out value="${rescheduleMovie ? 'Ngày kết thúc đợt chiếu lại *' : 'Ngày kết thúc'}"/></label>
        <input id="endDate" name="endDate" type="date" value="${escapedEndDate}" <c:if test="${rescheduleMovie}">required</c:if>>
      </div>
      <c:if test="${not rescheduleMovie}">
      <div class="field movie-form-full">
        <span class="field-label">Thể loại</span>
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
        <label for="posterUrl">Poster URL (tùy chọn)</label>
        <input id="posterUrl" name="posterUrl" type="url" maxlength="500" value="${escapedPosterUrl}" placeholder="https://...">
      </div>
      <div class="field">
        <label for="trailerUrl">Trailer URL ngoài (tùy chọn)</label>
        <input id="trailerUrl" name="trailerUrl" type="url" maxlength="500" value="${escapedTrailerUrl}" placeholder="YouTube hoặc URL HTTPS">
      </div>
      <div class="field movie-form-full">
        <label for="posterFile">Tải poster lên (JPG, JPEG, PNG, WEBP; tối đa 5 MB)</label>
        <input id="posterFile" name="posterFile" type="file" accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp" data-max-bytes="5242880">
        <div class="poster-preview-wrap">
          <c:choose>
            <c:when test="${movie.uploadedPoster}"><img id="poster-preview" class="poster-preview" src="${ctx}${posterSrc}" alt="Xem trước poster" <c:if test="${empty movie.posterDisplayUrl}">hidden</c:if>></c:when>
            <c:otherwise><img id="poster-preview" class="poster-preview" src="${posterSrc}" alt="Xem trước poster" <c:if test="${empty movie.posterDisplayUrl}">hidden</c:if>></c:otherwise>
          </c:choose>
          <span id="poster-preview-empty" <c:if test="${not empty movie.posterDisplayUrl}">hidden</c:if>>Chưa có poster</span>
        </div>
        <c:if test="${not empty movie.posterUrl}">
          <label class="check movie-remove-check"><input type="checkbox" name="deletePoster" value="true"><span>Xóa poster hiện tại</span></label>
        </c:if>
      </div>
      <div class="field movie-form-full">
        <label for="trailerFile">Tải video trailer lên (MP4, WEBM; tối đa 100 MB)</label>
        <input id="trailerFile" name="trailerFile" type="file" accept=".mp4,.webm,video/mp4,video/webm" data-max-bytes="104857600">
        <c:if test="${not empty movie.trailerFile or not empty movie.trailerUrl}">
          <p class="muted">Video hiện tại: <c:out value="${movie.trailerFile}"/></p>
          <label class="check movie-remove-check"><input type="checkbox" name="deleteTrailer" value="true"><span>Xóa video và URL trailer hiện tại</span></label>
        </c:if>
      </div>
      </c:if>
    </div>
    <div class="movie-form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/movies">Hủy</a>
      <button class="btn btn-primary" type="submit">Lưu phim</button>
    </div>
  </form>
    </div>
  </div>
</div></main>
<script src="${ctx}/assets/js/movie-form.js" defer></script>
<%@ include file="_footer.jspf" %>



