﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Layout gháº¿ Â· ${room.roomName}"/>
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
      <div class="dash-layout">
        <div>
      <div class="rm-head">
        <div>
          <h1><c:out value="${room.roomName}"/> <span class="chip"><c:out value="${room.roomType}"/></span></h1>
          <p><c:out value="${room.cinemaName}"/> Â· Thiáº¿t láº­p layout gháº¿, loáº¡i gháº¿ vÃ  báº£o trÃ¬ gháº¿.</p>
        </div>
        <div>
          <a class="btn btn-soft" href="${ctx}/admin/rooms?action=edit&id=${room.roomId}">Sá»­a thÃ´ng tin phÃ²ng</a>
          <a class="btn btn-outline" href="${ctx}/admin/rooms">â† Danh sÃ¡ch phÃ²ng</a>
        </div>
      </div>

      <div class="rm-stats">
        <div class="rm-stat"><b>${room.capacity}</b>Sá»©c chá»©a</div>
        <div class="rm-stat"><b>${seatTotal}</b>Sá»‘ gháº¿ hiá»‡n cÃ³</div>
        <div class="rm-stat"><b>${room.maintenanceCount}</b>Äang báº£o trÃ¬</div>
        <div class="rm-stat"><b>${room.upcomingShowtimes}</b>Suáº¥t chiáº¿u sáº¯p tá»›i</div>
      </div>

      <%-- ================= SÆ¡ Ä‘á»“ gháº¿ + báº£o trÃ¬ ================= --%>
      <div class="rm-panel">
        <h2>SÆ¡ Ä‘á»“ gháº¿ &amp; báº£o trÃ¬</h2>
        <p class="sub">Chá»n gháº¿ rá»“i báº¥m â€œBáº£o trÃ¬â€ Ä‘á»ƒ cháº·n Ä‘áº·t vÃ©, hoáº·c â€œMá»Ÿ láº¡iâ€ khi báº£o trÃ¬ xong. Gháº¿ Ä‘Ã´i luÃ´n Ä‘Æ°á»£c xá»­ lÃ½ cáº£ cáº·p.</p>
        <c:choose>
          <c:when test="${seatTotal == 0}">
            <div class="rm-empty">PhÃ²ng chÆ°a cÃ³ layout gháº¿. HÃ£y thiáº¿t láº­p layout á»Ÿ pháº§n bÃªn dÆ°á»›i.</div>
          </c:when>
          <c:otherwise>
            <div class="legend">
              <span><i class="l-std"></i>Gháº¿ thÆ°á»ng</span>
              <span><i class="l-vip"></i>Gháº¿ VIP</span>
              <span><i class="l-cpl"></i>Gháº¿ Ä‘Ã´i (cáº·p)</span>
              <span><i class="l-mnt"></i>Äang báº£o trÃ¬</span>
              <span><i class="l-sel"></i>ÄÃ£ chá»n</span>
            </div>
            <div class="seatmap">
              <div class="screen">MÃ€N HÃŒNH</div>
              <c:forEach var="row" items="${seatRows}">
                <div class="seat-row">
                  <div class="row-label"><c:out value="${row.key}"/></div>
                  <c:forEach var="s" items="${row.value}">
                    <label class="seat t-${s.seatTypeName}${s.couple ? (s.seatNumber % 2 == 1 ? ' couple-left' : ' couple-right') : ''}${s.maintenance ? ' maint' : ''}"
                           title="${s.label} Â· ${s.seatTypeName}${s.maintenance ? ' Â· Ä‘ang báº£o trÃ¬' : ''}">
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
                      <select name="typeId" aria-label="Loáº¡i gháº¿ hÃ ng ${row.key}">
                        <c:forEach var="t" items="${seatTypes}">
                          <option value="${t.seatTypeId}" ${t.seatTypeId == row.value[0].seatTypeId ? 'selected' : ''}><c:out value="${t.typeName}"/></option>
                        </c:forEach>
                      </select>
                      <button class="btn btn-soft" type="submit">Äá»•i loáº¡i</button>
                    </form>
                  </div>
                </div>
              </c:forEach>
            </div>

            <form id="maintForm" method="post" action="${ctx}/admin/seats">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="roomId" value="${room.roomId}">
              <div class="maint-bar">
                <button class="btn btn-danger" type="submit" name="action" value="maintain" id="btnMaintain" disabled>Báº£o trÃ¬ gháº¿ Ä‘Ã£ chá»n</button>
                <button class="btn btn-primary" type="submit" name="action" value="reopen" id="btnReopen" disabled>Má»Ÿ láº¡i gháº¿ Ä‘Ã£ chá»n</button>
                <button class="btn btn-outline" type="button" id="btnClear">Bá» chá»n</button>
                <span class="count" id="selCount">ChÆ°a chá»n gháº¿ nÃ o</span>
              </div>
            </form>
          </c:otherwise>
        </c:choose>
      </div>

      <%-- ================= Thiáº¿t láº­p layout ================= --%>
      <div class="rm-panel">
        <h2>Thiáº¿t láº­p layout gháº¿</h2>
        <p class="sub">Nháº­p sá»‘ hÃ ng, sá»‘ gháº¿ má»—i hÃ ng vÃ  chá»n loáº¡i gháº¿ cho tá»«ng hÃ ng (hÃ ng A lÃ  hÃ ng gáº§n mÃ n hÃ¬nh nháº¥t). Gháº¿ Ä‘Ã´i Ä‘Æ°á»£c ghÃ©p cáº·p 1-2, 3-4, â€¦ nÃªn sá»‘ gháº¿ má»—i hÃ ng pháº£i cháºµn.</p>
        <c:if test="${seatTotal > 0}">
          <div class="rm-warnbox">
            PhÃ²ng Ä‘Ã£ cÃ³ ${seatTotal} gháº¿. Báº¥m â€œÃp dá»¥ng layoutâ€ sáº½ <strong>thay tháº¿ toÃ n bá»™</strong> layout hiá»‡n táº¡i
            (cáº£ tráº¡ng thÃ¡i báº£o trÃ¬). Náº¿u gháº¿ Ä‘Ã£ tá»«ng cÃ³ vÃ©, há»‡ thá»‘ng sáº½ tá»« chá»‘i â€” khi Ä‘Ã³ hÃ£y dÃ¹ng â€œÄá»•i loáº¡iâ€ theo tá»«ng hÃ ng á»Ÿ trÃªn.
          </div>
        </c:if>
        <form id="layoutForm" method="post" action="${ctx}/admin/seats">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="generate">
          <input type="hidden" name="roomId" value="${room.roomId}">
          <input type="hidden" name="rowTypes" id="rowTypes" value="<c:out value='${layoutRowTypes}'/>">
          <div class="layout-grid">
            <div class="field">
              <label for="f-rows">Sá»‘ hÃ ng (1â€“26)</label>
              <input id="f-rows" type="number" name="rows" min="1" max="26" value="${layoutRows}" required>
            </div>
            <div class="field">
              <label for="f-cols">Gháº¿ má»—i hÃ ng (1â€“30)</label>
              <input id="f-cols" type="number" name="cols" min="1" max="30" value="${layoutCols}" required>
            </div>
            <div class="hint" style="align-self:end;color:var(--slate-500);font-size:13px">
              Loáº¡i gháº¿:
              <c:forEach var="t" items="${seatTypes}" varStatus="vs"><c:out value="${t.typeName}"/><c:if test="${t.couple}"> (Ä‘Ã´i)</c:if><c:if test="${!vs.last}">, </c:if></c:forEach>
            </div>
          </div>
          <div class="row-types" id="rowTypeBox"></div>
          <p class="alert alert-error" id="layoutErr" style="display:none"></p>
          <button class="btn btn-cta" type="submit">Ãp dá»¥ng layout</button>
        </form>

        <template id="typeTpl">
          <c:forEach var="t" items="${seatTypes}">
            <option value="${t.seatTypeId}" data-couple="${t.couple}"><c:out value="${t.typeName}"/></option>
          </c:forEach>
        </template>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>

