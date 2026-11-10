<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Combo & thanh toán"/>
<%@ include file="../layout/top.jspf" %>
<fmt:setLocale value="vi_VN"/>
<style>
  .sec-num { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; background: var(--brand-50); color: var(--brand-700); font-weight: 700; font-size: 14px; flex: none; }
  .combo-row { display: grid; grid-template-columns: 56px minmax(0, 1fr) auto auto; gap: 14px; align-items: center; padding: 14px 0; border-bottom: 1px solid var(--line); }
  .combo-row:last-child { border-bottom: 0; }
  .combo-row img, .combo-row .ph { width: 56px; height: 56px; border-radius: var(--r-md); object-fit: cover; background: var(--accent-50); color: var(--accent-700); display: grid; place-items: center; }
  .combo-row .ph svg { width: 26px; height: 26px; }
  .qty { display: inline-flex; align-items: center; gap: 4px; padding: 3px; border: 1px solid var(--line); border-radius: var(--r-pill); }
  .qty button { width: 32px; height: 32px; border: 0; border-radius: 50%; background: var(--surface-3); color: var(--ink); font-size: 18px; line-height: 1; }
  .qty button:hover { background: var(--brand-50); color: var(--brand-700); }
  .qty .uip-qty-value { min-width: 26px; text-align: center; font-weight: 700; }
  .voucher-pick tbody tr { cursor: pointer; }
  .voucher-pick tbody tr:hover { background: var(--brand-50); }
  .inline-form { display: flex; gap: 10px; flex-wrap: wrap; }
  .inline-form .field { flex: 1 1 200px; }
  .pay-notice { position: fixed; inset: 0; z-index: var(--z-modal); display: grid; place-items: center; padding: 16px; background: rgba(11, 19, 36, .55); }
  .pay-notice-box { width: min(760px, 100%); max-height: 90vh; display: flex; flex-direction: column; background: var(--surface); border-radius: var(--r-xl); box-shadow: var(--sh-lg); overflow: hidden; }
  .pay-notice-box h3 { padding: 18px 24px; border-bottom: 1px solid var(--line); font-size: 18px; }
  .pay-notice-body { padding: 18px 24px; overflow-y: auto; font-size: 14.5px; line-height: 1.6; color: var(--text); }
  .pay-notice-body p { margin: 0 0 10px; }
  .pay-notice-body ul { margin: 0 0 6px 20px; padding: 0; }
  .pay-notice-actions { display: flex; justify-content: flex-end; gap: 10px; padding: 14px 24px; border-top: 1px solid var(--line); background: var(--surface-2); }
