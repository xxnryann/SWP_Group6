<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Trang chủ"/>
<c:set var="mainClass" value="p-0"/>
<%@ include file="../layout/top.jspf" %>
<c:set var="heroMovies" value="${not empty nowShowingMovies ? nowShowingMovies : upcomingMovies}"/>
<c:set var="heroFirst" value="${empty heroMovies ? null : heroMovies[0].movie}"/>

<section class="home-hero" aria-labelledby="hero-title">
  <c:if test="${not empty heroFirst.posterDisplayUrl}">
    <div class="home-hero-bg" style="background-image:url('${heroFirst.uploadedPoster ? ctx : ''}<c:out value="${heroFirst.posterDisplayUrl}"/>')"></div>
  </c:if>
  <div class="container">
    <div>
      <span class="eyebrow">Trải nghiệm điện ảnh cùng CineStar</span>
      <h1 id="hero-title">Màn ảnh lớn.<br><em>Cảm xúc bất tận.</em></h1>
      <p class="lead">Tạm gác bộn bề, bước vào thế giới điện ảnh. Bộ phim tiếp theo và chỗ ngồi yêu thích đang chờ bạn.</p>
      <div class="cluster">
        <a class="btn btn-accent btn-lg" href="${ctx}/showtimes">${ic.ticket}Đặt vé ngay</a>
        <a class="btn btn-light btn-lg" href="#phim-tai-rap">Xem phim đang chiếu</a>
      </div>
      <c:if test="${not empty heroFirst}">
        <div class="hero-feature">${ic.play}<span>Nổi bật tuần này: <strong><c:out value="${heroFirst.title}"/></strong></span></div>
      </c:if>
    </div>
    <div class="hero-stack" aria-hidden="true">
      <c:forEach var="feature" items="${heroMovies}" begin="0" end="2" varStatus="st">
        <c:if test="${not empty feature.movie.posterDisplayUrl}">
          <figure class="poster">
            <img src="${feature.movie.uploadedPoster ? ctx : ''}<c:out value='${feature.movie.posterDisplayUrl}'/>" alt="" fetchpriority="${st.first ? 'high' : 'auto'}">
            <figcaption><c:out value="${feature.movie.title}"/></figcaption>
          </figure>
        </c:if>
      </c:forEach>
    </div>
  </div>
</section>

