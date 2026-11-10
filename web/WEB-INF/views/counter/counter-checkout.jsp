<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Bán vé tại quầy"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .sec-num { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; background: var(--brand-50); color: var(--brand-700); font-weight: 700; font-size: 14px; flex: none; }
  .combo-row { display: grid; grid-template-columns: 52px minmax(0, 1fr) auto auto; gap: 14px; align-items: center; padding: 12px 0; border-bottom: 1px solid var(--line); }
  .combo-row:last-child { border-bottom: 0; }
  .combo-row img, .combo-row .ph { width: 52px; height: 52px; border-radius: var(--r-md); object-fit: cover; background: var(--accent-50); color: var(--accent-700); display: grid; place-items: center; }
  .qty { display: inline-flex; align-items: center; gap: 4px; padding: 3px; border: 1px solid var(--line); border-radius: var(--r-pill); }
  .qty button { width: 32px; height: 32px; border: 0; border-radius: 50%; background: var(--surface-3); color: var(--ink); font-size: 18px; line-height: 1; }
  .qty button:hover { background: var(--brand-50); color: var(--brand-700); }
  .qty .uip-qty-value { min-width: 26px; text-align: center; font-weight: 700; }
  .inline-form { display: flex; gap: 10px; flex-wrap: wrap; }
  .inline-form .field { flex: 1 1 220px; }
  .voucher-pick tbody tr { cursor: pointer; }
  .voucher-pick tbody tr:hover { background: var(--brand-50); }
</style>
<nav class="stepper" aria-label="Các bước bán vé">
  <span class="step done"><b>${ic.check}</b>Chọn suất chiếu</span><span class="bar done"></span>
  <span class="step done"><b>${ic.check}</b>Chọn ghế</span><span class="bar done"></span>
  <span class="step active" aria-current="step"><b>3</b>Thanh toán</span>
</nav>

