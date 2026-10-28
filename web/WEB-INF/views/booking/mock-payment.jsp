﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Cá»•ng thanh toÃ¡n (giáº£ láº­p)"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cá»•ng thanh toÃ¡n giáº£ láº­p Â· CineStar</title>
  <link rel="stylesheet" href="${ctx}/assets/css/cinema.css">
  <style>
    .uip-line { display: flex; justify-content: space-between; gap: 14px; padding: 8px 0;
                border-top: 1px solid var(--slate-100); font-size: 14.5px; }
  </style>
</head>
<body>
<main class="page"><div class="container">
  <div class="card" style="max-width:560px;margin:0 auto">
    <p class="eyebrow">MÃ”I TRÆ¯á»œNG THá»¬ NGHIá»†M</p>
    <h2>Cá»•ng thanh toÃ¡n giáº£ láº­p â€” VNPAY</h2>
    <p class="sub">Trang nÃ y chá»‰ dÃ¹ng cho mÃ´i trÆ°á»ng dev, khÃ´ng cÃ³ giÃ¡ trá»‹ tiá»n tháº­t.</p>

    <div class="uip-line"><span>MÃ£ Ä‘Æ¡n</span><span><strong><c:out value="${txnRef}"/></strong></span></div>
    <div class="uip-line"><span>Ná»™i dung</span><span><c:out value="${orderInfo}"/></span></div>
    <div class="uip-line"><span>Sá»‘ tiá»n</span>
         <span><strong>${amount} VNÄ</strong></span></div>

    <form method="post" action="${ctx}/mock/payment" style="margin-top:22px;display:flex;gap:12px;flex-wrap:wrap">
      <c:forEach var="p" items="${params}">
        <input type="hidden" name="${p.key}" value="${p.value}">
      </c:forEach>
      <button class="btn btn-cta" type="submit" name="decision" value="success">Thanh toÃ¡n</button>
      <button class="btn btn-outline" type="submit" name="decision" value="cancel">Huá»· giao dá»‹ch</button>
    </form>
  </div>
</div></main>
</body>
</html>