</style>
<div class="container">
  <nav class="stepper" aria-label="Các bước đặt vé">
    <span class="step done"><b>${ic.check}</b>Chọn suất chiếu</span><span class="bar done"></span>
    <span class="step done"><b>${ic.check}</b>Chọn ghế</span><span class="bar done"></span>
    <span class="step active" aria-current="step"><b>3</b>Combo &amp; thanh toán</span>
  </nav>

  <div class="split">
    <div class="stack" style="--gap:20px">
      <section class="card">
        <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">${ic.user}</span><h2>Thông tin thanh toán</h2></div></div>
        <div class="card-body">
          <dl class="grid grid-3" style="--gap:14px">
            <div><dt class="muted text-xs">Họ tên</dt><dd class="fw-600 text-ink" style="margin:2px 0 0"><c:out value="${not empty payer.fullName ? payer.fullName : sessionScope.authUser.fullName}"/></dd></div>
            <div><dt class="muted text-xs">Số điện thoại</dt><dd class="fw-600 text-ink" style="margin:2px 0 0"><c:out value="${empty payer.phone ? 'Chưa cập nhật' : payer.phone}"/></dd></div>
            <div><dt class="muted text-xs">Email</dt><dd class="fw-600 text-ink" style="margin:2px 0 0;word-break:break-all"><c:out value="${not empty payer.email ? payer.email : booking.customerEmail}"/></dd></div>
          </dl>
          <c:if test="${empty payer.phone}"><p class="hint mt-8">Bạn chưa có số điện thoại. <a href="${ctx}/account/profile">Cập nhật trong thông tin cá nhân</a>.</p></c:if>
          <div class="mt-16">
            <c:forEach var="g" items="${seatGroups}">
              <div class="kv">
                <span>Ghế <strong class="text-ink"><c:out value="${g.type_vi}"/></strong> <span class="muted">(<c:out value="${g.seats}"/>)</span></span>
                <span><c:out value="${g.qty}"/> × <fmt:formatNumber value="${g.unit_price}" pattern="#,##0"/> = <strong><fmt:formatNumber value="${g.line_total}" pattern="#,##0"/> đ</strong></span>
              </div>
            </c:forEach>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">1</span><div><h2>Combo bắp nước</h2><p>Không bắt buộc</p></div></div></div>
        <form method="post" action="${ctx}/booking/extras">
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
                  <button type="button" data-qty-action="decrease" aria-label="Giảm số lượng <c:out value='${cb.comboName}'/>">−</button>
                  <input type="hidden" name="qty" value="${comboQty[cb.comboId] != null ? comboQty[cb.comboId] : 0}">
                  <span class="uip-qty-value">${comboQty[cb.comboId] != null ? comboQty[cb.comboId] : 0}</span>
                  <button type="button" data-qty-action="increase" aria-label="Tăng số lượng <c:out value='${cb.comboName}'/>">+</button>
                </span>
              </div>
            </c:forEach>
          </div>
          <div class="card-foot"><button class="btn btn-soft" type="submit">${ic.refresh}Cập nhật combo</button></div>
        </form>
      </section>

      <section class="card">
        <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">2</span><h2>Voucher</h2></div></div>
        <div class="card-body">
          <form method="post" action="${ctx}/booking/extras" class="inline-form">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="applyVoucher">
            <div class="field"><label class="sr-only" for="voucherCode">Mã voucher</label>
              <div class="input-group">${ic.tag}<input id="voucherCode" type="text" name="voucherCode" placeholder="Nhập mã voucher" maxlength="30"></div></div>
            <button class="btn btn-primary" type="submit">Áp dụng</button>
          </form>
          <c:if test="${not empty vouchers}">
            <p class="label mt-16 mb-8">Voucher của bạn <span class="muted fw-600 text-xs">(bấm để chọn)</span></p>
            <div class="table-wrap" style="border:1px solid var(--line);border-radius:var(--r-md)">
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
        </div>
      </section>

      <section class="card">
        <div class="card-head"><div class="cluster" style="--gap:12px"><span class="sec-num">3</span><div><h2>Điểm MyPoint</h2><p>Bạn đang có <strong class="text-ink">${pointBalance}</strong> điểm</p></div></div></div>
        <div class="card-body">
          <form method="post" action="${ctx}/booking/extras" class="inline-form">
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="applyPoints">
            <div class="field"><label class="sr-only" for="pointsInput">Số điểm dùng</label>
              <input id="pointsInput" type="number" name="points" min="0" max="${pointBalance}" value="${booking.pointsUsed}" placeholder="Nhập số điểm"></div>
            <button class="btn btn-primary" type="submit">Đổi điểm</button>
          </form>
          <p class="mt-8 text-sm">Số tiền được giảm ≈ <strong class="text-success" id="pointsDiscountPreview">0</strong> đ</p>
          <div class="alert alert-info mt-16">${ic.info}<span>Áp voucher sẽ xóa điểm đã dùng, nên áp voucher trước rồi mới đổi điểm. Đã giảm: voucher <strong>${booking.voucherDiscountLabel} đ</strong>, MyPoint <strong>${booking.pointsDiscountLabel} đ</strong> (${booking.pointsUsed} điểm).</span></div>
        </div>
      </section>
    </div>

    <aside class="card sticky">
      <div class="card-head"><div><h2>Tóm tắt đơn</h2><p>Mã đơn <span class="voucher-code"><c:out value="${booking.bookingCode}"/></span></p></div></div>
      <div class="card-body">
        <h3 style="font-size:17px"><c:out value="${booking.movieTitle}"/></h3>
        <div class="movie-meta mt-4"><span><c:out value="${booking.roomName}"/></span><span>${booking.startTimeLabel}</span></div>
        <p class="mt-8 text-sm">Ghế: <strong class="text-ink"><c:out value="${booking.seatLabelText}"/></strong></p>
        <hr class="divider" style="margin:16px 0 6px">
        <div class="kv"><span>Tiền vé</span><strong>${booking.ticketTotalLabel} đ</strong></div>
        <div class="kv"><span>Tiền combo</span><strong>${booking.comboTotalLabel} đ</strong></div>
        <c:if test="${booking.voucherDiscount > 0}"><div class="kv"><span>Giảm voucher</span><strong class="text-success">− ${booking.voucherDiscountLabel} đ</strong></div></c:if>
        <c:if test="${booking.pointsDiscount > 0}"><div class="kv"><span>Giảm MyPoint</span><strong class="text-success">− ${booking.pointsDiscountLabel} đ</strong></div></c:if>
        <div class="kv total"><span>Tổng phải trả</span><strong>${booking.totalAmountLabel} đ</strong></div>
      </div>
      <div class="card-foot" style="display:grid;grid-template-columns:1fr 1.5fr">
        <form method="post" action="${ctx}/booking/extras" data-confirm="Quay lại chọn ghế? Ghế đang giữ sẽ được trả lại.">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="back">
          <button class="btn btn-block" type="submit">${ic.chevronLeft}Quay lại</button>
        </form>
        <form id="nextForm" method="post" action="${ctx}/booking/extras">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="next">
          <button class="btn btn-accent btn-block" type="submit">Thanh toán ${ic.arrowRight}</button>
        </form>
      </div>
    </aside>
  </div>
