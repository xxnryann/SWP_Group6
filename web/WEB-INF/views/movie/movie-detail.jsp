<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${movie.title}"/>
<c:set var="mainClass" value="main-flush"/>
<c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
<c:set var="escapedMovieTitle"><c:out value="${movie.title}"/></c:set>
<c:set var="trailerSrc"><c:out value="${movie.trailerFileDisplayUrl}"/></c:set>
<c:set var="trailerEmbedSrc"><c:out value="${movie.trailerEmbedUrl}"/></c:set>
<c:set var="trailerLinkSrc"><c:out value="${movie.trailerLinkUrl}"/></c:set>
<c:url var="editUrl" value="/manage/movies"><c:param name="id" value="${movie.movieId}"/></c:url>
<c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
<c:set var="trailerMimeType"><c:out value="${movie.trailerMimeType}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<%-- Đặt sau top.jspf: biến ctx (context path) được tạo trong top.jspf; đặt trước thì ctx rỗng và poster upload bị 404. --%>
<c:set var="posterFull" value="${movie.uploadedPoster ? ctx : ''}${posterSrc}"/>

<section class="detail-hero" aria-labelledby="movie-title">
  <c:if test="${not empty movie.posterDisplayUrl}"><div class="home-hero-bg" style="background-image:url('${posterFull}')"></div></c:if>
  <div class="container">
    <div class="poster">
      <c:choose>
        <c:when test="${not empty movie.posterDisplayUrl}"><img src="${posterFull}" alt="Poster phim ${escapedMovieTitle}"></c:when>
        <c:otherwise><span class="poster-ph">${ic.film}</span></c:otherwise>
      </c:choose>
    </div>
    <div>
      <div class="cluster" style="--gap:8px">
        <span class="age age-${movie.ageRating}"><c:out value="${movie.ageRating}"/></span>
        <c:choose>
          <c:when test="${movie.status == 'NowShowing'}"><span class="badge badge-success badge-dot">Đang chiếu</span></c:when>
          <c:when test="${movie.status == 'Upcoming'}"><span class="badge badge-accent">Sắp chiếu</span></c:when>
          <c:otherwise><span class="badge">Ngừng chiếu</span></c:otherwise>
        </c:choose>
        <c:if test="${reviewStats.review_count > 0}"><span class="rating-pill">${ic.star}<c:out value="${reviewStats.avg_rating}"/>/5 · <c:out value="${reviewStats.review_count}"/> đánh giá</span></c:if>
      </div>
      <h1 id="movie-title"><c:out value="${movie.title}"/></h1>
      <c:if test="${not empty movie.originalTitle}"><p class="original"><c:out value="${movie.originalTitle}"/></p></c:if>
      <div class="facts">
        <span>${ic.clock}<c:out value="${movie.durationMinutes}"/> phút</span>
        <c:if test="${not empty movie.genres}"><span>${ic.film}<c:out value="${movie.genres}"/></span></c:if>
        <span>${ic.calendar}Khởi chiếu <c:out value="${movie.releaseDateLabel}"/></span>
        <c:if test="${not empty movie.country}"><span>${ic.globe}<c:out value="${movie.country}"/></span></c:if>
      </div>
      <c:if test="${not empty movie.synopsis}"><p class="synopsis"><c:out value="${movie.synopsis}"/></p></c:if>
      <div class="cluster mt-24">
        <c:if test="${canManageMovies}"><a class="btn btn-light btn-lg" href="${escapedEditUrl}">${ic.edit}Sửa phim</a></c:if>
      </div>
    </div>
  </div>
</section>

