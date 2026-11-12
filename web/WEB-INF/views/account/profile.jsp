<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thông tin cá nhân"/>
<%@ include file="../layout/top.jspf" %>
<div class="${appShell ? '' : 'container'}">
  <div class="page-head">
    <div>
      <h1>Thông tin cá nhân</h1>
      <p>Cập nhật hồ sơ, ảnh đại diện<c:if test="${sessionScope.authUser.role != 'ADMIN'}"> và mật khẩu</c:if> của bạn.</p>
    </div>
  </div>
  <div class="split" style="grid-template-columns:300px minmax(0,1fr)">
    <aside class="stack sticky" style="--gap:16px">
      <section class="card card-pad profile-card">
        <form method="post" enctype="multipart/form-data" action="${ctx}/account/avatar">
          <input type="hidden" name="_csrf" value="${csrf}">
          <div class="avatar avatar-lg" id="avatarPreview">
            <c:choose>
              <c:when test="${not empty profile.avatarUrl}"><img src="${ctx}${profile.avatarUrl}" alt="Ảnh đại diện"></c:when>
              <c:otherwise><span><c:out value="${empty profile.fullName ? '?' : profile.fullName.substring(0, 1).toUpperCase()}"/></span></c:otherwise>
            </c:choose>
          </div>
          <h2><c:out value="${profile.fullName}"/></h2>
          <p class="muted mt-4"><c:out value="${profile.email}"/></p>
          <span class="badge badge-brand mt-8">${empty roleLabel ? 'Thành viên' : roleLabel}</span>
          <input id="avatarFile" name="avatar" type="file" accept="image/jpeg,image/png,image/webp" hidden>
          <div class="avatar-actions">
            <button class="btn btn-soft" type="button" id="avatarPick">${ic.upload}Chọn ảnh mới</button>
            <button class="btn btn-primary" type="submit" id="avatarSave" disabled>Lưu ảnh đại diện</button>
          </div>
          <p class="hint mt-8">JPG, PNG hoặc WEBP. Chọn ảnh xong bạn được cắt vùng muốn dùng.</p>
        </form>
      </section>
    </aside>

    <div class="stack" style="--gap:24px">
      <section class="card">
        <div class="card-head"><div><h2>Hồ sơ</h2><p>Chỉ họ tên, email và số điện thoại là bắt buộc.</p></div></div>
        <form method="post" action="${ctx}/account/profile" novalidate>
          <div class="card-body form-grid">
            <input type="hidden" name="_csrf" value="${csrf}">
            <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
              <label for="fullName">Họ tên<span class="req">*</span></label>
              <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${profile.fullName}'/>">
              <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
            </div>
            <div class="field">
              <label for="email">Email<span class="req">*</span></label>
              <input id="email" type="email" value="<c:out value='${profile.email}'/>" readonly>
              <div class="hint">Email dùng để đăng nhập nên không thể thay đổi.</div>
            </div>
            <div class="field ${not empty errors.phone ? 'has-error' : ''}">
              <label for="phone">Số điện thoại<span class="req">*</span></label>
              <input id="phone" name="phone" type="tel" maxlength="12" required placeholder="09xxxxxxxx" value="<c:out value='${profile.phone}'/>">
              <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
            </div>
            <div class="field ${not empty errors.idNumber ? 'has-error' : ''}">
              <label for="idNumber">CMND / CCCD / Hộ chiếu</label>
              <input id="idNumber" name="idNumber" type="text" maxlength="12" placeholder="Không bắt buộc" value="<c:out value='${profile.idNumber}'/>">
              <c:if test="${not empty errors.idNumber}"><div class="error-text"><c:out value="${errors.idNumber}"/></div></c:if>
            </div>
            <div class="field ${not empty errors.dob ? 'has-error' : ''}">
              <label for="dob">Ngày sinh</label>
              <input id="dob" name="dob" type="date" value="<c:out value='${profile.dateOfBirth}'/>">
              <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
            </div>
            <div class="field">
              <label for="gender">Giới tính</label>
              <select id="gender" name="gender">
                <option value="">Không chọn</option>
                <option value="MALE"   ${profile.gender == 'MALE' ? 'selected' : ''}>Nam</option>
                <option value="FEMALE" ${profile.gender == 'FEMALE' ? 'selected' : ''}>Nữ</option>
                <option value="OTHER"  ${profile.gender == 'OTHER' ? 'selected' : ''}>Khác</option>
              </select>
            </div>
            <div class="field ${not empty errors.province ? 'has-error' : ''}">
              <label for="province">Tỉnh / Thành phố</label>
              <select id="province" name="province" data-selected="<c:out value='${profile.province}'/>"><option value="">Tỉnh/Thành phố</option></select>
              <c:if test="${not empty errors.province}"><div class="error-text"><c:out value="${errors.province}"/></div></c:if>
            </div>
            <div class="field">
              <label for="district">Quận / Huyện</label>
              <select id="district" name="district" data-selected="<c:out value='${profile.district}'/>"><option value="">Quận/Huyện</option></select>
            </div>
            <div class="field full ${not empty errors.address ? 'has-error' : ''}">
              <label for="address">Địa chỉ</label>
              <textarea id="address" name="address" rows="2" maxlength="255" placeholder="Số nhà, đường, phường/xã"><c:out value="${profile.address}"/></textarea>
              <c:if test="${not empty errors.address}"><div class="error-text"><c:out value="${errors.address}"/></div></c:if>
            </div>
            <c:if test="${receivePromo != null}">
              <div class="field full">
                <input type="hidden" name="promoField" value="1">
                <label class="check"><input type="checkbox" name="receivePromo" value="1" ${receivePromo ? 'checked' : ''}>
                  <span>Nhận email thông báo phim mới và ưu đãi voucher<span class="hint" style="display:block">Email vé điện tử, hủy vé và nhắc lịch chiếu vẫn luôn được gửi.</span></span></label>
              </div>
            </c:if>
          </div>
          <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Lưu thay đổi</button></div>
        </form>
      </section>

      <c:if test="${sessionScope.authUser.role != 'ADMIN'}">
        <section class="card" id="password">
          <div class="card-head"><div><h2>Đổi mật khẩu</h2><p>Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.</p></div></div>
          <form method="post" action="${ctx}/account/password" novalidate>
            <div class="card-body form-grid">
              <input type="hidden" name="_csrf" value="${csrf}">
              <div class="field full ${not empty errors.currentPassword ? 'has-error' : ''}">
                <label for="currentPassword">Mật khẩu hiện tại</label>
                <div class="pw-wrap">
                  <input id="currentPassword" name="currentPassword" type="password" autocomplete="current-password" required>
                  <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
                </div>
                <c:if test="${not empty errors.currentPassword}"><div class="error-text"><c:out value="${errors.currentPassword}"/></div></c:if>
              </div>
              <div class="field ${not empty errors.newPassword ? 'has-error' : ''}">
                <label for="newPassword">Mật khẩu mới</label>
                <div class="pw-wrap">
                  <input id="newPassword" name="newPassword" type="password" autocomplete="new-password" required>
                  <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
                </div>
                <c:if test="${not empty errors.newPassword}"><div class="error-text"><c:out value="${errors.newPassword}"/></div></c:if>
              </div>
              <div class="field ${not empty errors.confirmPassword ? 'has-error' : ''}">
                <label for="confirmPassword">Nhập lại mật khẩu mới</label>
                <div class="pw-wrap">
                  <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
                  <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
                </div>
                <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
              </div>
            </div>
            <div class="card-foot"><button class="btn btn-dark" type="submit">${ic.key}Cập nhật mật khẩu</button></div>
          </form>
        </section>
      </c:if>
    </div>
  </div>
