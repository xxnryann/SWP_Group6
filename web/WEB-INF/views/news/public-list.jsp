<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Tin tức"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .news-feature { display: grid; grid-template-columns: 1.2fr 1fr; overflow: hidden; color: var(--ink); }
  .news-feature:hover { color: var(--ink); }
  .news-feature .news-thumb { aspect-ratio: auto; min-height: 320px; }
  .news-feature .card-body { display: flex; flex-direction: column; justify-content: center; gap: 12px; padding: 32px; }
  .news-feature h2 { font-size: 28px; line-height: 1.25; }
  .news-feature p.excerpt { color: var(--muted); display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
  @media (max-width: 760px) { .news-feature { grid-template-columns: 1fr; } .news-feature .news-thumb { min-height: 200px; } }
</style>
<section class="hero-band">
  <div class="container">
    <span class="eyebrow">Tin tức điện ảnh</span>
    <h1>Tạp chí điện ảnh &amp; sự kiện</h1>
    <p>Tin phim mới, sự kiện độc quyền và chương trình ưu đãi từ CineStar Cinemas.</p>
  </div>
</section>
<div class="container mt-32">
  <c:choose>
    <c:when test="${empty newsList}">
      <div class="card empty"><div class="empty-icon">${ic.news}</div><h3>Chưa có tin tức nào</h3><p>Bài viết mới sẽ xuất hiện ở đây.</p></div>
    </c:when>
    <c:otherwise>
      <c:forEach var="n" items="${newsList}" end="0">
        <a class="card card-interactive news-feature" href="${ctx}/news?id=${n.newsId}">
          <div class="news-thumb">
            <c:choose>
              <c:when test="${not empty n.thumbnailUrl}"><img src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${n.thumbnailUrl}'/>" alt=""></c:when>
              <c:otherwise><span class="poster-ph">${ic.news}</span></c:otherwise>
            </c:choose>
          </div>
          <div class="card-body">
            <span class="badge badge-accent" style="align-self:flex-start">Nổi bật</span>
            <h2><c:out value="${n.title}"/></h2>
            <p class="excerpt"><c:out value="${n.content}"/></p>
            <div class="movie-meta"><span><c:out value="${n.authorName}"/></span><span>${n.createdAtLabel}</span></div>
            <span class="btn btn-primary" style="align-self:flex-start">Đọc tiếp ${ic.arrowRight}</span>
          </div>
        </a>
      </c:forEach>
      <div class="grid grid-3 mt-24">
        <c:forEach var="n" items="${newsList}" begin="1">
          <a class="card card-interactive news-card" href="${ctx}/news?id=${n.newsId}">
            <div class="news-thumb">
              <c:choose>
                <c:when test="${not empty n.thumbnailUrl}"><img src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${n.thumbnailUrl}'/>" alt="" loading="lazy"></c:when>
                <c:otherwise><span class="poster-ph">${ic.news}</span></c:otherwise>
              </c:choose>
            </div>
            <div class="card-body">
              <span class="muted text-xs">${n.createdAtLabel}</span>
              <h3><c:out value="${n.title}"/></h3>
              <span class="text-brand fw-600 text-sm" style="margin-top:auto">Đọc tiếp →</span>
            </div>
          </a>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</div>
<div style="height:56px"></div>
<%@ include file="../layout/bottom.jspf" %>
