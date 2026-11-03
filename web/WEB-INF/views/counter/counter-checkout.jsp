<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Bán vé tại quầy — Thanh toán"/>
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
  .uip-layout { display: grid; grid-template-columns: 1fr 360px; gap: 22px; align-items: start; }
  .uip-sec { margin-bottom: 20px; padding: 24px 26px; }
  .uip-sec h2 { font-size: 17px; margin: 0 0 14px; display: flex; align-items: center; gap: 10px; }
  .uip-sec h2 .uip-n { width: 26px; height: 26px; border-radius: 50%; background: var(--brand); color: #fff;
                       display: grid; place-items: center; font-size: 14px; flex: none; }
  .uip-sec p { margin: 0 0 10px; }
  .uip-inline-form { display: flex; gap: 8px; flex-wrap: wrap; }
  .uip-inline-form input { padding: 10px 13px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                           font: 14.5px var(--font); outline: none; background: #fff; }
  .uip-inline-form input:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-inline-form input[type=search], .uip-inline-form input[type=text] { flex: 1; min-width: 200px; }
  .uip-inline-form input[type=number] { width: 150px; }
  .uip-qty { width: 84px; padding: 8px 10px; border: 1px solid var(--slate-300); border-radius: 8px;
             font: 14.5px var(--font); outline: none; }
  .uip-qty:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-summary { position: sticky; top: 96px; padding: 24px 26px; }
  .uip-summary h2 { font-size: 17px; margin: 0 0 4px; }
  .uip-code { font-family: ui-monospace, Consolas, monospace; font-weight: 800; color: var(--brand); font-size: 17px; }
  .uip-movie { color: var(--slate-600); font-size: 14px; margin: 6px 0 14px; }
  .uip-line { display: flex; justify-content: space-between; gap: 14px; padding: 8px 0;
              border-top: 1px solid var(--slate-100); font-size: 14.5px; }
  .uip-line .uip-neg { color: var(--success); font-weight: 700; }
  .uip-total { display: flex; justify-content: space-between; align-items: baseline; gap: 14px;
               border-top: 2px solid var(--slate-200); margin-top: 8px; padding-top: 14px; }
  .uip-total .uip-amt { color: var(--cta); font-weight: 800; font-size: 25px; }
  .uip-cash { margin-top: 18px; }
  .uip-cancel { text-align: center; margin-top: 12px; }
  .uip-voucher-list { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px; }
  .uip-voucher-list th, .uip-voucher-list td { padding: 8px; border-bottom: 1px solid var(--slate-100); text-align: left; }
  .uip-voucher-list tbody tr { cursor: pointer; }
  .uip-voucher-list tbody tr:hover { background: var(--slate-50); }
  .uip-voucher-code { font-family: ui-monospace, Consolas, monospace; font-weight: 800; color: var(--brand); }
  .uip-point-value { color: var(--success); font-weight: 700; }
  .uip-qty-stepper { display: inline-flex; align-items: center; gap: 8px; }
  .uip-qty-stepper button { width: 30px; height: 30px; border: 1px solid var(--slate-300); border-radius: 50%;
                            background: #fff; color: var(--brand); font-size: 18px; line-height: 1; cursor: pointer; }
  .uip-qty-stepper button:hover { background: var(--slate-100); }
  .uip-qty-value { min-width: 22px; text-align: center; font-weight: 700; }
  @media (max-width: 960px) { .uip-layout { grid-template-columns: 1fr; } .uip-summary { position: static; } }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="uip-steps">
        <span class="uip-step done"><span class="uip-num">✓</span> Chọn suất chiếu</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step done"><span class="uip-num">✓</span> Chọn ghế</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step active"><span class="uip-num">3</span> Thanh toán</span>
      </div>

      <div class="uip-layout">
        <div>
          <div class="card uip-sec">
            <h2><span class="uip-n">1</span> Combo bắp nước (tùy chọn)</h2>
            <form method="post" action="${ctx}/staff/counter">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="updateCombos">
              <div class="table-wrap" style="margin-bottom:14px">
                <table class="data" style="min-width:0">
                  <thead><tr><th>Combo</th><th>Giá (VNĐ)</th><th>Số lượng</th></tr></thead>
                  <tbody>
                    <c:forEach var="c" items="${combos}">
                      <tr>
                        <td>
                          <c:choose>
                            <c:when test="${c.hasImage()}"><img src="<c:out value='${c.imageUrl}'/>"
                              alt="<c:out value='${c.comboName}'/>" style="width:52px;height:52px;object-fit:cover;border-radius:50%;vertical-align:middle;margin-right:8px"></c:when>
                            <c:otherwise><span style="font-size:28px;vertical-align:middle;margin-right:8px">🍿</span></c:otherwise>
                          </c:choose>
                          <strong><c:out value="${c.comboName}"/></strong><br>
                          <small style="color:var(--slate-500)"><c:out value="${c.description}"/></small>
                        </td>
                        <td>${c.priceLabel}</td>
                        <td>
                          <input type="hidden" name="comboId" value="${c.comboId}">
                          <span class="uip-qty-stepper">
                            <button type="button" data-qty-action="decrease" aria-label="Giảm số lượng">−</button>
                            <input type="hidden" name="qty" value="${comboQty[c.comboId] != null ? comboQty[c.comboId] : 0}">
                            <span class="uip-qty-value">${comboQty[c.comboId] != null ? comboQty[c.comboId] : 0}</span>
                            <button type="button" data-qty-action="increase" aria-label="Tăng số lượng">+</button>
                          </span>
                        </td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
              <button class="btn btn-outline" type="submit">Cập nhật combo</button>
            </form>
          </div>

          <div class="card uip-sec">
            <h2><span class="uip-n">2</span> Khách hàng (tùy chọn)</h2>
            <c:choose>
              <c:when test="${summary.hasCustomer}">
                <p>Khách hàng: <strong><c:out value="${summary.customerName}"/></strong>
                   <span class="chip chip-success" style="margin-left:8px">Đã gắn</span></p>
              </c:when>
              <c:otherwise>
                <form method="post" action="${ctx}/staff/counter" class="uip-inline-form">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="attachCustomer">
                  <input type="search" name="q" placeholder="Email hoặc SĐT khách hàng đã đăng ký...">
                  <button class="btn btn-outline" type="submit">Gắn khách hàng</button>
                </form>
              </c:otherwise>
            </c:choose>
          </div>

          <div class="card uip-sec">
            <h2><span class="uip-n">4</span> Điểm</h2>
            <c:choose>
              <c:when test="${summary.hasCustomer}">
                <p>Điểm hiện có: <strong>${pointBalance}</strong></p>
                <form method="post" action="${ctx}/staff/counter" class="uip-inline-form">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="applyPoints">
                  <input id="pointsInput" type="number" name="points" min="0" max="${pointBalance}" value="${summary.pointsUsed}"
                         placeholder="Nhập điểm">
                  <button class="btn btn-outline" type="submit">Đổi điểm</button>
                </form>
                <p>Số tiền được giảm = <span class="uip-point-value" id="pointsDiscountPreview">0</span> VNĐ</p>
                <p class="uip-hint"><em>Áp voucher sẽ xóa điểm đã dùng, hãy áp voucher trước rồi mới đổi điểm.</em></p>
                <p style="margin-top:12px">Đã giảm: voucher <strong>${summary.voucherDiscountLabel} VNĐ</strong>,
                   MyPoint <strong>${summary.pointsDiscountLabel} VNĐ</strong> (${summary.pointsUsed} điểm).</p>
              </c:when>
              <c:otherwise><p><em>Gắn khách hàng đã đăng ký ở mục 2 để áp dụng điểm.</em></p></c:otherwise>
            </c:choose>
          </div>

          <div class="card uip-sec">
            <h2><span class="uip-n">3</span> Voucher</h2>
            <c:choose>
              <c:when test="${summary.hasCustomer}">
                <form method="post" action="${ctx}/staff/counter" class="uip-inline-form">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="applyVoucher">
                  <input type="text" name="voucherCode" placeholder="Mã voucher (nếu có)">
                  <button class="btn btn-outline" type="submit">Áp dụng</button>
                </form>
                <strong style="display:block;margin-top:18px">VOUCHER CỦA BẠN</strong>
                <table class="uip-voucher-list">
                  <thead><tr><th>Mã voucher</th><th>Nội dung voucher</th><th>Ngày hết hạn</th></tr></thead>
                  <tbody>
                    <c:forEach var="v" items="${vouchers}">
                      <tr data-voucher-code="<c:out value='${v.code}'/>">
                        <td class="uip-voucher-code"><c:out value="${v.code}"/></td>
                        <td><c:out value="${v.description}"/></td>
                        <td><c:out value="${v.valid_to_txt}"/></td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </c:when>
              <c:otherwise>
                <p><em>Khách vãng lai không dùng được voucher/MyPoint (quy định trong sp_ApplyVoucher).
                   Gắn khách hàng đã đăng ký ở mục 2 để áp dụng.</em></p>
              </c:otherwise>
            </c:choose>
          </div>
        </div>

        <aside class="card uip-summary">
          <h2>Tóm tắt đơn</h2>
          <div>Mã đơn: <span class="uip-code"><c:out value="${summary.bookingCode}"/></span></div>
          <c:if test="${not empty showtime}">
            <p class="uip-movie">🎬 <strong><c:out value="${showtime.title}"/></strong><br>
               <c:out value="${showtime.roomName}"/> — ${showtime.startTimeLabel}<br>
               Vé đã giữ: <strong>${summary.ticketCodes.size()}</strong> ghế</p>
          </c:if>
          <div class="uip-line"><span>Tiền vé</span><span>${summary.ticketTotalLabel} VNĐ</span></div>
          <div class="uip-line"><span>Tiền combo</span><span>${summary.comboTotalLabel} VNĐ</span></div>
          <c:if test="${summary.voucherDiscount > 0}">
            <div class="uip-line"><span>Giảm voucher</span><span class="uip-neg">− ${summary.voucherDiscountLabel} VNĐ</span></div>
          </c:if>
          <c:if test="${summary.pointsDiscount > 0}">
            <div class="uip-line"><span>Giảm MyPoint</span><span class="uip-neg">− ${summary.pointsDiscountLabel} VNĐ</span></div>
          </c:if>
          <div class="uip-total"><span><strong>Tổng phải thu</strong></span><span class="uip-amt">${summary.totalAmountLabel} <small style="font-size:14px">VNĐ</small></span></div>

          <form class="uip-cash" method="post" action="${ctx}/staff/counter"
                onsubmit="return confirm('Xác nhận đã thu đủ tiền mặt?')">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="pay">
            <div class="field">
              <label for="f-cash">Tiền khách đưa (VNĐ)</label>
              <input id="f-cash" type="number" name="cashReceived" min="0" required placeholder="VD: 500000">
            </div>
            <button class="btn btn-cta btn-block" type="submit">Xác nhận thu tiền</button>
          </form>

          <div class="uip-cancel">
            <form method="post" action="${ctx}/staff/counter"
                  onsubmit="return confirm('Hủy đơn này? Ghế đã giữ sẽ được nhả lại.')">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="cancelBooking">
              <button class="btn-link" type="submit" style="color:var(--danger)">Hủy đơn này</button>
            </form>
          </div>
        </aside>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
<script>
(function () {
  document.querySelectorAll('.uip-qty-stepper').forEach(function (stepper) {
    var input = stepper.querySelector('input[name="qty"]');
    var output = stepper.querySelector('.uip-qty-value');
    stepper.addEventListener('click', function (e) {
      var button = e.target.closest('button[data-qty-action]');
      if (!button) return;
      var value = parseInt(input.value || '0', 10);
      value += button.dataset.qtyAction === 'increase' ? 1 : -1;
      value = Math.max(0, Math.min(99, value));
      input.value = value;
      output.textContent = value;
    });
  });
  var voucherInput = document.querySelector('input[name="voucherCode"]');
  document.querySelectorAll('[data-voucher-code]').forEach(function (row) {
    row.addEventListener('click', function () {
      if (voucherInput) voucherInput.value = row.dataset.voucherCode;
    });
  });
  var pointsInput = document.getElementById('pointsInput');
  var pointPreview = document.getElementById('pointsDiscountPreview');
  var pointValue = ${not empty pointConfig ? pointConfig.pointValueVnd : 0};
  function updatePointPreview() {
    if (pointsInput && pointPreview) {
      pointPreview.textContent = (Math.max(0, parseInt(pointsInput.value || '0', 10)) * pointValue).toLocaleString('vi-VN');
    }
  }
  if (pointsInput) {
    pointsInput.addEventListener('input', updatePointPreview);
    updatePointPreview();
  }
})();
</script>
