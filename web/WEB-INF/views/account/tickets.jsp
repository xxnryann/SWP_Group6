<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Lịch sử vé"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="tickets"/>
<%@ include file="../_header.jspf" %>
<style>
  /* ---------- vé dạng thẻ (mỗi vé 1 thẻ + 1 mã QR) ---------- */
  .tk-list { display: flex; flex-direction: column; gap: 16px; margin-top: 4px; }

  .tk-card {
    display: grid; grid-template-columns: 1fr 260px;
    background: var(--surface); color: var(--text);
    border: 1px solid var(--line); border-radius: 14px; overflow: hidden;
    box-shadow: var(--shadow);
  }
  .tk-left { padding: 22px 26px; }

  .tk-head { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; margin-bottom: 6px; }
  .tk-head h3 { color: var(--ink); font-size: 19px; margin: 0; }
  .tk-badge { padding: 3px 11px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .tk-badge.st-active { background: rgba(16,185,129,.22); color: var(--success); }
  .tk-badge.st-used { background: rgba(56,189,248,.22); color: var(--brand); }
  .tk-badge.st-expired { background: rgba(148,163,184,.22); color: var(--muted); }
  .tk-badge.st-cancelled { background: rgba(220,38,38,.22); color: var(--danger); }

  .tk-rows { margin-top: 14px; }
  .tk-row { display: grid; grid-template-columns: 132px 1fr; gap: 14px;
            padding: 11px 0; border-top: 1px solid var(--line); }
  .tk-row:first-child { border-top: 0; }
  .tk-row .tk-label { color: var(--muted); font-size: 15px; font-weight: 600; }
  .tk-row .tk-value { color: var(--ink); font-size: 15px; }
  .tk-row .tk-value.muted { color: var(--muted); }
  .tk-seat { font-weight: 800; font-size: 16px; }

  .tk-actions { margin-top: 18px; }
  .tk-cancel { background: var(--danger); color: #fff; border: 0; border-radius: 999px;
               padding: 9px 22px; font: 700 14px var(--font); cursor: pointer; }
  .tk-cancel:hover { background: #991b1b; }
  .tk-cancel[disabled] { opacity: .45; cursor: not-allowed; }
  .tk-note { margin-top: 10px; color: var(--muted); font-size: 14px; }

  /* ---------- cột QR ---------- */
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

  /* Vé hết hạn / đã huỷ -> làm mờ QR (không dùng để soát vé nữa) */
  .tk-card.is-inactive .tk-right img { opacity: .22; filter: grayscale(1); }
  .tk-card.is-inactive .tk-left { opacity: .78; }

  /* ---------- tab Lịch sử vé / Combo của tôi ---------- */
  .tk-tabs { display: flex; gap: 8px; margin: 14px 0 18px; border-bottom: 2px solid var(--slate-200, #e2e8f0); }
  .tk-tab { padding: 10px 20px; font-weight: 700; font-size: 15px; color: var(--slate-500);
            text-decoration: none; border-bottom: 3px solid transparent; margin-bottom: -2px; }
  .tk-tab:hover { color: var(--navy); }
  .tk-tab.is-active { color: var(--brand); border-bottom-color: var(--brand); }

  .cb-card { background: var(--surface); color: var(--text); border: 1px solid var(--line); border-radius: 14px; padding: 22px 26px;
             box-shadow: var(--shadow); }
  .cb-card.is-inactive { opacity: .78; }
  .cb-lines { margin: 14px 0 0; padding: 0; list-style: none; }
  .cb-lines li { display: grid; grid-template-columns: 1fr 70px 110px 120px; gap: 12px;
                 padding: 10px 0; border-top: 1px solid var(--line); font-size: 14.5px; }
  .cb-lines li:first-child { border-top: 0; }
  .cb-lines .cb-sub { text-align: right; }
  .cb-total { display: flex; justify-content: space-between; margin-top: 8px; padding-top: 12px;
              border-top: 1px dashed rgba(148,163,184,.4); font-weight: 800; font-size: 16px; }
  @media (max-width: 860px) { .cb-lines li { grid-template-columns: 1fr 50px 90px; } .cb-lines .cb-unit { display: none; } }

  .tk-pager { display: flex; flex-wrap: wrap; gap: 7px; justify-content: center; margin-top: 22px; }
  .tk-pager a { min-width: 36px; padding: 7px 10px; border: 1px solid var(--line); border-radius: 8px; text-align: center;
                color: var(--ink); text-decoration: none; font-weight: 700; font-size: 14px; }
  .tk-pager a.is-active { background: var(--brand); border-color: var(--brand); color: #fff; }

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
      <h2>Lịch sử vé</h2>
      <nav class="tk-tabs" aria-label="Lịch sử">
        <a class="tk-tab ${tab == 'combos' ? '' : 'is-active'}" href="${pageContext.request.contextPath}/account/tickets">Lịch sử vé</a>
        <a class="tk-tab ${tab == 'combos' ? 'is-active' : ''}" href="${pageContext.request.contextPath}/account/tickets?tab=combos">Combo của tôi</a>
      </nav>
      <c:choose>
        <c:when test="${tab == 'combos'}">
          <c:choose>
            <c:when test="${empty comboOrders}">
              <div class="tk-empty"><p>Bạn chưa mua combo nào.</p></div>
            </c:when>
            <c:otherwise>
              <div class="tk-list">
                <c:forEach var="o" items="${comboOrders}">
                  <article class="cb-card ${o.cancelled ? 'is-inactive' : ''}">
                    <div class="tk-head">
                      <h3><c:out value="${o.movieTitle}"/></h3>
                      <span class="tk-badge ${o.statusCss}"><c:out value="${o.statusLabel}"/></span>
                    </div>
                    <p class="tk-note">Đơn <c:out value="${o.bookingCode}"/> · <c:out value="${o.roomName}"/> — <c:out value="${o.cinemaName}"/>
                      · Suất <c:out value="${o.showTimeLabel}"/> · Mua lúc <c:out value="${o.purchasedLabel}"/></p>
                    <ul class="cb-lines">
                      <c:forEach var="l" items="${o.lines}">
                        <li>
                          <span><c:out value="${l.name}"/></span>
                          <span>x<c:out value="${l.quantity}"/></span>
                          <span class="cb-unit"><c:out value="${l.unitPriceLabel}"/></span>
                          <span class="cb-sub"><c:out value="${l.subtotalLabel}"/></span>
                        </li>
                      </c:forEach>
                    </ul>
                    <div class="cb-total"><span>Tổng combo</span><span><c:out value="${o.totalLabel}"/></span></div>
                    <c:choose>
                      <c:when test="${o.comboCancelledOnly}"><p class="tk-note">Combo đã được huỷ. Vé của đơn vẫn còn hiệu lực.</p></c:when>
                      <c:when test="${o.cancelled}"><p class="tk-note">Đơn đã được huỷ nên combo không còn hiệu lực.</p></c:when>
                      <c:otherwise><p class="tk-note">Combo đã thanh toán không thể hủy/hoàn tiền. Nếu suất chiếu bị hủy do sự cố, giá trị combo được hoàn thành MyPoint.</p></c:otherwise>
                    </c:choose>
                  </article>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </c:when>
        <c:when test="${empty tickets}">
          <div class="tk-empty">
            <p>Bạn chưa có vé nào.</p>
            <a class="btn btn-cta" href="${pageContext.request.contextPath}/showtimes">Đặt vé ngay</a>
          </div>
        </c:when>
        <c:otherwise>
          <div class="tk-list">
          <c:forEach var="t" items="${tickets}">
            <%-- is-inactive: vé không còn hiệu lực -> mờ QR, không hiện nút Huỷ --%>
            <article class="tk-card ${t.active ? '' : 'is-inactive'}">
              <div class="tk-left">
                <div class="tk-head">
                  <h3><c:out value="${t.movieTitle}"/></h3>
                  <span class="tk-badge ${t.statusCss}"><c:out value="${t.statusLabel}"/></span>
                </div>

                <div class="tk-rows">
                  <div class="tk-row">
                    <span class="tk-label">Ghế</span>
                    <span class="tk-value tk-seat"><c:out value="${t.seatDisplay}"/></span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">Phòng / Rạp</span>
                    <span class="tk-value muted">
                      <c:out value="${t.roomName}"/> — <c:out value="${t.cinemaName}"/>
                    </span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">Suất chiếu</span>
                    <span class="tk-value muted"><c:out value="${t.showTimeLabel}"/></span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">Ngày giờ mua</span>
                    <span class="tk-value muted"><c:out value="${empty t.purchasedLabel ? '—' : t.purchasedLabel}"/></span>
                  </div>
                  <div class="tk-row">
                    <span class="tk-label">Giá</span>
                    <span class="tk-value"><c:out value="${t.priceLabel}"/></span>
                  </div>
                </div>

                <div class="tk-actions">
                  <c:choose>
                    <c:when test="${t.active}">
                      <p class="tk-note">Vé đã thanh toán không thể hủy/đổi trả/hoàn tiền. Nếu suất chiếu bị hủy do sự cố, giá trị vé được hoàn thành MyPoint kèm voucher đền bù.</p>
                    </c:when>
                    <c:when test="${t.expired}">
                      <p class="tk-note">Vé đã quá thời gian chiếu nên không còn hiệu lực.</p>
                    </c:when>
                    <c:when test="${t.used}">
                      <p class="tk-note">Vé đã được soát vé tại rạp.</p>
                      <c:if test="${t.canReview}">
                        <a class="btn btn-cta btn-small" href="${pageContext.request.contextPath}/movies/detail?id=${t.movieId}#reviews">Viết đánh giá</a>
                      </c:if>
                    </c:when>
                    <c:otherwise>
                      <p class="tk-note">Vé đã được huỷ.</p>
                    </c:otherwise>
                  </c:choose>
                </div>
              </div>

              <div class="tk-right">
                <span class="tk-qr-title">Mã vé</span>
                <img src="${pageContext.request.contextPath}/account/tickets/qr?ticketId=${t.ticketId}"
                     alt="Mã QR vé <c:out value='${t.ticketCode}'/>" loading="lazy">
                <span class="tk-code"><c:out value="${t.ticketCode}"/></span>
                <span class="tk-seat-mini">Ghế <c:out value="${t.seatDisplay}"/></span>
                <c:choose>
                  <c:when test="${t.active}">
                    <span class="tk-muted">Đưa mã này cho nhân viên để vào rạp</span>
                  </c:when>
                  <c:otherwise>
                    <span class="tk-muted">Mã không còn dùng để soát vé</span>
                  </c:otherwise>
                </c:choose>
              </div>
            </article>
          </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
      <c:if test="${totalPages > 1}">
        <nav class="tk-pager" aria-label="Phân trang">
          <c:forEach var="n" begin="1" end="${totalPages}">
            <a class="${n == page ? 'is-active' : ''}" href="${pageContext.request.contextPath}/account/tickets?page=${n}${tab == 'combos' ? '&amp;tab=combos' : ''}">${n}</a>
          </c:forEach>
        </nav>
      </c:if>
    </section>
  </div>
</div></main>
<%@ include file="../_footer.jspf" %>


