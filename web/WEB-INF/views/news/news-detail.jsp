<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${news.title}"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-article { max-width: 820px; }
  .uip-article h1 { font-size: 34px; margin: 10px 0 12px; }
  .uip-meta { color: var(--slate-500); font-size: 14px; display: flex; gap: 10px; flex-wrap: wrap;
              padding-bottom: 20px; border-bottom: 1px solid var(--slate-200); margin-bottom: 24px; }
  .uip-hero-img { width: 100%; border-radius: 14px; margin-bottom: 24px; box-shadow: var(--shadow); }
  .uip-content { font-size: 16.5px; line-height: 1.9; color: var(--slate-800); white-space: pre-line; }
  .uip-back { display: inline-block; margin: 28px 0 4px; font-weight: 700; }
</style>
<main>
  <section class="page">
    <div class="container uip-article">
      <a class="uip-back" href="${ctx}/news">← Tất cả tin tức</a>
      <article>
        <span class="chip">Tin tức</span>
        <h1><c:out value="${news.title}"/></h1>
        <p class="uip-meta"><span>✍ Tác giả: <strong><c:out value="${news.authorName}"/></strong></span><span>·</span><span>🕒 ${news.createdAtLabel}</span></p>
        <c:if test="${not empty news.thumbnailUrl}">
          <img class="uip-hero-img" src="${news.thumbnailUrl.startsWith('/') ? pageContext.request.contextPath : ''}<c:out value='${news.thumbnailUrl}'/>" alt="<c:out value='${news.title}'/>">
        </c:if>
        <div class="uip-content"><c:out value="${news.content}"/></div>
      </article>
      <a class="uip-back" href="${ctx}/news">← Tất cả tin tức</a>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



