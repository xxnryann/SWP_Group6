<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thanh toán không thành công"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <div class="card" style="max-width:640px;margin:0 auto;text-align:center">
        <h2>Thanh toán không thành công</h2>
        <p class="sub">
          <c:choose>
            <c:when test="${not empty flashMsg}"><c:out value="${flashMsg}"/></c:when>
            <c:otherwise>Đơn đặt vé của bạn đã được huỷ và ghế đã được trả lại.</c:otherwise>
          </c:choose>
        </p>
        <div style="margin-top:22px;display:flex;gap:12px;justify-content:center;flex-wrap:wrap">
          <a class="btn btn-cta" href="${ctx}/showtimes">Chọn suất chiếu khác</a>
          <a class="btn btn-outline" href="${ctx}/account/tickets">Lịch sử vé của tôi</a>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
