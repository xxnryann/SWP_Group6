<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Điểm MyPoint"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="points"/>
<%@ include file="../_header.jspf" %>
<c:set var="accountTab" value="points"/>
<main class="page"><div class="container">
  <%@ include file="_account_tabs.jspf" %>
  <div class="account-grid">
    <section class="panel">
      <h2>Điểm MyPoint</h2>
      <p class="sub">Số điểm hiện có: <strong><c:out value="${points}"/></strong></p>
      <c:if test="${not empty pointConfig}">
        <div class="panel" style="margin:18px 0 24px;background:var(--slate-50)">
          <h3>Cách tích điểm &amp; dùng điểm</h3>
          <ol class="sub" style="padding-left:22px;line-height:1.8">
            <li>Cách tích: mỗi đơn thanh toán thành công được cộng
              <strong><fmt:formatNumber value="${pointConfig.earnRatePercent}" maxFractionDigits="2"/>%</strong>
              giá trị đơn, quy ra điểm theo giá trị 1 điểm.</li>
            <li>Quy đổi: 1 điểm = <strong><fmt:formatNumber value="${pointConfig.pointValueVnd}" groupingUsed="true"/> VNĐ</strong>.</li>
            <li>Cách dùng: nhập điểm ở bước thanh toán khi đặt vé; voucher áp trước, điểm áp sau trên số tiền còn lại,
              dùng được toàn bộ điểm đang có.</li>
          </ol>
        </div>
      </c:if>
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
<%@ include file="../_footer.jspf" %>


