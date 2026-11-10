<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thông tin cá nhân"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="profile"/>
<%@ include file="../_header.jspf" %>
<c:set var="accountTab" value="info"/>
<main class="page"><div class="container">
  <%@ include file="_account_tabs.jspf" %>
  <div class="account-grid">
    <div class="panel profile-panel">
      <h2>Thông tin cá nhân</h2>

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
        <span class="hint">JPG, PNG hoặc WEBP. Chọn ảnh xong bạn được cắt vùng muốn dùng.</span>
      </form>

      <div class="crop-modal" id="cropModal" hidden role="dialog" aria-modal="true" aria-labelledby="cropTitle">
        <div class="crop-box">
          <h3 id="cropTitle">Cắt ảnh đại diện</h3>
          <p class="sub">Kéo ảnh để chọn vùng trong khung tròn, dùng thanh trượt hoặc con lăn chuột để phóng to.</p>
          <div class="crop-stage" id="cropStage"><canvas id="cropCanvas" width="600" height="600"></canvas></div>
          <label class="crop-zoom">Thu nhỏ
            <input type="range" id="cropZoom" min="1" max="4" step="0.01" value="1" aria-label="Phóng to ảnh">
          Phóng to</label>
          <div class="crop-actions">
            <button class="btn btn-soft" type="button" id="cropCancel">Hủy</button>
            <button class="btn btn-primary" type="button" id="cropApply">Dùng vùng này</button>
          </div>
        </div>
      </div>

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
            <label for="idNumber">CMND/HỘ CHIẾU</label>
            <input id="idNumber" name="idNumber" type="text" maxlength="12" placeholder="CMND/CCCD/Hộ chiếu" value="<c:out value='${profile.idNumber}'/>">
            <c:if test="${not empty errors.idNumber}"><div class="error-text"><c:out value="${errors.idNumber}"/></div></c:if>
          </div>
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
        <c:if test="${receivePromo != null}">
          <div class="field">
            <input type="hidden" name="promoField" value="1">
            <label class="check-row"><input type="checkbox" name="receivePromo" value="1" ${receivePromo ? 'checked' : ''}>
              Nhận email thông báo phim mới và ưu đãi voucher</label>
            <p class="sub">Email vé điện tử, huỷ vé và nhắc lịch chiếu vẫn luôn được gửi.</p>
          </div>
        </c:if>
        <c:if test="${sessionScope.authUser.role != 'ADMIN'}">
          <p class="pw-link"><a href="#password" id="pwOpenLink">Đổi mật khẩu?</a></p>
        </c:if>
        <div class="profile-actions"><button class="btn btn-primary btn-update" type="submit">CẬP NHẬT</button></div>
      </form>
    </div>
    <c:if test="${sessionScope.authUser.role != 'ADMIN'}">
    <form class="panel" id="password" method="post" action="${pageContext.request.contextPath}/account/password" novalidate ${passwordOpen ? '' : 'hidden'}>
      <h2>Đổi mật khẩu</h2>
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
    </c:if>
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
    /* Ảnh chọn xong được cắt vuông trong khung (kéo để chọn vùng, phóng to bằng thanh trượt/con lăn),
       xuất JPEG 512x512 rồi mới gửi lên, nên ảnh to bao nhiêu cũng chỉ lưu đúng vùng đã chọn. */
    var OUT = 512, MAX_SOURCE = 15 * 1024 * 1024;
    var modal = document.getElementById('cropModal'), stage = document.getElementById('cropStage');
    var canvas = document.getElementById('cropCanvas'), ctx = canvas.getContext('2d');
    var zoomIn = document.getElementById('cropZoom'), form = file.form;
    var img = null, cropped = null, base = 1, zoom = 1, cx = 0, cy = 0, drag = null;

    function clamp() {                       /* không để lộ khoảng trống ngoài ảnh trong khung */
      var s = base * zoom, half = canvas.width / 2 / s;
      cx = Math.min(Math.max(cx, half), img.width - half);
      cy = Math.min(Math.max(cy, half), img.height - half);
    }
    function draw() {
      var s = base * zoom;
      clamp();
      ctx.fillStyle = '#0f172a'; ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, canvas.width / 2 - cx * s, canvas.height / 2 - cy * s, img.width * s, img.height * s);
    }
    function setZoom(z, keep) {
      zoom = Math.min(4, Math.max(1, z)); zoomIn.value = zoom;
      if (!keep) draw();
    }
    function openCropper(f) {
      var url = URL.createObjectURL(f), im = new Image();
      im.onload = function () {
        img = im; base = canvas.width / Math.min(im.width, im.height);   /* cạnh ngắn vừa khít khung */
        cx = im.width / 2; cy = im.height / 2; setZoom(1, true); draw();
        modal.hidden = false; zoomIn.focus();
      };
      im.onerror = function () { URL.revokeObjectURL(url); showToast('Không đọc được ảnh này.', 'error'); file.value = ''; };
      im.src = url;
    }
    function closeCropper() { modal.hidden = true; file.value = ''; }

    pick.addEventListener('click', function () { file.click(); });
    file.addEventListener('change', function () {
      var f = file.files && file.files[0];
      if (!f) return;
      if (!/^image\/(jpeg|png|webp)$/.test(f.type)) { showToast('Chỉ nhận ảnh JPG, PNG hoặc WEBP.', 'error'); file.value = ''; return; }
      if (f.size > MAX_SOURCE) { showToast('Ảnh gốc quá lớn (tối đa 15 MB).', 'error'); file.value = ''; return; }
      openCropper(f);
    });

    stage.addEventListener('pointerdown', function (e) {
      if (!img) return;
      drag = { x: e.clientX, y: e.clientY, cx: cx, cy: cy };
      stage.setPointerCapture(e.pointerId); stage.classList.add('dragging');
    });
    stage.addEventListener('pointermove', function (e) {
      if (!drag) return;
      var k = canvas.width / stage.clientWidth / (base * zoom);   /* px màn hình -> px ảnh gốc */
      cx = drag.cx - (e.clientX - drag.x) * k; cy = drag.cy - (e.clientY - drag.y) * k; draw();
    });
    ['pointerup', 'pointercancel'].forEach(function (t) {
      stage.addEventListener(t, function () { drag = null; stage.classList.remove('dragging'); });
    });
    stage.addEventListener('wheel', function (e) { e.preventDefault(); setZoom(zoom * (e.deltaY < 0 ? 1.08 : 1 / 1.08)); }, { passive: false });
    zoomIn.addEventListener('input', function () { setZoom(parseFloat(zoomIn.value)); });
    document.getElementById('cropCancel').addEventListener('click', closeCropper);
    modal.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeCropper(); });

    document.getElementById('cropApply').addEventListener('click', function () {
      var out = document.createElement('canvas'), s = base * zoom, side = canvas.width / s;
      out.width = OUT; out.height = OUT;
      var o = out.getContext('2d');
      o.fillStyle = '#fff'; o.fillRect(0, 0, OUT, OUT);         /* nền trắng cho ảnh PNG trong suốt */
      o.drawImage(img, cx - side / 2, cy - side / 2, side, side, 0, 0, OUT, OUT);
      out.toBlob(function (blob) {
        if (!blob) { showToast('Không cắt được ảnh, hãy thử ảnh khác.', 'error'); return; }
        cropped = blob;
        var p = document.createElement('img'); p.alt = 'Ảnh đại diện'; p.src = URL.createObjectURL(blob);
        preview.innerHTML = ''; preview.appendChild(p);
        save.disabled = false; modal.hidden = true; file.value = '';
      }, 'image/jpeg', 0.9);
    });

    /* Gửi ảnh đã cắt thay cho file gốc; server trả redirect về trang hồ sơ kèm thông báo. */
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      if (!cropped) { showToast('Vui lòng chọn ảnh trước khi lưu.', 'error'); return; }
      var data = new FormData(form);
      data.set('avatar', cropped, 'avatar.jpg');
      save.disabled = true;
      fetch(form.action, { method: 'POST', body: data, credentials: 'same-origin' })
        .then(function (r) { location.href = r.url || location.href; })
        .catch(function () { save.disabled = false; showToast('Không gửi được ảnh, hãy thử lại.', 'error'); });
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
</script><%@ include file="../_footer.jspf" %>



