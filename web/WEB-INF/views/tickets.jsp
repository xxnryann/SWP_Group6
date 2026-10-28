﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Lá»‹ch sá»­ vÃ©"/>
<c:set var="parentTitle" value="TÃ i khoáº£n"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="tickets"/>
<%@ include file="_header.jspf" %>
<style>
  /* ---------- vÃ© dáº¡ng tháº» (má»—i vÃ© 1 tháº» + 1 mÃ£ QR) ---------- */
  .tk-list { display: flex; flex-direction: column; gap: 16px; margin-top: 4px; }

  .tk-card {
    display: grid; grid-template-columns: 1fr 260px;
    background: var(--navy); color: #fff;
    border-radius: 14px; overflow: hidden;
    box-shadow: var(--shadow);
  }
  .tk-left { padding: 22px 26px; }

  .tk-head { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; margin-bottom: 6px; }
  .tk-head h3 { color: #fff; font-size: 19px; margin: 0; }
  .tk-badge { padding: 3px 11px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .tk-badge.st-active { background: rgba(16,185,129,.22); color: #34d399; }
  .tk-badge.st-used { background: rgba(56,189,248,.22); color: #7dd3fc; }
  .tk-badge.st-expired { background: rgba(148,163,184,.22); color: #cbd5e1; }
  .tk-badge.st-cancelled { background: rgba(220,38,38,.22); color: #fca5a5; }

  .tk-rows { margin-top: 14px; }
  .tk-row { display: grid; grid-template-columns: 132px 1fr; gap: 14px;
            padding: 11px 0; border-top: 1px solid rgba(148,163,184,.18); }
  .tk-row:first-child { border-top: 0; }
  .tk-row .tk-label { color: var(--slate-400); font-size: 14px; font-weight: 600; }
  .tk-row .tk-value { color: #fff; font-size: 14.5px; }
  .tk-row .tk-value.muted { color: var(--slate-300); }
  .tk-seat { font-weight: 800; font-size: 16px; }

  .tk-actions { margin-top: 18px; }
  .tk-cancel { background: #ef4444; color: #fff; border: 0; border-radius: 999px;
               padding: 9px 22px; font: 700 14px var(--font); cursor: pointer; }
  .tk-cancel:hover { background: #dc2626; }
  .tk-cancel[disabled] { opacity: .45; cursor: not-allowed; }
  .tk-note { margin-top: 10px; color: var(--slate-400); font-size: 13px; }

  /* ---------- cá»™t QR ---------- */
  .tk-right { background: #fff; color: var(--navy);
              padding: 22px; display: flex; flex-direction: column;
              align-items: center; justify-content: center; gap: 8px;
              border-left: 2px dashed rgba(148,163,184,.55); }
  .tk-right .tk-qr-title { font-size: 12px; letter-spacing: .1em; color: var(--slate-500);
                            font-weight: 700; text-transform: uppercase; }
  .tk-right img { width: 190px; height: 190px; display: block; }
  .tk-right .tk-code { font-family: ui-monospace, Consolas, monospace;
                        font-weight: 800; font-size: 17px; letter-spacing: .04em;
                        color: var(--navy); text-align: center; word-break: break-all; }
  .tk-right .tk-seat-mini { color: var(--slate-500); font-size: 13.5px; font-weight: 600; }
  .tk-right .tk-muted { color: var(--slate-400); font-size: 12.5px; text-align: center; }

  /* VÃ© háº¿t háº¡n / Ä‘Ã£ huá»· -> lÃ m má» QR (khÃ´ng dÃ¹ng Ä‘á»ƒ soÃ¡t vÃ© ná»¯a) */
  .tk-card.is-inactive .tk-right img { opacity: .22; filter: grayscale(1); }
  .tk-card.is-inactive .tk-left { opacity: .78; }

  .tk-empty { text-align: center; padding: 48px 20px; }
  .tk-empty p { color: var(--slate-500); }

  @media (max-width: 860px) {
    .tk-card { grid-template-columns: 1fr; }
    .tk-right { border-left: 0; border-top: 2px dashed rgba(148,163,184,.55); }
    .tk-row { grid-template-columns: 110px 1fr; }
  }
</style>
<main class="page"><div class="container">
  <div class="account-grid">
    <section class="panel">
      <h2>Lá»‹ch sá»­ vÃ©</h2>
      <p class="sub">CÃ¡c vÃ© báº¡n Ä‘Ã£ Ä‘áº·t. Má»—i vÃ© cÃ³ má»™t mÃ£ QR riÃªng Ä‘á»ƒ check-in táº¡i ráº¡p.</p>
      <c:choose>
        <c:when test="${empty tickets}">
          <div class="tk-empty">
            <p>Báº¡n chÆ°a cÃ³ vÃ© nÃ o.</p>
            <a class="btn btn-cta" href="${pageContext.request.contextPath}/showtimes">Äáº·t vÃ© ngay</a>
          </div>
        </c:when>
        <c:otherwise>
          <div class="tk-list">
          <c:forEach var="t" items="${tickets}">
            <%-- is-inactive: vÃ© khÃ´ng cÃ²n hiá»‡u lá»±c -> má» QR, khÃ´ng hiá»‡n nÃºt Huá»· --%>
            <article class="tk-card ${t.active ? '' : 'is-inactive'}">
              <div class="tk-left">
                <div class="tk-head">
                  <h3><c:out value="${t.movieTitle}"/></h3>
                  <span class="tk-badge ${t.statusCss}"><c:out value="${t.statusLabel}"/></span>
                </div>

                <div class="tk-rows">
                  <div class="tk-row">
                    <span class="tk-label">Gháº¿</span>
                    <span class="tk-value tk-seat"><c:out value="${t.seatDisplay}"/></span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">PhÃ²ng / Ráº¡p</span>
                    <span class="tk-value muted">
                      <c:out value="${t.roomName}"/> â€” <c:out value="${t.cinemaName}"/>
                    </span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">Suáº¥t chiáº¿u</span>
                    <span class="tk-value muted"><c:out value="${t.showTimeLabel}"/></span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">GiÃ¡</span>
                    <span class="tk-value"><c:out value="${t.priceLabel}"/></span>
                  </div>
                </div>

                <div class="tk-actions">
                  <c:choose>
                    <c:when test="${t.canCancel}">
                      <form method="post" action="${pageContext.request.contextPath}/account/tickets"
                            onsubmit="return confirm('Huá»· vÃ© ${t.seatDisplay}? Tiá»n vÃ© sáº½ Ä‘Æ°á»£c hoÃ n láº¡i.');">
                        <input type="hidden" name="_csrf" value="${csrf}">
                        <input type="hidden" name="action" value="cancel">
                        <input type="hidden" name="ticketId" value="${t.ticketId}">
                        <button class="tk-cancel" type="submit">Huá»· vÃ©</button>
                      </form>
                    </c:when>
                    <c:when test="${t.active}">
                      <%-- CÃ²n hiá»‡u lá»±c nhÆ°ng Ä‘Ã£ quÃ¡ thá»i háº¡n huá»· -> khÃ´ng cho huá»· --%>
                      <button class="tk-cancel" type="button" disabled>Huá»· vÃ©</button>
                      <p class="tk-note">ÄÃ£ quÃ¡ thá»i háº¡n cho phÃ©p huá»· vÃ©. Vui lÃ²ng liÃªn há»‡ ráº¡p Ä‘á»ƒ Ä‘Æ°á»£c há»— trá»£.</p>
                    </c:when>
                    <c:when test="${t.expired}">
                      <p class="tk-note">VÃ© Ä‘Ã£ quÃ¡ thá»i gian chiáº¿u nÃªn khÃ´ng cÃ²n hiá»‡u lá»±c.</p>
                    </c:when>
                    <c:when test="${t.used}">
                      <p class="tk-note">VÃ© Ä‘Ã£ Ä‘Æ°á»£c soÃ¡t vÃ© táº¡i ráº¡p.</p>
                    </c:when>
                    <c:otherwise>
                      <p class="tk-note">VÃ© Ä‘Ã£ Ä‘Æ°á»£c huá»·.</p>
                    </c:otherwise>
                  </c:choose>
                </div>
              </div>

              <div class="tk-right">
                <span class="tk-qr-title">MÃ£ vÃ©</span>
                <img src="${pageContext.request.contextPath}/account/tickets/qr?ticketId=${t.ticketId}"
                     alt="MÃ£ QR vÃ© <c:out value='${t.ticketCode}'/>" loading="lazy">
                <span class="tk-code"><c:out value="${t.ticketCode}"/></span>
                <span class="tk-seat-mini">Gháº¿ <c:out value="${t.seatDisplay}"/></span>
                <c:choose>
                  <c:when test="${t.active}">
                    <span class="tk-muted">ÄÆ°a mÃ£ nÃ y cho nhÃ¢n viÃªn Ä‘á»ƒ vÃ o ráº¡p</span>
                  </c:when>
                  <c:otherwise>
                    <span class="tk-muted">MÃ£ khÃ´ng cÃ²n dÃ¹ng Ä‘á»ƒ soÃ¡t vÃ©</span>
                  </c:otherwise>
                </c:choose>
              </div>
            </article>
          </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>



