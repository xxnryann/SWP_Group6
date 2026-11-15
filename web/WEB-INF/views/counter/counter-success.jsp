<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hóa đơn bán vé"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .receipt { max-width: 680px; margin: 0 auto; }
  .receipt-ok { display: grid; place-items: center; width: 72px; height: 72px; margin: 0 auto 14px; border-radius: 50%; background: var(--success-50); color: var(--success); }
  .receipt-ok svg { width: 34px; height: 34px; }
  .qr-grid { display: flex; flex-wrap: wrap; justify-content: center; gap: 14px; margin: 12px 0 8px; }
  .qr-item { padding: 12px; text-align: center; border: 1.5px dashed var(--line-strong); border-radius: var(--r-lg); background: #fff; }
  .qr-item img { width: 130px; height: 130px; }
  .qr-item .voucher-code { display: block; margin-top: 8px; font-size: 12px; }
  .change-box { display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap; margin: 18px auto 0; max-width: 460px; padding: 16px 18px; border: 2px solid var(--brand-500); border-radius: var(--r-lg); background: var(--brand-50); text-align: left; }
  .change-box .change-label { font-weight: 600; color: var(--brand-700); }
  .change-box .change-amount { font-size: 26px; font-weight: 800; color: var(--brand-700); white-space: nowrap; }
  .change-box.exact { border-color: var(--success); background: var(--success-50); }
  .change-box.exact .change-label, .change-box.exact .change-amount { color: var(--success); }
  @media print { .site-header, .sidebar, .app-topbar, .no-print { display: none !important; } .app { display: block; } }
</style>
<div class="receipt">
  <section class="card">
    <div class="card-body text-center">
      <div class="receipt-ok">${ic.check}</div>
      <h1 style="font-size:26px">Thanh toán thành công</h1>
      <p class="muted mt-8">Mã đơn <span class="voucher-code"><c:out value="${summary.bookingCode}"/></span> · Khách hàng: <strong class="text-ink"><c:out value="${summary.hasCustomer ? summary.customerName : 'Khách vãng lai'}"/></strong></p>
      <c:if test="${not empty cashReceived}">
        <div class="change-box ${hasChange ? '' : 'exact'}">
          <div>
            <div class="change-label">
              <c:choose>
                <c:when test="${hasChange}">Trả lại khách (tiền thối)</c:when>
                <c:otherwise>Khách đưa đủ số tiền</c:otherwise>
              </c:choose>
            </div>
            <div class="muted text-sm">Tiền khách đưa <strong class="text-ink">${cashReceived} đ</strong> · Tổng thu <strong class="text-ink">${summary.totalAmountLabel} đ</strong></div>
          </div>
          <div class="change-amount"><c:out value="${change}"/> đ</div>
        </div>
      </c:if>
      <p class="label mt-24">Mã vé (dùng để soát vé)</p>
      <div class="cluster mt-8" style="justify-content:center;--gap:8px">
        <c:forEach var="code" items="${summary.ticketCodes}"><span class="voucher-code">${ic.ticket} <c:out value="${code}"/></span></c:forEach>
      </div>
      <c:if test="${not empty summary.ticketIds}">
        <div class="qr-grid">
          <c:forEach var="tid" items="${summary.ticketIds}" varStatus="loop">
            <div class="qr-item">
              <img src="${ctx}/staff/tickets/qr?ticketId=${tid}" alt="Mã QR vé ${loop.index + 1}">
              <span class="voucher-code"><c:forEach var="code" items="${summary.ticketCodes}" varStatus="cLoop"><c:if test="${cLoop.index == loop.index}"><c:out value="${code}"/></c:if></c:forEach></span>
              <span class="muted text-xs">Vé ${loop.index + 1}</span>
            </div>
          </c:forEach>
        </div>
      </c:if>
    </div>
    <div class="card-body" style="border-top:1px solid var(--line)">
      <c:forEach var="cl" items="${summary.comboLines}">
        <div class="kv"><span><c:out value="${cl.comboName}"/> × ${cl.quantity}</span><strong>${cl.lineTotalLabel} đ</strong></div>
      </c:forEach>
      <div class="kv"><span>Tiền vé</span><strong>${summary.ticketTotalLabel} đ</strong></div>
      <div class="kv"><span>Tiền combo</span><strong>${summary.comboTotalLabel} đ</strong></div>
      <c:if test="${summary.voucherDiscount > 0}"><div class="kv"><span>Giảm voucher</span><strong class="text-success">− ${summary.voucherDiscountLabel} đ</strong></div></c:if>
      <c:if test="${summary.pointsDiscount > 0}"><div class="kv"><span>Giảm MyPoint (${summary.pointsUsed} điểm)</span><strong class="text-success">− ${summary.pointsDiscountLabel} đ</strong></div></c:if>
      <div class="kv total"><span>Tổng thu</span><strong>${summary.totalAmountLabel} đ</strong></div>
      <c:if test="${not empty cashReceived}">
        <div class="kv"><span>Tiền khách đưa</span><strong>${cashReceived} đ</strong></div>
        <div class="kv"><span>Tiền thối lại khách</span><strong class="text-brand" style="font-size:18px">${change} đ</strong></div>
      </c:if>
    </div>
    <div class="card-foot no-print" style="justify-content:center">
      <button class="btn" type="button" onclick="window.print()">${ic.download}In hóa đơn</button>
      <a class="btn btn-primary" href="${ctx}/staff/counter">${ic.ticket}Bán vé mới</a>
    </div>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
