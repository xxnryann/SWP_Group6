﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="ÄÄƒng kÃ½"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <div class="eyebrow">ThÃ nh viÃªn CineStar</div>
    <h1>Trá»Ÿ thÃ nh<br>há»™i viÃªn VIP</h1>
    <p>ÄÄƒng kÃ½ miá»…n phÃ­ Ä‘á»ƒ Ä‘áº·t vÃ© nhanh, tÃ­ch Ä‘iá»ƒm vÃ  nháº­n Æ°u Ä‘Ã£i dÃ nh riÃªng cho há»™i viÃªn.</p>
  </section>
      <form class="card" method="post" action="${pageContext.request.contextPath}/register" novalidate>
      <h2>Táº¡o tÃ i khoáº£n</h2>
      <p class="sub">ChÃºng tÃ´i sáº½ gá»­i mÃ£ OTP tá»›i email Ä‘á»ƒ xÃ¡c thá»±c.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
        <label for="fullName">Há»Œ VÃ€ TÃŠN</label>
        <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${form.fullName}'/>">
        <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.email ? 'has-error' : ''}">
        <label for="email">EMAIL</label>
        <input id="email" name="email" type="email" maxlength="150" autocomplete="email" required value="<c:out value='${form.email}'/>">
        <c:if test="${not empty errors.email}"><div class="error-text"><c:out value="${errors.email}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.phone ? 'has-error' : ''}">
        <label for="phone">Sá» ÄIá»†N THOáº I</label>
        <input id="phone" name="phone" type="tel" maxlength="12" autocomplete="tel" required value="<c:out value='${form.phone}'/>">
        <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
      </div>
      <div class="row">
        <div class="field ${not empty errors.dob ? 'has-error' : ''}">
          <label for="dob">NGÃ€Y SINH</label>
          <input id="dob" name="dob" type="date" value="<c:out value='${form.dob}'/>">
          <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
        </div>
        <div class="field">
          <label for="gender">GIá»šI TÃNH</label>
          <select id="gender" name="gender">
            <option value="">â€”</option>
            <option value="MALE"   ${form.gender == 'MALE' ? 'selected' : ''}>Nam</option>
            <option value="FEMALE" ${form.gender == 'FEMALE' ? 'selected' : ''}>Ná»¯</option>
            <option value="OTHER"  ${form.gender == 'OTHER' ? 'selected' : ''}>KhÃ¡c</option>
          </select>
        </div>
      </div>
      <div class="field ${not empty errors.password ? 'has-error' : ''}">
        <label for="password">Máº¬T KHáº¨U</label>
        <div class="pw-wrap">
          <input id="password" name="password" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
        <c:choose>
          <c:when test="${not empty errors.password}"><div class="error-text"><c:out value="${errors.password}"/></div></c:when>
          <c:otherwise><div class="hint">Tá»‘i thiá»ƒu 8 kÃ½ tá»±, gá»“m chá»¯ hoa, chá»¯ thÆ°á»ng vÃ  sá»‘.</div></c:otherwise>
        </c:choose>
      </div>
      <div class="field ${not empty errors.confirmPassword ? 'has-error' : ''}">
        <label for="confirmPassword">NHáº¬P Láº I Máº¬T KHáº¨U</label>
        <div class="pw-wrap">
          <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiá»‡n/áº©n máº­t kháº©u">Hiá»‡n</button>
        </div>
        <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
      </div>
      <button class="btn btn-cta btn-block" type="submit">ÄÄƒng kÃ½</button>
      <p class="alt">ÄÃ£ cÃ³ tÃ i khoáº£n? <a href="${pageContext.request.contextPath}/login">ÄÄƒng nháº­p</a></p>
    </form>
</div></div>
</main>
<%@ include file="_footer.jspf" %>



