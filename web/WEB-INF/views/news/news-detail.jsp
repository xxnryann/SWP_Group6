<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${news.title}"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .article h1 { font-size: 38px; line-height: 1.2; margin: 14px 0 14px; }
  .article .cover { width: 100%; border-radius: var(--r-xl); margin: 24px 0; box-shadow: var(--sh-md); }
  .article .content { font-size: 17px; line-height: 1.85; color: var(--text); white-space: pre-line; }
</style>
<div class="container container-sm">
  <a class="btn btn-ghost btn-sm" href="${ctx}/news">${ic.chevronLeft}Tất cả tin tức</a>
  <article class="article mt-16">
    <span class="badge badge-brand">Tin tức</span>
    <h1><c:out value="${news.title}"/></h1>
    <div class="person">
      <span class="avatar"><c:out value="${empty news.authorName ? 'C' : news.authorName.substring(0, 1)}"/></span>
      <div><span class="cell-main"><c:out value="${news.authorName}"/></span><span class="cell-sub">${news.createdAtLabel}</span></div>
    </div>
    <c:if test="${not empty news.thumbnailUrl}">
      <img class="cover" src="${news.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${news.thumbnailUrl}'/>" alt="<c:out value='${news.title}'/>">
    </c:if>
    <div class="content"><c:out value="${news.content}"/></div>
  </article>
  <hr class="divider">
  <a class="btn" href="${ctx}/news">${ic.chevronLeft}Xem các tin khác</a>
</div>
<%@ include file="../layout/bottom.jspf" %>
