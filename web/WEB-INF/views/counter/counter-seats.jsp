﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="BÃ¡n vÃ© táº¡i quáº§y â€” Chá»n gháº¿"/>
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
  .seatmap { display:flex; flex-direction:column; gap:8px; align-items:center; margin:14px 0 20px;
             background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow);
             padding:28px 16px 24px; overflow-x:auto; }
  .seat-row { display:flex; gap:6px; align-items:center; }
  .row-label { width:24px; font-weight:800; text-align:center; color:var(--slate-500); font-size:13px; }
  .seat { width:42px; height:38px; border-radius:10px 10px 4px 4px; border:2px solid var(--slate-300);
          cursor:pointer; font: 700 11.5px var(--font); background:#fff; color:var(--slate-700);
          transition: transform .08s, background .12s, border-color .12s; }
  .seat:hover:not(:disabled) { transform: translateY(-2px); }
  .seat.GREEN { background:#ecfdf5; border-color:var(--success); color:#065f46; }
  .seat.YELLOW { background:#fef3c7; border-color:var(--accent); color:#92400e; cursor:not-allowed; }
  .seat.RED { background:#fee2e2; border-color:#fca5a5; color:#991b1b; cursor:not-allowed; }
  .seat.GREY { background:var(--slate-100); border-color:var(--slate-200); color:var(--slate-400); cursor:not-allowed; }
  .seat.selected { background:var(--brand); border-color:var(--brand); color:#fff;
                   box-shadow: 0 0 0 3px rgba(29,78,216,.30); }
  .screen { width:62%; min-width:280px; text-align:center; color:#fff; padding:10px; margin-bottom:22px;
            background: linear-gradient(180deg, var(--navy), var(--slate-700)); border-radius:6px 6px 26px 26px;
            letter-spacing:6px; font-weight:700; font-size:13px; box-shadow: 0 14px 18px -10px rgba(15,23,42,.45); }
  .legend { display:flex; gap:18px; flex-wrap:wrap; margin:14px 0 4px; font-size:13.5px; color:var(--slate-600); }
  .legend span { display:inline-flex; align-items:center; gap:7px; }
  .legend .seat { width:24px; height:22px; cursor:default; font-size:0; }
  .legend .seat:hover { transform:none; }
  .uip-note { color: var(--slate-500); font-size: 13.5px; text-align: center; margin: 0 0 6px; }
  .uip-actions { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }
  .uip-count { font-size: 15px; }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="uip-steps">
        <span class="uip-step done"><span class="uip-num">âœ“</span> Chá»n suáº¥t chiáº¿u</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step active"><span class="uip-num">2</span> Chá»n gháº¿</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step"><span class="uip-num">3</span> Thanh toÃ¡n</span>
      </div>

      <div class="uip-movie-bar">
        <h1><c:out value="${showtime.title}"/></h1>
        <span class="chip">ðŸŽ¬ <c:out value="${showtime.roomName}"/></span>
        <span class="chip">ðŸ•’ ${showtime.startTimeLabel}</span>
      </div>

      <c:if test="${not empty error}">
        <p class="alert alert-error"><c:out value="${error}"/></p>
      </c:if>
      <c:if test="${reselectWarning}">
        <p class="alert alert-info">ÄÆ¡n hiá»‡n táº¡i Ä‘Ã£ giá»¯ gháº¿ cá»§a suáº¥t nÃ y â€” náº¿u chá»n láº¡i,
           Ä‘Æ¡n cÅ© sáº½ bá»‹ há»§y vÃ  táº¡o Ä‘Æ¡n má»›i (gháº¿ cÅ© Ä‘Æ°á»£c nháº£ láº¡i).</p>
      </c:if>

      <div class="legend">
        <span><button class="seat GREEN" type="button" disabled></button> Trá»‘ng</span>
        <span><button class="seat YELLOW" type="button" disabled></button> Äang giá»¯</span>
        <span><button class="seat RED" type="button" disabled></button> ÄÃ£ bÃ¡n</span>
        <span><button class="seat GREY" type="button" disabled></button> Báº£o trÃ¬</span>
        <span><button class="seat selected" type="button" disabled></button> Äang chá»n</span>
      </div>

      <div class="seatmap">
        <div class="screen">MÃ€N HÃŒNH</div>
        <c:forEach var="row" items="${seatRows}">
          <div class="seat-row">
            <span class="row-label">${row[0].rowLabel}</span>
            <c:forEach var="s" items="${row}">
              <button type="button" class="seat ${s.color}" title="${s.label} (${s.seatType})"
                      data-id="${s.seatId}" data-pair="${s.pairSeatId}"
                      ${s.available ? '' : 'disabled="disabled"'}
                      onclick="toggleSeat(this)">${s.seatNumber}</button>
            </c:forEach>
          </div>
        </c:forEach>
      </div>
      <p class="uip-note">Gháº¿ Ä‘Ã´i (hÃ ng E) luÃ´n pháº£i chá»n cáº£ cáº·p â€” báº¥m má»™t gháº¿ sáº½ tá»± chá»n luÃ´n gháº¿ cÃ²n láº¡i.</p>

      <form method="post" action="${ctx}/staff/counter" onsubmit="return checkSeats()">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="hold">
        <input type="hidden" name="showtimeId" value="${showtime.showtimeId}">
        <input type="hidden" id="seatIds" name="seatIds" value="">
        <div class="uip-actions">
          <span class="uip-count">ÄÃ£ chá»n: <strong id="selCount">0</strong> gháº¿</span>
          <button class="btn btn-cta" type="submit">Giá»¯ gháº¿ &amp; sang thanh toÃ¡n â†’</button>
          <a class="btn btn-outline" href="${ctx}/staff/counter">â† Äá»•i suáº¥t chiáº¿u</a>
        </div>
      </form>
    </div>
  </section>
</main>
<script>
  const byId = {};
  document.querySelectorAll('.seat[data-id]').forEach(b => { byId[b.dataset.id] = b; });
  const selected = new Set();

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
    document.getElementById('seatIds').value = [...selected].join(',');
    document.getElementById('selCount').textContent = selected.size;
  }

  function checkSeats() {
    if (selected.size === 0) { alert('Vui lÃ²ng chá»n Ã­t nháº¥t má»™t gháº¿.'); return false; }
    return true;
  }
</script>
<%@ include file="../_footer.jspf" %>



