<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đặt vé — Combo & ưu đãi"/>
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
  .uip-sec { margin-bottom: 20px; padding: 24px 26px; }
  .uip-sec h2 { font-size: 17px; margin: 0 0 14px; display: flex; align-items: center; gap: 10px; }
  .uip-sec h2 .uip-n { width: 26px; height: 26px; border-radius: 50%; background: var(--brand); color: #fff;
                       display: grid; place-items: center; font-size: 14px; flex: none; }
  .uip-inline-form { display: flex; gap: 8px; flex-wrap: wrap; }
  .uip-inline-form input { padding: 10px 13px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                           font: 14.5px var(--font); outline: none; background: #fff; }
  .uip-inline-form input:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-inline-form input[type=search], .uip-inline-form input[type=text] { flex: 1; min-width: 190px; }
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
  .uip-next { margin-top: 18px; }
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
            <form method="post" action="${ctx}/booking/extras">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="updateCombos">
              <div class="table-wrap" style="margin-bottom:14px">
                <table class="data" style="min-width:0">
                  <thead><tr><th>Combo</th><th>Giá (VNĐ)</th><th>Tồn kho</th><th>Số lượng</th></tr></thead>
                  <tbody>
                    <c:forEach var="cb" items="${combos}">
                      <tr>
                        <td><strong><c:out value="${cb.comboName}"/></strong></td>
                        <td>${cb.priceLabel}</td>
                        <td>${cb.stock}</td>
                        <td>
                          <input type="hidden" name="comboId" value="${cb.comboId}">
                          <input class="uip-qty" type="number" name="qty" min="0" max="${cb.stock}"
                                 value="${comboQty[cb.comboId] != null ? comboQty[cb.comboId] : 0}">
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
            <h2><span class="uip-n">2</span> Voucher &amp; MyPoint</h2>
            <c:if test="${not empty pointConfig}">
              <p><em><c:out value="${pointConfig.ruleLabel}"/></em></p>
            </c:if>
            <p>Số dư MyPoint của bạn: <strong>${pointBalance}</strong> điểm.</p>
            <form method="post" action="${ctx}/booking/extras" class="uip-inline-form">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="applyDiscount">
              <input type="text" name="voucherCode" placeholder="Mã voucher (nếu có)" maxlength="30">
              <input type="number" name="points" min="0" max="${pointBalance}" value="0"
                     placeholder="Điểm muốn dùng">
              <button class="btn btn-outline" type="submit">Áp dụng giảm giá</button>
            </form>
            <p style="margin-top:12px">Đã giảm: voucher <strong>${booking.voucherDiscountLabel} VNĐ</strong>,
               MyPoint <strong>${booking.pointsDiscountLabel} VNĐ</strong> (${booking.pointsUsed} điểm).</p>
            <p style="margin-top:6px"><em>Voucher được áp trước, MyPoint áp sau — vì áp voucher sẽ
               huỷ số điểm đã dùng trước đó.</em></p>
          </div>
        </div>

        <aside class="card uip-summary">
          <h2>Tóm tắt đơn</h2>
          <div>Mã đơn: <span class="uip-code"><c:out value="${booking.bookingCode}"/></span></div>
          <p class="uip-movie">🎬 <strong><c:out value="${booking.movieTitle}"/></strong><br>
             <c:out value="${booking.roomName}"/> — ${booking.startTimeLabel}<br>
             Ghế: <strong><c:out value="${booking.seatLabelText}"/></strong></p>
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

          <form class="uip-next" method="post" action="${ctx}/booking/extras">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="next">
            <button class="btn btn-cta btn-block" type="submit">Tiếp tục thanh toán →</button>
          </form>
        </aside>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