<div class="split" style="grid-template-columns:minmax(0,1fr) 380px">
  <div class="stack" style="--gap:20px">
    <section class="card">
      <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">1</span><div><h2>Combo bắp nước</h2><p>Không bắt buộc</p></div></div></div>
      <form method="post" action="${ctx}/staff/counter">
        <div class="card-body" style="padding-top:6px;padding-bottom:6px">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="updateCombos">
          <c:forEach var="cb" items="${combos}">
            <div class="combo-row">
              <c:choose>
                <c:when test="${cb.hasImage()}"><img src="<c:out value='${cb.imageUrl}'/>" alt=""></c:when>
                <c:otherwise><span class="ph">${ic.popcorn}</span></c:otherwise>
              </c:choose>
              <div><strong class="text-ink"><c:out value="${cb.comboName}"/></strong><span class="cell-sub"><c:out value="${cb.description}"/></span></div>
              <strong class="text-ink money">${cb.priceLabel}</strong>
              <span class="qty uip-qty-stepper">
                <input type="hidden" name="comboId" value="${cb.comboId}">
                <button type="button" data-qty-action="decrease" aria-label="Giảm số lượng">−</button>
                <input type="hidden" name="qty" value="${comboQty[cb.comboId] != null ? comboQty[cb.comboId] : 0}">
                <span class="uip-qty-value">${comboQty[cb.comboId] != null ? comboQty[cb.comboId] : 0}</span>
                <button type="button" data-qty-action="increase" aria-label="Tăng số lượng">+</button>
              </span>
            </div>
          </c:forEach>
        </div>
        <div class="card-foot"><button class="btn btn-soft" type="submit">${ic.refresh}Cập nhật combo</button></div>
      </form>
    </section>

    <section class="card">
      <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">2</span><div><h2>Khách hàng</h2><p>Gắn tài khoản để tích điểm và dùng voucher</p></div></div></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${summary.hasCustomer}">
            <div class="person"><span class="avatar">${ic.user}</span><div><span class="cell-main"><c:out value="${summary.customerName}"/></span><span class="cell-sub"><span class="badge badge-success">Đã gắn tài khoản</span></span></div></div>
          </c:when>
          <c:otherwise>
            <form method="post" action="${ctx}/staff/counter" class="inline-form">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="attachCustomer">
              <div class="field"><label class="sr-only" for="custQ">Email hoặc SĐT khách hàng</label>
                <div class="input-group">${ic.search}<input id="custQ" type="search" name="q" placeholder="Email hoặc SĐT khách đã đăng ký"></div></div>
              <button class="btn btn-primary" type="submit">Gắn khách hàng</button>
            </form>
          </c:otherwise>
        </c:choose>
      </div>
    </section>

    <section class="card">
      <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">3</span><h2>Voucher</h2></div></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${summary.hasCustomer}">
            <form method="post" action="${ctx}/staff/counter" class="inline-form">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="applyVoucher">
              <div class="field"><label class="sr-only" for="voucherCode">Mã voucher</label>
                <div class="input-group">${ic.tag}<input id="voucherCode" type="text" name="voucherCode" placeholder="Mã voucher"></div></div>
              <button class="btn btn-primary" type="submit">Áp dụng</button>
            </form>
            <c:if test="${not empty vouchers}">
              <div class="table-wrap mt-16" style="border:1px solid var(--line);border-radius:var(--r-md)">
                <table class="table voucher-pick">
                  <thead><tr><th>Mã</th><th>Nội dung</th><th>Hết hạn</th></tr></thead>
                  <tbody>
                    <c:forEach var="v" items="${vouchers}">
                      <tr data-voucher-code="<c:out value='${v.code}'/>">
                        <td><span class="voucher-code"><c:out value="${v.code}"/></span></td>
                        <td class="text-sm"><c:out value="${v.description}"/></td>
                        <td class="nowrap muted text-sm"><c:out value="${v.valid_to_txt}"/></td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
            </c:if>
          </c:when>
          <c:otherwise><p class="muted text-sm">Khách vãng lai không dùng được voucher và MyPoint. Gắn khách hàng đã đăng ký ở mục 2 để áp dụng.</p></c:otherwise>
        </c:choose>
      </div>
    </section>

    <section class="card">
      <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">4</span><h2>Điểm MyPoint</h2></div></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${summary.hasCustomer}">
            <p class="text-sm mb-8">Điểm hiện có: <strong class="text-ink">${pointBalance}</strong></p>
            <form method="post" action="${ctx}/staff/counter" class="inline-form">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="applyPoints">
              <div class="field"><label class="sr-only" for="pointsInput">Số điểm</label>
                <input id="pointsInput" type="number" name="points" min="0" max="${pointBalance}" value="${summary.pointsUsed}" placeholder="Nhập điểm"></div>
              <button class="btn btn-primary" type="submit">Đổi điểm</button>
            </form>
            <p class="mt-8 text-sm">Số tiền được giảm ≈ <strong class="text-success" id="pointsDiscountPreview">0</strong> đ</p>
            <div class="alert alert-info mt-16">${ic.info}<span>Áp voucher sẽ xóa điểm đã dùng. Đã giảm: voucher <strong>${summary.voucherDiscountLabel} đ</strong>, MyPoint <strong>${summary.pointsDiscountLabel} đ</strong> (${summary.pointsUsed} điểm).</span></div>
          </c:when>
          <c:otherwise><p class="muted text-sm">Gắn khách hàng đã đăng ký ở mục 2 để áp dụng điểm.</p></c:otherwise>
        </c:choose>
      </div>
    </section>
  </div>

  <aside class="card sticky">
    <div class="card-head"><div><h2>Tóm tắt đơn</h2><p>Mã đơn <span class="voucher-code"><c:out value="${summary.bookingCode}"/></span></p></div></div>
    <div class="card-body">
      <c:if test="${not empty showtime}">
        <h3 style="font-size:17px"><c:out value="${showtime.title}"/></h3>
        <div class="movie-meta mt-4"><span><c:out value="${showtime.roomName}"/></span><span>${showtime.startTimeLabel}</span></div>
        <p class="text-sm mt-8">Vé đã giữ: <strong class="text-ink">${summary.ticketCodes.size()}</strong> ghế</p>
        <hr class="divider" style="margin:16px 0 6px">
      </c:if>
      <div class="kv"><span>Tiền vé</span><strong>${summary.ticketTotalLabel} đ</strong></div>
      <div class="kv"><span>Tiền combo</span><strong>${summary.comboTotalLabel} đ</strong></div>
      <c:if test="${summary.voucherDiscount > 0}"><div class="kv"><span>Giảm voucher</span><strong class="text-success">− ${summary.voucherDiscountLabel} đ</strong></div></c:if>
      <c:if test="${summary.pointsDiscount > 0}"><div class="kv"><span>Giảm MyPoint</span><strong class="text-success">− ${summary.pointsDiscountLabel} đ</strong></div></c:if>
      <div class="kv total"><span>Tổng phải thu</span><strong>${summary.totalAmountLabel} đ</strong></div>
      <form class="form mt-16" method="post" action="${ctx}/staff/counter" data-confirm="Xác nhận đã thu đủ tiền mặt?">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="pay">
        <div class="field">
          <label for="f-cash">Tiền khách đưa (đ)</label>
          <input id="f-cash" type="number" name="cashReceived" min="0" required placeholder="500000">
        </div>
        <button class="btn btn-accent btn-lg btn-block" type="submit">${ic.wallet}Xác nhận thu tiền</button>
      </form>
      <form class="text-center mt-12" method="post" action="${ctx}/staff/counter" data-confirm="Hủy đơn này? Ghế đã giữ sẽ được nhả lại.">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="cancelBooking">
        <button class="btn btn-ghost btn-sm text-danger" type="submit">${ic.x}Hủy đơn này</button>
      </form>
    </div>
  </aside>
</div>
<script>
(function () {
  document.querySelectorAll('.uip-qty-stepper').forEach(function (stepper) {
    var input = stepper.querySelector('input[name="qty"]'), output = stepper.querySelector('.uip-qty-value');
    stepper.addEventListener('click', function (e) {
      var button = e.target.closest('button[data-qty-action]');
      if (!button) return;
      var value = parseInt(input.value || '0', 10) + (button.dataset.qtyAction === 'increase' ? 1 : -1);
      value = Math.max(0, Math.min(99, value));
      input.value = value; output.textContent = value;
    });
  });
  var voucherInput = document.querySelector('input[name="voucherCode"]');
  document.querySelectorAll('[data-voucher-code]').forEach(function (row) {
    row.addEventListener('click', function () { if (voucherInput) { voucherInput.value = row.dataset.voucherCode; voucherInput.focus(); } });
  });
  var pointsInput = document.getElementById('pointsInput'), pointPreview = document.getElementById('pointsDiscountPreview');
  var pointValue = ${not empty pointConfig ? pointConfig.pointValueVnd : 0};
  function updatePointPreview() { if (pointsInput && pointPreview) pointPreview.textContent = (Math.max(0, parseInt(pointsInput.value || '0', 10)) * pointValue).toLocaleString('vi-VN'); }
  if (pointsInput) { pointsInput.addEventListener('input', updatePointPreview); updatePointPreview(); }
})();
</script>
<%@ include file="../layout/bottom.jspf" %>
