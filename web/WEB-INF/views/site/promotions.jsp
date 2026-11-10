<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Khuyến mãi"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>
<section class="hero-band">
  <div class="container">
    <span class="eyebrow">Xem phim vui hơn</span>
    <h1>Khuyến mãi</h1>
    <p>Voucher đang áp dụng. Nhập mã ở bước thanh toán để được giảm giá.</p>
  </div>
</section>
<div class="container mt-32">
  <c:choose>
    <c:when test="${empty vouchers}">
      <div class="card empty"><div class="empty-icon">${ic.gift}</div><h3>Hiện chưa có voucher nào</h3><p>Quay lại sau để không bỏ lỡ ưu đãi mới nhé.</p></div>
    </c:when>
    <c:otherwise>
      <%@ include file="../_voucher_grid.jspf" %>
      <c:if test="${empty sessionScope.authUser}">
        <div class="alert alert-info mt-24">${ic.info}<span><a class="fw-600" href="${ctx}/login">Đăng nhập</a> để dùng voucher khi đặt vé.</span></div>
      </c:if>
    </c:otherwise>
  </c:choose>
</div>
<div style="height:56px"></div>
<%@ include file="../layout/bottom.jspf" %>
