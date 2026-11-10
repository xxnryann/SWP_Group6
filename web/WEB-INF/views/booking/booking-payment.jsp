<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Thanh toán"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .countdown { display: flex; align-items: center; gap: 16px; padding: 18px 20px; border-radius: var(--r-lg); background: var(--accent-50); border: 1px solid #fde3b0; }
  .countdown .clock { font-size: 34px; font-weight: 800; color: var(--accent-700); font-variant-numeric: tabular-nums; letter-spacing: -.01em; line-height: 1; }
  .countdown svg { width: 28px; height: 28px; color: var(--accent-700); }
  .countdown.expired { background: var(--danger-50); border-color: #f6c9cb; }
  .countdown.expired .clock, .countdown.expired svg { color: var(--danger); }
  .pay-method { display: flex; align-items: center; gap: 14px; padding: 16px; border: 2px solid var(--brand-500); border-radius: var(--r-lg); background: var(--brand-50); }
  .pay-method .logo { display: grid; place-items: center; width: 52px; height: 36px; border-radius: var(--r-sm); background: #fff; color: #005baa; font-weight: 800; font-size: 13px; letter-spacing: -.02em; box-shadow: var(--sh-xs); }
  .pay-method .logo b { color: #ed1c24; }
</style>
<div class="container">
  <nav class="stepper" aria-label="Các bước đặt vé">
    <span class="step done"><b>${ic.check}</b>Chọn suất chiếu</span><span class="bar done"></span>
    <span class="step done"><b>${ic.check}</b>Chọn ghế</span><span class="bar done"></span>
    <span class="step active" aria-current="step"><b>3</b>Combo &amp; thanh toán</span>
  </nav>

  <div class="split">
    <section class="card">
      <div class="card-head"><div><h2>Thanh toán đơn vé</h2><p>Ghế được giữ tối đa ${paymentWindowMinutes} phút</p></div></div>
      <div class="card-body stack" style="--gap:20px">
        <div class="countdown" id="countdownBox" role="timer" aria-live="off">
          ${ic.clock}
          <div><div class="clock" id="clock"><c:out value="${remainingSeconds}"/></div><div class="muted text-sm mt-4">thời gian còn lại để thanh toán</div></div>
        </div>
        <div>
          <div class="kv"><span>Phim</span><strong><c:out value="${booking.movieTitle}"/></strong></div>
          <div class="kv"><span>Phòng</span><strong><c:out value="${booking.roomName}"/></strong></div>
          <div class="kv"><span>Suất chiếu</span><strong>${booking.startTimeLabel}</strong></div>
          <div class="kv"><span>Ghế</span><strong><c:out value="${booking.seatLabelText}"/></strong></div>
          <div class="kv"><span>Số vé</span><strong>${booking.ticketCodes.size()}</strong></div>
        </div>
        <div>
          <p class="label mb-8">Phương thức thanh toán</p>
          <div class="pay-method"><span class="logo">VN<b>PAY</b></span><div><strong class="text-ink">Ví VNPAY / thẻ ATM / QR ngân hàng</strong><span class="cell-sub">Bạn sẽ được chuyển sang cổng thanh toán VNPAY</span></div>${ic.checkCircle}</div>
        </div>
        <form method="post" action="${ctx}/booking/payment" data-loading>
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="pay">
          <button class="btn btn-accent btn-lg btn-block" type="submit" id="payBtn">${ic.lock}Thanh toán ${booking.totalAmountLabel} đ qua VNPAY</button>
        </form>
        <div class="cluster between">
          <a class="btn btn-ghost" href="${ctx}/booking/extras">${ic.chevronLeft}Quay lại</a>
          <form method="post" action="${ctx}/booking/payment" data-confirm="Hủy đơn này? Ghế đã giữ sẽ được trả lại.">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="cancel">
            <button class="btn btn-ghost text-danger" type="submit">${ic.x}Hủy đơn này</button>
          </form>
        </div>
      </div>
    </section>

    <aside class="card sticky">
      <div class="card-head"><div><h2>Tóm tắt đơn</h2><p>Mã đơn <span class="voucher-code"><c:out value="${booking.bookingCode}"/></span></p></div></div>
      <div class="card-body">
        <div class="kv"><span>Tiền vé</span><strong>${booking.ticketTotalLabel} đ</strong></div>
        <div class="kv"><span>Tiền combo</span><strong>${booking.comboTotalLabel} đ</strong></div>
        <c:if test="${booking.voucherDiscount > 0}"><div class="kv"><span>Giảm voucher</span><strong class="text-success">− ${booking.voucherDiscountLabel} đ</strong></div></c:if>
        <c:if test="${booking.pointsDiscount > 0}"><div class="kv"><span>Giảm MyPoint</span><strong class="text-success">− ${booking.pointsDiscountLabel} đ</strong></div></c:if>
        <div class="kv total"><span>Tổng phải trả</span><strong>${booking.totalAmountLabel} đ</strong></div>
        <p class="hint mt-16">${ic.shield} Giao dịch được xử lý qua VNPAY. CineStar không lưu thông tin thẻ của bạn.</p>
      </div>
    </aside>
  </div>
</div>
<script>
  (function () {
    var remaining = Number('<c:out value="${remainingSeconds}"/>') || 0;
    var clock = document.getElementById('clock'), payBtn = document.getElementById('payBtn'), box = document.getElementById('countdownBox');
    function render() {
      var m = Math.floor(remaining / 60), s = remaining % 60;
      clock.textContent = m + ':' + String(s).padStart(2, '0');
      if (remaining <= 0) {
        clock.textContent = '0:00'; box.classList.add('expired');
        if (payBtn) { payBtn.disabled = true; payBtn.textContent = 'Đã hết thời gian thanh toán'; }
        return;
      }
      remaining -= 1;
      setTimeout(render, 1000);
    }
    render();
  })();
</script>
<%@ include file="../layout/bottom.jspf" %>