<script>
(function () {
  /* ---------- chá»n gháº¿ Ä‘á»ƒ báº£o trÃ¬ ---------- */
  var boxes = Array.prototype.slice.call(document.querySelectorAll('input[name="seatIds"]'));
  var byId = {};
  boxes.forEach(function (b) { byId[b.value] = b; });
  var btnM = document.getElementById('btnMaintain'), btnR = document.getElementById('btnReopen');
  var cnt = document.getElementById('selCount');

  function refresh() {
    var n = boxes.filter(function (b) { return b.checked; }).length;
    if (btnM) btnM.disabled = n === 0;
    if (btnR) btnR.disabled = n === 0;
    if (cnt) cnt.textContent = n === 0 ? 'ChÆ°a chá»n gháº¿ nÃ o' : 'ÄÃ£ chá»n ' + n + ' gháº¿';
  }
  boxes.forEach(function (b) {
    b.addEventListener('change', function () {
      var p = b.getAttribute('data-pair');           /* gháº¿ Ä‘Ã´i: chá»n/bá» cáº£ cáº·p */
      if (p && byId[p]) byId[p].checked = b.checked;
      refresh();
    });
  });
  var clr = document.getElementById('btnClear');
  if (clr) clr.addEventListener('click', function () { boxes.forEach(function (b) { b.checked = false; }); refresh(); });
  refresh();

  /* ---------- form layout: chá»n loáº¡i gháº¿ theo tá»«ng hÃ ng ---------- */
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
      lab.textContent = 'HÃ ng ' + String.fromCharCode(65 + i);
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
    if (!sels.length) msg = 'Sá»‘ hÃ ng khÃ´ng há»£p lá»‡.';
    Array.prototype.forEach.call(sels, function (s, i) {
      if (s.options[s.selectedIndex].getAttribute('data-couple') === 'true' && cols % 2 !== 0)
        msg = 'HÃ ng ' + String.fromCharCode(65 + i) + ' lÃ  gháº¿ Ä‘Ã´i nÃªn sá»‘ gháº¿ má»—i hÃ ng pháº£i lÃ  sá»‘ cháºµn.';
    });
    if (msg) { e.preventDefault(); err.textContent = msg; err.style.display = 'block'; return; }
    err.style.display = 'none';
    hidden.value = Array.prototype.map.call(sels, function (s) { return s.value; }).join(',');
    if (${seatTotal > 0} && !confirm('Thay tháº¿ toÃ n bá»™ layout gháº¿ hiá»‡n táº¡i?')) e.preventDefault();
  });
})();
</script>
<%@ include file="../_footer.jspf" %>



