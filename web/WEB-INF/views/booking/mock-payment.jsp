<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Cổng thanh toán (giả lập)"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cổng thanh toán giả lập · CineStar</title>
  <link rel="stylesheet" href="${ctx}/assets/css/cinema.css">
  <style>
    .uip-line { display: flex; justify-content: space-between; gap: 14px; padding: 8px 0;
                border-top: 1px solid var(--slate-100); font-size: 14.5px; }
  </style>
</head>
<body>
<main class="page"><div class="container">
  <div class="card" style="max-width:560px;margin:0 auto">
    <p class="eyebrow">MÔI TRƯỜNG THỬ NGHIỆM</p>
    <h2>Cổng thanh toán giả lập — VNPAY</h2>
    <p class="sub">Trang này chỉ dùng cho môi trường dev, không có giá trị tiền thật.</p>

    <div class="uip-line"><span>Mã đơn</span><span><strong><c:out value="${txnRef}"/></strong></span></div>
    <div class="uip-line"><span>Nội dung</span><span><c:out value="${orderInfo}"/></span></div>
    <div class="uip-line"><span>Số tiền</span>
         <span><strong>${amount} VNĐ</strong></span></div>

    <form method="post" action="${ctx}/mock/payment" style="margin-top:22px;display:flex;gap:12px;flex-wrap:wrap">
      <c:forEach var="p" items="${params}">
        <input type="hidden" name="${p.key}" value="${p.value}">
      </c:forEach>
      <button class="btn btn-cta" type="submit" name="decision" value="success">Thanh toán</button>
      <button class="btn btn-outline" type="submit" name="decision" value="cancel">Huỷ giao dịch</button>
    </form>
  </div>
</div></main>
</body>
</html>



