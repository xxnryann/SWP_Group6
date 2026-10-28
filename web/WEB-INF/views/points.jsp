﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Äiá»ƒm MyPoint"/>
<c:set var="parentTitle" value="TÃ i khoáº£n"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="points"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <section class="panel">
      <h2>Äiá»ƒm MyPoint</h2>
      <p class="sub">Sá»‘ Ä‘iá»ƒm hiá»‡n cÃ³: <strong><c:out value="${points}"/></strong></p>
      <c:choose>
        <c:when test="${empty history}">
          <p class="sub">ChÆ°a cÃ³ giao dá»‹ch Ä‘iá»ƒm nÃ o.</p>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="data">
              <thead><tr><th>Thá»i gian</th><th>Ná»™i dung</th><th>Äiá»ƒm</th></tr></thead>
              <tbody>
              <c:forEach var="p" items="${history}">
                <tr>
                  <td><c:out value="${p.createdAt.toLocalDate()}"/> <c:out value="${p.createdAt.toLocalTime().toString().substring(0,5)}"/></td>
                  <td><c:out value="${p.reason}"/></td>
                  <td><strong><c:if test="${p.points > 0}">+</c:if><c:out value="${p.points}"/></strong></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>



