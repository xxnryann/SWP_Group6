<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Bán vé tại quầy — Hóa đơn"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-receipt { max-width: 640px; margin: 0 auto; padding: 36px 38px; }
  .uip-ok { width: 76px; height: 76px; border-radius: 50%; background: #d1fae5; color: var(--success);
            display: grid; place-items: center; font-size: 38px; margin: 0 auto 14px; }
  .uip-receipt h1 { text-align: center; margin: 0 0 6px; font-size: 26px; }
  .uip-receipt .uip-sub { text-align: center; color: var(--slate-500); margin: 0 0 22px; }
  .uip-code { font-family: ui-monospace, Consolas, monospace; font-weight: 800; color: var(--brand); font-size: 18px; }
  .uip-tickets { display: flex; gap: 8px; flex-wrap: wrap; justify-content: center; margin: 4px 0 18px; }
  .uip-ticket { font-family: ui-monospace, Consolas, monospace; font-weight: 700; font-size: 14px;
                background: var(--slate-100); border: 1.5px dashed var(--slate-400); border-radius: 8px; padding: 5px 12px; }
  .uip-qr-grid { display: flex; gap: 14px; flex-wrap: wrap; justify-content: center; margin: 6px 0 18px; }
  .uip-qr { text-align: center; padding: 12px; border: 1.5px dashed var(--slate-300);
            border-radius: 12px; background: #fff; }
  .uip-qr img { width: 130px; height: 130px; display: block; }
  .uip-qr .uip-qr-code { font-family: ui-monospace, Consolas, monospace; font-weight: 800;
                        font-size: 12.5px; margin-top: 6px; word-break: break-all; }
  .uip-qr .uip-qr-label { font-size: 11.5px; color: var(--slate-500); margin-top: 2px; }
  .uip-line { display: flex; justify-content: space-between; gap: 14px; padding: 8px 0;
              border-top: 1px solid var(--slate-100); font-size: 14.5px; }
  .uip-line .uip-neg { color: var(--success); font-weight: 700; }
  .uip-total { display: flex; justify-content: space-between; align-items: baseline; gap: 14px;
               border-top: 2px solid var(--slate-200); margin-top: 8px; padding-top: 14px; }
  .uip-total .uip-amt { color: var(--cta); font-weight: 800; font-size: 24px; }
  .uip-center { text-align: center; margin-top: 24px; }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="card uip-receipt">
        <div class="uip-ok">✓</div>
        <h1>Thanh toán thành công</h1>
        <p class="uip-sub">Mã đơn <span class="uip-code"><c:out value="${summary.bookingCode}"/></span> ·
           Khách hàng: <c:out value="${summary.hasCustomer ? summary.customerName : 'Khách vãng lai'}"/></p>

        <p style="text-align:center;margin:0;color:var(--slate-500);font-size:13.5px">MÃ VÉ (DÙNG CHECK-IN)</p>
        <div class="uip-tickets">
          <c:forEach var="code" items="${summary.ticketCodes}">
            <span class="uip-ticket">🎟 <c:out value="${code}"/></span>
          </c:forEach>
        </div>

        <%-- Mã QR từng vé: khách dùng để soát vé tại quầy (UC39) --%>
        <c:if test="${not empty summary.ticketIds}">
          <p style="text-align:center;margin:14px 0 0;color:var(--slate-500);font-size:13.5px">
            QUÉT MÃ ĐỂ VÀO RẠP
          </p>
          <div class="uip-qr-grid">
            <c:forEach var="tid" items="${summary.ticketIds}" varStatus="loop">
              <div class="uip-qr">
                <img src="${ctx}/staff/tickets/qr?ticketId=${tid}" alt="Mã QR vé ${loop.index + 1}">
                <div class="uip-qr-code">
                  <c:forEach var="code" items="${summary.ticketCodes}" varStatus="cLoop">
                    <c:if test="${cLoop.index == loop.index}"><c:out value="${code}"/></c:if>
                  </c:forEach>
                </div>
                <div class="uip-qr-label">Vé ${loop.index + 1}</div>
              </div>
            </c:forEach>
          </div>
        </c:if>

        <c:forEach var="cl" items="${summary.comboLines}">
          <div class="uip-line"><span>🍿 <c:out value="${cl.comboName}"/> × ${cl.quantity}</span><span>${cl.lineTotalLabel} VNĐ</span></div>
        </c:forEach>
        <div class="uip-line"><span>Tiền vé</span><span>${summary.ticketTotalLabel} VNĐ</span></div>
        <div class="uip-line"><span>Tiền combo</span><span>${summary.comboTotalLabel} VNĐ</span></div>
        <c:if test="${summary.voucherDiscount > 0}">
          <div class="uip-line"><span>Giảm voucher</span><span class="uip-neg">− ${summary.voucherDiscountLabel} VNĐ</span></div>
        </c:if>
        <c:if test="${summary.pointsDiscount > 0}">
          <div class="uip-line"><span>Giảm MyPoint (${summary.pointsUsed} điểm)</span><span class="uip-neg">− ${summary.pointsDiscountLabel} VNĐ</span></div>
        </c:if>
        <div class="uip-total"><span><strong>Tổng thu</strong></span><span class="uip-amt">${summary.totalAmountLabel} VNĐ</span></div>
        <c:if test="${not empty cashReceived}">
          <div class="uip-line"><span>Tiền khách đưa</span><span>${cashReceived} VNĐ</span></div>
          <div class="uip-line"><span><strong>Tiền thối lại</strong></span><span><strong>${change} VNĐ</strong></span></div>
        </c:if>

        <div class="uip-center"><a class="btn btn-cta" href="${ctx}/staff/counter">🎟 Bán vé mới</a></div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
