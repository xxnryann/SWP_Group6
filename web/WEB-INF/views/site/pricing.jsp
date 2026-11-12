<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Bảng giá vé"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>
<fmt:setLocale value="vi_VN"/>
<style>
  .pz { --std-f: #eef2f7; --std-s: #8b9ab0; --vip-f: #fff3d1; --vip-s: #dc9b04; --vip-c: #f5b301;
        --cpl-f: #fde6f0; --cpl-s: #e2508f; --day: #fff4d6; --day-ink: #a86500; --night: #1f2a5c; --night-ink: #e7ebff; }
  .pz-section { margin-top: 40px; }
  .pz-section > h2 { font-size: 22px; display: flex; align-items: center; gap: 10px; }
  .pz-section > .sub { color: var(--muted); margin-top: 4px; }
  .pz-num { display: inline-grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; background: var(--brand-600); color: #fff; font-size: 14px; font-weight: 800; flex: none; }

  /* Hero chips */
  .pz-chips { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }
  .pz-chip { display: inline-flex; align-items: center; gap: 8px; padding: 8px 14px; border-radius: 999px; background: var(--surface); border: 1px solid var(--line); font-size: 14px; color: var(--text); box-shadow: var(--sh-sm); }
  .pz-chip strong { color: var(--ink); }
  .pz-chip svg { width: 18px; height: 18px; }

  /* Công thức */
  .pz-formula { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)) auto minmax(0, 1fr); align-items: stretch; gap: 0; margin-top: 18px; }
  .pz-f { position: relative; display: flex; flex-direction: column; align-items: center; text-align: center; gap: 8px; padding: 18px 12px; background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-lg); box-shadow: var(--sh-sm); margin: 0 10px; }
  .pz-f svg { width: 54px; height: 54px; }
  .pz-f b { color: var(--ink); font-size: 15px; }
  .pz-f span { color: var(--muted); font-size: 12.5px; }
  .pz-f + .pz-f::before { content: "+"; position: absolute; left: -17px; top: 50%; transform: translateY(-50%); font-size: 22px; font-weight: 800; color: var(--subtle); }
  .pz-eq { display: grid; place-items: center; font-size: 26px; font-weight: 800; color: var(--subtle); padding: 0 4px; }
  .pz-f.total { background: linear-gradient(135deg, var(--brand-600), var(--brand-900)); border-color: transparent; color: #fff; }
  .pz-f.total b { color: #fff; font-size: 17px; }
  .pz-f.total span { color: rgba(255,255,255,.8); }

  /* Bộ chọn */
  .pz-pick { display: flex; flex-wrap: wrap; align-items: center; gap: 14px 22px; margin-top: 18px; padding: 16px 18px; background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-lg); }
  .pz-pick .lbl { font-size: 12px; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; color: var(--subtle); margin-right: 4px; }
  .seg { display: inline-flex; flex-wrap: wrap; gap: 4px; padding: 4px; background: var(--surface-3); border-radius: 999px; }
  .seg button { display: inline-flex; align-items: center; gap: 6px; border: 0; background: transparent; padding: 8px 14px; border-radius: 999px; font: inherit; font-size: 14px; font-weight: 600; color: var(--muted); cursor: pointer; }
  .seg button svg { width: 16px; height: 16px; }
  .seg button small { font-weight: 500; color: var(--subtle); }
  .seg button[aria-pressed="true"] { background: var(--surface); color: var(--ink); box-shadow: var(--sh-sm); }
  .seg button[aria-pressed="true"] small { color: var(--muted); }
  .pz-now { font-size: 13px; color: var(--muted); margin-left: auto; }
  .pz-now.is-now { color: #0a7a44; font-weight: 600; }

  /* Thẻ ghế */
  .pz-seats { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 18px; margin-top: 18px; }
  .seat-card { position: relative; display: flex; flex-direction: column; align-items: center; text-align: center; padding: 24px 20px 22px; border-radius: var(--r-xl); background: var(--surface); border: 1px solid var(--line); box-shadow: var(--sh-sm); overflow: hidden; }
  .seat-card::before { content: ""; position: absolute; inset: 0 0 auto 0; height: 110px; opacity: .55; }
  .seat-card.k-std::before { background: linear-gradient(180deg, var(--std-f), transparent); }
  .seat-card.k-vip::before { background: linear-gradient(180deg, var(--vip-f), transparent); }
  .seat-card.k-cpl::before { background: linear-gradient(180deg, var(--cpl-f), transparent); }
  .seat-card > * { position: relative; }
  .seat-svg { height: 104px; width: auto; }
  .seat-card h3 { font-size: 19px; margin-top: 10px; color: var(--ink); }
  .seat-card .desc { font-size: 13px; color: var(--muted); margin-top: 2px; min-height: 18px; }
  .seat-card .price { margin-top: 14px; font-size: 34px; font-weight: 800; letter-spacing: -.03em; color: var(--ink); font-variant-numeric: tabular-nums; line-height: 1.1; }
  .seat-card .price small { font-size: 15px; font-weight: 600; color: var(--muted); letter-spacing: 0; }
  .seat-card .pair { margin-top: 6px; font-size: 13px; color: var(--cpl-s); font-weight: 600; }
  .seat-card .tag { position: absolute; top: 14px; right: 14px; font-size: 11px; font-weight: 700; padding: 3px 9px; border-radius: 999px; background: var(--vip-c); color: #4a3200; }
  .s-back, .s-cush, .s-arm { stroke-width: 4; }
  .k-std .s-back, .k-std .s-cush, .k-std .s-arm { fill: var(--std-f); stroke: var(--std-s); }
  .k-vip .s-back, .k-vip .s-cush, .k-vip .s-arm { fill: var(--vip-f); stroke: var(--vip-s); }
  .k-cpl .s-back, .k-cpl .s-cush, .k-cpl .s-arm { fill: var(--cpl-f); stroke: var(--cpl-s); }
  .s-leg { stroke-width: 6; stroke-linecap: round; fill: none; }
  .k-std .s-leg { stroke: var(--std-s); } .k-vip .s-leg { stroke: var(--vip-s); } .k-cpl .s-leg { stroke: var(--cpl-s); }
  .s-crown { fill: var(--vip-c); stroke: var(--vip-s); stroke-width: 2.5; stroke-linejoin: round; }
  .s-heart { fill: var(--cpl-s); }
  .s-div { stroke: var(--cpl-s); stroke-width: 3; stroke-dasharray: 5 5; }

  /* Thanh 24 giờ */
  .tl { margin-top: 22px; padding: 26px 22px 14px; background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-xl); box-shadow: var(--sh-sm); }
  .tl-bar { position: relative; height: 64px; border-radius: 14px; overflow: visible; background: var(--surface-3); }
  .tl-seg { position: absolute; top: 0; bottom: 0; display: flex; align-items: center; justify-content: center; gap: 8px; font-weight: 700; font-size: 14px; overflow: hidden; white-space: nowrap; }
  .tl-seg.day { background: linear-gradient(180deg, #ffe7a3, var(--day)); color: var(--day-ink); }
  .tl-seg.night { background: linear-gradient(180deg, #2b3a7a, var(--night)); color: var(--night-ink); }
  .tl-seg svg { width: 22px; height: 22px; flex: none; }
  .tl-seg.first { border-radius: 14px 0 0 14px; } .tl-seg.last { border-radius: 0 14px 14px 0; }
  .tl-now { position: absolute; top: -10px; bottom: -10px; width: 0; border-left: 2px dashed var(--danger); }
  .tl-now span { position: absolute; top: -22px; left: 50%; transform: translateX(-50%); white-space: nowrap; font-size: 11.5px; font-weight: 700; color: #fff; background: var(--danger); padding: 2px 8px; border-radius: 999px; }
  .tl-now.edge-r span { left: auto; right: -2px; transform: none; }
  .tl-now.edge-l span { left: -2px; transform: none; }
  .tl-ticks { position: relative; height: 22px; margin-top: 8px; font-size: 12px; color: var(--subtle); font-variant-numeric: tabular-nums; }
  .tl-ticks span { position: absolute; transform: translateX(-50%); }
  .tl-ticks span:first-child { transform: none; } .tl-ticks span:last-child { transform: translateX(-100%); }
  .tl-legend { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; margin-top: 14px; }
  .tl-item { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: var(--r-md); border: 1px solid var(--line); }
  .tl-item .ico { display: grid; place-items: center; width: 42px; height: 42px; border-radius: 12px; flex: none; }
  .tl-item .ico svg { width: 24px; height: 24px; }
  .tl-item.day .ico { background: var(--day); color: var(--day-ink); }
  .tl-item.night .ico { background: var(--night); color: var(--night-ink); }
  .tl-item b { color: var(--ink); display: block; }
  .tl-item span { color: var(--muted); font-size: 13px; }

  /* Tuần + ngày lễ */
  .pz-week { display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 8px; margin-top: 18px; }
  .wd { position: relative; padding: 14px 6px 12px; text-align: center; border-radius: var(--r-md); border: 1.5px solid; }
  .wd b { display: block; font-size: 18px; }
  .wd span { font-size: 11.5px; font-weight: 600; }
  .wd.normal { background: var(--brand-50); border-color: var(--brand-200); color: var(--brand-700); }
  .wd.weekend { background: var(--accent-50); border-color: #ffd58a; color: var(--accent-700); }
  .wd.today { box-shadow: 0 0 0 3px var(--brand-500); }
  .wd.today::after { content: "Hôm nay"; position: absolute; top: -10px; left: 50%; transform: translateX(-50%); font-size: 10.5px; font-weight: 700; background: var(--brand-600); color: #fff; padding: 1px 7px; border-radius: 999px; white-space: nowrap; }
  .pz-days { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; align-items: start; }
  .pz-hols { display: grid; gap: 10px; margin-top: 18px; }
  .hol { display: flex; align-items: center; gap: 14px; padding: 12px 14px; border-radius: var(--r-md); background: var(--surface); border: 1px solid var(--line); }
  .hol .cal { flex: none; width: 52px; text-align: center; border: 1.5px solid #f3b4b7; border-radius: 10px; overflow: hidden; background: #fff; }
  .hol .cal small { display: block; background: var(--danger); color: #fff; font-size: 10.5px; font-weight: 700; padding: 2px 0; }
  .hol .cal b { display: block; font-size: 20px; color: var(--ink); line-height: 1.4; }
  .hol .t b { color: var(--ink); display: block; }
  .hol .t span { color: var(--muted); font-size: 13px; }
  .pz-card { padding: 20px; background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-xl); box-shadow: var(--sh-sm); }
  .pz-card h3 { font-size: 16px; color: var(--ink); display: flex; align-items: center; gap: 8px; }
  .pz-card h3 .dot { width: 12px; height: 12px; border-radius: 4px; }

  /* Phòng chiếu */
  .pz-rooms { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-top: 18px; }
  .room-card { display: flex; flex-direction: column; align-items: center; text-align: center; padding: 20px 16px; border-radius: var(--r-xl); background: var(--surface); border: 1px solid var(--line); box-shadow: var(--sh-sm); }
  .room-card svg { width: 112px; height: 74px; }
  .room-card h3 { font-size: 18px; margin-top: 8px; color: var(--ink); }
  .room-card .desc { font-size: 12.5px; color: var(--muted); min-height: 34px; }
  .room-card .sc { margin-top: 10px; font-size: 20px; font-weight: 800; color: var(--brand-700); }
  .room-card .sc.free { color: #0a7a44; font-size: 16px; }
  .r-screen { fill: #e8eeff; stroke: var(--brand-500); stroke-width: 3; }
  .r-line { stroke: var(--brand-500); stroke-width: 3; stroke-linecap: round; fill: none; }
  .r-text { font: 800 15px/1 system-ui, sans-serif; fill: var(--brand-700); }

  /* Ví dụ */
  .pz-example { display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 12px 16px; margin-top: 18px; padding: 22px; border-radius: var(--r-xl); background: linear-gradient(135deg, var(--brand-50), #fff); border: 1px solid var(--brand-100); }
  .ex-part { display: flex; align-items: center; gap: 10px; padding: 10px 14px; background: #fff; border-radius: var(--r-md); border: 1px solid var(--line); }
  .ex-part svg { width: 44px; height: 40px; }
  .ex-part b { display: block; color: var(--ink); font-variant-numeric: tabular-nums; }
  .ex-part span { font-size: 12.5px; color: var(--muted); }
  .ex-op { font-size: 24px; font-weight: 800; color: var(--subtle); }
  .ex-total { padding: 12px 18px; border-radius: var(--r-md); background: var(--brand-600); color: #fff; text-align: center; }
  .ex-total b { display: block; font-size: 24px; font-variant-numeric: tabular-nums; }
  .ex-total span { font-size: 12.5px; opacity: .85; }

  /* Bảng đầy đủ */
  details.pz-full { margin-top: 18px; }
  details.pz-full > summary { cursor: pointer; font-weight: 700; color: var(--brand-700); list-style: none; display: inline-flex; align-items: center; gap: 6px; }
  details.pz-full > summary::-webkit-details-marker { display: none; }
  .pz-full-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px; margin-top: 14px; }
  .pz-full-grid table { width: 100%; border-collapse: collapse; font-size: 14px; }
  .pz-full-grid th, .pz-full-grid td { padding: 8px 10px; border-bottom: 1px solid var(--line); text-align: right; font-variant-numeric: tabular-nums; }
  .pz-full-grid th:first-child, .pz-full-grid td:first-child { text-align: left; }
  .pz-full-grid thead th { font-size: 12px; color: var(--muted); font-weight: 600; }

  @media (max-width: 960px) {
    .pz-formula { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px 0; }
    .pz-f + .pz-f::before { display: none; }
    .pz-eq { display: none; }
    .pz-f.total { grid-column: 1 / -1; }
    .pz-days { grid-template-columns: 1fr; }
  }
  @media (max-width: 640px) {
    .pz-week { gap: 4px; } .wd b { font-size: 15px; } .wd span { font-size: 10px; }
    .tl-seg span.nm { display: none; }
    .tl-ticks span:nth-child(even) { display: none; }
    .pz-now { margin-left: 0; }
  }
</style>

<%-- ==== Biểu tượng dùng lại ==== --%>
<c:set var="svgSun"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4.5" fill="currentColor" fill-opacity=".25"/><path d="M12 2v2.5M12 19.5V22M4.2 4.2l1.8 1.8M18 18l1.8 1.8M2 12h2.5M19.5 12H22M4.2 19.8 6 18M18 6l1.8-1.8"/></svg></c:set>
<c:set var="svgMoon"><svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.5 14.2A8.5 8.5 0 0 1 9.8 3.5a8.5 8.5 0 1 0 10.7 10.7z"/><circle cx="17" cy="5" r="1"/><circle cx="20" cy="9" r=".8"/></svg></c:set>
<c:set var="svgSeatStd"><svg class="seat-svg" viewBox="0 -8 120 118" aria-hidden="true"><rect class="s-back" x="28" y="14" width="64" height="56" rx="14"/><rect class="s-cush" x="20" y="58" width="80" height="24" rx="9"/><rect class="s-arm" x="8" y="44" width="18" height="42" rx="8"/><rect class="s-arm" x="94" y="44" width="18" height="42" rx="8"/><path class="s-leg" d="M34 86v14M86 86v14"/></svg></c:set>
<c:set var="svgSeatVip"><svg class="seat-svg" viewBox="0 -8 120 118" aria-hidden="true"><rect class="s-back" x="28" y="14" width="64" height="56" rx="14"/><path class="s-crown" d="M44 16 L46 0 L54 8 L60 -4 L66 8 L74 0 L76 16 Z"/><rect class="s-cush" x="20" y="58" width="80" height="24" rx="9"/><rect class="s-arm" x="8" y="44" width="18" height="42" rx="8"/><rect class="s-arm" x="94" y="44" width="18" height="42" rx="8"/><path class="s-leg" d="M34 86v14M86 86v14"/></svg></c:set>
<c:set var="svgSeatCpl"><svg class="seat-svg" viewBox="0 -8 200 118" aria-hidden="true"><rect class="s-back" x="28" y="14" width="144" height="56" rx="16"/><path class="s-div" d="M100 22v40"/><path class="s-heart" d="M100 50c-10-7-15-12-15-18a7 7 0 0 1 15-3 7 7 0 0 1 15 3c0 6-5 11-15 18z"/><rect class="s-cush" x="20" y="58" width="160" height="24" rx="10"/><rect class="s-arm" x="8" y="44" width="18" height="42" rx="8"/><rect class="s-arm" x="174" y="44" width="18" height="42" rx="8"/><path class="s-leg" d="M36 86v14M164 86v14"/></svg></c:set>

<section class="hero-band">
  <div class="container">
    <span class="eyebrow">Minh bạch, dễ chọn</span>
    <h1>Bảng giá vé</h1>
    <p>Xem nhanh giá một ghế theo loại ghế, giờ chiếu, ngày xem và loại phòng. Số tiền cuối cùng luôn hiển thị ở bước chọn ghế.</p>
    <div class="pz-chips">
      <c:if test="${not empty minPrice}"><span class="pz-chip">${ic.ticket}Chỉ từ <strong><fmt:formatNumber value="${minPrice}" pattern="#,##0"/>đ</strong> / ghế</span></c:if>
      <c:forEach var="s" items="${slots}"><span class="pz-chip" style="color:${s.night ? 'var(--night)' : 'var(--day-ink)'}">${s.night ? svgMoon : svgSun}<span style="color:var(--text)"><strong><c:out value="${s.slot_name}"/></strong> ${s.slot_from} – ${s.slot_to}</span></span></c:forEach>
      <span class="pz-chip">${ic.calendar}Hôm nay: <strong>${todayLabel}</strong></span>
    </div>
  </div>
</section>

<div class="container pz">
  <c:choose>
    <c:when test="${empty seatGroups}">
      <div class="card empty mt-32"><div class="empty-icon">${ic.wallet}</div><h3>Chưa có cấu hình giá vé</h3></div>
    </c:when>
    <c:otherwise>

  <%-- ===== Công thức ===== --%>
  <section class="pz-section">
    <h2>Giá một ghế được tính thế nào?</h2>
    <p class="sub">Bốn yếu tố quyết định giá — xem từng phần bên dưới.</p>
    <div class="pz-formula">
      <div class="pz-f k-vip">${svgSeatVip}<b>Loại ghế</b><span>Thường · VIP · Ghế đôi</span></div>
      <div class="pz-f" style="color:var(--night)">${svgMoon}<b>Giờ chiếu</b><span>Trong ngày hay Khuya</span></div>
      <div class="pz-f" style="color:var(--accent-700)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="4.5" width="18" height="16.5" rx="2.5"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/><circle cx="12" cy="15" r="2.4" fill="currentColor"/></svg><b>Ngày xem</b><span>Thường · Cuối tuần · Lễ</span></div>
      <div class="pz-f" style="color:var(--brand-600)"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M2.5 6.5Q12 3 21.5 6.5L20.5 16Q12 13.5 3.5 16Z" fill="currentColor" fill-opacity=".12"/><path d="M8 20h8M12 15.5V20"/></svg><b>Loại phòng</b><span>Phụ thu 3D, IMAX, 4DX</span></div>
      <div class="pz-eq">=</div>
      <div class="pz-f total">${ic.ticket}<b>Giá vé</b><span>cho mỗi ghế</span></div>
    </div>
  </section>

  <%-- ===== 1. Loại ghế + bộ chọn ===== --%>
  <section class="pz-section" id="seatPrices">
    <h2><span class="pz-num">1</span>Chọn ghế — xem giá ngay</h2>
    <p class="sub">Bấm chọn ngày và giờ chiếu để xem giá từng loại ghế (chưa gồm phụ thu phòng).</p>
    <div class="pz-pick">
      <div><span class="lbl">Ngày</span>
        <div class="seg" id="segDay" role="group" aria-label="Loại ngày">
          <button type="button" data-day="Weekday">Ngày thường <small>T2–T6</small></button>
          <button type="button" data-day="Weekend">Cuối tuần <small>T7, CN</small></button>
          <button type="button" data-day="Holiday">Ngày lễ</button>
        </div></div>
      <div><span class="lbl">Giờ chiếu</span>
        <div class="seg" id="segSlot" role="group" aria-label="Khung giờ">
          <c:forEach var="s" items="${slots}">
            <button type="button" data-slot="${s.slot_id}">${s.night ? svgMoon : svgSun}<c:out value="${s.slot_name}"/> <small>${s.slot_from}–${s.slot_to}</small></button>
          </c:forEach>
        </div></div>
      <span class="pz-now" id="pzNow" aria-live="polite"></span>
    </div>

    <div class="pz-seats">
      <c:forEach var="g" items="${seatGroups}">
        <article class="seat-card k-${g.kind}">
          <c:if test="${g.kind == 'vip'}"><span class="tag">Hàng ghế đẹp</span></c:if>
          <c:choose>
            <c:when test="${g.kind == 'cpl'}">${svgSeatCpl}</c:when>
            <c:when test="${g.kind == 'vip'}">${svgSeatVip}</c:when>
            <c:otherwise>${svgSeatStd}</c:otherwise>
          </c:choose>
          <h3><c:out value="${g.label}"/></h3>
          <div class="desc"><c:if test="${g.desc != g.label}"><c:out value="${g.desc}"/></c:if></div>
          <c:forEach var="r" items="${g.rows}">
            <c:forEach var="d" items="Weekday,Weekend,Holiday" varStatus="ds">
              <c:set var="v" value="${ds.index == 0 ? r.weekday : (ds.index == 1 ? r.weekend : r.holiday)}"/>
              <div class="pp" data-slot="${r.slot_id}" data-day="${d}" hidden>
                <div class="price"><c:choose><c:when test="${v != null}"><fmt:formatNumber value="${v}" pattern="#,##0"/><small>đ / ghế</small></c:when><c:otherwise><small>Chưa mở bán</small></c:otherwise></c:choose></div>
                <c:if test="${g.couple and v != null}"><div class="pair">1 cặp (2 ghế) = <fmt:formatNumber value="${v * 2}" pattern="#,##0"/>đ</div></c:if>
              </div>
            </c:forEach>
          </c:forEach>
        </article>
      </c:forEach>
    </div>

    <details class="pz-full">
      <summary>${ic.list}Xem bảng giá đầy đủ</summary>
      <div class="pz-full-grid">
        <c:forEach var="g" items="${seatGroups}">
          <div class="pz-card">
            <h3><span class="dot" style="background:var(--${g.kind}-s)"></span><c:out value="${g.label}"/></h3>
            <table>
              <thead><tr><th>Giờ chiếu</th><th>T2 – T6</th><th>T7, CN</th><th>Ngày lễ</th></tr></thead>
              <tbody>
                <c:forEach var="r" items="${g.rows}">
                  <tr><td><c:out value="${r.slot_name}"/></td>
                    <td><c:if test="${r.weekday != null}"><fmt:formatNumber value="${r.weekday}" pattern="#,##0"/>đ</c:if></td>
                    <td><c:if test="${r.weekend != null}"><fmt:formatNumber value="${r.weekend}" pattern="#,##0"/>đ</c:if></td>
                    <td><c:if test="${r.holiday != null}"><fmt:formatNumber value="${r.holiday}" pattern="#,##0"/>đ</c:if></td></tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:forEach>
      </div>
    </details>
  </section>

  <%-- ===== 2. Giờ chiếu ===== --%>
  <section class="pz-section">
    <h2><span class="pz-num">2</span>Giờ chiếu</h2>
    <p class="sub">Tính theo giờ <strong>bắt đầu</strong> của suất chiếu.</p>
    <div class="tl">
      <div class="tl-bar">
        <c:forEach var="s" items="${segments}" varStatus="st">
          <div class="tl-seg ${s.night ? 'night' : 'day'} ${st.first ? 'first' : ''} ${st.last ? 'last' : ''}" style="left:${s.left}%;width:${s.width}%" title="${s.name}: ${s.from} – ${s.to}">
            ${s.night ? svgMoon : svgSun}<span class="nm"><c:out value="${s.name}"/></span>
          </div>
        </c:forEach>
        <div class="tl-now ${nowPct > 88 ? 'edge-r' : (nowPct < 12 ? 'edge-l' : '')}" style="left:${nowPct}%"><span>Bây giờ ${nowTime}</span></div>
      </div>
      <div class="tl-ticks">
        <c:forEach var="h" begin="0" end="24" step="3"><span style="left:${h * 100 / 24}%">${h < 10 ? '0' : ''}${h}:00</span></c:forEach>
      </div>
      <div class="tl-legend">
        <c:forEach var="s" items="${slots}">
          <div class="tl-item ${s.night ? 'night' : 'day'}">
            <span class="ico">${s.night ? svgMoon : svgSun}</span>
            <div><b><c:out value="${s.slot_name}"/> · ${s.slot_from} – ${s.slot_to}${s.overnight ? ' hôm sau' : ''}</b>
              <span>${s.hours} giờ<c:if test="${s.night}"> · suất chiếu đêm</c:if></span></div>
          </div>
        </c:forEach>
      </div>
    </div>
  </section>

  <%-- ===== 3. Ngày xem ===== --%>
  <section class="pz-section">
    <h2><span class="pz-num">3</span>Ngày xem</h2>
    <p class="sub">Ngày lễ có giá riêng — được ưu tiên kể cả khi rơi vào cuối tuần.</p>
    <div class="pz-days">
      <div class="pz-card">
        <h3><span class="dot" style="background:var(--brand-500)"></span>Ngày thường <span class="muted" style="font-weight:500">&amp;</span> <span class="dot" style="background:var(--accent-500)"></span>Cuối tuần</h3>
        <div class="pz-week">
          <c:forEach var="w" items="T2,T3,T4,T5,T6,T7,CN" varStatus="ws">
            <div class="wd ${ws.index >= 5 ? 'weekend' : 'normal'} ${ws.index == todayIndex ? 'today' : ''}"><b>${w}</b><span>${ws.index >= 5 ? 'Cuối tuần' : 'Thường'}</span></div>
          </c:forEach>
        </div>
      </div>
      <div class="pz-card">
        <h3><span class="dot" style="background:var(--danger)"></span>Ngày lễ sắp tới</h3>
        <c:choose>
          <c:when test="${empty holidays}"><p class="hint" style="margin-top:12px">Chưa có ngày lễ nào sắp tới.</p></c:when>
          <c:otherwise>
            <div class="pz-hols">
              <c:forEach var="h" items="${holidays}">
                <div class="hol"><span class="cal"><small>TH ${h.month}</small><b>${h.day}</b></span>
                  <div class="t"><b><c:out value="${h.name}"/></b><span>${h.weekday} · <c:choose><c:when test="${h.days_until == 0}">hôm nay</c:when><c:otherwise>còn ${h.days_until} ngày</c:otherwise></c:choose></span></div></div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ===== 4. Loại phòng ===== --%>
  <section class="pz-section">
    <h2><span class="pz-num">4</span>Loại phòng chiếu</h2>
    <p class="sub">Phòng đặc biệt cộng thêm phụ thu cho <strong>mỗi ghế</strong>.</p>
    <div class="pz-rooms">
      <c:forEach var="rt" items="${roomTypes}">
        <div class="room-card">
          <c:choose>
            <c:when test="${rt.type_code == '3D'}"><svg viewBox="0 0 120 80" aria-hidden="true"><path class="r-line" d="M10 34 2 24M110 34l8-10"/><rect x="10" y="28" width="44" height="30" rx="10" fill="#ffd6d9" stroke="#e5484d" stroke-width="3"/><rect x="66" y="28" width="44" height="30" rx="10" fill="#cdeefe" stroke="#0ea5e9" stroke-width="3"/><path class="r-line" d="M54 38q6-7 12 0"/></svg></c:when>
            <c:when test="${rt.type_code == 'IMAX'}"><svg viewBox="0 0 120 80" aria-hidden="true"><path class="r-screen" d="M4 14Q60 0 116 14L112 58Q60 46 8 58Z"/><text class="r-text" x="60" y="38" text-anchor="middle">IMAX</text><path class="r-line" d="M30 72h60"/></svg></c:when>
            <c:when test="${rt.type_code == '4DX'}"><svg viewBox="0 0 120 80" aria-hidden="true"><path class="r-line" d="M14 26q-8 10 0 20M6 20q-12 16 0 32M106 26q8 10 0 20M114 20q12 16 0 32"/><rect x="40" y="10" width="40" height="36" rx="9" fill="#e8eeff" stroke="var(--brand-500)" stroke-width="3"/><rect x="32" y="40" width="56" height="16" rx="6" fill="#e8eeff" stroke="var(--brand-500)" stroke-width="3"/><path class="r-line" d="M60 56v14M46 72h28"/><circle cx="96" cy="12" r="3" fill="#0ea5e9"/><circle cx="104" cy="6" r="2" fill="#0ea5e9"/></svg></c:when>
            <c:otherwise><svg viewBox="0 0 120 80" aria-hidden="true"><rect class="r-screen" x="12" y="8" width="96" height="52" rx="5"/><text class="r-text" x="60" y="40" text-anchor="middle"><c:out value="${rt.type_code}"/></text><path class="r-line" d="M60 60v12M44 72h32"/></svg></c:otherwise>
          </c:choose>
          <h3>Phòng <c:out value="${rt.type_code}"/></h3>
          <div class="desc"><c:out value="${rt.description}"/></div>
          <c:choose>
            <c:when test="${rt.surcharge > 0}"><div class="sc">+<fmt:formatNumber value="${rt.surcharge}" pattern="#,##0"/>đ<small style="font-size:12px;color:var(--muted);font-weight:600"> / ghế</small></div></c:when>
            <c:otherwise><div class="sc free">Không phụ thu</div></c:otherwise>
          </c:choose>
        </div>
      </c:forEach>
    </div>
  </section>

  <%-- ===== Ví dụ ===== --%>
  <c:if test="${not empty example}">
    <section class="pz-section">
      <h2>${ic.sparkles}Ví dụ</h2>
      <p class="sub">${example.seat}, suất ${example.time} Thứ Bảy, phòng ${example.room}:</p>
      <div class="pz-example">
        <div class="ex-part k-${example.kind}">
          <c:choose><c:when test="${example.kind == 'cpl'}">${svgSeatCpl}</c:when><c:when test="${example.kind == 'vip'}">${svgSeatVip}</c:when><c:otherwise>${svgSeatStd}</c:otherwise></c:choose>
          <div><b><fmt:formatNumber value="${example.base}" pattern="#,##0"/>đ</b><span>${example.seat} · ${example.slot} · Cuối tuần</span></div>
        </div>
        <span class="ex-op">+</span>
        <div class="ex-part"><span style="color:var(--brand-600)">${ic.film}</span><div><b><fmt:formatNumber value="${example.surcharge}" pattern="#,##0"/>đ</b><span>Phụ thu phòng ${example.room}</span></div></div>
        <span class="ex-op">=</span>
        <div class="ex-total"><b><fmt:formatNumber value="${example.total}" pattern="#,##0"/>đ</b><span>mỗi ghế</span></div>
      </div>
    </section>
  </c:if>

  <section class="pz-section">
    <div class="alert alert-info">${ic.info}
      <div><strong>Lưu ý</strong>
        <ul style="margin:6px 0 0;padding-left:18px">
          <li>Giá tính cho từng ghế (VNĐ). Ghế đôi bán theo cặp — giá trong bảng là giá mỗi ghế.</li>
          <li>Giờ chiếu tính theo giờ bắt đầu suất chiếu; suất bắt đầu sau nửa đêm thuộc khung Khuya.</li>
          <li>Giá có thể thay đổi theo thời điểm; số tiền cuối cùng là số hiển thị ở bước chọn ghế.</li>
        </ul>
      </div>
    </div>
    <div class="text-center" style="margin-top:22px"><a class="btn btn-primary btn-lg" href="${ctx}/showtimes">${ic.ticket}Xem lịch chiếu và đặt vé</a></div>
  </section>

    </c:otherwise>
  </c:choose>
</div>
<div style="height:56px"></div>

<script>
(function () {
  var segDay = document.getElementById('segDay'), segSlot = document.getElementById('segSlot');
  if (!segDay || !segSlot) return;
  var NOW = { day: '${nowDayType}', slot: '${nowSlotId}' };
  var state = { day: NOW.day || 'Weekday', slot: NOW.slot || (segSlot.querySelector('button') || {}).dataset.slot };
  var dayNames = { Weekday: 'Ngày thường', Weekend: 'Cuối tuần', Holiday: 'Ngày lễ' };
  var nowEl = document.getElementById('pzNow');
  function render() {
    Array.prototype.forEach.call(segDay.querySelectorAll('button'), function (b) { b.setAttribute('aria-pressed', b.dataset.day === state.day); });
    Array.prototype.forEach.call(segSlot.querySelectorAll('button'), function (b) { b.setAttribute('aria-pressed', b.dataset.slot === String(state.slot)); });
    Array.prototype.forEach.call(document.querySelectorAll('.pp'), function (p) { p.hidden = !(p.dataset.day === state.day && p.dataset.slot === String(state.slot)); });
    var isNow = state.day === NOW.day && String(state.slot) === String(NOW.slot);
    nowEl.className = 'pz-now' + (isNow ? ' is-now' : '');
    nowEl.textContent = isNow ? '● Đang hiển thị giá cho thời điểm hiện tại' : 'Đang xem: ' + dayNames[state.day];
  }
  segDay.addEventListener('click', function (e) { var b = e.target.closest('button'); if (b) { state.day = b.dataset.day; render(); } });
  segSlot.addEventListener('click', function (e) { var b = e.target.closest('button'); if (b) { state.slot = b.dataset.slot; render(); } });
  render();
})();
</script>
<%@ include file="../layout/bottom.jspf" %>
