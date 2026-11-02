<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Trang chủ"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard cinema-home" id="main-content">
  <div class="container">
    <section class="cinema-hero" aria-labelledby="hero-title">
      <div class="cinema-hero-copy">
        <p class="hero-kicker"><span></span> TRẢI NGHIỆM ĐIỆN ẢNH CÙNG CINESTAR</p>
        <h1 id="hero-title">Màn ảnh lớn.<br><em>Cảm xúc bất tận.</em></h1>
        <p class="hero-description">Tạm gác bộn bề, bước vào thế giới điện ảnh. Bộ phim tiếp theo và chỗ ngồi yêu thích đang chờ bạn.</p>
        <div class="hero-actions">
          <a class="btn btn-primary" href="${ctx}/showtimes">Khám phá lịch chiếu <span aria-hidden="true">↗</span></a>
          <a class="hero-secondary" href="#phim-tai-rap">Chọn phim yêu thích <span aria-hidden="true">↓</span></a>
        </div>
        <div class="hero-signature"><span class="hero-play" aria-hidden="true">▶</span><span>Một tấm vé.<br><strong>Ngàn khoảnh khắc đáng nhớ.</strong></span></div>
      </div>
      <div class="cinema-hero-art" aria-hidden="true">
        <div class="hero-orbit"></div>
        <div class="hero-film-label">THE MOVIE EXPERIENCE</div>
        <c:set var="heroMovies" value="${not empty nowShowingMovies ? nowShowingMovies : upcomingMovies}"/>
        <c:choose>
          <c:when test="${not empty heroMovies}">
            <div class="hero-posters">
              <c:forEach var="feature" items="${heroMovies}" begin="0" end="2" varStatus="posterIndex">
                <div class="hero-poster hero-poster-${posterIndex.index}">
                  <c:choose>
                    <c:when test="${not empty feature.movie.posterDisplayUrl}"><img src="${feature.movie.uploadedPoster ? ctx : ''}<c:out value='${feature.movie.posterDisplayUrl}'/>" alt="" fetchpriority="${posterIndex.first ? 'high' : 'auto'}"></c:when>
                    <c:otherwise><span class="hero-poster-fallback">CINE<br>STAR</span></c:otherwise>
                  </c:choose>
                  <span class="hero-poster-caption"><c:out value="${feature.movie.title}"/></span>
                </div>
              </c:forEach>
            </div>
          </c:when>
          <c:otherwise><div class="hero-ticket"><span>CINESTAR CINEMAS</span><strong>LET'S<br>GO TO THE<br>MOVIES.</strong><span>YOUR NEXT GREAT EXPERIENCE</span></div></c:otherwise>
        </c:choose>
        <div class="hero-floating-note"><span aria-hidden="true">✦</span> Hẹn bạn tại rạp!</div>
      </div>
    </section>
    <nav class="home-shortcuts" aria-label="Khám phá CineStar">
      <a href="${ctx}/showtimes"><span class="shortcut-icon" aria-hidden="true">01</span><span><strong>Chọn suất chiếu</strong><small>Tìm giờ xem phù hợp với bạn</small></span><span class="shortcut-arrow" aria-hidden="true">↗</span></a>
      <a href="${ctx}/pricing"><span class="shortcut-icon" aria-hidden="true">02</span><span><strong>Khám phá giá vé</strong><small>Sẵn sàng cho buổi hẹn điện ảnh</small></span><span class="shortcut-arrow" aria-hidden="true">↗</span></a>
      <a href="${ctx}/promotions"><span class="shortcut-icon" aria-hidden="true">03</span><span><strong>Ưu đãi dành cho bạn</strong><small>Xem phim vui hơn cùng ưu đãi</small></span><span class="shortcut-arrow" aria-hidden="true">↗</span></a>
    </nav>
    <section class="dashboard-section dash-movies" id="phim-tai-rap" aria-labelledby="movies-heading">
      <div class="home-section-head">
        <div><p class="section-kicker">LÊN LỊCH CHO MỘT BUỔI XEM PHIM</p><h2 id="movies-heading">Hôm nay, xem gì?</h2></div>
        <a class="section-more" href="${ctx}/movies">Tất cả phim <span aria-hidden="true">↗</span></a>
      </div>
      <div class="dash-tabs" role="tablist" aria-label="Phim theo trạng thái">
        <button type="button" class="dash-tab is-active" role="tab" id="dtab-now" aria-controls="dpanel-now" aria-selected="true" data-target="dpanel-now">Đang chiếu <span><c:out value="${fn:length(nowShowingMovies)}"/></span></button>
        <button type="button" class="dash-tab" role="tab" id="dtab-soon" aria-controls="dpanel-soon" aria-selected="false" tabindex="-1" data-target="dpanel-soon">Sắp chiếu <span><c:out value="${fn:length(upcomingMovies)}"/></span></button>
      </div>
      <div class="dash-panel" role="tabpanel" id="dpanel-now" aria-labelledby="dtab-now" tabindex="0">
        <c:choose>
          <c:when test="${empty nowShowingMovies}"><div class="dashboard-empty"><h3>Hẹn bạn ở suất chiếu tiếp theo</h3><p>Danh sách phim đang được cập nhật. Bạn có thể khám phá các phim sắp chiếu.</p></div></c:when>
          <c:otherwise><div class="mv-grid"><c:forEach var="item" items="${nowShowingMovies}"><c:set var="upcoming" value="${false}"/><%@ include file="_dash_movie_card.jspf" %></c:forEach></div></c:otherwise>
        </c:choose>
      </div>
      <div class="dash-panel" role="tabpanel" id="dpanel-soon" aria-labelledby="dtab-soon" tabindex="0" hidden>
        <c:choose>
          <c:when test="${empty upcomingMovies}"><div class="dashboard-empty"><h3>Những câu chuyện mới đang đến</h3><p>Lịch ra mắt sẽ sớm được cập nhật. Hãy quay lại để không bỏ lỡ nhé.</p></div></c:when>
          <c:otherwise><div class="mv-grid"><c:forEach var="item" items="${upcomingMovies}"><c:set var="upcoming" value="${true}"/><%@ include file="_dash_movie_card.jspf" %></c:forEach></div></c:otherwise>
        </c:choose>
      </div>
    </section>
    <section class="home-membership" aria-labelledby="member-heading">
      <div class="membership-mark" aria-hidden="true">✦</div>
      <div><p class="section-kicker">THÊM NIỀM VUI, THÊM ĐẶC QUYỀN</p><h2 id="member-heading">Mỗi lần xem, thêm gắn kết.</h2><p>Khám phá ưu đãi và tận hưởng những trải nghiệm dành riêng cho thành viên CineStar.</p></div>
      <c:choose>
        <c:when test="${empty sessionScope.authUser}"><a class="btn btn-primary" href="${ctx}/register">Trở thành thành viên <span aria-hidden="true">↗</span></a></c:when>
        <c:otherwise><a class="btn btn-primary" href="${ctx}/account/vouchers">Ưu đãi của tôi <span aria-hidden="true">↗</span></a></c:otherwise>
      </c:choose>
    </section>
    <c:if test="${not empty featuredNews}">
      <section class="home-news" aria-labelledby="news-heading">
        <div class="home-section-head"><div><p class="section-kicker">CHUYỆN BÊN NGOÀI MÀN ẢNH</p><h2 id="news-heading">Góc điện ảnh</h2></div><a class="section-more" href="${ctx}/news">Tất cả tin tức <span aria-hidden="true">↗</span></a></div>
        <div class="home-news-grid">
          <c:forEach var="n" items="${featuredNews}" begin="0" end="2">
            <a class="home-news-card" href="${ctx}/news?id=${n.newsId}">
              <div class="home-news-image"><img src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${n.thumbnailUrl}'/>" alt="" loading="lazy"></div>
              <span class="section-kicker">CINESTAR STORIES <span aria-hidden="true">↗</span></span><h3><c:out value="${n.title}"/></h3>
            </a>
          </c:forEach>
        </div>
      </section>
    </c:if>
  </div>
</main>
<script>
(function () {
  var tabs = Array.prototype.slice.call(document.querySelectorAll('.dash-tab'));
  function activate(tab) {
    tabs.forEach(function (item) {
      var active = item === tab;
      item.classList.toggle('is-active', active);
      item.setAttribute('aria-selected', String(active));
      item.tabIndex = active ? 0 : -1;
      document.getElementById(item.dataset.target).hidden = !active;
    });
  }
  tabs.forEach(function (tab, index) {
    tab.addEventListener('click', function () { activate(tab); });
    tab.addEventListener('keydown', function (event) {
      var target;
      if (event.key === 'ArrowRight') target = tabs[(index + 1) % tabs.length];
      if (event.key === 'ArrowLeft') target = tabs[(index + tabs.length - 1) % tabs.length];
      if (event.key === 'Home') target = tabs[0];
      if (event.key === 'End') target = tabs[tabs.length - 1];
      if (target) { event.preventDefault(); activate(target); target.focus(); }
    });
  });
})();
</script>
<%@ include file="../_footer.jspf" %>
