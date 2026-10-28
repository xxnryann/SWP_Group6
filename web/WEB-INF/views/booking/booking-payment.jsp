<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đặt vé — Thanh toán"/>
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
  .uip-layout { display: grid; grid-template-columns: 1fr 340px; gap: 22px; align-items: start; }
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
  .uip-countdown { text-align: center; padding: 16px; margin-bottom: 18px; }
  .uip-countdown .uip-clock { font-size: 38px; font-weight: 800; color: var(--cta);
                             font-variant-numeric: tabular-nums; letter-spacing: 1px; }
  .uip-countdown .uip-label { color: var(--slate-500); font-size: 13.5px; }
  .uip-pay { margin-top: 18px; }
  .uip-cancel { text-align: center; margin-top: 12px; }
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
        <div class="card">
          <h2>Thanh toán đơn vé</h2>
          <p class="sub">Kiểm tra lại thông tin trước khi thanh toán qua cổng VNPAY.</p>

          <div class="uip-countdown">
            <div class="uip-clock" id="clock"><c:out value="${remainingSeconds}"/></div>
            <div class="uip-label">giây còn lại để thanh toán (ghế được giữ tối đa 5 phút)</div>
          </div>

          <div class="uip-line"><span>Phim</span><span><strong><c:out value="${booking.movieTitle}"/></strong></span></div>
          <div class="uip-line"><span>Phòng</span><span><c:out value="${booking.roomName}"/></span></div>
          <div class="uip-line"><span>Suất chiếu</span><span>${booking.startTimeLabel}</span></div>
          <div class="uip-line"><span>Ghế</span><span><strong><c:out value="${booking.seatLabelText}"/></strong></span></div>
          <div class="uip-line"><span>Số vé</span><span>${booking.ticketCodes.size()}</span></div>

          <form class="uip-pay" method="post" action="${ctx}/booking/payment">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="pay">
            <button class="btn btn-cta btn-block" type="submit" id="payBtn">Thanh toán qua VNPAY</button>
          </form>

          <div class="uip-cancel">
            <form method="post" action="${ctx}/booking/payment"
                  onsubmit="return confirm('Huỷ đơn này? Ghế đã giữ sẽ được trả lại.');">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="cancel">
              <button class="btn-link" type="submit" style="color:var(--danger)">Huỷ đơn này</button>
            </form>
          </div>
        </div>

        <aside class="card uip-summary">
          <h2>Tóm tắt đơn</h2>
          <div>Mã đơn: <span class="uip-code"><c:out value="${booking.bookingCode}"/></span></div>
          <div class="uip-line"><span>Tiền vé</span><span>${booking.ticketTotalLabel} VNĐ</span></div>
          <div class="uip-line"><span>Tiền combo</span><span>${booking.comboTotalLabel} VNĐ</span></div>
          <c:if test="${booking.voucherDiscount > 0}">
            <div class="uip-line"><span>Giảm voucher</span>
                 <span class="uip-neg">− ${booking.voucherDiscountLabel} VNĐ</span></div>
          </c:if>
          <c:if test="${booking.pointsDiscount > 0}">
            <div class="uip-line"><span>Giảm MyPoint</span>
                 <span class="uip-neg">− ${booking.pointsDiscountLabel} VNĐ</span></div>
          </c:if>
          <div class="uip-total"><span><strong>Tổng phải trả</strong></span>
               <span class="uip-amt">${booking.totalAmountLabel} <small style="font-size:14px">VNĐ</small></span></div>
        </aside>
      </div>
    </div>
  </section>
</main>
<script>
  (function () {
    let remaining = Number('<c:out value="${remainingSeconds}"/>') || 0;
    const clock = document.getElementById('clock');
    const payBtn = document.getElementById('payBtn');
    function render() {
      const m = Math.floor(remaining / 60);
      const s = remaining % 60;
      clock.textContent = m + ':' + String(s).padStart(2, '0');
      if (remaining <= 0) {
        clock.textContent = '0:00';
        if (payBtn) {
          payBtn.disabled = true;
          payBtn.textContent = 'Đã hết thời gian thanh toán';
        }
        return;
      }
      remaining -= 1;
      setTimeout(render, 1000);
    }
    render();
  })();
</script>
<%@ include file="../_footer.jspf" %>



