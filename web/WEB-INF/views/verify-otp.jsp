﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="XÃ¡c thá»±c OTP"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <div class="eyebrow">BÆ°á»›c cuá»‘i cÃ¹ng</div>
    <h1>XÃ¡c thá»±c<br>tÃ i khoáº£n</h1>
    <p>MÃ£ gá»“m 6 chá»¯ sá»‘ Ä‘Ã£ Ä‘Æ°á»£c gá»­i tá»›i email cá»§a báº¡n vÃ  cÃ³ hiá»‡u lá»±c trong vÃ i phÃºt.</p>
  </section>
      <div class="card">
      <h2>Nháº­p mÃ£ OTP</h2>
      <p class="sub">Gá»­i tá»›i <strong><c:out value="${email}"/></strong></p>
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert"><c:out value="${error}"/></div></c:if>
      <form method="post" action="${pageContext.request.contextPath}/verify-otp">
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="field">
          <input class="otp-input" name="otp" type="text" inputmode="numeric" pattern="\d{6}" maxlength="6"
                 autocomplete="one-time-code" placeholder="000000" required autofocus>
        </div>
        <button class="btn btn-cta btn-block" type="submit">XÃ¡c thá»±c</button>
      </form>
      <form method="post" action="${pageContext.request.contextPath}/verify-otp" class="alt">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="resend">
        KhÃ´ng nháº­n Ä‘Æ°á»£c mÃ£? <button class="btn-link" type="submit">Gá»­i láº¡i mÃ£</button>
      </form>
    </div>
</div></div>
</main>
<%@ include file="_footer.jspf" %>



