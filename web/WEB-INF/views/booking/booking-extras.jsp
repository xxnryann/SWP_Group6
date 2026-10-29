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
  .uip-nav { display: grid; grid-template-columns: 1fr 1.4fr; gap: 10px; }
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

          <div class="uip-next uip-nav">
            <form method="post" action="${ctx}/booking/extras"
                  onsubmit="return confirm('Quay lại chọn ghế? Ghế đang giữ sẽ được trả lại.');">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="back">
              <button class="btn btn-outline btn-block" type="submit">← Quay lại</button>
            </form>
            <form id="nextForm" method="post" action="${ctx}/booking/extras">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="next">
              <button class="btn btn-cta btn-block" type="submit">Tiếp tục thanh toán →</button>
            </form>
          </div>
        </aside>
      </div>
    </div>
  </section>
</main>

<div class="pay-notice" id="payNotice" role="dialog" aria-modal="true" aria-labelledby="payNoticeTitle" hidden>
  <div class="pay-notice-box">
    <h3 id="payNoticeTitle">THÔNG BÁO</h3>
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
      <button type="button" class="btn btn-outline" id="payNoticeClose">Đóng</button>
      <button type="button" class="btn btn-cta" id="payNoticeOk">Đồng ý và tiếp tục</button>
    </div>
  </div>
</div>
<style>
  .pay-notice { position: fixed; inset: 0; z-index: 1000; background: rgba(15,23,42,.55);
                display: flex; align-items: center; justify-content: center; padding: 16px; }
  .pay-notice[hidden] { display: none; }
  .pay-notice-box { background: #fff; border-radius: 10px; width: 100%; max-width: 760px; max-height: 90vh;
                    display: flex; flex-direction: column; box-shadow: 0 20px 50px rgba(0,0,0,.3); }
  .pay-notice-box h3 { margin: 0; padding: 16px 24px; text-align: center; font-size: 20px; color: var(--brand);
                       border-bottom: 1px solid var(--slate-200); }
  .pay-notice-body { padding: 16px 24px; overflow-y: auto; font-size: 14.5px; line-height: 1.55; color: var(--slate-700, #334155); }
  .pay-notice-body p { margin: 0 0 10px; }
  .pay-notice-body ul { margin: 0 0 6px 20px; padding: 0; }
  .pay-notice-actions { display: flex; justify-content: center; gap: 12px; padding: 14px 24px;
                        border-top: 1px solid var(--slate-200); }
</style>
<script>
(function () {
  var form = document.getElementById('nextForm'), box = document.getElementById('payNotice');
  var confirmed = false;
  form.addEventListener('submit', function (e) {
    if (confirmed) return;
    e.preventDefault();
    box.hidden = false;
    box.querySelector('.pay-notice-body').scrollTop = 0;
  });
  document.getElementById('payNoticeClose').addEventListener('click', function () { box.hidden = true; });
  document.getElementById('payNoticeOk').addEventListener('click', function () { confirmed = true; form.submit(); });
  box.addEventListener('click', function (e) { if (e.target === box) box.hidden = true; });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') box.hidden = true; });
})();
</script>
<%@ include file="../_footer.jspf" %>



