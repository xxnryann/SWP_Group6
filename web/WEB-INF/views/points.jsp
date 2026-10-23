<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Điểm MyPoint"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="points"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <%@ include file="_account_side.jspf" %>
    <section class="panel">
      <h2>Điểm MyPoint</h2>
      <p class="sub">Số điểm hiện có: <strong><c:out value="${points}"/></strong></p>
      <c:choose>
        <c:when test="${empty history}">
          <p class="sub">Chưa có giao dịch điểm nào.</p>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="data">
              <thead><tr><th>Thời gian</th><th>Nội dung</th><th>Điểm</th></tr></thead>
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