</div>

<div class="pay-notice" id="payNotice" role="dialog" aria-modal="true" aria-labelledby="payNoticeTitle" hidden>
  <div class="pay-notice-box">
    <h3 id="payNoticeTitle">Lưu ý trước khi thanh toán</h3>
    <div class="pay-notice-body">
      <p>Chào mừng Quý khách hàng đến với Hệ thống Bán Vé Online của chuỗi Rạp Chiếu Phim CINESTAR CINEMAS!</p>
      <p>Xin cảm ơn và chúc Quý khách hàng có những giây phút xem phim tuyệt vời tại CINESTAR CINEMAS!</p>
      <p><strong>Sau đây là một số lưu ý trước khi thanh toán trực tuyến:</strong></p>
      <p>1. Thẻ phải được kích hoạt chức năng thanh toán trực tuyến, và có đủ hạn mức/ số dư để thanh toán. Quý khách cần nhập chính xác thông tin thẻ (tên chủ thẻ, số thẻ, ngày hết hạn, số CVC, OTP,...).</p>
      <p>2. Vé và hàng hóa đã thanh toán thành công không thể hủy/đổi trả/hoàn tiền vì bất kỳ lý do gì. CineStar Cinemas chỉ thực hiện hoàn tiền trong trường hợp thẻ của Quý khách đã bị trừ tiền nhưng hệ thống của CineStar không ghi nhận việc đặt vé/đơn hàng của Quý khách, và Quý khách không nhận được xác nhận đặt vé/đơn hàng thành công.</p>
      <p>3. Trong vòng 30 phút kể từ khi thanh toán thành công, CineStar Cinemas sẽ gửi Quý khách mã xác nhận thông tin vé/đơn hàng qua email của Quý khách. Nếu Quý khách cần hỗ trợ hay thắc mắc, khiếu nại về xác nhận mã vé/đơn hàng thì vui lòng phản hồi về Fanpage Facebook CineStar Cinemas trong vòng 60 phút kể từ khi thanh toán vé thành công. Sau khoảng thời gian trên, CineStar Cinemas sẽ không chấp nhận giải quyết bất kỳ khiếu nại nào.</p>
      <p>4. CineStar Cinemas không chịu trách nhiệm trong trường hợp thông tin địa chỉ email, số điện thoại Quý khách nhập không chính xác dẫn đến không nhận được thư xác nhận. Vui lòng kiểm tra kỹ các thông tin này trước khi thực hiện thanh toán. CineStar Cinemas không hỗ trợ xử lý và không chịu trách nhiệm trong trường hợp đã gửi thư xác nhận mã vé/đơn hàng đến địa chỉ email của Quý khách nhưng vì một lý do nào đó mà Quý khách không thể đến xem phim.</p>
      <p>5. Vui lòng kiểm tra thông tin xác nhận vé cẩn thận và ghi nhớ mã đặt vé/đơn hàng. Khi đến nhận vé/hàng hóa tại Quầy vé của CineStar Cinemas, Quý khách cũng cần mang theo giấy tờ tùy thân như Căn cước công dân/Chứng minh nhân dân, Thẻ học sinh, Thẻ sinh viên hoặc hộ chiếu.</p>
      <p>6. Theo quy định của Cục Điện Ảnh, một số phim sẽ không dành cho khán giả dưới 13, hoặc 16, hoặc 18 tuổi. Khi đến lấy vé tại quầy vé, nhân viên có thể yêu cầu Quý khách hàng xuất trình giấy tờ tùy thân (Giấy khai sinh, Căn cước công dân, Thẻ học sinh, Thẻ sinh viên, Bằng lái xe hoặc các giấy tờ tùy thân khác) để xác định độ tuổi chính xác của Quý khách hàng. Quý khách hàng vui lòng lưu ý và cân nhắc trước khi mua vé.</p>
      <p>Căn cứ vào Điều 9 Nghị định 131/2022/NĐ-CP quy định chi tiết một số điều của Luật Điện Ảnh, CineStar Cinemas áp dụng quy định về khung giờ chiếu phim cho trẻ em, áp dụng cho toàn bộ hệ thống rạp chiếu phim như sau:</p>
      <p>Giờ chiếu phim cho trẻ em dưới 13 tuổi tại tất cả các cụm rạp CineStar Cinemas kết thúc trước 22 giờ.</p>
      <p>Giờ chiếu phim cho trẻ em dưới 16 tuổi tại tất cả các cụm rạp CineStar Cinemas kết thúc trước 23 giờ.</p>
      <p>Lưu ý, Ban Quản Lý tại các cụm rạp chiếu phim CineStar Cinemas có quyền kiểm tra và từ chối yêu cầu xem phim của Quý khách hàng nếu Quý khách hàng không tuân thủ quy định về độ tuổi xem phim.</p>
      <p>7. Vì một số sự cố kỹ thuật bất khả kháng, suất chiếu có thể bị huỷ để đảm bảo an toàn tối đa cho khách hàng, CineStar Cinemas sẽ thực hiện hoàn trả số tiền giao dịch về tài khoản mà Quý khách đã thực hiện mua vé. CineStar Cinemas sẽ liên hệ với Quý khách qua các thông tin liên hệ trong mục Thông tin thành viên để thông báo và xác nhận.</p>
      <p>Sau khi đã xác nhận, tùy theo từng loại tài khoản mà Quý khách sử dụng và tuỳ theo chính sách của các ngân hàng mà việc hoàn tiền sẽ có thời gian khác nhau:</p>
      <ul>
        <li>Thẻ quốc tế: trong vòng 30 ngày làm việc</li>
        <li>Thẻ nội địa: trong vòng 7 ngày làm việc</li>
        <li>Ứng dụng di động: 1-2 ngày làm việc</li>
        <li>Ví điện tử: 7-14 ngày làm việc</li>
      </ul>
    </div>
    <div class="pay-notice-actions">
      <button type="button" class="btn" id="payNoticeClose">Đóng</button>
      <button type="button" class="btn btn-accent" id="payNoticeOk">Đồng ý và tiếp tục</button>
    </div>
  </div>
