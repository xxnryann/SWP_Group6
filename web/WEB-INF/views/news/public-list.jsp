<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Tin tức"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-hero { background: linear-gradient(120deg, var(--navy) 10%, var(--brand) 100%); color: #fff;
              padding: 56px 0 64px; position: relative; overflow: hidden; }
  .uip-hero::after { content: ""; position: absolute; right: -110px; bottom: -150px; width: 420px; height: 420px;
                     border-radius: 50%; background: rgba(249,115,22,.28); }
  .uip-hero .container { position: relative; z-index: 1; }
  .uip-eyebrow { color: var(--accent); font-weight: 700; letter-spacing: .14em; font-size: 12px;
                 text-transform: uppercase; margin-bottom: 10px; }
  .uip-hero h1 { color: #fff; font-size: 40px; margin: 0 0 12px; }
  .uip-hero p { color: var(--slate-200); max-width: 560px; font-size: 16px; margin: 0; }
  .uip-feat { display: grid; grid-template-columns: 1.15fr 1fr; background: #fff; border: 1px solid var(--slate-200);
              border-radius: 16px; overflow: hidden; box-shadow: var(--shadow); margin-bottom: 28px; }
  .uip-feat .uip-img { min-height: 280px; background: linear-gradient(135deg, var(--brand), var(--navy));
                       display: grid; place-items: center; font-size: 72px; }
  .uip-feat .uip-img img { width: 100%; height: 100%; object-fit: cover; display: block; }
  .uip-feat .uip-body { padding: 30px; display: flex; flex-direction: column; gap: 12px; }
  .uip-feat h2 { font-size: 26px; margin: 0; }
  .uip-feat h2 a { color: var(--navy); }
  .uip-feat h2 a:hover { color: var(--brand); }
  .uip-excerpt { color: var(--slate-600); display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical;
                 overflow: hidden; margin: 0; }
  .uip-meta { color: var(--slate-500); font-size: 13px; display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
  .uip-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 22px; }
  .uip-ncard { background: #fff; border: 1px solid var(--slate-200); border-radius: 14px; overflow: hidden;
               box-shadow: var(--shadow); display: flex; flex-direction: column; transition: transform .15s, box-shadow .15s; }
  .uip-ncard:hover { transform: translateY(-3px); }
  .uip-ncard .uip-img { aspect-ratio: 16/9; background: linear-gradient(135deg, var(--brand), var(--navy));
                        display: grid; place-items: center; font-size: 44px; }
  .uip-ncard .uip-img img { width: 100%; height: 100%; object-fit: cover; display: block; }
  .uip-ncard .uip-body { padding: 18px 20px 20px; display: flex; flex-direction: column; gap: 8px; flex: 1; }
  .uip-ncard h3 { font-size: 17px; margin: 0; display: -webkit-box; -webkit-line-clamp: 2;
                  -webkit-box-orient: vertical; overflow: hidden; }
  .uip-ncard h3 a { color: var(--navy); }
  .uip-ncard h3 a:hover { color: var(--brand); }
  .uip-more { margin-top: auto; font-weight: 700; font-size: 14px; }
  .uip-empty { text-align: center; padding: 56px 20px; background: #fff; border: 1px dashed var(--slate-300);
               border-radius: 14px; color: var(--slate-500); }
  @media (max-width: 760px) { .uip-feat { grid-template-columns: 1fr; } .uip-hero h1 { font-size: 30px; } }
</style>
<main>
  <div class="uip-hero">
    <div class="container">
      <p class="uip-eyebrow">Tin tức điện ảnh</p>
      <h1>Tạp chí Điện Ảnh &amp; Sự Kiện</h1>
      <p>Cập nhật tin tức phim ảnh nóng hổi, sự kiện độc quyền và chương trình ưu đãi mới nhất từ CineStar Cinemas.</p>
    </div>
  </div>
  <section class="page">
    <div class="container">
      <c:forEach var="n" items="${newsList}" end="0">
        <article class="uip-feat">
          <div class="uip-img">
            <c:choose>
              <c:when test="${not empty n.thumbnailUrl}"><img src="<c:out value='${n.thumbnailUrl}'/>" alt="<c:out value='${n.title}'/>"></c:when>
              <c:otherwise>🎬</c:otherwise>
            </c:choose>
          </div>
          <div class="uip-body">
            <span class="chip" style="align-self:flex-start">Nổi bật</span>
            <h2><a href="${ctx}/news?id=${n.newsId}"><c:out value="${n.title}"/></a></h2>
            <p class="uip-excerpt"><c:out value="${n.content}"/></p>
            <p class="uip-meta"><span>✍ <c:out value="${n.authorName}"/></span><span>·</span><span>${n.createdAtLabel}</span></p>
            <p style="margin:0"><a class="btn btn-cta" href="${ctx}/news?id=${n.newsId}">Đọc tiếp →</a></p>
          </div>
        </article>
      </c:forEach>

      <div class="uip-grid">
        <c:forEach var="n" items="${newsList}" begin="1">
          <article class="uip-ncard">
            <div class="uip-img">
              <c:choose>
                <c:when test="${not empty n.thumbnailUrl}"><img src="<c:out value='${n.thumbnailUrl}'/>" alt="<c:out value='${n.title}'/>"></c:when>
                <c:otherwise>🎬</c:otherwise>
              </c:choose>
            </div>
            <div class="uip-body">
              <h3><a href="${ctx}/news?id=${n.newsId}"><c:out value="${n.title}"/></a></h3>
              <p class="uip-meta"><span>${n.createdAtLabel}</span></p>
              <a class="uip-more" href="${ctx}/news?id=${n.newsId}">Đọc tiếp →</a>
            </div>
          </article>
        </c:forEach>
      </div>
      <c:if test="${empty newsList}"><div class="uip-empty">📰<br>Chưa có tin tức nào được xuất bản.</div></c:if>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
