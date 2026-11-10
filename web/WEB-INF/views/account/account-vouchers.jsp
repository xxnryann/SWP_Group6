<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Voucher"/>
<%@ include file="../layout/top.jspf" %>
<div class="${isStaffRole ? '' : 'container'}">
  <div class="page-head"><div><h1>Voucher của tôi</h1><p>Voucher đang áp dụng cho tài khoản của bạn. Nhập mã ở bước thanh toán.</p></div></div>
  <%@ include file="../layout/account-nav.jspf" %>
  <c:choose>
    <c:when test="${empty vouchers}">
      <div class="card empty"><div class="empty-icon">${ic.tag}</div><h3>Chưa có voucher nào</h3><p>Voucher mới sẽ xuất hiện ở đây và trong hộp thư của bạn.</p></div>
    </c:when>
    <c:otherwise><%@ include file="../_voucher_grid.jspf" %></c:otherwise>
  </c:choose>
</div>
<%@ include file="../layout/bottom.jspf" %>
