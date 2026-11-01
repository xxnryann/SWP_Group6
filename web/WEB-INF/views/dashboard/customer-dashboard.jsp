<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Trang chủ"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <c:if test="${not empty featuredNews}">
      <section class="news-slider" id="news-slider" aria-label="Tin tức nổi bật">
        <div class="news-slider-track">
          <c:forEach var="n" items="${featuredNews}">
            <a class="news-slide" href="${ctx}/news?id=${n.newsId}">
              <c:set var="slideImg"><c:out value='${n.thumbnailUrl}'/></c:set>
              <span class="news-slide-media">
                <span class="news-slide-bg" style="background-image:url('${n.thumbnailUrl.startsWith('/') ? ctx : ''}${slideImg}')"></span>
                <img src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}${slideImg}" alt="<c:out value='${n.title}'/>">
              </span>
              <span class="news-slide-title"><c:out value="${n.title}"/></span>
            </a>
          </c:forEach>
        </div>
        <button type="button" class="news-slider-nav is-prev" aria-label="Tin trước">&#10094;</button>
        <button type="button" class="news-slider-nav is-next" aria-label="Tin sau">&#10095;</button>
        <div class="news-slider-dots"></div>
      </section>
    </c:if>

    <section class="dashboard-section dash-movies">
      <h2 class="home-heading">Phim tại rạp</h2>
      <div class="dash-tabs" role="tablist" aria-label="Phim theo trạng thái">
        <button type="button" class="dash-tab is-active" role="tab" id="dtab-now" aria-controls="dpanel-now" aria-selected="true" data-target="dpanel-now">Phim đang chiếu</button>
        <button type="button" class="dash-tab" role="tab" id="dtab-soon" aria-controls="dpanel-soon" aria-selected="false" data-target="dpanel-soon">Phim sắp chiếu</button>
      </div>

      <div class="dash-panel" role="tabpanel" id="dpanel-now" aria-labelledby="dtab-now">
        <c:choose>
          <c:when test="${empty nowShowingMovies}">
            <div class="dashboard-empty"><p>Không có phim đang chiếu lúc này.</p></div>
          </c:when>
          <c:otherwise>
            <div class="mv-grid">
              <c:forEach var="item" items="${nowShowingMovies}">
                <c:set var="upcoming" value="${false}"/>
                <%@ include file="_dash_movie_card.jspf" %>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>

      <div class="dash-panel" role="tabpanel" id="dpanel-soon" aria-labelledby="dtab-soon" hidden>
        <c:choose>
          <c:when test="${empty upcomingMovies}">
            <div class="dashboard-empty"><p>Chưa có phim sắp chiếu.</p></div>
          </c:when>
          <c:otherwise>
            <div class="mv-grid">
              <c:forEach var="item" items="${upcomingMovies}">
                <c:set var="upcoming" value="${true}"/>
                <%@ include file="_dash_movie_card.jspf" %>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </section>
    <p class="home-more"><a class="btn btn-outline" href="${ctx}/movies">Xem tất cả phim</a></p>

  </div>
</main>
<script>
(function () {
  var tabs = document.querySelectorAll('.dash-tab');
  tabs.forEach(function (t) {
    t.addEventListener('click', function () {
      tabs.forEach(function (x) {
        var on = x === t;
        x.classList.toggle('is-active', on);
        x.setAttribute('aria-selected', on);
        document.getElementById(x.dataset.target).hidden = !on;
      });
    });
  });
})();
</script>
<script>
(function () {
  var root = document.getElementById('news-slider');
  if (!root) return;
  var track = root.querySelector('.news-slider-track');
  var count = track.children.length;
  var dots = root.querySelector('.news-slider-dots');
  var index = 0, timer = null;
  for (var i = 0; i < count; i++) {
    var d = document.createElement('button');
    d.type = 'button';
    d.setAttribute('aria-label', 'Tin ' + (i + 1));
    (function (n) { d.addEventListener('click', function () { go(n); restart(); }); })(i);
    dots.appendChild(d);
  }
  function go(n) {
    index = (n + count) % count;
    track.style.transform = 'translateX(' + (-100 * index) + '%)';
    Array.prototype.forEach.call(dots.children, function (b, k) { b.classList.toggle('is-active', k === index); });
  }
  function restart() { clearInterval(timer); if (count > 1) timer = setInterval(function () { go(index + 1); }, 1000); }
  root.querySelector('.is-prev').addEventListener('click', function () { go(index - 1); restart(); });
  root.querySelector('.is-next').addEventListener('click', function () { go(index + 1); restart(); });
  root.addEventListener('mouseenter', function () { clearInterval(timer); });
  root.addEventListener('mouseleave', restart);
  go(0); restart();
})();
</script>
<%@ include file="../_footer.jspf" %>

