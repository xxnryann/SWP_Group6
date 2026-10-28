﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thanh toÃ¡n khÃ´ng thÃ nh cÃ´ng"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <div class="card" style="max-width:640px;margin:0 auto;text-align:center">
        <h2>Thanh toÃ¡n khÃ´ng thÃ nh cÃ´ng</h2>
        <p class="sub">
          <c:choose>
            <c:when test="${not empty flashMsg}"><c:out value="${flashMsg}"/></c:when>
            <c:otherwise>ÄÆ¡n Ä‘áº·t vÃ© cá»§a báº¡n Ä‘Ã£ Ä‘Æ°á»£c huá»· vÃ  gháº¿ Ä‘Ã£ Ä‘Æ°á»£c tráº£ láº¡i.</c:otherwise>
          </c:choose>
        </p>
        <div style="margin-top:22px;display:flex;gap:12px;justify-content:center;flex-wrap:wrap">
          <a class="btn btn-cta" href="${ctx}/showtimes">Chá»n suáº¥t chiáº¿u khÃ¡c</a>
          <a class="btn btn-outline" href="${ctx}/account/tickets">Lá»‹ch sá»­ vÃ© cá»§a tÃ´i</a>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