<div class="container mt-32">
  <div class="split">
    <div class="stack" style="--gap:24px">
      <section class="card card-pad" id="trailer">
        <h2 class="mb-16" style="font-size:var(--fs-h3)">Trailer</h2>
        <c:choose>
          <c:when test="${not empty movie.trailerFileDisplayUrl}">
            <div class="video-frame"><video controls preload="metadata" playsinline><source src="${ctx}${trailerSrc}" type="${trailerMimeType}">Trình duyệt của bạn không hỗ trợ video.</video></div>
          </c:when>
          <c:when test="${not empty movie.trailerEmbedUrl}">
            <div class="video-frame"><iframe src="${trailerEmbedSrc}" title="Trailer ${escapedMovieTitle}" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></div>
            <%-- Dự phòng khi trình duyệt/YouTube chặn phát trong khung nhúng. --%>
            <c:if test="${not empty movie.trailerLinkUrl}"><a class="btn btn-sm mt-12" href="${trailerLinkSrc}" target="_blank" rel="noopener noreferrer">${ic.play}Xem trên YouTube</a></c:if>
          </c:when>
          <c:when test="${not empty movie.trailerLinkUrl}">
            <a class="btn" href="${trailerLinkSrc}" target="_blank" rel="noopener noreferrer">${ic.external}Mở trailer trong tab mới</a>
          </c:when>
          <c:otherwise><div class="empty" style="padding:28px"><div class="empty-icon">${ic.play}</div><p>Phim chưa có trailer.</p></div></c:otherwise>
        </c:choose>
      </section>

      <section class="card card-pad" id="reviews">
        <div class="cluster between mb-8">
          <h2 style="font-size:var(--fs-h3)">Đánh giá từ khán giả</h2>
          <c:if test="${reviewStats.review_count > 0}"><span class="badge badge-accent">★ <c:out value="${reviewStats.avg_rating}"/>/5 · <c:out value="${reviewStats.review_count}"/> lượt</span></c:if>
        </div>

        <p class="muted text-sm">Chỉ khách đã đặt vé phim này và suất chiếu đã kết thúc mới gửi được đánh giá (không cần soát vé tại rạp). Đánh giá từ 2 sao trở xuống bắt buộc nhập nhận xét nêu lý do. Mỗi phim bạn có một đánh giá và có thể sửa lại bất cứ lúc nào; +5 MyPoint chỉ được cộng cho lần đánh giá đầu tiên, sửa đánh giá không cộng thêm điểm.</p>

        <c:set var="isStaffViewer" value="${not empty sessionScope.authUser and sessionScope.authUser.role != 'CUSTOMER'}"/>
        <c:if test="${not isStaffViewer}">
          <form method="post" action="${ctx}/movies/review" class="form card card-pad mt-16" style="background:var(--surface-2);box-shadow:none" data-loading>
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="movieId" value="${movie.movieId}">
            <div class="cluster between" style="--gap:8px">
              <strong class="text-ink"><c:out value="${hasReviewed ? 'Đánh giá của bạn' : 'Bạn thấy phim thế nào?'}"/></strong>
              <c:if test="${hasReviewed}"><span class="badge badge-success">${ic.checkCircle}Đã đánh giá<c:if test="${not empty myReview.updated_at}"> · đã sửa</c:if></span></c:if>
            </div>
            <c:if test="${empty sessionScope.authUser}"><p class="muted text-sm">Bạn cần <a href="${ctx}/login">đăng nhập</a> để gửi đánh giá.</p></c:if>
            <c:if test="${not empty sessionScope.authUser and not hasReviewed and not hasWatched}">
              <p class="muted text-sm">Bạn chưa có lịch sử đặt vé phim này (hoặc suất chiếu chưa kết thúc) — đánh giá sẽ bị từ chối cho đến khi suất chiếu bạn đã đặt kết thúc.</p>
            </c:if>
            <c:if test="${myReview.is_hidden == 1}"><p class="muted text-sm">Nhận xét của bạn đang bị quản lý ẩn; số sao vẫn được tính.</p></c:if>
            <div class="field">
              <label for="rating">Số sao<span class="req">*</span></label>
              <select id="rating" name="rating" required>
                <option value="">Chọn số sao</option>
                <option value="5" ${myReview.rating == 5 ? 'selected' : ''}>★★★★★ Rất hay</option>
                <option value="4" ${myReview.rating == 4 ? 'selected' : ''}>★★★★ Hay</option>
                <option value="3" ${myReview.rating == 3 ? 'selected' : ''}>★★★ Bình thường</option>
                <option value="2" ${myReview.rating == 2 ? 'selected' : ''}>★★ Tệ</option>
                <option value="1" ${myReview.rating == 1 ? 'selected' : ''}>★ Rất tệ</option>
              </select>
            </div>
            <div class="field">
              <label for="comment">Nhận xét <span id="comment-req-note" class="muted" style="font-weight:400">(tùy chọn)</span></label>
              <textarea id="comment" name="comment" rows="3" maxlength="1000" placeholder="Chia sẻ cảm nhận của bạn về bộ phim..."><c:out value="${myReview.comment}"/></textarea>
            </div>
            <div class="form-actions start"><button class="btn btn-primary" type="submit"><c:out value="${hasReviewed ? 'Cập nhật đánh giá' : 'Gửi đánh giá'}"/></button></div>
          </form>
          <script>
            // Đánh giá <= 2 sao: bắt buộc nhập nhận xét nêu lý do.
            (function () {
              var rating = document.getElementById('rating'), comment = document.getElementById('comment');
              var note = document.getElementById('comment-req-note');
              if (!rating || !comment) return;
              var sync = function () {
                var low = rating.value !== '' && Number(rating.value) <= 2;
                comment.required = low;
                comment.placeholder = low ? 'Vui lòng cho biết lý do bạn chưa hài lòng với bộ phim...' : 'Chia sẻ cảm nhận của bạn về bộ phim...';
                if (note) { note.textContent = low ? '(bắt buộc với đánh giá từ 2 sao trở xuống)' : '(tùy chọn)'; note.style.color = low ? 'var(--danger)' : ''; }
              };
              rating.addEventListener('change', sync);
              sync();
            })();
          </script>
        </c:if>

        <c:choose>
          <c:when test="${empty reviews}"><div class="empty" style="padding:28px"><div class="empty-icon">${ic.message}</div><p>Chưa có đánh giá nào.</p></div></c:when>
          <c:otherwise>
            <div class="mt-8">
              <c:forEach var="r" items="${reviews}">
                <div class="review">
                  <span class="avatar"><c:out value="${empty r.reviewer_name ? '?' : r.reviewer_name.substring(0, 1)}"/></span>
                  <div>
                    <div class="cluster" style="--gap:10px">
                      <strong class="text-ink"><c:out value="${r.reviewer_name}"/></strong>
                      <span class="stars" aria-label="${r.rating} trên 5 sao"><c:forEach begin="1" end="${r.rating}">★</c:forEach><span class="off"><c:forEach begin="${r.rating + 1}" end="5">★</c:forEach></span></span>
                      <span class="muted text-xs"><c:out value="${r.created_at}"/><c:if test="${not empty r.updated_at}"> · đã sửa</c:if></span>
                    </div>
                    <c:if test="${not empty r.comment}"><p class="mt-4"><c:out value="${r.comment}"/></p></c:if>
                  </div>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </section>
    </div>

    <aside class="card card-pad sticky">
      <h2 class="mb-16" style="font-size:var(--fs-h4)">Thông tin phim</h2>
      <dl class="dl">
        <dt>Thể loại</dt><dd><c:out value="${empty movie.genres ? '—' : movie.genres}"/></dd>
        <dt>Thời lượng</dt><dd><c:out value="${movie.durationMinutes}"/> phút</dd>
        <dt>Đạo diễn</dt><dd><c:out value="${empty movie.director ? '—' : movie.director}"/></dd>
        <dt>Diễn viên</dt><dd><c:out value="${empty movie.mainCast ? '—' : movie.mainCast}"/></dd>
        <dt>Ngôn ngữ</dt><dd><c:out value="${empty movie.spokenLanguage ? '—' : movie.spokenLanguage}"/></dd>
        <c:forEach var="vc" items="${voiceCasts}">
          <dt>Lồng tiếng <c:out value="${vc.key.startsWith('Tiếng ') ? vc.key.substring(6) : vc.key}"/></dt><dd><c:out value="${vc.value}"/></dd>
        </c:forEach>
        <dt>Quốc gia</dt><dd><c:out value="${empty movie.country ? '—' : movie.country}"/></dd>
        <dt>Khởi chiếu</dt><dd><c:out value="${movie.releaseDateLabel}"/></dd>
        <dt>Kết thúc</dt><dd><c:out value="${movie.endDateLabel}"/></dd>
        <dt>Độ tuổi</dt><dd><c:out value="${movie.ageRating}"/></dd>
        <c:if test="${canManageMovies}">
          <dt>Mã phim</dt><dd><c:out value="${movie.movieId}"/></dd>
          <dt>Ngày tạo</dt><dd><c:out value="${movie.createdAtLabel}"/></dd>
          <dt>Cập nhật</dt><dd><c:out value="${movie.updatedAtLabel}"/></dd>
          <dt>Tệp trailer</dt><dd><c:out value="${empty movie.trailerFile ? '—' : movie.trailerFile}"/></dd>
        </c:if>
      </dl>
    </aside>
  </div>
</div>

<%@ include file="../layout/bottom.jspf" %>
