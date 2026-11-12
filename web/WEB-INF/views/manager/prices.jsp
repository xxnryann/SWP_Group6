<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Giá vé"/>
<%@ include file="../layout/top.jspf" %>
<fmt:setLocale value="vi_VN"/>
<style>
  .pr-meta { margin-top: 8px; font-size: var(--fs-xs); color: var(--subtle); }
  .pr-meta strong { color: var(--muted); font-weight: 600; }
  .tabs a .count { display: inline-grid; place-items: center; min-width: 20px; height: 20px; padding: 0 6px; margin-left: 6px; border-radius: 999px; background: var(--surface-3); color: var(--muted); font-size: 11.5px; font-weight: 700; }
  .tabs a.active .count { background: var(--brand-50); color: var(--brand-700); }

  /* ---- Cách tính giá ---- */
  details.pr-how-card > summary { cursor: pointer; list-style: none; }
  details.pr-how-card > summary::-webkit-details-marker { display: none; }
  details.pr-how-card > summary .chev { transition: transform .15s; display: inline-flex; color: var(--muted); }
  details.pr-how-card[open] > summary .chev { transform: rotate(180deg); }
  .pr-how { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); border-top: 1px solid var(--line); }
  .pr-step { padding: 18px 20px; }
  .pr-step + .pr-step { border-left: 1px solid var(--line); }
  .pr-step-num { display: inline-grid; place-items: center; width: 24px; height: 24px; border-radius: 50%; background: var(--brand-50); color: var(--brand-700); font-size: 12px; font-weight: 800; margin-right: 8px; flex: none; }
  .pr-step h3 { display: flex; align-items: center; font-size: 14.5px; color: var(--ink); margin-bottom: 10px; }
  .pr-step ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 6px; font-size: var(--fs-sm); }
  .pr-step li { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
  .pr-step li > span:last-child { color: var(--muted); font-variant-numeric: tabular-nums; text-align: right; }
  .pr-step .note { margin-top: 10px; font-size: var(--fs-xs); color: var(--muted); }

  /* ---- Bảng giá ---- */
  .pr-tools { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 10px 12px; padding: 14px 24px; border-bottom: 1px solid var(--line); background: var(--surface-2); }
  .pr-tools .field { margin: 0; }
  .pr-tools label { font-size: var(--fs-xs); }
  .pr-tools select, .pr-tools input { min-height: 38px !important; padding-top: 6px !important; padding-bottom: 6px !important; }
  .pr-tools .ttl { width: 100%; font-size: 13px; font-weight: 700; color: var(--ink); display: flex; gap: 8px; align-items: baseline; }
  .pr-tools .ttl .hint { font-weight: 400; }
  .pr-table th.day { text-align: right; white-space: nowrap; }
  .pr-table th.day small { display: block; font-weight: 500; color: var(--subtle); text-transform: none; letter-spacing: 0; margin-top: 2px; }
  .pr-table th.day.holiday { color: var(--accent-700); }
  .pr-group td { background: var(--surface-2); padding-top: 12px; padding-bottom: 12px; }
  .pr-group .grp { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; }
  .pr-group .grp strong { color: var(--ink); font-size: 15px; }
  .pr-group .grp .desc { color: var(--muted); font-size: var(--fs-sm); }
  .pr-slot .cell-main { display: block; }
  .pr-slot .cell-sub { white-space: nowrap; }
  .pr-cell { display: inline-flex; flex-direction: column; align-items: flex-end; gap: 4px; margin: 0; }
  .pr-input-wrap { position: relative; display: inline-flex; align-items: center; }
  .pr-input-wrap .unit { position: absolute; right: 12px; color: var(--subtle); font-size: 13px; pointer-events: none; }
  .field input.price-input { width: 132px; min-height: 40px !important; padding: 8px 28px 8px 10px !important; text-align: right; font-variant-numeric: tabular-nums; font-weight: 600; }
  .field input.price-input.is-dirty { border-color: var(--accent-500) !important; background: var(--accent-50) !important; }
  .field input.price-input.is-empty { border-color: var(--danger) !important; background: var(--danger-50) !important; }
  .field input.price-input.is-invalid { border-color: var(--danger) !important; box-shadow: 0 0 0 3px var(--danger-50) !important; }
  .field input.price-input.is-warn { box-shadow: 0 0 0 3px var(--warning-50) !important; }
  .pr-delta { font-size: 11.5px; color: var(--subtle); font-variant-numeric: tabular-nums; min-height: 14px; }
  .pr-delta.up { color: var(--warning); }
  .pr-delta.down { color: var(--success); }
  .pr-delta.err { color: var(--danger); }
  .pr-sched { font-size: 11px; color: var(--brand-700); background: var(--brand-50); border-radius: 6px; padding: 1px 6px; white-space: nowrap; }
  .pr-legend { display: flex; flex-wrap: wrap; gap: 14px; font-size: var(--fs-xs); color: var(--muted); }
  .pr-legend i { display: inline-block; width: 12px; height: 12px; border-radius: 3px; border: 1.5px solid; vertical-align: -2px; margin-right: 5px; }
  #sanity { margin: 14px 24px 0; }
  #sanity ul { margin: 4px 0 0; padding-left: 18px; font-size: var(--fs-sm); }

  /* ---- Thanh lưu ---- */
  .pr-savebar { position: sticky; bottom: 0; z-index: 5; display: grid; gap: 12px; padding: 14px 24px; border-top: 1px solid var(--line); background: var(--surface-2); border-radius: 0 0 var(--r-lg) var(--r-lg); }
  .pr-savebar.dirty { background: var(--accent-50); border-top-color: var(--accent-400); }
  .pr-savebar .row { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 10px; }
  .pr-savebar .status { font-size: var(--fs-sm); color: var(--muted); }
  .pr-savebar.dirty .status { color: var(--accent-700); font-weight: 600; }
  .pr-mode { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 18px; font-size: var(--fs-sm); }
  .pr-mode label { display: inline-flex; align-items: center; gap: 6px; cursor: pointer; }
  .pr-mode input[type="date"] { min-height: 36px; padding: 4px 8px; border: 1px solid var(--line-strong); border-radius: var(--r-sm); font: inherit; }

  /* ---- Cột phải ---- */
  .calc-result { margin-top: 14px; padding: 14px 16px; border-radius: var(--r-md); background: var(--surface-2); border: 1px solid var(--line); }
  .calc-result .total { font-size: 26px; font-weight: 800; color: var(--ink); letter-spacing: -.02em; }
  .calc-result dl { display: grid; grid-template-columns: auto 1fr; gap: 4px 12px; margin: 10px 0 0; font-size: var(--fs-sm); }
  .calc-result dt { color: var(--muted); }
  .calc-result dd { margin: 0; text-align: right; color: var(--text); font-variant-numeric: tabular-nums; }
  .calc-result.err { background: var(--danger-50); border-color: #f3c3c5; color: #b42a30; }
  .sched-group { border-top: 1px solid var(--line); padding: 14px 20px; }
  .sched-group .head { display: flex; align-items: flex-start; justify-content: space-between; gap: 10px; margin-bottom: 8px; }
  .sched-group ul { list-style: none; margin: 0; padding: 0; display: grid; gap: 4px; font-size: var(--fs-sm); }
  .sched-group li { display: flex; justify-content: space-between; gap: 10px; }
  .sched-group li .chg { white-space: nowrap; font-variant-numeric: tabular-nums; }
  .sched-group li .chg s { color: var(--subtle); }

  /* ---- Ngày lễ ---- */
  .hol-list { list-style: none; margin: 0; padding: 0; }
  .hol-item { display: flex; align-items: flex-start; gap: 14px; padding: 14px 20px; border-top: 1px solid var(--line); }
  .hol-date { flex: none; width: 50px; text-align: center; border: 1px solid var(--line); border-radius: var(--r-sm); overflow: hidden; background: var(--surface); }
  .hol-date b { display: block; font-size: 18px; line-height: 1.35; color: var(--ink); }
  .hol-date small { display: block; font-size: 10.5px; font-weight: 700; color: #fff; background: var(--accent-500); padding: 1px 0; }
  .hol-item.past .hol-date small { background: var(--subtle); }
  .hol-info { flex: 1; min-width: 0; display: grid; gap: 3px; }
  .hol-info .name { color: var(--ink); font-weight: 600; display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
  .hol-item.past .hol-info .name { color: var(--muted); }
  .hol-impact { font-size: var(--fs-xs); color: var(--warning); }
  .hol-actions { display: flex; gap: 6px; flex: none; }
  .hol-edit { margin-top: 8px; display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
  .hol-edit input[type="text"] { min-height: 36px !important; padding: 6px 10px !important; flex: 1 1 180px; }
  .hol-sec { padding: 10px 20px 8px; font-size: 11.5px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; color: var(--subtle); border-top: 1px solid var(--line); background: var(--surface-2); }
  details.hol-past > summary { cursor: pointer; list-style: none; display: flex; align-items: center; gap: 6px; }
  details.hol-past > summary::-webkit-details-marker { display: none; }
  #holImpact { font-size: var(--fs-sm); }
  .hol-info details > summary { list-style: none; display: inline-flex; align-items: center; gap: 4px; cursor: pointer; width: max-content; }
  .hol-info details > summary::-webkit-details-marker { display: none; }
  .hol-info details > summary svg { width: 14px; height: 14px; }
  .form-grid .field input, .form-grid .field select { min-width: 0; width: 100%; }
  .form-grid > .field { min-width: 0; }

  /* ---- Khung giờ / phụ thu ---- */
  .slot-table input[type="text"], .sc-input { min-height: 38px !important; padding: 6px 10px !important; }
  /* Chọn giờ 24h: 2 ô Giờ / Phút, không AM/PM */
  .time24 { display: inline-flex; align-items: center; gap: 4px; }
  .time24 b { color: var(--muted); font-weight: 700; }
  .time24 select { width: 68px; min-height: 38px; padding: 6px 8px; border: 1px solid var(--line-strong); border-radius: var(--r-md);
    background: var(--surface); color: var(--ink); font: inherit; font-weight: 600; font-variant-numeric: tabular-nums; text-align: center; }
  .time24 select:focus { outline: 2px solid var(--brand-300); outline-offset: 1px; border-color: var(--brand-500); }
  #calc .time24 select { width: 100%; min-height: 44px; }
  #calc .time24 { display: flex; }
  .sc-input { width: 140px; text-align: right; font-weight: 600; font-variant-numeric: tabular-nums; }

  @media (max-width: 1100px) {
    .pr-how { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .pr-step:nth-child(3) { border-left: 0; }
    .pr-step:nth-child(n+3) { border-top: 1px solid var(--line); }
  }
  @media (max-width: 640px) {
    .pr-how { grid-template-columns: 1fr; }
    .pr-step + .pr-step { border-left: 0; border-top: 1px solid var(--line); }
  }
</style>

<%-- ===================== Đầu trang ===================== --%>
<div class="page-head">
  <div>
    <h1>Quản lý giá vé</h1>
    <p>Giá của <strong>một ghế</strong> = giá theo loại ghế, khung giờ, loại ngày + phụ thu loại phòng. Vé đã bán luôn giữ giá lúc bán.</p>
    <c:if test="${not empty lastChange}">
      <div class="pr-meta">Cập nhật lần cuối: <strong><c:out value="${empty lastChange.changed_by_name ? 'Hệ thống' : lastChange.changed_by_name}"/></strong>
        lúc <strong>${lastChange.changed_at}</strong> — <c:out value="${lastChange.item}"/></div>
    </c:if>
  </div>
  <a class="btn" href="${ctx}/pricing" target="_blank" rel="noopener">${ic.eye}Xem bảng giá khách thấy</a>
</div>
<c:if test="${not empty error}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<div class="stats mb-24">
  <div class="stat">
    <div class="stat-icon">${ic.wallet}</div>
    <div class="stat-label">Khoảng giá đang áp dụng</div>
    <div class="stat-value" style="font-size:22px">
      <c:choose>
        <c:when test="${not empty priceMin}"><fmt:formatNumber value="${priceMin}" pattern="#,##0"/> – <fmt:formatNumber value="${priceMax}" pattern="#,##0"/>đ</c:when>
        <c:otherwise>—</c:otherwise>
      </c:choose>
    </div>
    <div class="stat-meta">Mỗi ghế, chưa gồm phụ thu phòng</div>
  </div>
  <div class="stat">
    <div class="stat-icon ${missingCount > 0 ? 'danger' : 'success'}">${missingCount > 0 ? ic.alert : ic.checkCircle}</div>
    <div class="stat-label">Ô giá chưa thiết lập</div>
    <div class="stat-value">${missingCount}<span style="font-size:15px;color:var(--subtle);font-weight:600"> / ${cellCount}</span></div>
    <div class="stat-meta">${missingCount > 0 ? 'Ghế thuộc ô này chưa bán được' : 'Đủ giá cho mọi trường hợp'}</div>
  </div>
  <div class="stat">
    <div class="stat-icon">${ic.clock}</div>
    <div class="stat-label">Lịch đổi giá sắp tới</div>
    <c:choose>
      <c:when test="${not empty schedules}">
        <div class="stat-value" style="font-size:22px">${schedules[0].display}</div>
        <div class="stat-meta">${scheduleCount} ô giá · ${schedules.size()} đợt</div>
      </c:when>
      <c:otherwise><div class="stat-value" style="font-size:22px">Không có</div><div class="stat-meta">Có thể lên lịch khi lưu bảng giá</div></c:otherwise>
    </c:choose>
  </div>
  <div class="stat">
    <div class="stat-icon accent">${ic.calendar}</div>
    <div class="stat-label">Ngày lễ sắp tới</div>
    <c:choose>
      <c:when test="${not empty nextHoliday}">
        <div class="stat-value" style="font-size:22px">${nextHoliday.display}</div>
        <div class="stat-meta"><c:out value="${nextHoliday.holiday_name}"/> ·
          <c:choose><c:when test="${nextHoliday.days_until == 0}">hôm nay</c:when><c:otherwise>còn ${nextHoliday.days_until} ngày</c:otherwise></c:choose></div>
      </c:when>
      <c:otherwise><div class="stat-value" style="font-size:22px">Chưa có</div><div class="stat-meta">Thêm ở tab Ngày lễ</div></c:otherwise>
    </c:choose>
  </div>
</div>

<nav class="tabs" aria-label="Phần quản lý giá vé">
  <a href="${ctx}/manager/prices?tab=gia" class="${tab == 'gia' ? 'active' : ''}">Bảng giá<c:if test="${missingCount > 0}"><span class="count" style="background:var(--danger-50);color:var(--danger)">${missingCount}</span></c:if></a>
  <a href="${ctx}/manager/prices?tab=le" class="${tab == 'le' ? 'active' : ''}">Ngày lễ<span class="count">${upcomingHolidays.size()}</span></a>
  <a href="${ctx}/manager/prices?tab=khung" class="${tab == 'khung' ? 'active' : ''}">Khung giờ &amp; phụ thu phòng</a>
  <a href="${ctx}/manager/prices?tab=lichsu" class="${tab == 'lichsu' ? 'active' : ''}">Lịch sử thay đổi</a>
</nav>

<c:choose>
<%-- ============================================================
     TAB 1. BẢNG GIÁ
     ============================================================ --%>
<c:when test="${tab == 'gia'}">
  <details class="card mb-24 pr-how-card" open>
    <summary class="card-head">
      <div><h2>Hệ thống tính giá một ghế như thế nào?</h2><p>Mỗi ghế khi đặt lấy đúng 1 ô trong bảng giá, cộng phụ thu của loại phòng.</p></div>
      <span class="chev">${ic.chevronDown}</span>
    </summary>
    <div class="pr-how">
      <div class="pr-step">
        <h3><span class="pr-step-num">1</span>Loại ghế</h3>
        <ul>
          <c:forEach var="g" items="${seatGroups}">
            <li><span class="cluster" style="--gap:8px"><i class="seat-type-dot t-${g.name}"></i><c:out value="${g.name}"/></span><span><c:out value="${g.desc}"/></span></li>
          </c:forEach>
        </ul>
        <p class="note">Ghế đôi: giá ghi là giá <strong>mỗi ghế</strong> — một cặp tính 2 lần.</p>
      </div>
      <div class="pr-step">
        <h3><span class="pr-step-num">2</span>Khung giờ</h3>
        <ul>
          <c:forEach var="s" items="${slots}"><li><span><c:out value="${s.slot_name}"/></span><span>${s.slot_range}</span></li></c:forEach>
        </ul>
        <p class="note">Theo giờ <strong>bắt đầu</strong> suất chiếu; khung muộn nhất kéo qua nửa đêm. Sửa ở tab Khung giờ.</p>
      </div>
      <div class="pr-step">
        <h3><span class="pr-step-num">3</span>Loại ngày</h3>
        <ul>
          <li><span>Ngày thường</span><span>T2 – T6</span></li>
          <li><span>Cuối tuần</span><span>T7, CN</span></li>
          <li><span>Ngày lễ</span><span>Theo tab Ngày lễ</span></li>
        </ul>
        <p class="note">Ngày lễ được ưu tiên, kể cả khi rơi vào cuối tuần.</p>
      </div>
      <div class="pr-step">
        <h3><span class="pr-step-num">4</span>Phụ thu loại phòng</h3>
        <ul>
          <c:forEach var="rt" items="${roomTypes}">
            <li><span><c:out value="${rt.type_code}"/></span><span><c:choose><c:when test="${rt.surcharge > 0}">+<fmt:formatNumber value="${rt.surcharge}" pattern="#,##0"/>đ</c:when><c:otherwise>không</c:otherwise></c:choose></span></li>
          </c:forEach>
        </ul>
        <p class="note">Cộng thêm vào mỗi ghế. Sửa ở tab Khung giờ &amp; phụ thu.</p>
      </div>
    </div>
  </details>

  <div class="split" style="grid-template-columns:minmax(0,1fr) 340px">
    <section class="card">
      <div class="card-head">
        <div><h2>Bảng giá theo loại ghế</h2><p>Đơn vị: đồng / ghế, bội số 1.000đ. Dòng nhỏ dưới ô cho biết chênh lệch so với ngày thường.</p></div>
        <div class="pr-legend" aria-hidden="true">
          <span><i style="border-color:var(--accent-500);background:var(--accent-50)"></i>Đã sửa</span>
          <span><i style="border-color:var(--danger);background:var(--danger-50)"></i>Chưa có giá</span>
          <span><i style="border-color:var(--brand-300);background:var(--brand-50)"></i>Có lịch đổi</span>
        </div>
      </div>

      <div class="pr-tools" id="bulkTools">
        <div class="ttl">Điều chỉnh nhanh <span class="hint">— chỉ điền sẵn vào bảng, bấm Lưu mới ghi.</span></div>
        <div class="field"><label for="bulkScope">Phạm vi</label>
          <select id="bulkScope">
            <option value="all">Toàn bảng</option>
            <option value="day:Weekday">Cột Ngày thường</option>
            <option value="day:Weekend">Cột Cuối tuần</option>
            <option value="day:Holiday">Cột Ngày lễ</option>
            <c:forEach var="g" items="${seatGroups}"><option value="seat:${g.id}">Loại ghế <c:out value="${g.name}"/></option></c:forEach>
          </select></div>
        <div class="field"><label for="bulkOp">Cách</label>
          <select id="bulkOp">
            <option value="add">Cộng / trừ số tiền (đ)</option>
            <option value="pct">Tăng / giảm theo %</option>
            <option value="set">Đặt bằng (đ)</option>
            <option value="fromWeekday">= Ngày thường + số tiền (đ)</option>
          </select></div>
        <div class="field"><label for="bulkVal">Giá trị</label><input id="bulkVal" type="text" inputmode="numeric" placeholder="VD: 10000 hoặc -5" style="width:150px"></div>
        <button class="btn btn-soft btn-sm" type="button" id="bulkApply">${ic.check}Áp dụng vào bảng</button>
      </div>

      <div id="sanity" class="alert alert-warning" role="status" hidden>${ic.alert}<div><strong>Kiểm tra lại giá</strong> (chỉ là cảnh báo, vẫn lưu được)<ul></ul></div></div>

      <form method="post" action="${ctx}/manager/prices" id="priceForm">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="savePrices">
        <input type="hidden" name="tab" value="gia">
        <div class="table-wrap"><table class="table pr-table">
          <thead><tr>
            <th>Khung giờ</th>
            <th class="day">Ngày thường<small>T2 – T6</small></th>
            <th class="day">Cuối tuần<small>T7, CN</small></th>
            <th class="day holiday">Ngày lễ<small>Ưu tiên cao nhất</small></th>
          </tr></thead>
          <c:forEach var="g" items="${seatGroups}">
            <tbody>
              <tr class="pr-group"><td colspan="4">
                <div class="grp">
                  <i class="seat-type-dot t-${g.name}"></i><strong><c:out value="${g.name}"/></strong>
                  <c:if test="${not empty g.desc}"><span class="desc"><c:out value="${g.desc}"/></span></c:if>
                  <c:if test="${g.couple}"><span class="badge badge-accent">Giá mỗi ghế · cặp = ×2</span></c:if>
                </div>
              </td></tr>
              <c:forEach var="r" items="${g.rows}">
                <tr class="pr-slot" data-row data-seat="${g.id}" data-seat-name="<c:out value='${g.name}'/>" data-slot="${r.slot_id}" data-slot-name="<c:out value='${r.slot_name}'/>">
                  <td><span class="cell-main"><c:out value="${r.slot_name}"/></span><span class="cell-sub">${r.slot_range}</span></td>
                  <c:forEach var="d" items="Weekday,Weekend,Holiday" varStatus="ds">
                    <c:set var="val" value="${ds.index == 0 ? r.weekday : (ds.index == 1 ? r.weekend : r.holiday)}"/>
                    <c:set var="dayLabel" value="${ds.index == 0 ? 'ngày thường' : (ds.index == 1 ? 'cuối tuần' : 'ngày lễ')}"/>
                    <c:set var="ck" value="${r.seat_type_id}_${r.slot_id}_${d}"/>
                    <td class="num">
                      <div class="field pr-cell">
                        <span class="pr-input-wrap">
                          <input class="price-input" type="text" inputmode="numeric" autocomplete="off"
                                 name="p_${ck}" value="${val}" data-orig="${val}" data-day="${d}"
                                 placeholder="Chưa có" aria-label="${g.name}, ${r.slot_name}, ${dayLabel}">
                          <span class="unit">đ</span>
                        </span>
                        <input type="hidden" name="o_${ck}" value="${val}">
                        <span class="pr-delta" aria-live="polite"></span>
                        <c:if test="${not empty scheduleHints[ck]}"><span class="pr-sched" title="Đã lên lịch đổi giá">${ic.clock} ${scheduleHints[ck]}</span></c:if>
                      </div>
                    </td>
                  </c:forEach>
                </tr>
              </c:forEach>
            </tbody>
          </c:forEach>
        </table></div>
        <div class="pr-savebar" id="saveBar">
          <div class="pr-mode" role="radiogroup" aria-label="Thời điểm áp dụng">
            <strong style="color:var(--ink)">Áp dụng:</strong>
            <label><input type="radio" name="mode" value="now" checked> Ngay — cho mọi suất chiếu chưa bán</label>
            <label><input type="radio" name="mode" value="schedule"> Cho suất chiếu từ ngày</label>
            <input type="date" name="effectiveFrom" id="effectiveFrom" min="${today.plusDays(1)}" aria-label="Ngày bắt đầu áp dụng giá mới" disabled>
          </div>
          <div class="row">
            <span class="status" id="saveStatus">Không có thay đổi</span>
            <div class="cluster" style="--gap:10px">
              <button class="btn btn-ghost" type="button" id="resetBtn" disabled>${ic.refresh}Hoàn tác</button>
              <button class="btn btn-primary" type="submit" id="saveBtn">${ic.check}Lưu bảng giá</button>
            </div>
          </div>
        </div>
      </form>
    </section>

    <div class="stack" style="--gap:24px">
      <section class="card">
        <div class="card-head"><div><h2>Tính thử giá</h2><p>Dùng đúng công thức khi khách đặt vé.</p></div></div>
        <div class="card-body form" id="calc">
          <div class="form-grid" style="grid-template-columns:1fr 1fr;gap:12px">
            <div class="field"><label for="calcSeat">Loại ghế</label>
              <select id="calcSeat"><c:forEach var="g" items="${seatGroups}"><option value="${g.id}"><c:out value="${g.name}"/></option></c:forEach></select></div>
            <div class="field"><label for="calcRoom">Loại phòng</label>
              <select id="calcRoom"><c:forEach var="rt" items="${roomTypes}"><option value="<c:out value='${rt.type_code}'/>"><c:out value="${rt.type_code}"/></option></c:forEach></select></div>
            <div class="field"><label for="calcDate">Ngày chiếu</label><input id="calcDate" type="date" value="${today}"></div>
            <div class="field"><label>Giờ bắt đầu</label>
              <span class="time24" data-step="5"><select class="t-h" aria-label="Giờ"></select><b>:</b><select class="t-m" aria-label="Phút"></select>
                <input type="hidden" id="calcTime" value="19:30"></span></div>
          </div>
          <div class="calc-result" id="calcResult" aria-live="polite"><span class="hint">Đang tính…</span></div>
        </div>
      </section>

      <section class="card">
        <div class="card-head"><div><h2>Lịch đổi giá</h2><p>Giá mới tự áp dụng cho suất chiếu từ ngày đã chọn.</p></div></div>
        <c:choose>
          <c:when test="${empty schedules}">
            <div class="card-body"><p class="hint">Chưa có lịch nào. Sửa bảng giá rồi chọn <strong>"Cho suất chiếu từ ngày"</strong> trước khi lưu.</p></div>
          </c:when>
          <c:otherwise>
            <c:forEach var="s" items="${schedules}">
              <div class="sched-group">
                <div class="head">
                  <div><strong style="color:var(--ink)">Từ ${s.weekday_name}, ${s.display}</strong>
                    <div class="hint">còn ${s.days_until} ngày · ${s.items.size()} ô giá</div></div>
                  <form method="post" action="${ctx}/manager/prices" data-confirm="Hủy toàn bộ lịch đổi giá ngày ${s.display}?">
                    <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="cancelSchedule">
                    <input type="hidden" name="tab" value="gia"><input type="hidden" name="date" value="${s.date}">
                    <button class="btn btn-xs btn-danger" type="submit">Hủy lịch</button>
                  </form>
                </div>
                <ul>
                  <c:forEach var="it" items="${s.items}">
                    <li><span><c:out value="${it.type_name}"/> · <c:out value="${it.slot_name}"/> · ${it.day_label}</span>
                      <span class="chg"><c:if test="${not empty it.old_price}"><s><fmt:formatNumber value="${it.old_price}" pattern="#,##0"/></s> → </c:if><strong><fmt:formatNumber value="${it.price}" pattern="#,##0"/>đ</strong></span></li>
                  </c:forEach>
                </ul>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </section>
    </div>
  </div>
</c:when>

<%-- ============================================================
     TAB 2. NGÀY LỄ
     ============================================================ --%>
<c:when test="${tab == 'le'}">
  <div class="split" style="grid-template-columns:minmax(0,1fr) 360px">
    <section class="card">
      <div class="card-head"><div><h2>Danh sách ngày lễ</h2><p>Các ngày này dùng cột <strong>Ngày lễ</strong> thay cho giá thường / cuối tuần. Vé đã bán giữ nguyên giá.</p></div></div>
      <div class="hol-sec">Sắp tới (${upcomingHolidays.size()})</div>
      <c:choose>
        <c:when test="${empty upcomingHolidays}"><p class="hint" style="padding:16px 20px">Chưa có ngày lễ nào sắp tới.</p></c:when>
        <c:otherwise>
          <ul class="hol-list">
            <c:forEach var="h" items="${upcomingHolidays}">
              <li class="hol-item">
                <span class="hol-date"><small>TH ${h.next_date.monthValue}</small><b>${h.next_date.dayOfMonth}</b></span>
                <div class="hol-info">
                  <span class="name"><c:out value="${h.holiday_name}"/><c:if test="${h.is_recurring}"><span class="badge badge-brand">Hằng năm</span></c:if></span>
                  <span class="hint">${h.weekday_name}, ${h.display} ·
                    <c:choose><c:when test="${h.days_until == 0}">hôm nay</c:when><c:otherwise>còn ${h.days_until} ngày</c:otherwise></c:choose>
                    <c:if test="${h.is_recurring and h.base_display != h.display}"> · bắt đầu từ ${h.base_display}</c:if></span>
                  <c:if test="${h.impact_showtimes > 0}">
                    <span class="hol-impact">${ic.alert} ${h.impact_showtimes} suất chiếu đã xếp<c:if test="${h.impact_tickets > 0}">, ${h.impact_tickets} vé đã bán/giữ</c:if> trong ngày này</span>
                  </c:if>
                  <details>
                    <summary class="hint">${ic.edit}Sửa</summary>
                    <form method="post" action="${ctx}/manager/prices" class="hol-edit field">
                      <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="updateHoliday">
                      <input type="hidden" name="tab" value="le"><input type="hidden" name="holidayDate" value="${h.holiday_date}">
                      <input type="text" name="holidayName" maxlength="100" required value="<c:out value='${h.holiday_name}'/>" aria-label="Tên ngày lễ">
                      <label class="check"><input type="checkbox" name="recurring" value="1" ${h.is_recurring ? 'checked' : ''}> Hằng năm</label>
                      <button class="btn btn-sm btn-soft" type="submit">Lưu</button>
                    </form>
                  </details>
                </div>
                <div class="hol-actions">
                  <c:set var="delMsg">Xóa ngày lễ ${h.display}?<c:if test="${h.impact_showtimes > 0}"> Ngày này có ${h.impact_showtimes} suất chiếu — vé đặt sau sẽ tính lại giá thường/cuối tuần.</c:if></c:set>
                  <form method="post" action="${ctx}/manager/prices" data-confirm="${delMsg}">
                    <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="deleteHoliday">
                    <input type="hidden" name="tab" value="le"><input type="hidden" name="holidayDate" value="${h.holiday_date}">
                    <button class="btn btn-xs btn-danger btn-icon" type="submit" aria-label="Xóa ngày lễ <c:out value='${h.holiday_name}'/>">${ic.trash}</button>
                  </form>
                </div>
              </li>
            </c:forEach>
          </ul>
        </c:otherwise>
      </c:choose>
      <c:if test="${not empty pastHolidays}">
        <details class="hol-past">
          <summary class="hol-sec">${ic.chevronDown}Đã qua (${pastHolidays.size()})</summary>
          <ul class="hol-list">
            <c:forEach var="h" items="${pastHolidays}">
              <li class="hol-item past">
                <span class="hol-date"><small>TH ${h.next_date.monthValue}</small><b>${h.next_date.dayOfMonth}</b></span>
                <div class="hol-info"><span class="name"><c:out value="${h.holiday_name}"/></span><span class="hint">${h.weekday_name}, ${h.display}</span></div>
                <div class="hol-actions">
                  <form method="post" action="${ctx}/manager/prices" data-confirm="Xóa ngày lễ đã qua ${h.display}?">
                    <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="deleteHoliday">
                    <input type="hidden" name="tab" value="le"><input type="hidden" name="holidayDate" value="${h.holiday_date}">
                    <button class="btn btn-xs btn-danger btn-icon" type="submit" aria-label="Xóa ngày lễ <c:out value='${h.holiday_name}'/>">${ic.trash}</button>
                  </form>
                </div>
              </li>
            </c:forEach>
          </ul>
        </details>
      </c:if>
    </section>

    <section class="card sticky">
      <div class="card-head"><div><h2>Thêm ngày lễ</h2><p>Nhập một ngày hoặc cả kỳ nghỉ (tối đa 31 ngày).</p></div></div>
      <div class="card-body">
        <form method="post" action="${ctx}/manager/prices" class="form" id="holidayForm">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="addHoliday">
          <input type="hidden" name="tab" value="le">
          <div class="form-grid" style="grid-template-columns:1fr 1fr;gap:12px">
            <div class="field"><label for="holidayDate">Từ ngày<span class="req">*</span></label><input id="holidayDate" name="holidayDate" type="date" min="${today}" required></div>
            <div class="field"><label for="holidayTo">Đến ngày</label><input id="holidayTo" name="holidayTo" type="date" min="${today}"></div>
          </div>
          <div class="field"><label for="holidayName">Tên ngày lễ<span class="req">*</span></label><input id="holidayName" name="holidayName" type="text" maxlength="100" required placeholder="VD: Tết Nguyên đán"></div>
          <label class="check"><input type="checkbox" name="recurring" value="1"> Lặp lại hằng năm (cùng ngày dương lịch)</label>
          <div id="holImpact" class="hint" aria-live="polite"></div>
          <button class="btn btn-primary" type="submit" style="width:100%">${ic.plus}Thêm ngày lễ</button>
        </form>
      </div>
    </section>
  </div>
</c:when>

<%-- ============================================================
     TAB 3. KHUNG GIỜ & PHỤ THU
     ============================================================ --%>
<c:when test="${tab == 'khung'}">
  <div class="stack" style="--gap:24px">
    <section class="card">
      <div class="card-head"><div><h2>Khung giờ giá</h2>
        <p>${timeSlots.size()} khung cố định phủ kín 24 giờ, tính theo giờ <strong>bắt đầu</strong> suất chiếu. Mỗi khung kéo dài tới giờ bắt đầu của khung kế tiếp; khung muộn nhất kéo qua nửa đêm.
          Có thể đổi tên hoặc giờ bắt đầu — các suất chiếu <strong>chưa diễn ra</strong> sẽ được xếp lại khung, vé đã bán giữ nguyên giá.</p></div></div>
      <form method="post" action="${ctx}/manager/prices" id="slotForm"
            data-confirm="Lưu khung giờ? Các suất chiếu chưa diễn ra sẽ được xếp lại theo khung mới.">
        <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="saveSlots"><input type="hidden" name="tab" value="khung">
        <div class="table-wrap"><table class="table slot-table">
          <thead><tr><th>Tên khung</th><th>Bắt đầu</th><th>Kết thúc</th><th class="num">Thời lượng</th><th class="num">Suất sắp tới</th></tr></thead>
          <tbody>
            <c:forEach var="s" items="${timeSlots}">
              <tr data-slot-row>
                <td><div class="field" style="margin:0"><input type="hidden" name="slotId" value="${s.slot_id}">
                  <input type="text" name="slotName_${s.slot_id}" maxlength="30" required value="<c:out value='${s.slot_name}'/>" aria-label="Tên khung giờ"></div></td>
                <td><span class="time24" data-step="5"><select class="t-h" aria-label="Giờ bắt đầu khung ${s.slot_name}"></select><b>:</b><select class="t-m" aria-label="Phút"></select>
                  <input type="hidden" name="slotStart_${s.slot_id}" value="${s.slot_from}"></span></td>
                <td class="slot-end" style="font-variant-numeric:tabular-nums">${s.slot_to}</td>
                <td class="num slot-len"></td>
                <td class="num">${s.future_showtimes}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table></div>
        <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Lưu khung giờ</button></div>
      </form>
    </section>

    <section class="card">
      <div class="card-head"><div><h2>Phụ thu theo loại phòng</h2><p>Cộng thêm vào <strong>mỗi ghế</strong> khi suất chiếu ở loại phòng này. Áp dụng ngay cho vé đặt sau khi lưu.</p></div></div>
      <form method="post" action="${ctx}/manager/prices">
        <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="saveSurcharges"><input type="hidden" name="tab" value="khung">
        <div class="table-wrap"><table class="table">
          <thead><tr><th>Loại phòng</th><th>Mô tả</th><th class="num">Phòng đang hoạt động</th><th class="num">Phụ thu / ghế</th></tr></thead>
          <tbody>
            <c:forEach var="rt" items="${roomTypes}">
              <tr>
                <td><strong class="text-ink"><c:out value="${rt.type_code}"/></strong></td>
                <td class="muted"><c:out value="${rt.description}"/></td>
                <td class="num">${rt.rooms}</td>
                <td class="num"><div class="field pr-cell"><span class="pr-input-wrap">
                  <input class="sc-input price-input" type="text" inputmode="numeric" name="sc_<c:out value='${rt.type_code}'/>" value="${rt.surcharge}" data-orig="${rt.surcharge}" aria-label="Phụ thu phòng ${rt.type_code}">
                  <span class="unit">đ</span></span>
                  <input type="hidden" name="so_<c:out value='${rt.type_code}'/>" value="${rt.surcharge}"></div></td>
              </tr>
            </c:forEach>
          </tbody>
        </table></div>
        <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Lưu phụ thu</button></div>
      </form>
    </section>
  </div>
</c:when>

<%-- ============================================================
     TAB 4. LỊCH SỬ
     ============================================================ --%>
<c:otherwise>
  <section class="card">
    <div class="card-head"><div><h2>Lịch sử thay đổi</h2><p>200 thay đổi gần nhất về giá vé, lịch đổi giá, phụ thu, khung giờ và ngày lễ.</p></div></div>
    <c:choose>
      <c:when test="${empty changeLog}"><div class="empty"><div class="empty-icon">${ic.clock}</div><h3>Chưa có thay đổi nào được ghi lại</h3></div></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="table">
          <thead><tr><th>Thời gian</th><th>Người thực hiện</th><th>Loại</th><th>Mục</th><th class="num">Trước</th><th class="num">Sau</th><th>Ghi chú</th></tr></thead>
          <tbody>
            <c:forEach var="l" items="${changeLog}">
              <tr>
                <td style="white-space:nowrap">${l.changed_at}</td>
                <td><c:out value="${empty l.changed_by_name ? 'Hệ thống' : l.changed_by_name}"/></td>
                <td><c:choose>
                  <c:when test="${l.category == 'Price'}"><span class="badge badge-brand">Giá vé</span></c:when>
                  <c:when test="${l.category == 'Schedule'}"><span class="badge badge-info">Lịch đổi giá</span></c:when>
                  <c:when test="${l.category == 'Surcharge'}"><span class="badge badge-accent">Phụ thu</span></c:when>
                  <c:when test="${l.category == 'TimeSlot'}"><span class="badge badge-dark">Khung giờ</span></c:when>
                  <c:otherwise><span class="badge badge-warning">Ngày lễ</span></c:otherwise>
                </c:choose></td>
                <td class="cell-main"><c:out value="${l.item}"/></td>
                <td class="num muted"><c:out value="${empty l.old_value ? '—' : l.old_value}"/></td>
                <td class="num"><strong><c:out value="${empty l.new_value ? '—' : l.new_value}"/></strong></td>
                <td class="muted"><c:out value="${l.note}"/></td>
              </tr>
            </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>
  </section>
</c:otherwise>
</c:choose>

<script>
(function () {
  var nf = new Intl.NumberFormat('vi-VN');
  var MAX = 5000000;
  var ctx = '${ctx}';
  function digits(s) { return String(s == null ? '' : s).replace(/[^\d]/g, ''); }
  function fmt(s) { var d = digits(s); return d === '' ? '' : nf.format(Number(d)); }
  function money(n) { return nf.format(n) + 'đ'; }
  function signed(n) { return (n > 0 ? '+' : n < 0 ? '−' : '±') + nf.format(Math.abs(n)); }
  function each(list, fn) { Array.prototype.forEach.call(list, fn); }
  function pad(n) { return (n < 10 ? '0' : '') + n; }

  /* Ô chọn giờ 24h (Giờ 00–23 : Phút) — ghi "HH:mm" vào input ẩn rồi phát sự kiện change */
  each(document.querySelectorAll('.time24'), function (w) {
    var h = w.querySelector('.t-h'), m = w.querySelector('.t-m'), hid = w.querySelector('input[type="hidden"]');
    var step = Number(w.dataset.step || 5), i;
    function add(sel, v) { var o = document.createElement('option'); o.value = o.textContent = v; sel.appendChild(o); }
    for (i = 0; i < 24; i++) add(h, pad(i));
    for (i = 0; i < 60; i += step) add(m, pad(i));
    var v = (hid.value || '00:00').slice(0, 5).split(':');
    if (!m.querySelector('option[value="' + v[1] + '"]')) add(m, v[1]);
    h.value = v[0]; m.value = v[1];
    function sync() { hid.value = h.value + ':' + m.value; hid.dispatchEvent(new Event('change', { bubbles: true })); }
    h.addEventListener('change', sync); m.addEventListener('change', sync);
  });

  /* Ô tiền: hiện "85.000", bỏ dấu chấm khi gửi */
  function bindMoney(inp, onChange) {
    inp.value = fmt(inp.value);
    inp.addEventListener('input', function () {
      var pos = inp.value.length - inp.selectionStart;
      inp.value = fmt(inp.value);
      var p = Math.max(0, inp.value.length - pos); inp.setSelectionRange(p, p);
      if (onChange) onChange(inp);
    });
    inp.addEventListener('focus', function () { inp.select(); });
  }
  each(document.querySelectorAll('.sc-input'), function (i) {
    bindMoney(i, function () { i.classList.toggle('is-dirty', digits(i.value) !== digits(i.dataset.orig)); });
    i.form.addEventListener('submit', function () { i.value = digits(i.value); });
  });

  /* ================= Bảng giá ================= */
  var form = document.getElementById('priceForm');
  if (form) {
    var inputs = Array.prototype.slice.call(form.querySelectorAll('.price-input'));
    var rows = Array.prototype.slice.call(form.querySelectorAll('[data-row]'));
    var bar = document.getElementById('saveBar'), status = document.getElementById('saveStatus');
    var resetBtn = document.getElementById('resetBtn'), saveBtn = document.getElementById('saveBtn');
    var effInput = document.getElementById('effectiveFrom');
    var sanity = document.getElementById('sanity');
    var submitting = false;
    function val(inp) { var d = digits(inp.value); return d === '' ? null : Number(d); }
    function dirty(inp) { return digits(inp.value) !== digits(inp.dataset.orig); }
    function cell(row, day) { return row.querySelector('.price-input[data-day="' + day + '"]'); }

    function refreshRow(row) {
      var base = val(cell(row, 'Weekday'));
      each(row.querySelectorAll('.price-input'), function (inp, i) {
        var delta = inp.closest('.pr-cell').querySelector('.pr-delta');
        var v = val(inp);
        inp.classList.toggle('is-empty', v === null);
        inp.classList.toggle('is-dirty', dirty(inp));
        inp.classList.toggle('is-invalid', v !== null && (v > MAX || v % 1000 !== 0));
        delta.className = 'pr-delta';
        if (v !== null && v > MAX) { delta.textContent = 'Tối đa 5.000.000đ'; delta.classList.add('err'); return; }
        if (v !== null && v % 1000 !== 0) { delta.textContent = 'Phải tròn 1.000đ'; delta.classList.add('err'); return; }
        if (v === null) { delta.textContent = 'Bắt buộc nhập'; delta.classList.add('err'); return; }
        if (i === 0 || base === null) { delta.textContent = i === 0 ? 'Giá gốc' : ''; return; }
        var diff = v - base;
        delta.textContent = diff === 0 ? 'Bằng ngày thường' : signed(diff) + 'đ';
        delta.classList.add(diff > 0 ? 'up' : 'down');
      });
    }

    /* Cảnh báo hợp lý: cuối tuần ≥ ngày thường, lễ ≥ cuối tuần, VIP ≥ Standard, ghế đôi ≥ Standard */
    function checkSanity() {
      var warns = [];
      each(inputs, function (i) { i.classList.remove('is-warn'); });
      rows.forEach(function (row) {
        var wd = cell(row, 'Weekday'), we = cell(row, 'Weekend'), ho = cell(row, 'Holiday');
        var label = row.dataset.seatName + ' · ' + row.dataset.slotName;
        if (val(we) !== null && val(wd) !== null && val(we) < val(wd)) { warns.push(label + ': cuối tuần rẻ hơn ngày thường'); we.classList.add('is-warn'); }
        if (val(ho) !== null && val(we) !== null && val(ho) < val(we)) { warns.push(label + ': ngày lễ rẻ hơn cuối tuần'); ho.classList.add('is-warn'); }
      });
      var bySeat = {};
      rows.forEach(function (r) { (bySeat[r.dataset.seatName] = bySeat[r.dataset.seatName] || {})[r.dataset.slot] = r; });
      var std = bySeat['Standard'];
      if (std) {
        ['VIP', 'Couple'].forEach(function (name) {
          var grp = bySeat[name]; if (!grp) return;
          Object.keys(grp).forEach(function (slot) {
            var r = grp[slot], s = std[slot]; if (!s) return;
            ['Weekday', 'Weekend', 'Holiday'].forEach(function (d) {
              var a = val(cell(r, d)), b = val(cell(s, d));
              if (a !== null && b !== null && a < b) {
                warns.push(name + ' · ' + r.dataset.slotName + ' rẻ hơn Standard (' + ({Weekday: 'ngày thường', Weekend: 'cuối tuần', Holiday: 'ngày lễ'})[d] + ')');
                cell(r, d).classList.add('is-warn');
              }
            });
          });
        });
      }
      var ul = sanity.querySelector('ul'); ul.innerHTML = '';
      warns.slice(0, 8).forEach(function (w) { var li = document.createElement('li'); li.textContent = w; ul.appendChild(li); });
      if (warns.length > 8) { var li = document.createElement('li'); li.textContent = '… và ' + (warns.length - 8) + ' cảnh báo khác'; ul.appendChild(li); }
      sanity.hidden = warns.length === 0;
    }

    function refreshBar() {
      var nDirty = inputs.filter(dirty).length;
      var nEmpty = inputs.filter(function (i) { return val(i) === null; }).length;
      var nBad = inputs.filter(function (i) { var v = val(i); return v !== null && (v > MAX || v % 1000 !== 0); }).length;
      var schedule = form.querySelector('input[name="mode"]:checked').value === 'schedule';
      bar.classList.toggle('dirty', nDirty > 0);
      resetBtn.disabled = nDirty === 0;
      saveBtn.disabled = nBad > 0 || nEmpty > 0 || nDirty === 0 || (schedule && !effInput.value);
      status.textContent = nEmpty > 0 ? 'Còn ' + nEmpty + ' ô trống — mọi ô phải có giá'
        : nBad > 0 ? nBad + ' ô không hợp lệ — sửa trước khi lưu'
        : nDirty === 0 ? 'Không có thay đổi'
        : schedule && !effInput.value ? 'Có ' + nDirty + ' ô đã sửa — chọn ngày áp dụng'
        : 'Có ' + nDirty + ' ô giá đã sửa, chưa lưu' + (schedule ? ' (áp dụng từ ' + effInput.value.split('-').reverse().join('/') + ')' : '');
    }
    function refreshAll() { rows.forEach(refreshRow); checkSanity(); refreshBar(); }

    inputs.forEach(function (inp) { bindMoney(inp, function () { refreshRow(inp.closest('[data-row]')); checkSanity(); refreshBar(); }); });
    each(form.querySelectorAll('input[name="mode"]'), function (r) {
      r.addEventListener('change', function () { effInput.disabled = r.value !== 'schedule' || !r.checked; if (!effInput.disabled) effInput.focus(); refreshBar(); });
    });
    effInput.addEventListener('change', refreshBar);
    resetBtn.addEventListener('click', function () { inputs.forEach(function (i) { i.value = fmt(i.dataset.orig); }); refreshAll(); });
    form.addEventListener('submit', function (e) {
      var n = inputs.filter(dirty).length;
      var schedule = form.querySelector('input[name="mode"]:checked').value === 'schedule';
      var msg = schedule ? 'Lên lịch đổi ' + n + ' ô giá cho các suất chiếu từ ' + effInput.value.split('-').reverse().join('/') + '?'
                         : 'Áp dụng ngay ' + n + ' ô giá mới? Vé đã bán giữ nguyên giá cũ.';
      if (!sanity.hidden) msg += '\n\nLưu ý: còn ' + sanity.querySelectorAll('li').length + ' cảnh báo về mức giá.';
      if (!confirm(msg)) { e.preventDefault(); return; }
      submitting = true;
      inputs.forEach(function (i) { i.value = digits(i.value); });
    });
    window.addEventListener('beforeunload', function (e) {
      if (!submitting && inputs.some(dirty)) { e.preventDefault(); e.returnValue = ''; }
    });

    /* Điều chỉnh nhanh */
    document.getElementById('bulkApply').addEventListener('click', function () {
      var scope = document.getElementById('bulkScope').value, op = document.getElementById('bulkOp').value;
      var raw = document.getElementById('bulkVal').value.trim().replace(/\./g, '').replace(',', '.');
      var num = Number(raw);
      if (raw === '' || isNaN(num)) { alert('Nhập giá trị là một số, ví dụ 10000, -5000 hoặc 10 (%).'); return; }
      var count = 0;
      rows.forEach(function (row) {
        if (scope.indexOf('seat:') === 0 && row.dataset.seat !== scope.slice(5)) return;
        each(row.querySelectorAll('.price-input'), function (inp) {
          if (scope.indexOf('day:') === 0 && inp.dataset.day !== scope.slice(4)) return;
          var cur = val(inp), next;
          if (op === 'set') next = num;
          else if (op === 'fromWeekday') { if (inp.dataset.day === 'Weekday') return; var b = val(cell(row, 'Weekday')); if (b === null) return; next = b + num; }
          else if (cur === null) return;
          else if (op === 'add') next = cur + num;
          else next = cur * (1 + num / 100);
          next = Math.max(0, Math.round(next / 1000) * 1000);
          inp.value = fmt(String(next)); count++;
        });
      });
      refreshAll();
      status.textContent = 'Đã điền ' + count + ' ô (làm tròn 1.000đ) — kiểm tra rồi bấm Lưu. ' + status.textContent;
    });

    refreshAll();
  }

  /* ================= Tính thử giá ================= */
  var calc = document.getElementById('calc');
  if (calc) {
    var out = document.getElementById('calcResult'), timer;
    function run() {
      var q = new URLSearchParams({ ajax: 'calc', seatType: document.getElementById('calcSeat').value,
        roomType: document.getElementById('calcRoom').value, date: document.getElementById('calcDate').value,
        time: document.getElementById('calcTime').value });
      if (!q.get('date') || !q.get('time')) return;
      fetch(ctx + '/manager/prices?' + q, { credentials: 'same-origin' }).then(function (r) { return r.json(); }).then(function (d) {
        out.className = 'calc-result';
        if (d.error) { out.classList.add('err'); out.textContent = d.error; return; }
        if (d.total == null) { out.classList.add('err'); out.textContent = 'Chưa có giá cho ' + d.seatType + ' · ' + d.slotName + ' · ' + d.dayLabel + ' — khách sẽ không đặt được ghế này.'; return; }
        out.innerHTML = '';
        var t = document.createElement('div'); t.className = 'total'; t.textContent = money(d.total); out.appendChild(t);
        var dl = document.createElement('dl');
        [['Loại ngày', d.dayLabel + (d.holidayName ? ' (' + d.holidayName + ')' : '')], ['Khung giờ', d.slotName],
         ['Giá ' + d.seatType, money(d.base)], ['Phụ thu phòng', d.surcharge > 0 ? '+' + money(d.surcharge) : 'không']]
          .forEach(function (p) { var dt = document.createElement('dt'), dd = document.createElement('dd'); dt.textContent = p[0]; dd.textContent = p[1]; dl.appendChild(dt); dl.appendChild(dd); });
        out.appendChild(dl);
      }).catch(function () { out.className = 'calc-result err'; out.textContent = 'Không tính được giá (mất kết nối?).'; });
    }
    each(calc.querySelectorAll('select, input'), function (el) { el.addEventListener('change', function () { clearTimeout(timer); timer = setTimeout(run, 150); }); });
    run();
  }

  /* ================= Ngày lễ: báo ảnh hưởng trước khi thêm ================= */
  var hf = document.getElementById('holidayForm');
  if (hf) {
    var from = document.getElementById('holidayDate'), to = document.getElementById('holidayTo'), box = document.getElementById('holImpact');
    var last = null;
    function impact() {
      if (!from.value) { box.textContent = ''; last = null; return; }
      if (to.value && to.value < from.value) { box.textContent = '"Đến ngày" phải sau "Từ ngày".'; return; }
      var q = new URLSearchParams({ ajax: 'impact', from: from.value, to: to.value || from.value });
      fetch(ctx + '/manager/prices?' + q, { credentials: 'same-origin' }).then(function (r) { return r.json(); }).then(function (d) {
        if (d.error) { box.textContent = d.error; last = null; return; }
        last = d;
        box.textContent = d.showtimes > 0
          ? 'Trong khoảng này đã có ' + d.showtimes + ' suất chiếu' + (d.tickets > 0 ? ' và ' + d.tickets + ' vé đã bán/giữ (giữ nguyên giá cũ)' : '') + '. Vé đặt sau sẽ tính giá ngày lễ.'
          : 'Chưa có suất chiếu nào trong khoảng này.';
      });
    }
    from.addEventListener('change', function () { to.min = from.value; impact(); });
    to.addEventListener('change', impact);
    hf.addEventListener('submit', function (e) {
      if (last && last.showtimes > 0 && !confirm('Đã có ' + last.showtimes + ' suất chiếu trong khoảng ngày này. Vé đặt sau khi thêm sẽ tính giá ngày lễ. Tiếp tục?')) e.preventDefault();
    });
  }

  /* ================= Khung giờ: giờ kết thúc cập nhật ngay ================= */
  var sf = document.getElementById('slotForm');
  if (sf) {
    var trs = Array.prototype.slice.call(sf.querySelectorAll('[data-slot-row]'));
    function mins(t) { var p = t.split(':'); return Number(p[0]) * 60 + Number(p[1]); }
    function ends() {
      var list = trs.map(function (tr) { return { tr: tr, start: tr.querySelector('input[name^="slotStart_"]').value }; })
        .filter(function (x) { return x.start; })
        .sort(function (a, b) { return a.start < b.start ? -1 : 1; });
      list.forEach(function (x, i) {
        var next = list[(i + 1) % list.length].start;           // khung cuối vòng về khung sớm nhất (qua đêm)
        var len = (mins(next) - mins(x.start) + 1440) % 1440 || 1440;
        x.tr.querySelector('.slot-end').textContent = next + (mins(next) <= mins(x.start) ? ' (hôm sau)' : '');
        x.tr.querySelector('.slot-len').textContent = Math.floor(len / 60) + ' giờ' + (len % 60 ? ' ' + (len % 60) + ' phút' : '');
      });
    }
    each(sf.querySelectorAll('input[name^="slotStart_"]'), function (i) { i.addEventListener('change', ends); });
    ends();
  }
})();
</script>
<%@ include file="../layout/bottom.jspf" %>
