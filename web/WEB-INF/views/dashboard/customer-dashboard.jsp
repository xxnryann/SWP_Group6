<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Tài khoản của tôi"/>
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

    <section class="dashboard-section">
      <h2>Phim đang chiếu</h2>
      <c:choose>
        <c:when test="${empty nowShowingMovies}">
          <div class="dashboard-empty">
            <p>Không có phim đang chiếu lúc này.</p>
          </div>
        </c:when>
        <c:otherwise>
          <div class="dashboard-movie-grid">
            <c:forEach var="item" items="${nowShowingMovies}">
              <c:set var="movie" value="${item.movie}"/>
              <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
              <c:set var="movieTitle"><c:out value="${movie.title}"/></c:set>
              <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
              <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
              <article class="dashboard-movie-card">
                <a class="dashboard-movie-card-main" href="${escapedDetailUrl}">
                  <div class="dashboard-movie-poster">
                    <c:choose>
                      <c:when test="${not empty movie.posterDisplayUrl}">
                        <c:choose>
                          <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:when>
                          <c:otherwise><img src="${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:otherwise>
                        </c:choose>
                      </c:when>
                      <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
                    </c:choose>
                    <span class="badge"><c:out value="${movie.ageRating}"/></span>
                  </div>
                  <div class="dashboard-movie-info">
                    <h3><c:out value="${movie.title}"/></h3>
                    <p class="dashboard-movie-meta">
                      <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                      <c:if test="${not empty movie.genres}"> · </c:if>
                      <c:out value="${movie.durationMinutes}"/> phút
                    </p>
                    <c:choose>
                      <c:when test="${not empty item.nextShowtimeLabel}">
                        <p class="dashboard-movie-showtime">Suất gần nhất: <strong><c:out value="${item.nextShowtimeLabel}"/></strong></p>
                      </c:when>
                      <c:otherwise>
                        <p class="dashboard-movie-showtime is-muted">Chưa có lịch chiếu</p>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </a>
                <a class="btn btn-primary dashboard-movie-buy" href="${ctx}/showtimes">Mua vé</a>
              </article>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</main>
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

