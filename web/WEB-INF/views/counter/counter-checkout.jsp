﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="BÃ¡n vÃ© táº¡i quáº§y â€” Thanh toÃ¡n"/>
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
  @media (max-width: 960px) { .uip-layout { grid-template-columns: 1fr; } .uip-summary { position: static; } }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="uip-steps">
        <span class="uip-step done"><span class="uip-num">âœ“</span> Chá»n suáº¥t chiáº¿u</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step done"><span class="uip-num">âœ“</span> Chá»n gháº¿</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step active"><span class="uip-num">3</span> Thanh toÃ¡n</span>
      </div>

      <div class="uip-layout">
        <div>
          <div class="card uip-sec">
            <h2><span class="uip-n">1</span> Combo báº¯p nÆ°á»›c (tÃ¹y chá»n)</h2>
            <form method="post" action="${ctx}/staff/counter">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="updateCombos">
              <div class="table-wrap" style="margin-bottom:14px">
                <table class="data" style="min-width:0">
                  <thead><tr><th>Combo</th><th>GiÃ¡ (VNÄ)</th><th>Tá»“n kho</th><th>Sá»‘ lÆ°á»£ng</th></tr></thead>
                  <tbody>
                    <c:forEach var="c" items="${combos}">
                      <tr>
                        <td><strong><c:out value="${c.comboName}"/></strong></td>
                        <td>${c.priceLabel}</td>
                        <td>${c.stock}</td>
                        <td>
                          <input type="hidden" name="comboId" value="${c.comboId}">
                          <input class="uip-qty" type="number" name="qty" min="0" max="${c.stock}"
                                 value="${comboQty[c.comboId] != null ? comboQty[c.comboId] : 0}">
                        </td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
              <button class="btn btn-outline" type="submit">Cáº­p nháº­t combo</button>
            </form>
          </div>

          <div class="card uip-sec">
            <h2><span class="uip-n">2</span> KhÃ¡ch hÃ ng (tÃ¹y chá»n)</h2>
            <c:choose>
              <c:when test="${summary.hasCustomer}">
                <p>KhÃ¡ch hÃ ng: <strong><c:out value="${summary.customerName}"/></strong>
                   <span class="chip chip-success" style="margin-left:8px">ÄÃ£ gáº¯n</span></p>
              </c:when>
              <c:otherwise>
                <form method="post" action="${ctx}/staff/counter" class="uip-inline-form">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="attachCustomer">
                  <input type="search" name="q" placeholder="Email hoáº·c SÄT khÃ¡ch hÃ ng Ä‘Ã£ Ä‘Äƒng kÃ½...">
                  <button class="btn btn-outline" type="submit">Gáº¯n khÃ¡ch hÃ ng</button>
                </form>
              </c:otherwise>
            </c:choose>
          </div>

          <div class="card uip-sec">
            <h2><span class="uip-n">3</span> Voucher &amp; MyPoint</h2>
            <c:choose>
              <c:when test="${summary.hasCustomer}">
                <c:if test="${not empty pointConfig}">
                  <p><em>1 Ä‘iá»ƒm = ${pointConfig.pointValueVnd} VNÄ, dÃ¹ng tá»‘i Ä‘a ${pointConfig.maxRedeemPercent}% giÃ¡ trá»‹ Ä‘Æ¡n.</em></p>
                </c:if>
                <form method="post" action="${ctx}/staff/counter" class="uip-inline-form">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="applyDiscount">
                  <input type="text" name="voucherCode" placeholder="MÃ£ voucher (náº¿u cÃ³)">
                  <input type="number" name="points" min="0" value="0" placeholder="Äiá»ƒm muá»‘n dÃ¹ng">
                  <button class="btn btn-outline" type="submit">Ãp dá»¥ng giáº£m giÃ¡</button>
                </form>
                <p style="margin-top:12px">ÄÃ£ giáº£m: voucher <strong>${summary.voucherDiscountLabel} VNÄ</strong>,
                   MyPoint <strong>${summary.pointsDiscountLabel} VNÄ</strong> (${summary.pointsUsed} Ä‘iá»ƒm).</p>
              </c:when>
              <c:otherwise>
                <p><em>KhÃ¡ch vÃ£ng lai khÃ´ng dÃ¹ng Ä‘Æ°á»£c voucher/MyPoint (quy Ä‘á»‹nh trong sp_ApplyVoucher).
                   Gáº¯n khÃ¡ch hÃ ng Ä‘Ã£ Ä‘Äƒng kÃ½ á»Ÿ má»¥c 2 Ä‘á»ƒ Ã¡p dá»¥ng.</em></p>
              </c:otherwise>
            </c:choose>
          </div>
        </div>

        <aside class="card uip-summary">
          <h2>TÃ³m táº¯t Ä‘Æ¡n</h2>
          <div>MÃ£ Ä‘Æ¡n: <span class="uip-code"><c:out value="${summary.bookingCode}"/></span></div>
          <c:if test="${not empty showtime}">
            <p class="uip-movie">ðŸŽ¬ <strong><c:out value="${showtime.title}"/></strong><br>
               <c:out value="${showtime.roomName}"/> â€” ${showtime.startTimeLabel}<br>
               VÃ© Ä‘Ã£ giá»¯: <strong>${summary.ticketCodes.size()}</strong> gháº¿</p>
          </c:if>
          <div class="uip-line"><span>Tiá»n vÃ©</span><span>${summary.ticketTotalLabel} VNÄ</span></div>
          <div class="uip-line"><span>Tiá»n combo</span><span>${summary.comboTotalLabel} VNÄ</span></div>
          <c:if test="${summary.voucherDiscount > 0}">
            <div class="uip-line"><span>Giáº£m voucher</span><span class="uip-neg">âˆ’ ${summary.voucherDiscountLabel} VNÄ</span></div>
          </c:if>
          <c:if test="${summary.pointsDiscount > 0}">
            <div class="uip-line"><span>Giáº£m MyPoint</span><span class="uip-neg">âˆ’ ${summary.pointsDiscountLabel} VNÄ</span></div>
          </c:if>
          <div class="uip-total"><span><strong>Tá»•ng pháº£i thu</strong></span><span class="uip-amt">${summary.totalAmountLabel} <small style="font-size:14px">VNÄ</small></span></div>

          <form class="uip-cash" method="post" action="${ctx}/staff/counter"
                onsubmit="return confirm('XÃ¡c nháº­n Ä‘Ã£ thu Ä‘á»§ tiá»n máº·t?')">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="pay">
            <div class="field">
              <label for="f-cash">Tiá»n khÃ¡ch Ä‘Æ°a (VNÄ)</label>
              <input id="f-cash" type="number" name="cashReceived" min="0" required placeholder="VD: 500000">
            </div>
            <button class="btn btn-cta btn-block" type="submit">XÃ¡c nháº­n thu tiá»n</button>
          </form>

          <div class="uip-cancel">
            <form method="post" action="${ctx}/staff/counter"
                  onsubmit="return confirm('Há»§y Ä‘Æ¡n nÃ y? Gháº¿ Ä‘Ã£ giá»¯ sáº½ Ä‘Æ°á»£c nháº£ láº¡i.')">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="cancelBooking">
              <button class="btn-link" type="submit" style="color:var(--danger)">Há»§y Ä‘Æ¡n nÃ y</button>
            </form>
          </div>
        </aside>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