<div class="container">
  <nav class="quick-links" aria-label="Lối tắt">
    <a class="quick-link" href="${ctx}/showtimes"><span class="stat-icon">${ic.calendar}</span><div><strong>Chọn suất chiếu</strong><span>Tìm giờ xem phù hợp với bạn</span></div>${ic.arrowRight}</a>
    <a class="quick-link" href="${ctx}/pricing"><span class="stat-icon accent">${ic.wallet}</span><div><strong>Bảng giá vé</strong><span>Giá theo khung giờ và loại ghế</span></div>${ic.arrowRight}</a>
    <a class="quick-link" href="${ctx}/promotions"><span class="stat-icon success">${ic.gift}</span><div><strong>Ưu đãi dành cho bạn</strong><span>Voucher và khuyến mãi mới</span></div>${ic.arrowRight}</a>
  </nav>

  <section class="section" id="phim-tai-rap" aria-labelledby="movies-heading">
    <div class="section-head">
      <div><span class="eyebrow">Lên lịch cho một buổi xem phim</span><h2 id="movies-heading">Hôm nay, xem gì?</h2></div>
      <a class="btn btn-ghost" href="${ctx}/movies">Tất cả phim ${ic.arrowRight}</a>
    </div>
    <div class="segmented mb-24" role="tablist" aria-label="Phim theo trạng thái">
      <button type="button" class="active" role="tab" id="dtab-now" aria-controls="dpanel-now" aria-selected="true" data-target="dpanel-now">Đang chiếu · <c:out value="${fn:length(nowShowingMovies)}"/></button>
      <button type="button" role="tab" id="dtab-soon" aria-controls="dpanel-soon" aria-selected="false" tabindex="-1" data-target="dpanel-soon">Sắp chiếu · <c:out value="${fn:length(upcomingMovies)}"/></button>
    </div>
    <div role="tabpanel" id="dpanel-now" aria-labelledby="dtab-now">
      <c:choose>
        <c:when test="${empty nowShowingMovies}"><div class="card empty"><div class="empty-icon">${ic.film}</div><h3>Hẹn bạn ở suất chiếu tiếp theo</h3><p>Danh sách phim đang được cập nhật. Bạn có thể xem các phim sắp chiếu.</p></div></c:when>
        <c:otherwise>
          <div class="movie-grid">
            <c:forEach var="item" items="${nowShowingMovies}">
              <c:set var="mv" value="${item.movie}"/><c:set var="mvNext" value="${item.nextShowtimeLabel}"/><c:set var="mvCta" value="showtimes"/>
              <%@ include file="../layout/movie-card.jspf" %>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
    <div role="tabpanel" id="dpanel-soon" aria-labelledby="dtab-soon" hidden>
      <c:choose>
        <c:when test="${empty upcomingMovies}"><div class="card empty"><div class="empty-icon">${ic.sparkles}</div><h3>Những câu chuyện mới đang đến</h3><p>Lịch ra mắt sẽ sớm được cập nhật.</p></div></c:when>
        <c:otherwise>
          <div class="movie-grid">
            <c:forEach var="item" items="${upcomingMovies}">
              <c:set var="mv" value="${item.movie}"/><c:set var="mvNext" value=""/><c:set var="mvCta" value="detail"/>
              <%@ include file="../layout/movie-card.jspf" %>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </div>
  </section>

  <section class="member-band" aria-labelledby="member-heading">
    <span class="stat-icon">${ic.star}</span>
    <div>
      <h2 id="member-heading">Mỗi lần xem, thêm đặc quyền.</h2>
      <p>Tích điểm MyPoint sau mỗi vé, đổi voucher và nhận ưu đãi dành riêng cho thành viên CineStar.</p>
    </div>
    <c:choose>
      <c:when test="${empty sessionScope.authUser}"><a class="btn btn-accent btn-lg" href="${ctx}/register">Đăng ký thành viên</a></c:when>
      <c:otherwise><a class="btn btn-accent btn-lg" href="${ctx}/account/vouchers">Ưu đãi của tôi</a></c:otherwise>
    </c:choose>
  </section>

  <c:if test="${not empty featuredNews}">
    <section class="section" aria-labelledby="news-heading">
      <div class="section-head">
        <div><span class="eyebrow">Chuyện bên ngoài màn ảnh</span><h2 id="news-heading">Góc điện ảnh</h2></div>
        <a class="btn btn-ghost" href="${ctx}/news">Tất cả tin tức ${ic.arrowRight}</a>
      </div>
      <div class="grid grid-3">
        <c:forEach var="n" items="${featuredNews}" begin="0" end="2">
          <a class="card card-interactive news-card" href="${ctx}/news?id=${n.newsId}">
            <div class="news-thumb"><img src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${n.thumbnailUrl}'/>" alt="" loading="lazy"></div>
            <div class="card-body"><span class="badge badge-brand" style="align-self:flex-start">Tin tức</span><h3><c:out value="${n.title}"/></h3></div>
          </a>
        </c:forEach>
      </div>
    </section>
  </c:if>
</div>
<div style="height:56px"></div>
<script>
(function () {
  var tabs = Array.prototype.slice.call(document.querySelectorAll('[role=tab][data-target]'));
  function activate(tab) {
    tabs.forEach(function (t) {
      var on = t === tab;
      t.classList.toggle('active', on); t.setAttribute('aria-selected', String(on)); t.tabIndex = on ? 0 : -1;
      document.getElementById(t.dataset.target).hidden = !on;
    });
  }
  tabs.forEach(function (tab, i) {
    tab.addEventListener('click', function () { activate(tab); });
    tab.addEventListener('keydown', function (e) {
      var n = e.key === 'ArrowRight' ? tabs[(i + 1) % tabs.length] : e.key === 'ArrowLeft' ? tabs[(i + tabs.length - 1) % tabs.length] : null;
      if (n) { e.preventDefault(); activate(n); n.focus(); }
    });
  });
})();
</script>
<%@ include file="../layout/bottom.jspf" %>
