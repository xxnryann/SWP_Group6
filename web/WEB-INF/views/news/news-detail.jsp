<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${news.title}"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <article>
        <h1><c:out value="${news.title}"/></h1>
        <p class="meta">Tác giả: <c:out value="${news.authorName}"/> · Ngày đăng: ${news.createdAt}</p>
        <c:if test="${not empty news.thumbnailUrl}">
          <img src="<c:out value='${news.thumbnailUrl}'/>" alt="<c:out value='${news.title}'/>" style="max-width:100%">
        </c:if>
        <div><c:out value="${news.content}"/></div>
      </article>
      <p><a href="${ctx}/news">← Tất cả tin tức</a></p>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
