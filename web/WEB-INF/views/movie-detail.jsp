<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
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
          <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
        </c:choose>
      </div>
      <div class="movie-detail-copy">
        <p class="eyebrow">CHI TIẾT PHIM</p>
        <h1><c:out value="${movie.title}"/></h1>
        <c:if test="${not empty movie.originalTitle}"><p class="movie-original-title"><c:out value="${movie.originalTitle}"/></p></c:if>
        <div class="movie-detail-badges">
          <span class="badge"><c:out value="${movie.ageRating}"/></span>
          <span class="chip"><c:choose>
            <c:when test="${movie.status == 'NowShowing'}">Đang chiếu</c:when>
            <c:when test="${movie.status == 'Upcoming'}">Sắp chiếu</c:when>
            <c:otherwise>Ngừng chiếu</c:otherwise>
          </c:choose></span>
        </div>
        <dl class="movie-metadata">
          <dt>Mã phim</dt><dd><c:out value="${movie.movieId}"/></dd>
          <dt>Thể loại</dt><dd><c:out value="${movie.genres}"/></dd>
          <dt>Thời lượng</dt><dd><c:out value="${movie.durationMinutes}"/> phút</dd>
          <dt>Đạo diễn</dt><dd><c:out value="${movie.director}"/></dd>
          <dt>Diễn viên</dt><dd><c:out value="${movie.mainCast}"/></dd>
          <dt>Ngôn ngữ</dt><dd><c:out value="${movie.spokenLanguage}"/></dd>
          <dt>Quốc gia</dt><dd><c:out value="${movie.country}"/></dd>
          <dt>Ngày khởi chiếu</dt><dd><c:out value="${movie.releaseDate}"/></dd>
          <dt>Ngày kết thúc</dt><dd><c:out value="${movie.endDate}"/></dd>
          <dt>Phân loại tuổi</dt><dd><c:out value="${movie.ageRating}"/></dd>
          <dt>Trạng thái</dt><dd><c:out value="${movie.status}"/></dd>
          <dt>Ngày tạo</dt><dd><c:out value="${movie.createdAt}"/></dd>
          <dt>Cập nhật</dt><dd><c:out value="${movie.updatedAt}"/></dd>
          <dt>URL trailer</dt><dd><c:out value="${movie.trailerUrl}"/></dd>
          <dt>Tệp trailer</dt><dd><c:out value="${movie.trailerFile}"/></dd>
          <dt>URL poster</dt><dd><c:out value="${movie.posterUrl}"/></dd>
        </dl>
        <c:if test="${not empty movie.synopsis}">
          <section class="movie-synopsis">
            <h2>Nội dung phim</h2>
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
            Trình duyệt của bạn không hỗ trợ video.
          </video>
        </c:when>
        <c:when test="${not empty movie.trailerEmbedUrl}">
          <div class="movie-embed">
            <iframe src="${trailerEmbedSrc}" title="Trailer ${escapedMovieTitle}" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
          </div>
        </c:when>
        <c:when test="${not empty movie.trailerLinkUrl}">
          <a class="btn btn-outline" href="${trailerLinkSrc}" target="_blank" rel="noopener noreferrer">Mở trailer trong tab mới</a>
        </c:when>
        <c:otherwise><p>Chưa có trailer</p></c:otherwise>
      </c:choose>
    </section>
    <section class="movie-reviews">
      <h2>Đánh giá từ khán giả
        <c:if test="${reviewStats.review_count > 0}">
          <span class="review-avg">★ <c:out value="${reviewStats.avg_rating}"/>/5 · <c:out value="${reviewStats.review_count}"/> lượt</span>
        </c:if>
      </h2>

      <c:if test="${canReview}">
        <form method="post" action="${ctx}/movies/review" class="review-form">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="movieId" value="${movie.movieId}">
          <div class="field">
            <label for="rating">SỐ SAO</label>
            <select id="rating" name="rating" required>
              <option value="">-- Chọn --</option>
              <option value="5">5 — Rất hay</option><option value="4">4 — Hay</option>
              <option value="3">3 — Bình thường</option><option value="2">2 — Tệ</option><option value="1">1 — Rất tệ</option>
            </select>
          </div>
          <div class="field">
            <label for="comment">NHẬN XÉT (TUỲ CHỌN)</label>
            <textarea id="comment" name="comment" rows="3" maxlength="1000" placeholder="Chia sẻ cảm nhận của bạn về bộ phim..."></textarea>
          </div>
          <button class="btn btn-primary" type="submit">Gửi đánh giá</button>
        </form>
      </c:if>
      <c:if test="${hasReviewed}"><p class="alert alert-info">Bạn đã đánh giá phim này.</p></c:if>
      <c:if test="${not canReview and not hasReviewed and sessionScope.authUser.role == 'CUSTOMER'}">
        <p class="review-note">Bạn có thể đánh giá sau khi xem phim (vé đã được soát tại rạp).</p>
      </c:if>

      <c:choose>
        <c:when test="${empty reviews}"><p class="review-note">Chưa có đánh giá nào.</p></c:when>
        <c:otherwise>
          <ul class="review-list">
            <c:forEach var="r" items="${reviews}">
              <li>
                <div class="review-head">
                  <strong><c:out value="${r.reviewer_name}"/></strong>
                  <span class="review-stars"><c:forEach begin="1" end="${r.rating}">★</c:forEach><c:forEach begin="${r.rating + 1}" end="5">☆</c:forEach></span>
                  <span class="review-date"><c:out value="${r.created_at}"/></span>
                </div>
                <c:if test="${not empty r.comment}"><p><c:out value="${r.comment}"/></p></c:if>
              </li>
            </c:forEach>
          </ul>
        </c:otherwise>
      </c:choose>
    </section>
    <div class="movie-detail-actions">
      <a class="btn btn-outline" href="${ctx}/movies">Quay lại danh sách</a>
      <c:if test="${canManageMovies}"><a class="btn btn-primary" href="${escapedEditUrl}">Sửa phim</a></c:if>
    </div>
  </article>
</main>

<%@ include file="_footer.jspf" %>



