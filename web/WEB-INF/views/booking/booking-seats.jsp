<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đặt vé — Chọn ghế"/>
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
  .uip-movie-bar { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-bottom: 6px; }
  .uip-movie-bar h1 { margin: 0 10px 0 0; font-size: 24px; }
  .uip-actions { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }
  .uip-count { font-size: 15px; }
  .uip-total { font-size: 15px; }
  .uip-total b { color: var(--brand); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="uip-steps">
        <span class="uip-step done"><span class="uip-num">✓</span> Chọn suất chiếu</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step active"><span class="uip-num">2</span> Chọn ghế</span>
        <span class="uip-arrow">→</span>
        <span class="uip-step"><span class="uip-num">3</span> Thanh toán</span>
      </div>

      <div class="uip-movie-bar">
        <h1><c:out value="${showtime.title}"/></h1>
        <span class="chip">🎬 <c:out value="${showtime.roomName}"/></span>
        <span class="chip">🕒 ${showtime.startTimeLabel}</span>
      </div>

      <c:if test="${not empty error}">
        <p class="alert alert-error"><c:out value="${error}"/></p>
      </c:if>

      <%@ include file="_seat-picker.jspf" %>

      <form method="post" action="${ctx}/booking/seats" onsubmit="return checkSeats()">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="showtimeId" value="${showtime.showtimeId}">
        <input type="hidden" id="seatIds" name="seatIds" value="">
        <div class="uip-actions">
          <span class="uip-count">Đã chọn: <strong id="selCount">0</strong> ghế</span>
          <span class="uip-total">Tạm tính: <strong id="selTotal">0</strong> VNĐ</span>
          <button class="btn btn-cta" type="submit">Giữ ghế &amp; sang thanh toán →</button>
          <a class="btn btn-outline" href="${ctx}/showtimes">← Đổi suất chiếu</a>
        </div>
      </form>
    </div>
  </section>
</main>
<%@ include file="_seat-picker-script.jspf" %>
<%@ include file="../_footer.jspf" %>



