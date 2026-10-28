<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đổi mật khẩu"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="password"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <form class="panel" method="post" action="${pageContext.request.contextPath}/account/password" novalidate>
      <h2>Đổi mật khẩu</h2>
      <p class="sub">Dùng mật khẩu mạnh và không trùng với dịch vụ khác.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field ${not empty errors.currentPassword ? 'has-error' : ''}">
        <label for="currentPassword">MẬT KHẨU HIỆN TẠI</label>
        <div class="pw-wrap">
          <input id="currentPassword" name="currentPassword" type="password" autocomplete="current-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:if test="${not empty errors.currentPassword}"><div class="error-text"><c:out value="${errors.currentPassword}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.newPassword ? 'has-error' : ''}">
        <label for="newPassword">MẬT KHẨU MỚI</label>
        <div class="pw-wrap">
          <input id="newPassword" name="newPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:choose>
          <c:when test="${not empty errors.newPassword}"><div class="error-text"><c:out value="${errors.newPassword}"/></div></c:when>
          <c:otherwise><div class="hint">Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.</div></c:otherwise>
        </c:choose>
      </div>
      <div class="field ${not empty errors.confirmPassword ? 'has-error' : ''}">
        <label for="confirmPassword">NHẬP LẠI MẬT KHẨU MỚI</label>
        <div class="pw-wrap">
          <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
      </div>
      <button class="btn btn-cta" type="submit">Cập nhật mật khẩu</button>
    </form>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>