</div>
<script>
(function () {
  var form = document.getElementById('nextForm'), box = document.getElementById('payNotice');
  var confirmed = false;
  form.addEventListener('submit', function (e) {
    if (confirmed) return;
    e.preventDefault();
    box.hidden = false;
    box.querySelector('.pay-notice-body').scrollTop = 0;
    document.getElementById('payNoticeOk').focus();
  });
  document.getElementById('payNoticeClose').addEventListener('click', function () { box.hidden = true; });
  document.getElementById('payNoticeOk').addEventListener('click', function () { confirmed = true; form.submit(); });
  box.addEventListener('click', function (e) { if (e.target === box) box.hidden = true; });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') box.hidden = true; });

  document.querySelectorAll('.uip-qty-stepper').forEach(function (stepper) {
    var input = stepper.querySelector('input[name="qty"]');
    var output = stepper.querySelector('.uip-qty-value');
    stepper.addEventListener('click', function (e) {
      var button = e.target.closest('button[data-qty-action]');
      if (!button) return;
      var value = parseInt(input.value || '0', 10);
      value += button.dataset.qtyAction === 'increase' ? 1 : -1;
      value = Math.max(0, Math.min(99, value));
      input.value = value; output.textContent = value;
    });
  });
  var voucherInput = document.querySelector('input[name="voucherCode"]');
  document.querySelectorAll('[data-voucher-code]').forEach(function (row) {
    row.addEventListener('click', function () { if (voucherInput) { voucherInput.value = row.dataset.voucherCode; voucherInput.focus(); } });
  });
  var pointsInput = document.getElementById('pointsInput');
  var pointPreview = document.getElementById('pointsDiscountPreview');
  var pointValue = ${not empty pointConfig ? pointConfig.pointValueVnd : 0};
  function updatePointPreview() {
    if (pointsInput && pointPreview) pointPreview.textContent = (Math.max(0, parseInt(pointsInput.value || '0', 10)) * pointValue).toLocaleString('vi-VN');
  }
  if (pointsInput) { pointsInput.addEventListener('input', updatePointPreview); updatePointPreview(); }
})();
</script>
<%@ include file="../layout/bottom.jspf" %>
