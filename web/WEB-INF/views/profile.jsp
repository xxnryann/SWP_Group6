﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="ThÃ´ng tin cÃ¡ nhÃ¢n"/>
<c:set var="parentTitle" value="TÃ i khoáº£n"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="profile"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <form class="panel" method="post" action="${pageContext.request.contextPath}/account/profile" novalidate>
      <h2>ThÃ´ng tin cÃ¡ nhÃ¢n</h2>
      <p class="sub">Cáº­p nháº­t thÃ´ng tin liÃªn há»‡ cá»§a báº¡n.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field">
        <label for="email">EMAIL</label>
        <input id="email" type="email" value="<c:out value='${profile.email}'/>" readonly>
        <div class="hint">Email dÃ¹ng Ä‘á»ƒ Ä‘Äƒng nháº­p nÃªn khÃ´ng thá»ƒ thay Ä‘á»•i.</div>
      </div>
      <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
        <label for="fullName">Há»Œ VÃ€ TÃŠN</label>
        <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${profile.fullName}'/>">
        <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.phone ? 'has-error' : ''}">
        <label for="phone">Sá» ÄIá»†N THOáº I</label>
        <input id="phone" name="phone" type="tel" maxlength="12" required value="<c:out value='${profile.phone}'/>">
        <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
      </div>
      <div class="row">
        <div class="field ${not empty errors.dob ? 'has-error' : ''}">
          <label for="dob">NGÃ€Y SINH</label>
          <input id="dob" name="dob" type="date" value="<c:out value='${profile.dateOfBirth}'/>">
          <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
        </div>
        <div class="field">
          <label for="gender">GIá»šI TÃNH</label>
          <select id="gender" name="gender">
            <option value="">â€”</option>
            <option value="MALE"   ${profile.gender == 'MALE' ? 'selected' : ''}>Nam</option>
            <option value="FEMALE" ${profile.gender == 'FEMALE' ? 'selected' : ''}>Ná»¯</option>
            <option value="OTHER"  ${profile.gender == 'OTHER' ? 'selected' : ''}>KhÃ¡c</option>
          </select>
        </div>
      </div>
      <button class="btn btn-cta" type="submit">LÆ°u thay Ä‘á»•i</button>
    </form>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>



