<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thông tin cá nhân"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="profile"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <form class="panel" method="post" action="${pageContext.request.contextPath}/account/profile" novalidate>
      <h2>Thông tin cá nhân</h2>
      <p class="sub">Cập nhật thông tin liên hệ của bạn.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field">
        <label for="email">EMAIL</label>
        <input id="email" type="email" value="<c:out value='${profile.email}'/>" readonly>
        <div class="hint">Email dùng để đăng nhập nên không thể thay đổi.</div>
      </div>
      <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
        <label for="fullName">HỌ VÀ TÊN</label>
        <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${profile.fullName}'/>">
        <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.phone ? 'has-error' : ''}">
        <label for="phone">SỐ ĐIỆN THOẠI</label>
        <input id="phone" name="phone" type="tel" maxlength="12" required value="<c:out value='${profile.phone}'/>">
        <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
      </div>
      <div class="row">
        <div class="field ${not empty errors.dob ? 'has-error' : ''}">
          <label for="dob">NGÀY SINH</label>
          <input id="dob" name="dob" type="date" value="<c:out value='${profile.dateOfBirth}'/>">
          <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
        </div>
        <div class="field">
          <label for="gender">GIỚI TÍNH</label>
          <select id="gender" name="gender">
            <option value="">—</option>
            <option value="MALE"   ${profile.gender == 'MALE' ? 'selected' : ''}>Nam</option>
            <option value="FEMALE" ${profile.gender == 'FEMALE' ? 'selected' : ''}>Nữ</option>
            <option value="OTHER"  ${profile.gender == 'OTHER' ? 'selected' : ''}>Khác</option>
          </select>
        </div>
      </div>
      <button class="btn btn-cta" type="submit">Lưu thay đổi</button>
    </form>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>
