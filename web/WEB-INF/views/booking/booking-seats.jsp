<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đặt vé — Chọn ghế"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-steps { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; margin: 4px 0 22px; }
  .uip-step { display: inline-flex; align-items: center; gap: 8px; padding: 7px 14px; border-radius: 99px;
              background: var(--slate-100); color: var(--slate-500); font-weight: 700; font-size: 13.5px; }
  .uip-step .uip-num { width: 22px; height: 22px; border-radius: 50%; background: var(--slate-300); color: #fff;
                       display: grid; place-items: center; font-size: 12.5px; }
  .uip-step.active { background: #dbeafe; color: var(--brand); }
  .uip-step.active .uip-num { background: var(--brand); }
  .uip-step.done { background: #d1fae5; color: var(--success); }
  .uip-step.done .uip-num { background: var(--success); }
  .uip-arrow { color: var(--slate-300); font-weight: 800; }
  .uip-movie-bar { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-bottom: 6px; }
  .uip-movie-bar h1 { margin: 0 10px 0 0; font-size: 24px; }
  .seatmap { display:flex; flex-direction:column; gap:8px; align-items:center; margin:0 0 20px;
             background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow);
             padding:28px 16px 24px; overflow-x:auto; }
  .sm-title { font-size:17px; margin:0 0 10px; }
  .seat-row { display:flex; gap:10px; align-items:center; }
  .row-label { width:40px; display:inline-flex; align-items:center; justify-content:center;
               font-weight:800; color:var(--slate-500); font-size:19px; }
  .seat { position:relative; width:56px; height:48px; border-radius:14px 14px 6px 6px; border:3px solid var(--slate-300);
          cursor:pointer; font: 800 14px var(--font); background:#fff; color:var(--slate-700); padding:0;
          transition: transform .08s, background .12s, border-color .12s; }
  .seat:hover:not(:disabled) { transform: translateY(-2px); }
  /* Ghe trong: mau theo LOAI ghe (thuong = xanh la, VIP = cam, doi = hong). Class GREEN/YELLOW/RED/GREY giu nguyen
     (test script doi khop class). */
  .seat.GREEN { background:#ecfdf5; border-color:#059669; color:#065f46; }
  .seat.GREEN[data-type="VIP"] { background:#fef3c7; border-color:#f59e0b; color:#92400e; }
  .seat.GREEN[data-type="Couple"] { background:#fce7f3; border-color:#db2777; color:#9d174d; }
  .seat.YELLOW { background:#fef3c7; border-color:var(--accent); color:#92400e; cursor:not-allowed; opacity:.65; }
  .seat.RED { background:#fee2e2; border-color:#fca5a5; color:#991b1b; cursor:not-allowed; }
  .seat.GREY { background:var(--slate-100); border-color:var(--slate-200); color:var(--slate-400); cursor:not-allowed; }
  .seat.selected, .seat.selected[data-type] { background:var(--brand); border-color:var(--brand); color:#fff;
                   box-shadow: 0 0 0 3px rgba(29,78,216,.30); opacity:1; }
  /* Ghe doi: hai ghe cua mot cap ghep thanh mot khoi, o giua co vach ngan */
  .seat.pair-l { border-radius:14px 0 0 6px; border-right-width:1.5px; margin-right:-10px; }
  .seat.pair-r { border-radius:0 14px 6px 0; border-left-width:1.5px; }
  .screen { width:62%; min-width:280px; text-align:center; color:#fff; padding:10px; margin-bottom:22px;
            background: linear-gradient(180deg, var(--navy), var(--slate-700)); border-radius:6px 6px 26px 26px;
            letter-spacing:6px; font-weight:700; font-size:13px; box-shadow: 0 14px 18px -10px rgba(15,23,42,.45); }
  .legend { display:flex; gap:18px; flex-wrap:wrap; margin:14px 0 4px; font-size:13.5px; color:var(--slate-600); }
  .legend span { display:inline-flex; align-items:center; gap:7px; }
  .legend .seat { width:24px; height:22px; cursor:default; font-size:0; border-width:2px; }
  .legend .seat:hover { transform:none; }

  /* ---------- panel chu thich loai ghe ---------- */
  .seat-guide { background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow);
                padding:20px 22px; margin:0 0 22px; }
  .seat-guide h2 { font-size:17px; margin:0 0 2px; }
  .seat-guide .sg-sub { color:var(--slate-500); font-size:13.5px; margin:0 0 16px; }
  .sg-block + .sg-block { margin-top:20px; padding-top:18px; border-top:1px dashed var(--slate-200); }
  .sg-block h3 { font-size:14px; margin:0 0 10px; color:var(--slate-700); text-transform:uppercase;
                 letter-spacing:.05em; }
  .sg-legend { display:flex; gap:16px 22px; flex-wrap:wrap; font-size:13.5px; color:var(--slate-600); }
  .sg-legend span { display:inline-flex; align-items:center; gap:8px; }
  .sg-legend .seat { width:24px; height:22px; cursor:default; font-size:0; box-shadow:none; border-width:2px; }
  .sg-types { display:grid; grid-template-columns:repeat(auto-fit, minmax(210px, 1fr)); gap:12px; }
  .sg-type { border:1px solid var(--slate-200); border-radius:12px; padding:12px 14px; background:var(--slate-50); }
  .sg-type .sg-type-name { display:flex; align-items:center; gap:8px; font-weight:800; color:var(--navy); font-size:14.5px; }
  .sg-type .sg-type-desc { color:var(--slate-500); font-size:12.5px; margin-top:4px; }
  .sg-type .sg-type-price { margin-top:8px; font-size:13px; color:var(--slate-700); }
  .sg-type .sg-type-price b { color:var(--brand); font-size:15px; }
  .seat-type-dot { width:10px; height:10px; border-radius:50%; flex:none; display:inline-block;
                    border:2px solid var(--slate-300); background:#fff; }
  .seat-type-dot.t-Standard { background:#ecfdf5; border-color:var(--success); }
  .seat-type-dot.t-VIP { background:#fef3c7; border-color:var(--accent); }
  .seat-type-dot.t-Couple { background:#fce7f3; border-color:#db2777; }
  .sg-empty { color:var(--slate-500); font-size:13.5px; margin:0; }
  .uip-note { color: var(--slate-500); font-size: 13.5px; text-align: center; margin: 0 0 6px; }
  .uip-actions { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }
  .uip-count { font-size: 15px; }
  .uip-total { font-size: 15px; }
  .uip-total b { color: var(--brand); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="uip-steps">
        <span class="uip-step done"><span class="uip-num">✓</span> Chọn suất chiếu</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step active"><span class="uip-num">2</span> Chọn ghế</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step"><span class="uip-num">3</span> Thanh toán</span>
      </div>

      <div class="uip-movie-bar">
        <h1><c:out value="${showtime.title}"/></h1>
        <span class="chip">🎬 <c:out value="${showtime.roomName}"/></span>
        <span class="chip">🕒 ${showtime.startTimeLabel}</span>
      </div>

      <c:if test="${not empty error}">
        <p class="alert alert-error"><c:out value="${error}"/></p>
      </c:if>

      <%-- ============ Chu thich loai ghe: trang thai + loai ghe kem gia ve ============ --%>
      <%-- Dat TREN so do ghe: khach doc chu thich truoc, roi moi chon ghe. --%>
      <div class="seat-guide">
        <h2>Chú thích sơ đồ ghế</h2>
        <p class="sg-sub">Ghế trống có màu theo <b>loại ghế</b> (xanh lá: thường, cam: VIP, hồng: ghế đôi);
           các màu khác cho biết <b>trạng thái</b> ghế. Di chuột lên tên hàng để xem giá vé của hàng đó.</p>

        <div class="sg-block">
          <h3>Trạng thái ghế</h3>
          <div class="sg-legend">
            <span><button class="seat GREEN" type="button" disabled></button> Trống — có thể chọn</span>
            <span><button class="seat YELLOW" type="button" disabled></button> Đang giữ — người khác đang chọn</span>
            <span><button class="seat RED" type="button" disabled></button> Đã bán</span>
            <span><button class="seat GREY" type="button" disabled></button> Bảo trì — không đặt vé</span>
            <span><button class="seat selected" type="button" disabled></button> Đang chọn</span>
          </div>
        </div>

        <div class="sg-block">
          <h3>Loại ghế &amp; giá vé</h3>
          <c:choose>
            <c:when test="${empty seatTypes}">
              <p class="sg-empty">Chưa có cấu hình giá vé theo loại ghế cho suất chiếu này.</p>
            </c:when>
            <c:otherwise>
              <div class="sg-types">
                <c:forEach var="t" items="${seatTypes}">
                  <div class="sg-type" data-type="<c:out value="${t.typeName}"/>"
                       data-has-price="${t.priceConfigured}" data-price="${t.priceInt}">
                    <div class="sg-type-name">
                      <i class="seat-type-dot t-${t.typeName}"></i>
                      <c:out value="${t.typeLabel}"/>
                    </div>
                    <div class="sg-type-desc"><c:out value="${t.descriptionLabel}"/></div>
                    <div class="sg-type-price">
                      <c:choose>
                        <c:when test="${t.priceConfigured}">Giá: <b><c:out value="${t.priceLabel}"/></b> / ghế</c:when>
                        <c:otherwise>Giá: <b>—</b> (chưa cấu hình)</c:otherwise>
                      </c:choose>
                    </div>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <h2 class="sm-title">Sơ đồ ghế</h2>
      <div class="seatmap">
        <div class="screen">MÀN HÌNH</div>
        <c:forEach var="row" items="${seatRows}">
          <div class="seat-row">
            <c:set var="lg" value="${rowLegendMap[row[0].rowLabel]}"/>
            <span class="row-label"
                  title="Hàng ${row[0].rowLabel} · ${row[0].seatType} · ${lg.seatRangeLabel} · ${lg.priceLabel} — ${lg.noteLabel}">
              ${row[0].rowLabel}
            </span>
            <c:forEach var="s" items="${row}">
              <button type="button" class="seat ${s.color}"
                      title="${s.label} · ${s.seatType} · ${s.statusLabel}"
                      data-id="${s.seatId}" data-pair="${s.pairSeatId}" data-type="${s.seatType}"
                      ${s.available ? '' : 'disabled="disabled"'}
                      onclick="toggleSeat(this)">${s.label}</button>
            </c:forEach>
          </div>
        </c:forEach>
      </div>

      <p class="uip-note">Ghế đôi luôn phải chọn cả cặp — bấm một ghế sẽ tự chọn luôn ghế còn lại.
         Ghế đã giữ bởi người khác sẽ tự trở lại khi hết thời gian chờ thanh toán.</p>

      <form method="post" action="${ctx}/booking/seats" onsubmit="return checkSeats()">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="showtimeId" value="${showtime.showtimeId}">
        <input type="hidden" id="seatIds" name="seatIds" value="">
        <div class="uip-actions">
          <span class="uip-count">Đã chọn: <strong id="selCount">0</strong> ghế</span>
          <span class="uip-total">Tạm tính: <strong id="selTotal">0</strong> VNĐ</span>
          <button class="btn btn-cta" type="submit">Giữ ghế &amp; sang thanh toán →</button>
          <a class="btn btn-outline" href="${ctx}/showtimes">← Đổi suất chiếu</a>
        </div>
      </form>
    </div>
  </section>
</main>
<script>
  const byId = {};
  document.querySelectorAll('.seat[data-id]').forEach(b => { byId[b.dataset.id] = b; });
  const selected = new Set();

  /* Ghep hai ghe doi lien ke thanh mot khoi (ghe trai / ghe phai). */
  document.querySelectorAll('.seat[data-pair]').forEach(b => {
    if (!b.dataset.pair || b.classList.contains('pair-l') || b.classList.contains('pair-r')) return;
    const next = b.nextElementSibling;
    if (next && next.dataset && next.dataset.id === b.dataset.pair) {
      b.classList.add('pair-l');
      next.classList.add('pair-r');
    }
  });

  /* Gia ve theo loai ghe cua suat chien hien tai (doc tu DOM de tranh loi JSON). */
  const seatPrices = {};
  let hasAnyPrice = false;
  document.querySelectorAll('.sg-type[data-type]').forEach(box => {
    if (box.dataset.hasPrice !== 'true') return;
    seatPrices[box.dataset.type] = parseInt(box.dataset.price, 10) || 0;
    hasAnyPrice = true;
  });

  /* Cac hang co so nut khac nhau (hang ghe doi ngan hon) -> dua ve cung do rong de chu cai A-E thang cot;
     ghe cua hang ngan duoc can giua trong phan con lai. */
  (function alignRows() {
    const rows = [...document.querySelectorAll('.seat-row')];
    if (!rows.length) return;
    const widths = rows.map(r => r.scrollWidth);
    const max = Math.max(...widths);
    rows.forEach((r, i) => {
      r.style.width = max + 'px';
      const firstSeat = r.querySelector('.seat');
      if (firstSeat && max > widths[i]) firstSeat.style.marginLeft = ((max - widths[i]) / 2) + 'px';
    });
  })();

  function formatVnd(value) {
    return value.toLocaleString('vi-VN');
  }

  function refreshSummary() {
    document.getElementById('seatIds').value = [...selected].join(',');
    document.getElementById('selCount').textContent = selected.size;

    let total = 0;
    let hasMissingPrice = false;
    selected.forEach(id => {
      const b = byId[id];
      const price = b ? seatPrices[b.dataset.type] : null;
      if (price === undefined || price === null) hasMissingPrice = true;
      else total += price;
    });
    const el = document.getElementById('selTotal');
    if (!hasAnyPrice) { el.textContent = '—'; return; }
    el.textContent = hasMissingPrice ? '—' : formatVnd(total);
  }

  function toggleSeat(btn) {
    const ids = [btn.dataset.id];
    if (btn.dataset.pair) ids.push(btn.dataset.pair);
    const allSelected = ids.every(id => selected.has(id));
    ids.forEach(id => {
      const b = byId[id];
      if (!b || b.disabled) return;
      if (allSelected) { selected.delete(id); b.classList.remove('selected'); }
      else { selected.add(id); b.classList.add('selected'); }
    });
    refreshSummary();
  }

  function checkSeats() {
    if (selected.size === 0) { alert('Vui lòng chọn ít nhất một ghế.'); return false; }
    return true;
  }

  refreshSummary();
</script>
<%@ include file="../_footer.jspf" %>



