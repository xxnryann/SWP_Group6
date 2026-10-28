﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Äá»•i máº­t kháº©u"/>
<c:set var="parentTitle" value="TÃ i khoáº£n"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="password"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <form class="panel" method="post" action="${pageContext.request.contextPath}/account/password" novalidate>
      <h2>Äá»•i máº­t kháº©u</h2>
      <p class="sub">DÃ¹ng máº­t kháº©u máº¡nh vÃ  khÃ´ng trÃ¹ng vá»›i dá»‹ch vá»¥ khÃ¡c.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field ${not empty errors.currentPassword ? 'has-error' : ''}">
        <label for="currentPassword">Máº¬T KHáº¨U HIá»†N Táº I</label>
        <div class="pw-wrap">
          <input id="currentPassword" name="currentPassword" type="password" autocomplete="current-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
        <c:if test="${not empty errors.currentPassword}"><div class="error-text"><c:out value="${errors.currentPassword}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.newPassword ? 'has-error' : ''}">
        <label for="newPassword">Máº¬T KHáº¨U Má»šI</label>
        <div class="pw-wrap">
          <input id="newPassword" name="newPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
        <c:choose>
          <c:when test="${not empty errors.newPassword}"><div class="error-text"><c:out value="${errors.newPassword}"/></div></c:when>
          <c:otherwise><div class="hint">Tá»‘i thiá»ƒu 8 kÃ½ tá»±, gá»“m chá»¯ hoa, chá»¯ thÆ°á»ng vÃ  sá»‘.</div></c:otherwise>
        </c:choose>
      </div>
      <div class="field ${not empty errors.confirmPassword ? 'has-error' : ''}">
        <label for="confirmPassword">NHáº¬P Láº I Máº¬T KHáº¨U Má»šI</label>
        <div class="pw-wrap">
          <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
        <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
      </div>
      <button class="btn btn-cta" type="submit">Cáº­p nháº­t máº­t kháº©u</button>
    </form>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>



