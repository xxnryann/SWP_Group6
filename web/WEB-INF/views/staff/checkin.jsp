<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Soát vé"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .scan-input input { font-family: ui-monospace, Consolas, monospace; font-size: 20px !important; letter-spacing: .06em; min-height: 56px !important; text-transform: uppercase; }
  .qr-scan-status { min-height: 20px; color: var(--muted); font-size: 14px; }
  .qr-scan-video { display: block; width: 100%; max-width: 420px; border-radius: var(--r-lg); background: var(--ink); }
  .result-card { border-width: 2px; }
  .result-card.ok { border-color: var(--success); }
  .result-card.bad { border-color: var(--danger); }
</style>
<div class="page-head">
  <div><h1>Soát vé</h1><p>Nhập mã vé, dùng máy quét hoặc quét mã QR trên vé điện tử của khách.</p></div>
</div>

<div class="split" style="grid-template-columns:minmax(0,1fr) minmax(0,1fr)">
  <section class="card">
    <div class="card-head"><div><h2>Kiểm tra vé</h2><p>Vé hợp lệ khi đúng suất và trong giờ cho phép vào phòng</p></div></div>
    <div class="card-body stack" style="--gap:18px">
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
      <c:if test="${not empty success}"><div class="alert alert-success" role="status">${ic.checkCircle}<span><c:out value="${success}"/></span></div></c:if>
      <form method="post" action="${ctx}/staff/checkin" class="form" id="checkinForm">
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="field scan-input">
          <label for="ticketCode">Mã vé</label>
          <input id="ticketCode" name="ticketCode" type="text" maxlength="30" autocomplete="off" autofocus
                 placeholder="TK4C537F9A2BD3" value="<c:out value='${param.ticketCode}'/>">
        </div>
        <button class="btn btn-primary btn-lg btn-block" type="submit">${ic.scan}Soát vé</button>
      </form>
      <div>
        <p class="label mb-8">Hoặc quét mã QR</p>
        <div class="cluster">
          <button class="btn" type="button" id="qrCameraBtn">${ic.qr}Quét bằng camera</button>
          <label class="btn" for="qrImage">${ic.image}Chọn ảnh mã QR</label>
          <input id="qrImage" type="file" accept="image/*" hidden>
        </div>
        <p class="qr-scan-status mt-8" id="qrStatus" role="status" aria-live="polite"></p>
        <video id="qrVideo" class="qr-scan-video mt-8" playsinline muted hidden></video>
      </div>
    </div>
  </section>

  <section class="card result-card ${empty ticket ? '' : (not empty success ? 'ok' : 'bad')}">
    <div class="card-head"><div><h2>Thông tin vé</h2><p>Kết quả lần soát gần nhất</p></div></div>
    <div class="card-body">
      <c:choose>
        <c:when test="${empty ticket}">
          <div class="empty" style="padding:28px"><div class="empty-icon">${ic.ticket}</div><p>Nhập hoặc quét mã để xem thông tin vé.</p></div>
        </c:when>
        <c:otherwise>
          <div class="cluster between mb-16">
            <h3 style="font-size:19px"><c:out value="${ticket.movie_title}"/></h3>
            <c:choose>
              <c:when test="${ticket.status == 'Used'}"><span class="badge badge-success badge-dot">Đã soát</span></c:when>
              <c:when test="${ticket.status == 'Booked'}"><span class="badge badge-brand badge-dot">Hợp lệ</span></c:when>
              <c:otherwise><span class="badge badge-danger badge-dot"><c:out value="${ticket.status}"/></span></c:otherwise>
            </c:choose>
          </div>
          <dl class="dl">
            <dt>Mã vé</dt><dd><span class="voucher-code"><c:out value="${ticket.ticket_code}"/></span></dd>
            <dt>Phòng / Ghế</dt><dd><c:out value="${ticket.room_name}"/> · <span class="text-brand" style="font-size:18px"><c:out value="${ticket.seat_label}"/></span></dd>
            <dt>Suất chiếu</dt><dd><c:out value="${ticket.start_time}"/> – <c:out value="${ticket.end_time}"/></dd>
            <dt>Khách hàng</dt><dd><c:out value="${empty ticket.customer_name ? 'Khách mua tại quầy' : ticket.customer_name}"/></dd>
          </dl>
        </c:otherwise>
      </c:choose>
    </div>
  </section>
</div>

<section class="card mt-24">
  <div class="card-head"><div><h2>Vé soát gần đây</h2><p>10 lượt gần nhất</p></div></div>
  <c:choose>
    <c:when test="${empty recent}"><div class="empty"><div class="empty-icon">${ic.list}</div><p>Chưa có vé nào được soát.</p></div></c:when>
    <c:otherwise>
      <div class="table-wrap"><table class="table">
        <thead><tr><th>Mã vé</th><th>Phim</th><th>Phòng</th><th>Ghế</th><th>Thời điểm</th><th>Nhân viên</th></tr></thead>
        <tbody>
        <c:forEach var="r" items="${recent}">
          <tr>
            <td><span class="voucher-code"><c:out value="${r.ticket_code}"/></span></td>
            <td class="cell-main"><c:out value="${r.movie_title}"/></td>
            <td><c:out value="${r.room_name}"/></td>
            <td class="fw-700"><c:out value="${r.seat_label}"/></td>
            <td class="muted text-sm nowrap"><c:out value="${r.checked_in_at}"/></td>
            <td><c:out value="${r.staff_name}"/></td>
          </tr>
        </c:forEach>
        </tbody>
      </table></div>
    </c:otherwise>
  </c:choose>
</section>
<script src="${ctx}/assets/js/vendor/jsQR.js"></script>
<script src="${ctx}/assets/js/checkin-scan.js"></script>
<%@ include file="../layout/bottom.jspf" %>
