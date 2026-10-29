<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Khuyến mãi"/>
<%@ include file="_header.jspf" %>
<fmt:setLocale value="vi_VN"/>
<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Khuyến mãi</h1>
      <p class="sub">Các mã voucher đang áp dụng. Nhập mã khi thanh toán để được giảm giá.</p>
    </div>
  </section>

  <c:choose>
    <c:when test="${empty vouchers}">
      <div class="movie-list-empty"><p>Hiện chưa có voucher nào đang áp dụng.</p></div>
    </c:when>
    <c:otherwise>
      <%@ include file="_voucher_grid.jspf" %>
      <c:if test="${empty sessionScope.authUser}">
        <p class="voucher-hint"><a href="${ctx}/login">Đăng nhập</a> để dùng voucher khi đặt vé.</p>
      </c:if>
    </c:otherwise>
  </c:choose>
</main>
<%@ include file="_footer.jspf" %>
