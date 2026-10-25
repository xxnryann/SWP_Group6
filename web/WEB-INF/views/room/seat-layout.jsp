<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Layout ghế · ${room.roomName}"/>
<%@ include file="../_header.jspf" %>
<style>
  .rm-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .rm-head h1 { margin: 0; }
  .rm-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .rm-stats { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
  .rm-stat { background: #fff; border: 1px solid var(--slate-200); border-radius: var(--radius); padding: 10px 16px; font-size: 13px; color: var(--slate-500); }
  .rm-stat b { display: block; font-size: 20px; color: var(--navy); }
  .rm-panel { background: #fff; border: 1px solid var(--slate-200); border-radius: 14px; box-shadow: var(--shadow); padding: 24px; margin-bottom: 24px; }
  .rm-panel h2 { margin: 0 0 4px; font-size: 18px; }
  .rm-panel .sub { color: var(--slate-500); font-size: 13.5px; margin-bottom: 16px; }

  .seatmap { display: flex; flex-direction: column; gap: 8px; align-items: center; overflow-x: auto; padding: 8px 4px 16px; }
  .screen { width: 62%; min-width: 260px; text-align: center; color: #fff; padding: 9px; margin-bottom: 18px;
            background: linear-gradient(180deg, var(--navy), var(--slate-700)); border-radius: 6px 6px 26px 26px;
            letter-spacing: 6px; font-weight: 700; font-size: 12.5px; }
  .seat-row { display: flex; gap: 6px; align-items: center; }
  .row-label { width: 24px; font-weight: 800; text-align: center; color: var(--slate-500); font-size: 13px; }
  .row-tools { margin-left: 12px; }
  .row-tools form { display: flex; gap: 4px; align-items: center; }
  .row-tools select { padding: 4px 6px; font: 12px var(--font); border: 1px solid var(--slate-300); border-radius: 6px; background: #fff; }
  .row-tools button { padding: 4px 9px; font-size: 12px; border-radius: 6px; }

  .seat { position: relative; display: inline-block; cursor: pointer; }
  .seat input { position: absolute; opacity: 0; inset: 0; width: 100%; height: 100%; margin: 0; cursor: pointer; }
  .seat span { display: block; width: 42px; height: 38px; line-height: 34px; text-align: center; border-radius: 10px 10px 4px 4px;
               border: 2px solid var(--slate-300); font: 700 11.5px/34px var(--font); background: #fff; color: var(--slate-700);
               transition: transform .08s, background .12s; }
  .seat:hover span { transform: translateY(-2px); }
  .seat.t-Standard span { background: #ecfdf5; border-color: var(--success); color: #065f46; }
  .seat.t-VIP span { background: #fef3c7; border-color: var(--accent); color: #92400e; }
  .seat.t-Couple span { background: #fce7f3; border-color: #db2777; color: #9d174d; }
  .seat.couple-left { margin-right: -6px; }
  .seat.couple-left span { border-radius: 10px 0 0 4px; width: 46px; border-right-width: 1px; }
  .seat.couple-right span { border-radius: 0 10px 4px 0; width: 46px; border-left-width: 1px; }
  .seat.maint span { background: var(--slate-200); border-color: var(--slate-400); color: var(--slate-500);
                     background-image: repeating-linear-gradient(45deg, transparent 0 5px, rgba(100,116,139,.25) 5px 7px); }
  .seat input:checked + span { background: var(--brand); border-color: var(--brand); color: #fff; box-shadow: 0 0 0 3px rgba(29,78,216,.30); background-image: none; }

  .legend { display: flex; gap: 16px; flex-wrap: wrap; margin: 6px 0 14px; font-size: 13px; color: var(--slate-600); }
  .legend i { display: inline-block; width: 18px; height: 16px; border-radius: 5px; border: 2px solid; vertical-align: -3px; margin-right: 6px; }
  .legend .l-std { background: #ecfdf5; border-color: var(--success); }
  .legend .l-vip { background: #fef3c7; border-color: var(--accent); }
  .legend .l-cpl { background: #fce7f3; border-color: #db2777; }
  .legend .l-mnt { background: var(--slate-200); border-color: var(--slate-400); }
  .legend .l-sel { background: var(--brand); border-color: var(--brand); }

  .maint-bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-top: 8px; }
  .maint-bar .count { color: var(--slate-500); font-size: 13.5px; }
  .layout-grid { display: grid; grid-template-columns: 140px 140px 1fr; gap: 16px; align-items: start; }
  .layout-grid .field { margin: 0; }
  .row-types { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; margin: 14px 0; }
  .row-types label { display: block; font-size: 12px; font-weight: 700; color: var(--slate-600); margin-bottom: 3px; }
  .row-types select { width: 100%; padding: 7px 8px; font: 13px var(--font); border: 1px solid var(--slate-300); border-radius: 8px; background: #fff; }
  .rm-warnbox { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; border-radius: var(--radius); padding: 10px 14px; font-size: 13.5px; margin-bottom: 12px; }
  .rm-empty { text-align: center; padding: 30px 10px; color: var(--slate-500); }
  @media (max-width: 720px) { .layout-grid { grid-template-columns: 1fr 1fr; } .layout-grid > :last-child { grid-column: 1 / -1; } }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="rm-head">
        <div>
          <h1><c:out value="${room.roomName}"/> <span class="chip"><c:out value="${room.roomType}"/></span></h1>
          <p><c:out value="${room.cinemaName}"/> · Thiết lập layout ghế, loại ghế và bảo trì ghế.</p>
        </div>
        <div>
          <a class="btn btn-soft" href="${ctx}/admin/rooms?action=edit&id=${room.roomId}">Sửa thông tin phòng</a>
          <a class="btn btn-outline" href="${ctx}/admin/rooms">← Danh sách phòng</a>
        </div>
      </div>

      <div class="rm-stats">
        <div class="rm-stat"><b>${room.capacity}</b>Sức chứa</div>
        <div class="rm-stat"><b>${seatTotal}</b>Số ghế hiện có</div>
        <div class="rm-stat"><b>${room.maintenanceCount}</b>Đang bảo trì</div>
        <div class="rm-stat"><b>${room.upcomingShowtimes}</b>Suất chiếu sắp tới</div>
      </div>

      <%-- ================= Sơ đồ ghế + bảo trì ================= --%>
      <div class="rm-panel">
        <h2>Sơ đồ ghế &amp; bảo trì</h2>
        <p class="sub">Chọn ghế rồi bấm “Bảo trì” để chặn đặt vé, hoặc “Mở lại” khi bảo trì xong. Ghế đôi luôn được xử lý cả cặp.</p>
        <c:choose>
          <c:when test="${seatTotal == 0}">
            <div class="rm-empty">Phòng chưa có layout ghế. Hãy thiết lập layout ở phần bên dưới.</div>
          </c:when>
          <c:otherwise>
            <div class="legend">
              <span><i class="l-std"></i>Ghế thường</span>
              <span><i class="l-vip"></i>Ghế VIP</span>
              <span><i class="l-cpl"></i>Ghế đôi (cặp)</span>
              <span><i class="l-mnt"></i>Đang bảo trì</span>
              <span><i class="l-sel"></i>Đã chọn</span>
            </div>
            <div class="seatmap">
              <div class="screen">MÀN HÌNH</div>
              <c:forEach var="row" items="${seatRows}">
                <div class="seat-row">
                  <div class="row-label"><c:out value="${row.key}"/></div>
                  <c:forEach var="s" items="${row.value}">
                    <label class="seat t-${s.seatTypeName}${s.couple ? (s.seatNumber % 2 == 1 ? ' couple-left' : ' couple-right') : ''}${s.maintenance ? ' maint' : ''}"
                           title="${s.label} · ${s.seatTypeName}${s.maintenance ? ' · đang bảo trì' : ''}">
                      <input type="checkbox" name="seatIds" value="${s.seatId}" form="maintForm"
                             <c:if test="${s.pairSeatId != null}">data-pair="${s.pairSeatId}"</c:if>>
                      <span>${s.label}</span>
                    </label>
                  </c:forEach>
                  <div class="row-tools">
                    <form method="post" action="${ctx}/admin/seats">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="rowType">
                      <input type="hidden" name="roomId" value="${room.roomId}">
                      <input type="hidden" name="row" value="<c:out value='${row.key}'/>">
                      <select name="typeId" aria-label="Loại ghế hàng ${row.key}">
                        <c:forEach var="t" items="${seatTypes}">
                          <option value="${t.seatTypeId}" ${t.seatTypeId == row.value[0].seatTypeId ? 'selected' : ''}><c:out value="${t.typeName}"/></option>
                        </c:forEach>
                      </select>
                      <button class="btn btn-soft" type="submit">Đổi loại</button>
                    </form>
                  </div>
                </div>
              </c:forEach>
            </div>

            <form id="maintForm" method="post" action="${ctx}/admin/seats">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="roomId" value="${room.roomId}">
              <div class="maint-bar">
                <button class="btn btn-danger" type="submit" name="action" value="maintain" id="btnMaintain" disabled>Bảo trì ghế đã chọn</button>
                <button class="btn btn-primary" type="submit" name="action" value="reopen" id="btnReopen" disabled>Mở lại ghế đã chọn</button>
                <button class="btn btn-outline" type="button" id="btnClear">Bỏ chọn</button>
                <span class="count" id="selCount">Chưa chọn ghế nào</span>
              </div>
            </form>
          </c:otherwise>
        </c:choose>
      </div>

      <%-- ================= Thiết lập layout ================= --%>
      <div class="rm-panel">
        <h2>Thiết lập layout ghế</h2>
        <p class="sub">Nhập số hàng, số ghế mỗi hàng và chọn loại ghế cho từng hàng (hàng A là hàng gần màn hình nhất). Ghế đôi được ghép cặp 1-2, 3-4, … nên số ghế mỗi hàng phải chẵn.</p>
        <c:if test="${seatTotal > 0}">
          <div class="rm-warnbox">
            Phòng đã có ${seatTotal} ghế. Bấm “Áp dụng layout” sẽ <strong>thay thế toàn bộ</strong> layout hiện tại
            (cả trạng thái bảo trì). Nếu ghế đã từng có vé, hệ thống sẽ từ chối — khi đó hãy dùng “Đổi loại” theo từng hàng ở trên.
          </div>
        </c:if>
        <form id="layoutForm" method="post" action="${ctx}/admin/seats">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="generate">
          <input type="hidden" name="roomId" value="${room.roomId}">
          <input type="hidden" name="rowTypes" id="rowTypes" value="<c:out value='${layoutRowTypes}'/>">
          <div class="layout-grid">
            <div class="field">
              <label for="f-rows">Số hàng (1–26)</label>
              <input id="f-rows" type="number" name="rows" min="1" max="26" value="${layoutRows}" required>
            </div>
            <div class="field">
              <label for="f-cols">Ghế mỗi hàng (1–30)</label>
              <input id="f-cols" type="number" name="cols" min="1" max="30" value="${layoutCols}" required>
            </div>
            <div class="hint" style="align-self:end;color:var(--slate-500);font-size:13px">
              Loại ghế:
              <c:forEach var="t" items="${seatTypes}" varStatus="vs"><c:out value="${t.typeName}"/><c:if test="${t.couple}"> (đôi)</c:if><c:if test="${!vs.last}">, </c:if></c:forEach>
            </div>
          </div>
          <div class="row-types" id="rowTypeBox"></div>
          <p class="alert alert-error" id="layoutErr" style="display:none"></p>
          <button class="btn btn-cta" type="submit">Áp dụng layout</button>
        </form>

        <template id="typeTpl">
          <c:forEach var="t" items="${seatTypes}">
            <option value="${t.seatTypeId}" data-couple="${t.couple}"><c:out value="${t.typeName}"/></option>
          </c:forEach>
        </template>
      </div>
    </div>
  </section>
</main>

<script>
(function () {
  /* ---------- chọn ghế để bảo trì ---------- */
  var boxes = Array.prototype.slice.call(document.querySelectorAll('input[name="seatIds"]'));
  var byId = {};
  boxes.forEach(function (b) { byId[b.value] = b; });
  var btnM = document.getElementById('btnMaintain'), btnR = document.getElementById('btnReopen');
  var cnt = document.getElementById('selCount');

  function refresh() {
    var n = boxes.filter(function (b) { return b.checked; }).length;
    if (btnM) btnM.disabled = n === 0;
    if (btnR) btnR.disabled = n === 0;
    if (cnt) cnt.textContent = n === 0 ? 'Chưa chọn ghế nào' : 'Đã chọn ' + n + ' ghế';
  }
  boxes.forEach(function (b) {
    b.addEventListener('change', function () {
      var p = b.getAttribute('data-pair');           /* ghế đôi: chọn/bỏ cả cặp */
      if (p && byId[p]) byId[p].checked = b.checked;
      refresh();
    });
  });
  var clr = document.getElementById('btnClear');
  if (clr) clr.addEventListener('click', function () { boxes.forEach(function (b) { b.checked = false; }); refresh(); });
  refresh();

  /* ---------- form layout: chọn loại ghế theo từng hàng ---------- */
  var rowsIn = document.getElementById('f-rows'), colsIn = document.getElementById('f-cols');
  var box = document.getElementById('rowTypeBox'), hidden = document.getElementById('rowTypes');
  var tpl = document.getElementById('typeTpl'), err = document.getElementById('layoutErr');
  var current = hidden.value ? hidden.value.split(',') : [];

  function build() {
    var n = parseInt(rowsIn.value, 10);
    if (isNaN(n) || n < 1) n = 0;
    if (n > 26) n = 26;
    var keep = Array.prototype.map.call(box.querySelectorAll('select'), function (s) { return s.value; });
    if (keep.length) current = keep;
    box.innerHTML = '';
    for (var i = 0; i < n; i++) {
      var wrap = document.createElement('div');
      var lab = document.createElement('label');
      lab.textContent = 'Hàng ' + String.fromCharCode(65 + i);
      var sel = document.createElement('select');
      sel.innerHTML = tpl.innerHTML;
      var want = current[i] !== undefined ? current[i] : current[current.length - 1];
      if (want !== undefined) sel.value = want;
      wrap.appendChild(lab); wrap.appendChild(sel); box.appendChild(wrap);
    }
  }
  rowsIn.addEventListener('input', build);
  build();

  document.getElementById('layoutForm').addEventListener('submit', function (e) {
    var sels = box.querySelectorAll('select'), cols = parseInt(colsIn.value, 10), msg = '';
    if (!sels.length) msg = 'Số hàng không hợp lệ.';
    Array.prototype.forEach.call(sels, function (s, i) {
      if (s.options[s.selectedIndex].getAttribute('data-couple') === 'true' && cols % 2 !== 0)
        msg = 'Hàng ' + String.fromCharCode(65 + i) + ' là ghế đôi nên số ghế mỗi hàng phải là số chẵn.';
    });
    if (msg) { e.preventDefault(); err.textContent = msg; err.style.display = 'block'; return; }
    err.style.display = 'none';
    hidden.value = Array.prototype.map.call(sels, function (s) { return s.value; }).join(',');
    if (${seatTotal > 0} && !confirm('Thay thế toàn bộ layout ghế hiện tại?')) e.preventDefault();
  });
})();
</script>
<%@ include file="../_footer.jspf" %>
