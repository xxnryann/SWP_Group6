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
<c:set var="escapedReleaseDate"><c:out value="${movie.releaseDate}"/></c:set>
<c:set var="escapedEndDate"><c:out value="${movie.endDate}"/></c:set>
<c:set var="escapedPosterUrl"><c:out value="${posterExternalUrl}"/></c:set>
<c:set var="escapedTrailerUrl"><c:out value="${movie.trailerUrl}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<style>
  .genre-checkboxes { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 4px; }
  .genre-checkboxes .check { padding: 8px 14px; border: 1px solid var(--line); border-radius: var(--r-pill); background: var(--surface); font-size: 14px; }
  .genre-checkboxes .check:has(input:checked) { border-color: var(--brand-500); background: var(--brand-50); color: var(--brand-700); }
  .genre-checkboxes .check input { margin-top: 1px; }
  .section-title { grid-column: 1 / -1; display: flex; align-items: center; gap: 10px; padding-top: 6px; color: var(--ink); font-size: 15px; font-weight: 700; }
  .section-title::after { content: ""; flex: 1; height: 1px; background: var(--line); }
</style>
<div class="page-head">
  <div>
    <a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/movies">${ic.chevronLeft}Danh sách phim</a>
    <h1><c:out value="${pageTitle}"/></h1>
    <p>
      <c:choose>
        <c:when test="${rescheduleMovie}"><strong class="text-ink"><c:out value="${movie.title}"/></strong> — chọn ngày bắt đầu, ngày kết thúc cho đợt chiếu lại.</c:when>
        <c:otherwise>Các trường có dấu <span class="req">*</span> là bắt buộc. Ngày kết thúc mặc định sau một tháng kể từ ngày khởi chiếu.</c:otherwise>
      </c:choose>
    </p>
  </div>
</div>

