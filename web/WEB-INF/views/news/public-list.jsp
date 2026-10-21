<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Tin tức"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <h1>Tin tức &amp; Sự kiện</h1>
      <div class="news-grid">
        <c:forEach var="n" items="${newsList}">
          <article class="news-card">
            <c:if test="${not empty n.thumbnailUrl}">
              <img src="<c:out value='${n.thumbnailUrl}'/>" alt="<c:out value='${n.title}'/>">
            </c:if>
            <h3><a href="${ctx}/news?id=${n.newsId}"><c:out value="${n.title}"/></a></h3>
            <p class="meta">${n.createdAt}</p>
          </article>
        </c:forEach>
      </div>
      <c:if test="${empty newsList}"><p>Chưa có tin tức nào.</p></c:if>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
