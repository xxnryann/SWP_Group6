﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="BÃ¡n vÃ© táº¡i quáº§y â€” Chá»n suáº¥t chiáº¿u"/>
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
  .uip-list { display: flex; flex-direction: column; gap: 12px; }
  .uip-show { display: grid; grid-template-columns: 128px 1fr auto; gap: 18px; align-items: center;
              background: #fff; border: 1px solid var(--slate-200); border-radius: 14px;
              box-shadow: var(--shadow); padding: 16px 20px; }
  .uip-time { text-align: center; background: linear-gradient(150deg, var(--brand), var(--navy)); color: #fff;
              border-radius: 12px; padding: 12px 8px; }
  .uip-time .uip-hhmm { font-size: 21px; font-weight: 800; line-height: 1.15; }
  .uip-time .uip-dd { font-size: 12px; color: var(--slate-200); }
  .uip-show h3 { margin: 0 0 6px; font-size: 18px; }
  .uip-facts { display: flex; gap: 8px; flex-wrap: wrap; }
  .uip-seats-ok { background: #d1fae5; color: var(--success); }
  .uip-seats-low { background: #fef3c7; color: #b45309; }
  .uip-seats-out { background: #fee2e2; color: var(--danger); }
  .uip-empty { text-align: center; padding: 52px 20px; background: #fff; border: 1px dashed var(--slate-300);
               border-radius: 14px; color: var(--slate-500); }
  @media (max-width: 760px) { .uip-show { grid-template-columns: 1fr; } .uip-time { max-width: 160px; } }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <h1>BÃ¡n vÃ© táº¡i quáº§y</h1>
      <div class="uip-steps">
        <span class="uip-step active"><span class="uip-num">1</span> Chá»n suáº¥t chiáº¿u</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step"><span class="uip-num">2</span> Chá»n gháº¿</span>
        <span class="uip-arrow">â†’</span>
        <span class="uip-step"><span class="uip-num">3</span> Thanh toÃ¡n</span>
      </div>

      <div class="uip-list">
        <c:forEach var="s" items="${showtimeList}">
          <article class="uip-show">
            <div class="uip-time">
              <div class="uip-hhmm">${s.startHourLabel}</div>
              <div class="uip-dd">${s.startDayLabel}</div>
            </div>
            <div>
              <h3><c:out value="${s.title}"/></h3>
              <div class="uip-facts">
                <span class="chip">ðŸŽ¬ <c:out value="${s.roomName}"/></span>
                <span class="chip">ðŸ•’ <c:out value="${s.timeRangeLabel}"/></span>
                <c:choose>
                  <c:when test="${s.availableSeats == 0}"><span class="chip uip-seats-out">Háº¿t gháº¿</span></c:when>
                  <c:when test="${s.availableSeats <= 10}"><span class="chip uip-seats-low">Sáº¯p háº¿t Â· cÃ²n ${s.availableSeats} gháº¿</span></c:when>
                  <c:otherwise><span class="chip uip-seats-ok">CÃ²n ${s.availableSeats} gháº¿ trá»‘ng</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div>
              <c:choose>
                <c:when test="${s.availableSeats > 0}">
                  <a class="btn btn-cta" href="${ctx}/staff/counter?action=seats&showtimeId=${s.showtimeId}">Chá»n gháº¿ â†’</a>
                </c:when>
                <c:otherwise><span class="badge">Háº¿t gháº¿</span></c:otherwise>
              </c:choose>
            </div>
          </article>
        </c:forEach>
      </div>
      <c:if test="${empty showtimeList}"><div class="uip-empty">ðŸŽ¬<br>KhÃ´ng cÃ³ suáº¥t chiáº¿u nÃ o sáº¯p diá»…n ra.</div></c:if>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>