<form id="movie-form" class="card" action="${ctx}/manage/movies" method="post" enctype="multipart/form-data">
  <div class="card-body form-grid">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="${escapedMovieId}">
    <c:if test="${rescheduleMovie}"><input type="hidden" name="reschedule" value="true"></c:if>

    <c:if test="${not rescheduleMovie}">
      <div class="section-title">Thông tin chung</div>
      <div class="field">
        <label for="title">Tên phim<span class="req">*</span></label>
        <input id="title" name="title" type="text" maxlength="200" required value="${escapedTitle}">
        <span class="hint">Từ 2 ký tự, không chỉ nhập khoảng trắng.</span>
      </div>
      <div class="field">
        <label for="originalTitle">Tên gốc</label>
        <input id="originalTitle" name="originalTitle" type="text" maxlength="200" value="${escapedOriginalTitle}">
        <span class="hint">Tối đa 200 ký tự.</span>
      </div>
      <div class="field full">
        <label for="synopsis">Tóm tắt nội dung</label>
        <textarea id="synopsis" name="synopsis" rows="4" maxlength="2000"><c:out value="${movie.synopsis}"/></textarea>
        <span class="hint">Tối đa 2.000 ký tự.</span>
      </div>
      <div class="field">
        <label for="director">Đạo diễn</label>
        <input id="director" name="director" type="text" maxlength="100" pattern="[\p{L}\p{N}][\p{L}\p{N} ,.&'()/+\-]*" value="${escapedDirector}">
        <span class="hint">Chỉ chữ, số và dấu câu cơ bản.</span>
      </div>
      <div class="field">
        <label for="mainCast">Diễn viên chính</label>
        <input id="mainCast" name="mainCast" type="text" maxlength="500" pattern="[\p{L}\p{N}][\p{L}\p{N} ,.&'()/+\-]*" value="${escapedMainCast}">
        <span class="hint">Ngăn cách nhiều diễn viên bằng dấu phẩy.</span>
      </div>
      <div class="field">
        <label for="durationMinutes">Thời lượng (phút)<span class="req">*</span></label>
        <input id="durationMinutes" name="durationMinutes" type="number" min="1" max="150" required value="${escapedDuration}">
        <span class="hint">Số nguyên từ 1 đến 150.</span>
      </div>
      <div class="field">
        <label for="ageRating">Phân loại tuổi<span class="req">*</span></label>
        <select id="ageRating" name="ageRating" required>
          <option value="">Chọn phân loại</option>
          <option value="P" ${movie.ageRating == 'P' ? 'selected' : ''}>P - Phổ biến</option>
          <option value="K" ${movie.ageRating == 'K' ? 'selected' : ''}>K - Có người giám hộ</option>
          <option value="T13" ${movie.ageRating == 'T13' ? 'selected' : ''}>T13 - Từ 13 tuổi</option>
          <option value="T16" ${movie.ageRating == 'T16' ? 'selected' : ''}>T16 - Từ 16 tuổi</option>
          <option value="T18" ${movie.ageRating == 'T18' ? 'selected' : ''}>T18 - Từ 18 tuổi</option>
        </select>
      </div>
      <div class="field" style="align-self:start">
        <label for="country">Quốc gia<span class="req">*</span></label>
        <select id="country" name="country" required>
          <option value="">Chọn quốc gia</option>
          <c:forEach var="countryName" items="${countries}">
            <option value="<c:out value='${countryName}'/>" ${movie.country == countryName ? 'selected' : ''}><c:out value="${countryName}"/></option>
          </c:forEach>
        </select>
        <c:if test="${not empty movie.country and not countries.contains(movie.country)}">
          <span class="hint text-danger">Quốc gia cũ "<c:out value="${movie.country}"/>" không có trong danh sách, hãy chọn lại.</span>
        </c:if>
      </div>
      <div class="field" style="align-self:start">
        <label for="spokenLanguage">Ngôn ngữ<span class="req">*</span></label>
        <select id="spokenLanguage" name="spokenLanguage" multiple size="8" required class="multi-select" data-placeholder="Chọn ngôn ngữ">
          <c:forEach var="lang" items="${languages}">
            <option value="<c:out value='${lang}'/>" ${selectedLanguages.contains(lang) ? 'selected' : ''}><c:out value="${lang.startsWith('Tiếng ') ? lang.substring(6) : lang}"/></option>
          </c:forEach>
        </select>
        <span class="hint">Chọn được nhiều ngôn ngữ: bấm vào từng ngôn ngữ để chọn / bỏ chọn. Khi thêm suất chiếu chỉ chọn được các ngôn ngữ này.</span>
        <c:if test="${not empty legacyLanguages}">
          <span class="hint text-danger">Giá trị cũ không có trong danh sách: <c:forEach var="l" items="${legacyLanguages}" varStatus="st"><c:out value="${l}"/><c:if test="${not st.last}">, </c:if></c:forEach>. Hãy chọn lại.</span>
        </c:if>
      </div>
      <c:set var="escapedVoiceJson"><c:out value="${voiceCastJson}"/></c:set>
      <c:set var="escapedCountryLangJson"><c:out value="${countryLanguageJson}"/></c:set>
      <div class="field full" id="voice-cast-group" data-casts="${escapedVoiceJson}" data-country-langs="${escapedCountryLangJson}" hidden>
        <span class="label">Diễn viên lồng tiếng<span class="req">*</span></span>
        <span class="hint">Bắt buộc cho mỗi ngôn ngữ khác ngôn ngữ gốc của phim (ngôn ngữ của quốc gia sản xuất). Hiện ở mục Thông tin phim.</span>
        <div class="voice-cast-rows" id="voice-cast-rows"></div>
      </div>
      <div class="section-title">Lịch chiếu</div>
    </c:if>

    <div class="field">
      <label for="releaseDate"><c:out value="${rescheduleMovie ? 'Ngày bắt đầu chiếu lại' : 'Ngày khởi chiếu'}"/><span class="req">*</span></label>
      <input id="releaseDate" name="releaseDate" type="date" required value="${escapedReleaseDate}" <c:if test="${not empty minReleaseDate}">min="${minReleaseDate}"</c:if>>
      <span class="hint">Phim mới không được chọn ngày trong quá khứ.</span>
    </div>
    <div class="field">
      <label for="endDate"><c:out value="${rescheduleMovie ? 'Ngày kết thúc đợt chiếu lại' : 'Ngày kết thúc'}"/><c:if test="${rescheduleMovie}"><span class="req">*</span></c:if></label>
      <input id="endDate" name="endDate" type="date" value="${escapedEndDate}" <c:if test="${rescheduleMovie}">required</c:if>>
      <span class="hint">Nếu nhập thì phải từ ngày khởi chiếu trở đi.</span>
    </div>

    <c:if test="${not rescheduleMovie}">
      <div class="field full">
        <span class="label">Thể loại<span class="req">*</span></span>
        <span class="hint">Chọn ít nhất một thể loại. Chưa có thì <a href="${ctx}/manage/genres">tạo thể loại</a> trước.</span>
        <div class="genre-checkboxes">
          <c:forEach var="genre" items="${genres}">
            <label class="check"><input type="checkbox" name="genreIds" value="<c:out value='${genre.genreId}'/>" ${genre.selected ? 'checked' : ''}><span><c:out value="${genre.genreName}"/></span></label>
          </c:forEach>
        </div>
      </div>
      <div class="section-title">Hình ảnh &amp; trailer</div>
      <div class="field full">
        <label for="posterUrl">Link poster</label>
        <div class="input-group">${ic.image}<input id="posterUrl" name="posterUrl" type="url" maxlength="500" value="${escapedPosterUrl}" placeholder="https://..."></div>
        <span class="hint">Dán link ảnh trực tiếp (JPG, PNG, WEBP...).</span>
      </div>
      <div class="field full">
        <label for="trailerUrl">Link YouTube trailer</label>
        <div class="input-group">${ic.play}<input id="trailerUrl" name="trailerUrl" type="url" maxlength="500" value="${escapedTrailerUrl}" placeholder="https://www.youtube.com/watch?v=..."></div>
        <span class="hint">Hỗ trợ link youtube.com, youtu.be và Shorts. Xem trước hiện ngay bên dưới.</span>
        <div id="trailer-url-preview" class="video-frame mt-8" style="max-width:560px" hidden>
          <iframe id="trailer-url-frame" title="Xem trước trailer" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
        </div>
      </div>
    </c:if>
  </div>
  <div class="card-foot">
    <a class="btn" href="${ctx}/manage/movies">Hủy</a>
    <button class="btn btn-primary" type="submit">${ic.check}Lưu phim</button>
  </div>
</form>
<script src="${ctx}/assets/js/movie-form.js?v=20261112-3" defer></script>
<%@ include file="../layout/bottom.jspf" %>
