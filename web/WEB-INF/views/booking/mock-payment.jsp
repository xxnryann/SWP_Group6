<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Cổng thanh toán giả lập"/>
<c:set var="layout" value="bare"/>
<%@ include file="../layout/top.jspf" %>
<div class="container container-sm" style="padding-top:40px">
  <section class="card">
    <div class="card-head">
      <div><span class="badge badge-warning">Môi trường thử nghiệm</span><h2 class="mt-8">Cổng thanh toán giả lập · VNPAY</h2><p>Trang này chỉ dùng cho môi trường dev, không có giá trị tiền thật.</p></div>
    </div>
    <div class="card-body">
      <div class="kv"><span>Mã đơn</span><strong><c:out value="${txnRef}"/></strong></div>
      <div class="kv"><span>Nội dung</span><strong><c:out value="${orderInfo}"/></strong></div>
      <div class="kv total"><span>Số tiền</span><strong>${amount} đ</strong></div>
      <c:if test="${not empty qrDataUri}">
        <div class="text-center mt-24">
          <img src="${qrDataUri}" alt="Mã QR thanh toán VNPAY (giả lập)" style="width:220px;height:220px;margin:0 auto;padding:10px;border:1px solid var(--line);border-radius:var(--r-lg);background:#fff">
          <p class="muted text-sm mt-8">Quét mã QR bằng ứng dụng ngân hàng (giả lập), hoặc bấm nút bên dưới để xác nhận ngay.</p>
        </div>
      </c:if>
    </div>
    <form class="card-foot" method="post" action="${ctx}/mock/payment">
      <c:forEach var="p" items="${params}">
        <input type="hidden" name="<c:out value='${p.key}'/>" value="<c:out value='${p.value}'/>">
      </c:forEach>
      <button class="btn" type="submit" name="decision" value="cancel">Hủy giao dịch</button>
      <button class="btn btn-primary" type="submit" name="decision" value="success">${ic.check}Thanh toán</button>
    </form>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