</div>

<div class="crop-modal" id="cropModal" hidden role="dialog" aria-modal="true" aria-labelledby="cropTitle">
  <div class="crop-box">
    <h3 id="cropTitle">Cắt ảnh đại diện</h3>
    <p class="sub">Kéo ảnh để chọn vùng trong khung tròn, dùng thanh trượt hoặc con lăn chuột để phóng to.</p>
    <div class="crop-stage" id="cropStage"><canvas id="cropCanvas" width="600" height="600"></canvas></div>
    <label class="crop-zoom">Thu nhỏ
      <input type="range" id="cropZoom" min="1" max="4" step="0.01" value="1" aria-label="Phóng to ảnh">
    Phóng to</label>
    <div class="crop-actions">
      <button class="btn" type="button" id="cropCancel">Hủy</button>
      <button class="btn btn-primary" type="button" id="cropApply">Dùng vùng này</button>
    </div>
  </div>
</div>

<script src="${ctx}/assets/js/vn-locations.js"></script>
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
  if (!file || !pick) return;
  /* Ảnh chọn xong được cắt vuông trong khung, xuất JPEG 512x512 rồi mới gửi lên. */
  var OUT = 512, MAX_SOURCE = 15 * 1024 * 1024;
  var modal = document.getElementById('cropModal'), stage = document.getElementById('cropStage');
  var canvas = document.getElementById('cropCanvas'), ctx = canvas.getContext('2d');
  var zoomIn = document.getElementById('cropZoom'), form = file.form;
  var img = null, cropped = null, base = 1, zoom = 1, cx = 0, cy = 0, drag = null;
  function clamp() { var s = base * zoom, half = canvas.width / 2 / s; cx = Math.min(Math.max(cx, half), img.width - half); cy = Math.min(Math.max(cy, half), img.height - half); }
  function draw() { var s = base * zoom; clamp(); ctx.fillStyle = '#0b1324'; ctx.fillRect(0, 0, canvas.width, canvas.height); ctx.drawImage(img, canvas.width / 2 - cx * s, canvas.height / 2 - cy * s, img.width * s, img.height * s); }
  function setZoom(z, keep) { zoom = Math.min(4, Math.max(1, z)); zoomIn.value = zoom; if (!keep) draw(); }
  function openCropper(f) {
    var url = URL.createObjectURL(f), im = new Image();
    im.onload = function () { img = im; base = canvas.width / Math.min(im.width, im.height); cx = im.width / 2; cy = im.height / 2; setZoom(1, true); draw(); modal.hidden = false; zoomIn.focus(); };
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
  stage.addEventListener('pointerdown', function (e) { if (!img) return; drag = { x: e.clientX, y: e.clientY, cx: cx, cy: cy }; stage.setPointerCapture(e.pointerId); stage.classList.add('dragging'); });
  stage.addEventListener('pointermove', function (e) { if (!drag) return; var k = canvas.width / stage.clientWidth / (base * zoom); cx = drag.cx - (e.clientX - drag.x) * k; cy = drag.cy - (e.clientY - drag.y) * k; draw(); });
  ['pointerup', 'pointercancel'].forEach(function (t) { stage.addEventListener(t, function () { drag = null; stage.classList.remove('dragging'); }); });
  stage.addEventListener('wheel', function (e) { e.preventDefault(); setZoom(zoom * (e.deltaY < 0 ? 1.08 : 1 / 1.08)); }, { passive: false });
  zoomIn.addEventListener('input', function () { setZoom(parseFloat(zoomIn.value)); });
  document.getElementById('cropCancel').addEventListener('click', closeCropper);
  modal.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeCropper(); });
  document.getElementById('cropApply').addEventListener('click', function () {
    var out = document.createElement('canvas'), s = base * zoom, side = canvas.width / s;
    out.width = OUT; out.height = OUT;
    var o = out.getContext('2d'); o.fillStyle = '#fff'; o.fillRect(0, 0, OUT, OUT);
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
    var data = new FormData(form); data.set('avatar', cropped, 'avatar.jpg');
    save.disabled = true;
    fetch(form.action, { method: 'POST', body: data, credentials: 'same-origin' })
      .then(function (r) { location.href = r.url || location.href; })
      .catch(function () { save.disabled = false; showToast('Không gửi được ảnh, hãy thử lại.', 'error'); });
  });
})();
</script>
<c:if test="${passwordOpen}"><script>document.getElementById('password').scrollIntoView({ block: 'start' });</script></c:if>
<%@ include file="../layout/bottom.jspf" %>
