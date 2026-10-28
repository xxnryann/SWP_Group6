﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="ÄÄƒng nháº­p"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <div class="eyebrow">ThÃ nh viÃªn CineStar</div>
    <h1>ChÃ o má»«ng<br>trá»Ÿ láº¡i</h1>
    <p>ÄÄƒng nháº­p Ä‘á»ƒ quáº£n lÃ½ vÃ©, gháº¿ yÃªu thÃ­ch vÃ  Ä‘áº·c quyá»n há»™i viÃªn cá»§a báº¡n.</p>
  </section>
      <form class="card" method="post" action="${pageContext.request.contextPath}/login" novalidate>
      <h2>ÄÄƒng nháº­p</h2>
      <p class="sub">DÃ¹ng email hoáº·c sá»‘ Ä‘iá»‡n thoáº¡i Ä‘Ã£ Ä‘Äƒng kÃ½.</p>
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert"><c:out value="${error}"/></div></c:if>
      <input type="hidden" name="_csrf" value="${csrf}">
      <div class="field">
        <label for="identifier">EMAIL / Sá» ÄIá»†N THOáº I</label>
        <input id="identifier" name="identifier" type="text" autocomplete="username" required
               value="<c:out value='${identifier}'/>" autofocus>
      </div>
      <div class="field">
        <label for="password">Máº¬T KHáº¨U</label>
        <div class="pw-wrap">
          <input id="password" name="password" type="password" autocomplete="current-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
      </div>
      <button class="btn btn-cta btn-block" type="submit">ÄÄƒng nháº­p</button>
      <p class="alt">ChÆ°a cÃ³ tÃ i khoáº£n? <a href="${pageContext.request.contextPath}/register">ÄÄƒng kÃ½ ngay</a></p>
    </form>
</div></div>
</main>
<%@ include file="_footer.jspf" %>



