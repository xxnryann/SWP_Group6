<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Phim"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>

<section class="hero-band">
  <div class="container">
    <div class="cluster between" style="align-items:flex-end">
      <div>
        <span class="eyebrow">CineStar Cinemas</span>
        <h1>Danh sách phim</h1>
        <p>Phim đang chiếu và sắp ra mắt tại rạp. Chọn phim, chọn suất chiếu và đặt vé chỉ với vài bước.</p>
      </div>
      <c:if test="${canManageMovies}"><a class="btn btn-primary" href="${ctx}/manage/movies">${ic.settings}Quản lý phim</a></c:if>
    </div>
  </div>
</section>

<div class="container mt-32">
  <c:if test="${showStatusFilter}">
    <nav class="tabs" aria-label="Trạng thái phim" style="margin-bottom:18px">
      <c:url var="tabAll" value="/movies"><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabNow" value="/movies"><c:param name="status" value="NowShowing"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabSoon" value="/movies"><c:param name="status" value="Upcoming"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabEnded" value="/movies"><c:param name="status" value="Stopped"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <a class="${empty selectedStatus ? 'active' : ''}" href="${tabAll}">Tất cả</a>
      <a class="${selectedStatus == 'NowShowing' ? 'active' : ''}" href="${tabNow}">Đang chiếu</a>
      <a class="${selectedStatus == 'Upcoming' ? 'active' : ''}" href="${tabSoon}">Sắp chiếu</a>
      <c:if test="${not hideEndedFilter}"><a class="${selectedStatus == 'Stopped' ? 'active' : ''}" href="${tabEnded}">Đã kết thúc</a></c:if>
    </nav>

    <div class="chips mb-24" aria-label="Thể loại">
      <c:url var="genreAll" value="/movies"><c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if></c:url>
      <a class="chip ${empty selectedGenre ? 'active' : ''}" href="${genreAll}">Mọi thể loại</a>
      <c:forEach var="genre" items="${genres}">
        <c:url var="genreUrl" value="/movies">
          <c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if>
          <c:param name="genre" value="${genre.genreId}"/>
        </c:url>
        <a class="chip ${selectedGenre == genre.genreId ? 'active' : ''}" href="${genreUrl}"><c:out value="${genre.genreName}"/></a>
      </c:forEach>
    </div>
  </c:if>

  <c:choose>
    <c:when test="${empty movies}">
      <div class="card empty"><div class="empty-icon">${ic.film}</div><h3>Không có phim nào phù hợp</h3><p>Thử chọn trạng thái hoặc thể loại khác.</p></div>
    </c:when>
    <c:otherwise>
      <p class="muted text-sm mb-16"><c:out value="${fn:length(movies)}"/> phim</p>
      <div class="movie-grid">
        <c:forEach var="movie" items="${movies}">
          <c:set var="mv" value="${movie}"/><c:set var="mvNext" value=""/>
          <%-- Khách / CUSTOMER: phim có suất trong 7 ngày tới hiện nút "Mua vé" mở popup lịch chiếu. --%>
          <c:set var="mvCta" value="${canBook and not empty movieShowtimes[movie.movieId] ? 'popup' : 'detail'}"/>
          <%@ include file="../layout/movie-card.jspf" %>
        </c:forEach>
      </div>

      <%-- Popup lịch chiếu cho từng phim (tiêu đề luôn có tên phim — DEF-002). --%>
      <c:forEach var="movie" items="${movies}">
        <c:set var="sts" value="${movieShowtimes[movie.movieId]}"/>
        <c:if test="${canBook and not empty sts}">
          <div class="modal buy-pop" id="buy-pop-${movie.movieId}" role="dialog" aria-modal="true" aria-labelledby="buy-pop-title-${movie.movieId}">
            <div class="modal-dialog" style="width:min(560px,100%)">
              <span class="eyebrow">Lịch chiếu 7 ngày tới</span>
              <h3 id="buy-pop-title-${movie.movieId}" class="buy-pop-title"><c:out value="${movie.title}"/></h3>
              <p class="text-sm"><c:out value="${movie.durationMinutes}"/> phút · <c:out value="${movie.ageRating}"/><c:if test="${not empty movie.genres}"> · <c:out value="${movie.genres}"/></c:if></p>
              <div style="max-height:55vh;overflow:auto">
                <c:set var="lastDate" value=""/>
                <c:forEach var="st" items="${sts}" varStatus="loop">
                  <c:if test="${st.scheduleDateDisplay != lastDate}">
                    <c:if test="${not loop.first}"></div></c:if>
                    <h4 class="text-sm fw-600 mt-16"><c:out value="${st.scheduleDateDisplay}"/></h4>
                    <div class="st-times" style="margin-top:8px">
                    <c:set var="lastDate" value="${st.scheduleDateDisplay}"/>
                  </c:if>
                  <c:url var="bookingUrl" value="/booking/seats"><c:param name="showtimeId" value="${st.showtimeId}"/></c:url>
                  <a class="time-chip st-time" href="${bookingUrl}">
                    <strong><c:out value="${st.startTimeOnly}"/></strong><span><c:out value="${st.roomName}"/></span><c:if test="${not empty st.languageShort}"><span class="st-lang"><c:out value="${st.languageShort}"/></span></c:if>
                  </a>
                  <c:if test="${loop.last}"></div></c:if>
                </c:forEach>
              </div>
              <div class="modal-actions">
                <a class="btn" href="${ctx}/showtimes">Xem toàn bộ lịch chiếu</a>
                <button class="btn btn-primary" type="button" data-buy-close>Đóng</button>
              </div>
            </div>
          </div>
        </c:if>
      </c:forEach>
      <script>
        (function () {
          var opened = null, opener = null;
          function close() { if (opened) { opened.classList.remove('open'); if (opener) opener.focus(); opened = opener = null; } }
          document.addEventListener('click', function (e) {
            var btn = e.target.closest('[data-buy-movie]');
            if (btn) {
              var pop = document.getElementById('buy-pop-' + btn.getAttribute('data-buy-movie'));
              if (!pop) return;
              close(); opened = pop; opener = btn; pop.classList.add('open');
              var first = pop.querySelector('.time-chip'); if (first) first.focus();
              return;
            }
            if (opened && (e.target === opened || e.target.closest('[data-buy-close]'))) close();
          });
          document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
        })();
      </script>
    </c:otherwise>
  </c:choose>
</div>

<%@ include file="../layout/bottom.jspf" %>
