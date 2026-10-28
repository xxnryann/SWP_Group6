<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thông tin cá nhân"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="profile"/>
<%@ include file="_header.jspf" %>
<c:set var="accountTab" value="info"/>
<main class="page"><div class="container">
  <%@ include file="_account_tabs.jspf" %>
  <div class="account-grid">
    <div class="panel profile-panel">
      <h2>Thông tin cá nhân</h2>
      <p class="sub">Cập nhật thông tin liên hệ của bạn.</p>

      <form class="avatar-row" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/account/avatar">
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="avatar-preview" id="avatarPreview">
          <c:choose>
            <c:when test="${not empty profile.avatarUrl}"><img src="${pageContext.request.contextPath}${profile.avatarUrl}" alt="Ảnh đại diện"></c:when>
            <c:otherwise><span><c:out value="${empty profile.fullName ? '?' : profile.fullName.substring(0, 1).toUpperCase()}"/></span></c:otherwise>
          </c:choose>
        </div>
        <input id="avatarFile" name="avatar" type="file" accept="image/jpeg,image/png,image/webp" hidden>
        <button class="btn btn-soft" type="button" id="avatarPick">TẢI ẢNH LÊN</button>
        <button class="btn btn-save-avatar" type="submit" id="avatarSave" disabled>LƯU ẢNH</button>
        <span class="hint">JPG, PNG hoặc WEBP, tối đa 2 MB.</span>
      </form>

      <form method="post" action="${pageContext.request.contextPath}/account/profile" novalidate>
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="row">
          <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
            <label for="fullName"><span class="req">*</span> HỌ TÊN</label>
            <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${profile.fullName}'/>">
            <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
          </div>
          <div class="field">
            <label for="email"><span class="req">*</span> EMAIL</label>
            <input id="email" type="email" value="<c:out value='${profile.email}'/>" readonly>
            <div class="hint">Email dùng để đăng nhập nên không thể thay đổi.</div>
          </div>
        </div>
        <div class="row">
          <div class="field ${not empty errors.phone ? 'has-error' : ''}">
            <label for="phone"><span class="req">*</span> SỐ ĐIỆN THOẠI</label>
            <input id="phone" name="phone" type="tel" maxlength="12" required placeholder="Số điện thoại" value="<c:out value='${profile.phone}'/>">
            <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
          </div>
          <div class="field ${not empty errors.idNumber ? 'has-error' : ''}">
            <label for="idNumber"><span class="req">*</span> CMND/HỘ CHIẾU</label>
            <input id="idNumber" name="idNumber" type="text" maxlength="12" required placeholder="CMND/CCCD/Hộ chiếu" value="<c:out value='${profile.idNumber}'/>">
            <c:if test="${not empty errors.idNumber}"><div class="error-text"><c:out value="${errors.idNumber}"/></div></c:if>
          </div>
        </div>
        <div class="row">
          <div class="field ${not empty errors.dob ? 'has-error' : ''}">
            <label for="dob"><span class="req">*</span> NGÀY SINH</label>
            <input id="dob" name="dob" type="date" required value="<c:out value='${profile.dateOfBirth}'/>">
            <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
          </div>
          <div class="field">
            <label for="gender">GIỚI TÍNH</label>
            <select id="gender" name="gender">
              <option value="">Giới tính</option>
              <option value="MALE"   ${profile.gender == 'MALE' ? 'selected' : ''}>Nam</option>
              <option value="FEMALE" ${profile.gender == 'FEMALE' ? 'selected' : ''}>Nữ</option>
              <option value="OTHER"  ${profile.gender == 'OTHER' ? 'selected' : ''}>Khác</option>
            </select>
          </div>
        </div>
        <div class="row">
          <div class="field ${not empty errors.province ? 'has-error' : ''}">
            <label for="province">TỈNH/THÀNH PHỐ</label>
            <select id="province" name="province" data-selected="<c:out value='${profile.province}'/>"><option value="">Tỉnh/Thành phố</option></select>
            <c:if test="${not empty errors.province}"><div class="error-text"><c:out value="${errors.province}"/></div></c:if>
          </div>
          <div class="field">
            <label for="district">QUẬN/HUYỆN</label>
            <select id="district" name="district" data-selected="<c:out value='${profile.district}'/>"><option value="">Quận/Huyện</option></select>
          </div>
        </div>
        <div class="field ${not empty errors.address ? 'has-error' : ''}">
          <label for="address">ĐỊA CHỈ</label>
          <textarea id="address" name="address" rows="3" maxlength="255" placeholder="Địa chỉ"><c:out value="${profile.address}"/></textarea>
          <c:if test="${not empty errors.address}"><div class="error-text"><c:out value="${errors.address}"/></div></c:if>
        </div>
        <p class="pw-link"><a href="#password" id="pwOpenLink">Đổi mật khẩu?</a></p>
        <div class="profile-actions"><button class="btn btn-primary btn-update" type="submit">CẬP NHẬT</button></div>
      </form>
    </div>
    <form class="panel" id="password" method="post" action="${pageContext.request.contextPath}/account/password" novalidate ${passwordOpen ? '' : 'hidden'}>
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
<script src="${pageContext.request.contextPath}/assets/js/vn-locations.js"></script>
<script>
(function () {
  var prov = document.getElementById('province'), dist = document.getElementById('district');
  var data = window.VN_LOCATIONS || {};
  function fill(sel, items, selected, placeholder) {
    sel.innerHTML = '';
    var o = document.createElement('option'); o.value = ''; o.textContent = placeholder; sel.appendChild(o);
    items.forEach(function (name) {
      var op = document.createElement('option'); op.value = name; op.textContent = name;
      if (name === selected) op.selected = true; sel.appendChild(op);
    });
  }
  if (prov && dist) {
    fill(prov, Object.keys(data), prov.getAttribute('data-selected'), 'Tỉnh/Thành phố');
    fill(dist, data[prov.value] || [], dist.getAttribute('data-selected'), 'Quận/Huyện');
    prov.addEventListener('change', function () { fill(dist, data[prov.value] || [], '', 'Quận/Huyện'); });
  }
  var file = document.getElementById('avatarFile'), pick = document.getElementById('avatarPick'),
      save = document.getElementById('avatarSave'), preview = document.getElementById('avatarPreview');
  if (file && pick) {
    pick.addEventListener('click', function () { file.click(); });
    file.addEventListener('change', function () {
      var f = file.files && file.files[0];
      if (!f) { save.disabled = true; return; }
      if (f.size > 2 * 1024 * 1024) { showToast('Ảnh vượt quá giới hạn 2 MB.', 'error'); file.value = ''; save.disabled = true; return; }
      var img = document.createElement('img'); img.alt = 'Ảnh đại diện'; img.src = URL.createObjectURL(f);
      preview.innerHTML = ''; preview.appendChild(img); save.disabled = false;
    });
  }
})();
</script><script>
(function () {
  var panel = document.getElementById('password');
  var link = document.getElementById('pwOpenLink');
  if (!panel || !link) return;
  function open() {
    panel.hidden = false;
    panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
    var f = document.getElementById('currentPassword'); if (f) f.focus({ preventScroll: true });
  }
  link.addEventListener('click', function (e) { e.preventDefault(); open(); });
  if (location.hash === '#password' || !panel.hidden) { panel.hidden = false; if (location.hash === '#password') open(); }
})();
</script><%@ include file="_footer.jspf" %>



