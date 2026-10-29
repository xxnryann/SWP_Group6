<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Voucher"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<%@ include file="_header.jspf" %>
<c:set var="accountTab" value="vouchers"/>
<main class="page"><div class="container">
  <%@ include file="_account_tabs.jspf" %>
  <section class="panel">
    <h2>Voucher hiện có</h2>
    <p class="sub">Các mã đang áp dụng. Nhập mã ở bước "Voucher &amp; MyPoint" khi đặt vé để được giảm giá.</p>
    <c:choose>
      <c:when test="${empty vouchers}">
        <p class="sub">Hiện chưa có voucher nào đang áp dụng.</p>
      </c:when>
      <c:otherwise>
        <%@ include file="_voucher_grid.jspf" %>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="_footer.jspf" %>
