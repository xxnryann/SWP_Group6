<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="seat" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle" value="Layout ghế · ${room.roomName}"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .rm-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .rm-head h1 { margin: 0; }
  .rm-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .rm-stats { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
  .rm-stat { background: #fff; border: 1px solid var(--slate-200); border-radius: var(--radius); padding: 10px 16px; font-size: 13px; color: var(--slate-500); }
  .rm-stat b { display: block; font-size: 20px; color: var(--navy); }
  .rm-panel { background: #fff; border: 1px solid var(--slate-200); border-radius: 14px; box-shadow: var(--shadow); padding: 32px; margin-bottom: 24px; }
  .rm-panel h2 { margin: 0 0 4px; font-size: 18px; }
  .rm-panel .sub { color: var(--slate-500); font-size: 13.5px; margin-bottom: 16px; }

  .row-tools { flex: none; display: flex; gap: 8px; align-items: center; }
  .row-tools select { padding: 5px 8px; font: 13px var(--font); border: 1px solid var(--slate-300); border-radius: 7px; background: #fff; min-width: 130px; }
  .row-tools button { padding: 5px 12px; font-size: 13px; border-radius: 7px; white-space: nowrap; }
  .rm-okbox { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; border-radius: var(--radius); padding: 10px 14px; font-size: 13.5px; margin-bottom: 12px; }

  .maint-bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; margin-top: 8px; }
  .maint-bar .count { color: var(--slate-500); font-size: 13.5px; }
  .layout-grid { display: grid; grid-template-columns: repeat(3, 160px); gap: 16px; align-items: start; }
  .layout-note { color: var(--slate-500); font-size: 13px; margin: 10px 0 0; }
  .layout-sum { margin: 12px 0 0; padding: 10px 14px; border-radius: var(--radius); font-size: 13.5px; border: 1px solid; }
  .layout-sum.ok { background: #ecfdf5; border-color: #a7f3d0; color: #065f46; }
  .layout-sum.bad { background: #fef2f2; border-color: #fecaca; color: #991b1b; }
  .layout-sum button { margin-left: 8px; padding: 4px 10px; font-size: 12.5px; border-radius: 6px; }
  .layout-grid .field { margin: 0; }
  .row-types { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; margin: 14px 0; }
  .row-types label { display: block; font-size: 12px; font-weight: 700; color: var(--slate-600); margin-bottom: 3px; }
  .row-types select { width: 100%; padding: 7px 8px; font: 13px var(--font); border: 1px solid var(--slate-300); border-radius: 8px; background: #fff; }
  .rm-warnbox { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; border-radius: var(--radius); padding: 10px 14px; font-size: 13.5px; margin-bottom: 12px; }
  .rm-empty { text-align: center; padding: 30px 10px; color: var(--slate-500); }
  @media (max-width: 720px) { .layout-grid { grid-template-columns: 1fr 1fr; } .layout-grid > :last-child { grid-column: 1 / -1; } }
</style>
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
        <c:choose>
          <c:when test="${seatTotal == 0}">
            <div class="rm-empty">Phòng chưa có layout ghế. Hãy thiết lập layout ở phần bên dưới.</div>
          </c:when>
          <c:otherwise>
            <div class="sp-legend">
              <span><i class="l-una"></i>Chưa chọn loại</span>
              <span><i></i>Ghế thường</span>
              <span><i class="l-vip"></i>Ghế VIP</span>
              <span><i class="l-cpl"></i>Ghế đôi (cặp)</span>
              <span><i class="l-mnt"></i>Đang bảo trì</span>
              <span><i class="l-sel"></i>Đã chọn</span>
            </div>
            <seat:plan variant="${planVariant}">
              <c:remove var="prevType"/>
              <c:forEach var="row" items="${seatRows}">
                <c:set var="rowType" value="${row.value[0].seatTypeName}"/>
                <c:if test="${rowType != prevType}"><seat:rowDivider type="${rowType}" variant="${planVariant}"/></c:if>
                <c:set var="prevType" value="${rowType}"/>
                <div class="sp-line" data-row="${row.key}">
                  <div class="seat-row row-${rowType}">
                    <span class="row-label"><c:out value="${row.key}"/></span>
                    <c:forEach var="s" items="${row.value}">
                      <c:set var="isAisle" value="${s.couple ? coupleAisles.contains(s.seatNumber) : fixedLayout && (s.seatNumber == aisleFromStart || (aisleFromEnd > 0 && s.seatNumber == row.value.size() - aisleFromEnd))}"/>
                      <c:set var="useWings" value="${planVariant == '3d' && !s.couple}"/>
                      <c:set var="opensPod" value="${planVariant == '4dx' && (s.couple ? s.seatNumber % 2 == 1 : s.seatNumber % 4 == 1)}"/>
                      <c:set var="closesPod" value="${planVariant == '4dx' && (s.couple ? s.seatNumber % 2 == 0 : (s.seatNumber % 4 == 0 || s.seatNumber == row.value.size()))}"/>
                      <c:if test="${opensPod}"><seat:podOpen row="${row.key}" number="${s.seatNumber}" couple="${s.couple}" seatType="${s.seatTypeName}" zone="${seatZones[s.label]}"/></c:if>
                      <c:if test="${useWings && s.seatNumber == 1}"><div class="sp-block sp-wing-l"></c:if>
                      <label class="seat t-${s.seatTypeName}${s.couple ? (s.seatNumber % 2 == 1 ? ' pair-l' : ' pair-r') : ''}${s.maintenance ? ' maint' : ''}"
                             title="${s.label} · ${s.seatTypeName}${s.maintenance ? ' · đang bảo trì' : ''}"
                             data-zone="${seatZones[s.label]}">
                        <input type="checkbox" name="seatIds" value="${s.seatId}" form="maintForm" aria-label="${s.label}"
                               <c:if test="${s.pairSeatId != null}">data-pair="${s.pairSeatId}"</c:if>>
                        <span>${s.seatNumber}</span>
                      </label>
                      <c:if test="${closesPod}"></div></c:if>
                      <c:if test="${useWings && isAisle}"></div></c:if>
                      <c:if test="${isAisle}"><span class="sp-gap"></span></c:if>
                      <c:if test="${useWings && isAisle}"><div class="sp-block ${s.seatNumber == 3 ? 'sp-center' : 'sp-wing-r'}"></c:if>
                      <c:if test="${useWings && s.seatNumber == row.value.size()}"></div></c:if>
                    </c:forEach>
                    <span class="row-label"><c:out value="${row.key}"/></span>
                  </div>
                  <c:if test="${!fixedLayout}">
                    <form class="row-tools" method="post" action="${ctx}/admin/seats">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="rowType">
                      <input type="hidden" name="roomId" value="${room.roomId}">
                      <input type="hidden" name="row" value="<c:out value='${row.key}'/>">
                      <select name="typeId" aria-label="Loại ghế hàng ${row.key}">
                        <c:choose>
                          <c:when test="${rowType == 'Unassigned'}">
                            <option value="" disabled selected>Chọn loại ghế</option>
                          </c:when>
                          <c:otherwise>
                            <option value="" disabled>Chọn loại ghế</option>
                          </c:otherwise>
                        </c:choose>
                        <c:forEach var="t" items="${seatTypes}">
                          <c:if test="${t.typeName != 'Unassigned'}">
                            <option value="${t.seatTypeId}" ${t.seatTypeId == row.value[0].seatTypeId ? 'selected' : ''}><c:out value="${t.typeName}"/></option>
                          </c:if>
                        </c:forEach>
                      </select>
                      <button class="btn btn-soft" type="submit">Đổi loại</button>
                    </form>
                  </c:if>
                </div>
              </c:forEach>
            </seat:plan>

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
      <c:choose>
        <c:when test="${fixedLayout}">
          <div class="rm-panel">
            <h2>Layout cố định của rạp ${room.roomType}</h2>
            <p class="sub">${fixedSummary}</p>
            <c:choose>
              <c:when test="${layoutMatchesFixed}">
                <div class="rm-okbox">Phòng đang dùng đúng layout chuẩn ${room.roomType}.</div>
              </c:when>
              <c:otherwise>
                <div class="rm-warnbox">
                  Phòng đang có ${seatTotal} ghế, chưa đúng layout chuẩn ${room.roomType}. Áp dụng sẽ giữ nguyên các ghế còn dùng và lịch sử vé.
                  Hệ thống từ chối nếu ghế cần đổi loại đang có vé còn hiệu lực.
                </div>
                <form method="post" action="${ctx}/admin/seats">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="applyFixed">
                  <input type="hidden" name="roomId" value="${room.roomId}">
                  <button class="btn btn-cta" type="submit">Áp dụng layout chuẩn ${room.roomType}</button>
                </form>
              </c:otherwise>
            </c:choose>
          </div>
        </c:when>
        <c:otherwise>
      <div class="rm-panel">
        <h2>Thiết lập layout ghế</h2>
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
              <label for="f-total">Tổng số ghế (1–500)</label>
              <input id="f-total" type="number" name="total" min="1" max="500" value="${layoutTotal}" required>
            </div>
            <div class="field">
              <label for="f-rows">Số hàng (1–26)</label>
              <input id="f-rows" type="number" name="rows" min="1" max="26" value="${layoutRows}" required>
            </div>
            <div class="field">
              <label for="f-cols">Ghế mỗi hàng (1–30)</label>
              <input id="f-cols" type="number" name="cols" min="1" max="30" value="${layoutCols}" required>
            </div>
          </div>
          <p class="layout-note">
            Mặc định bằng sức chứa của phòng (${room.capacity}). Các hàng đầu đủ số ghế mỗi hàng, <b>hàng cuối nhận phần
            còn lại</b> nên có thể ít ghế hơn. Áp dụng layout sẽ đặt sức chứa phòng bằng tổng số ghế.
          </p>
          <div class="layout-sum" id="layoutSum" aria-live="polite"></div>
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
        </c:otherwise>
      </c:choose>

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

  /* ---------- form layout: tổng số ghế, hàng × cột (hàng cuối nhận phần còn lại), loại ghế theo từng hàng ---------- */
  var totalIn = document.getElementById('f-total');
  var rowsIn = document.getElementById('f-rows'), colsIn = document.getElementById('f-cols');
  if (!rowsIn) return;
  var box = document.getElementById('rowTypeBox'), hidden = document.getElementById('rowTypes');
  var tpl = document.getElementById('typeTpl'), err = document.getElementById('layoutErr');
  var sum = document.getElementById('layoutSum');
  var current = hidden.value ? hidden.value.split(',') : [];
  var MAX_ROWS = 26, MAX_COLS = 30, MAX_TOTAL = 500;

  function L(i) { return String.fromCharCode(65 + i); }
  function num(input) { var v = parseInt(input.value, 10); return isNaN(v) ? 0 : v; }
  /* Số ghế của hàng i (hàng cuối nhận phần còn lại). */
  function seatsOfRow(i, rows, cols, total) { return i < rows - 1 ? cols : total - (rows - 1) * cols; }
  function lastNote(rows, cols, total) {
    var last = total - (rows - 1) * cols;
    return last < cols ? ' (hàng ' + L(rows - 1) + ' có ' + last + ' ghế)' : '';
  }
  /* Giống RoomRules.suggestGrid: ưu tiên chia hết, hàng dài khoảng gấp đôi số hàng; không thì hàng cuối ngắn hơn. */
  function suggest(total) {
    total = Math.max(1, Math.min(MAX_TOTAL, total));
    var minCols = Math.max(1, Math.ceil(total / MAX_ROWS)), best = null, bestScore = 1e9;
    for (var c = Math.max(minCols, 6); c <= Math.min(MAX_COLS, 20); c++) {
      if (total % c !== 0) continue;
      var r = total / c, score = Math.abs(c - 2 * r);
      if (score < bestScore) { bestScore = score; best = [r, c]; }
    }
    if (best) return best;
    var cols = Math.round(Math.sqrt(total * 2));
    cols = Math.max(minCols, Math.min(Math.min(MAX_COLS, 20), Math.max(Math.min(total, 6), cols)));
    return [Math.ceil(total / cols), cols];
  }
  /* Giống RoomRules.validateLayout: trả về lỗi kèm gợi ý, hoặc '' nếu hợp lệ. */
  function layoutError(rows, cols, total) {
    if (rows < 1 || rows > MAX_ROWS) return 'Số hàng phải từ 1 đến 26 (A–Z).';
    if (cols < 1 || cols > MAX_COLS) return 'Số ghế mỗi hàng phải từ 1 đến 30.';
    if (total < 1 || total > MAX_TOTAL) return 'Tổng số ghế phải từ 1 đến 500.';
    var fit = rows * cols;
    if (fit < total) {
      var needRows = Math.ceil(total / cols), needCols = Math.ceil(total / rows), hint = [];
      if (needRows <= MAX_ROWS) hint.push('tăng lên ' + needRows + ' hàng' + lastNote(needRows, cols, total));
      if (needCols <= MAX_COLS) hint.push('tăng lên ' + needCols + ' ghế mỗi hàng' + lastNote(rows, needCols, total));
      return 'Layout ' + rows + ' hàng × ' + cols + ' ghế chỉ chứa ' + fit + ' ghế, thiếu ' + (total - fit)
          + ' ghế so với tổng ' + total + '.' + (hint.length ? ' Hãy ' + hint.join(', hoặc ') + '.' : '')
          + ' Hoặc giảm tổng số ghế xuống ' + fit + '.';
    }
    if ((rows - 1) * cols >= total) {
      var need = Math.ceil(total / cols);
      return 'Với ' + total + ' ghế và ' + cols + ' ghế mỗi hàng chỉ cần ' + need + ' hàng' + lastNote(need, cols, total)
          + '; hàng ' + L(rows - 1) + ' sẽ không có ghế nào. Hãy giảm số hàng xuống ' + need + '.';
    }
    return '';
  }
  function shapeText(rows, cols, total) {
    var last = total - (rows - 1) * cols;
    if (last === cols || rows === 1) return rows + ' hàng × ' + cols + ' ghế = ' + total + ' ghế';
    return rows + ' hàng: ' + L(0) + (rows > 2 ? '–' + L(rows - 2) : '') + ' mỗi hàng ' + cols + ' ghế, hàng '
        + L(rows - 1) + ' có ' + last + ' ghế = ' + total + ' ghế';
  }

  function build() {
    var n = num(rowsIn);
    if (n < 1) n = 0;
    if (n > MAX_ROWS) n = MAX_ROWS;
    var keep = Array.prototype.map.call(box.querySelectorAll('select'), function (s) { return s.value; });
    if (keep.length) current = keep;
    box.innerHTML = '';
    for (var i = 0; i < n; i++) {
      var wrap = document.createElement('div');
      var lab = document.createElement('label');
      lab.setAttribute('data-row', i);
      var sel = document.createElement('select');
      sel.innerHTML = tpl.innerHTML;
      var want = current[i] !== undefined ? current[i] : current[current.length - 1];
      if (want !== undefined) sel.value = want;
      wrap.appendChild(lab); wrap.appendChild(sel); box.appendChild(wrap);
    }
    refreshSummary();
  }

  /* Cập nhật nhãn "Hàng E · 6 ghế" và dòng tóm tắt; trả về lỗi hiện tại ('' nếu hợp lệ). */
  function refreshSummary() {
    var rows = num(rowsIn), cols = num(colsIn), total = num(totalIn);
    var msg = layoutError(rows, cols, total);
    Array.prototype.forEach.call(box.querySelectorAll('label[data-row]'), function (lab) {
      var i = parseInt(lab.getAttribute('data-row'), 10), s = seatsOfRow(i, rows, cols, total);
      lab.textContent = 'Hàng ' + L(i) + (msg ? '' : ' · ' + s + ' ghế');
    });
    sum.innerHTML = '';
    sum.className = 'layout-sum ' + (msg ? 'bad' : 'ok');
    sum.appendChild(document.createTextNode(msg || ('Layout: ' + shapeText(rows, cols, total) + '.')));
    var g = suggest(total);
    if (total >= 1 && total <= MAX_TOTAL && (g[0] !== rows || g[1] !== cols)) {
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'btn btn-soft';
      b.textContent = 'Dùng gợi ý ' + g[0] + ' hàng × ' + g[1] + ' ghế' + lastNote(g[0], g[1], total);
      b.addEventListener('click', function () { rowsIn.value = g[0]; colsIn.value = g[1]; build(); });
      sum.appendChild(b);
    }
    return msg;
  }
  rowsIn.addEventListener('input', build);
  colsIn.addEventListener('input', refreshSummary);
  totalIn.addEventListener('input', refreshSummary);
  build();

  document.getElementById('layoutForm').addEventListener('submit', function (e) {
    var sels = box.querySelectorAll('select'), msg = refreshSummary();
    var rows = num(rowsIn), cols = num(colsIn), total = num(totalIn);
    if (!msg && !sels.length) msg = 'Số hàng không hợp lệ.';
    if (!msg) Array.prototype.forEach.call(sels, function (s, i) {
      var n = seatsOfRow(i, rows, cols, total);
      if (!msg && s.options[s.selectedIndex].getAttribute('data-couple') === 'true' && n % 2 !== 0)
        msg = 'Hàng ' + L(i) + ' là ghế đôi nên phải có số ghế chẵn (đang có ' + n + ' ghế).';
    });
    if (msg) { e.preventDefault(); err.textContent = msg; err.style.display = 'block'; return; }
    err.style.display = 'none';
    hidden.value = Array.prototype.map.call(sels, function (s) { return s.value; }).join(',');
    if (${seatTotal > 0} && !confirm('Thay thế toàn bộ layout ghế hiện tại?')) e.preventDefault();
  });
})();
</script>
<%@ include file="../layout/bottom.jspf" %>



