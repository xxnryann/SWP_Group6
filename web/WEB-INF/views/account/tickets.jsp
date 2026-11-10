<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Vé của tôi"/>
<%@ include file="../layout/top.jspf" %>
<div class="${isStaffRole ? '' : 'container'}">
  <div class="page-head">
    <div><h1>Vé của tôi</h1><p>Vé điện tử có mã QR, dùng để vào phòng chiếu. Hủy vé trước giờ chiếu ít nhất ${cancelHours} giờ để được hoàn tiền.</p></div>
    <a class="btn btn-primary" href="${ctx}/showtimes">${ic.ticket}Đặt vé mới</a>
  </div>
  <%@ include file="../layout/account-nav.jspf" %>

  <nav class="tabs" aria-label="Lịch sử">
    <a class="${tab == 'combos' ? '' : 'active'}" href="${ctx}/account/tickets">Vé xem phim</a>
    <a class="${tab == 'combos' ? 'active' : ''}" href="${ctx}/account/tickets?tab=combos">Combo bắp nước</a>
  </nav>

  <c:choose>
    <c:when test="${tab == 'combos'}">
      <c:choose>
        <c:when test="${empty comboOrders}">
          <div class="card empty"><div class="empty-icon">${ic.popcorn}</div><h3>Bạn chưa mua combo nào</h3><p>Thêm bắp nước ở bước đặt vé để thưởng thức trọn vẹn hơn.</p></div>
        </c:when>
        <c:otherwise>
          <div class="stack">
            <c:forEach var="o" items="${comboOrders}">
              <article class="card card-pad ${o.cancelled ? 'is-inactive' : ''}" style="${o.cancelled ? 'opacity:.8' : ''}">
                <div class="cluster between">
                  <h3 style="font-size:18px"><c:out value="${o.movieTitle}"/></h3>
                  <span class="badge ${o.cancelled ? 'badge-danger' : 'badge-success'} badge-dot"><c:out value="${o.statusLabel}"/></span>
                </div>
                <p class="muted text-sm mt-4">Đơn <strong class="text-ink"><c:out value="${o.bookingCode}"/></strong> · <c:out value="${o.roomName}"/> — <c:out value="${o.cinemaName}"/> · Suất <c:out value="${o.showTimeLabel}"/> · Mua lúc <c:out value="${o.purchasedLabel}"/></p>
                <ul class="combo-lines">
                  <c:forEach var="l" items="${o.lines}">
                    <li><span><c:out value="${l.name}"/></span><span class="muted">x<c:out value="${l.quantity}"/></span><span class="unit muted"><c:out value="${l.unitPriceLabel}"/></span><span class="sub"><c:out value="${l.subtotalLabel}"/></span></li>
                  </c:forEach>
                </ul>
                <div class="kv total"><span>Tổng combo</span><strong><c:out value="${o.totalLabel}"/></strong></div>
                <div class="eticket-foot">
                  <c:choose>
                    <c:when test="${o.comboCancelledOnly}"><span class="note">Combo đã được hủy. Vé của đơn vẫn còn hiệu lực.</span></c:when>
                    <c:when test="${o.cancelled}"><span class="note">Đơn đã được hủy nên combo không còn hiệu lực.</span></c:when>
                    <c:when test="${o.canCancel}">
                      <form method="post" action="${ctx}/account/tickets" data-confirm="Hủy toàn bộ combo của đơn này? Vé của đơn vẫn được giữ nguyên.">
                        <input type="hidden" name="_csrf" value="${csrf}">
                        <input type="hidden" name="action" value="cancelCombo">
                        <input type="hidden" name="bookingId" value="${o.bookingId}">
                        <input type="hidden" name="page" value="${page}">
                        <button class="btn btn-sm btn-danger" type="submit">${ic.x}Hủy combo</button>
                      </form>
                    </c:when>
                    <c:otherwise><span class="note">Đã quá thời hạn hủy combo: phải hủy trước giờ chiếu ít nhất ${cancelHours} giờ.</span></c:otherwise>
                  </c:choose>
                </div>
              </article>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </c:when>

    <c:when test="${empty tickets}">
      <div class="card empty"><div class="empty-icon">${ic.ticket}</div><h3>Bạn chưa có vé nào</h3><p>Chọn một bộ phim và đặt vé chỉ trong vài bước.</p><a class="btn btn-primary mt-8" href="${ctx}/showtimes">Đặt vé ngay</a></div>
    </c:when>

    <c:otherwise>
      <div class="stack" style="--gap:18px">
        <c:forEach var="t" items="${tickets}">
          <article class="eticket ${t.active ? '' : 'is-inactive'}">
            <div class="eticket-main">
              <div class="cluster between">
                <h3><c:out value="${t.movieTitle}"/></h3>
                <c:choose>
                  <c:when test="${t.active}"><span class="badge badge-success badge-dot"><c:out value="${t.statusLabel}"/></span></c:when>
                  <c:when test="${t.used}"><span class="badge badge-brand badge-dot"><c:out value="${t.statusLabel}"/></span></c:when>
                  <c:when test="${t.expired}"><span class="badge badge-dot"><c:out value="${t.statusLabel}"/></span></c:when>
                  <c:otherwise><span class="badge badge-danger badge-dot"><c:out value="${t.statusLabel}"/></span></c:otherwise>
                </c:choose>
              </div>
              <dl class="eticket-facts">
                <div><dt>Ghế</dt><dd class="seat"><c:out value="${t.seatDisplay}"/></dd></div>
                <div><dt>Suất chiếu</dt><dd><c:out value="${t.showTimeLabel}"/></dd></div>
                <div><dt>Giá vé</dt><dd><c:out value="${t.priceLabel}"/></dd></div>
                <div><dt>Phòng</dt><dd><c:out value="${t.roomName}"/></dd></div>
                <div><dt>Rạp</dt><dd><c:out value="${t.cinemaName}"/></dd></div>
                <div><dt>Ngày mua</dt><dd><c:out value="${empty t.purchasedLabel ? '—' : t.purchasedLabel}"/></dd></div>
              </dl>
              <div class="eticket-foot">
                <c:choose>
                  <c:when test="${t.canCancel}">
                    <c:set var="cancelMsg" value="${empty t.pairLabel ? 'Hủy vé '.concat(t.seatDisplay) : 'Đây là ghế đôi: sẽ hủy cả cặp '.concat(t.seatDisplay).concat(' và ').concat(t.pairLabel)}? Tiền vé sẽ được hoàn lại."/>
                    <form method="post" action="${ctx}/account/tickets" data-confirm="<c:out value='${cancelMsg}'/>">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="cancel">
                      <input type="hidden" name="ticketId" value="${t.ticketId}">
                      <input type="hidden" name="page" value="${page}">
                      <button class="btn btn-sm btn-danger" type="submit">${ic.x}Hủy vé</button>
                    </form>
                    <c:if test="${not empty t.pairLabel}"><span class="note">Ghế đôi bán theo cặp: hủy vé này sẽ hủy luôn ghế <c:out value="${t.pairLabel}"/>.</span></c:if>
                  </c:when>
                  <c:when test="${t.active}">
                    <button class="btn btn-sm" type="button" disabled>Hủy vé</button>
                    <span class="note">Đã quá thời hạn hủy (trước giờ chiếu ${cancelHours} giờ). Vui lòng liên hệ rạp để được hỗ trợ.</span>
                  </c:when>
                  <c:when test="${t.expired}"><span class="note">Vé đã quá thời gian chiếu nên không còn hiệu lực.</span></c:when>
                  <c:when test="${t.used}">
                    <span class="note">Vé đã được soát tại rạp.</span>
                    <c:if test="${t.canReview}"><a class="btn btn-sm btn-accent" href="${ctx}/movies/detail?id=${t.movieId}#reviews">${ic.star}Viết đánh giá</a></c:if>
                  </c:when>
                  <c:otherwise><span class="note">Vé đã được hủy.</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="eticket-qr">
              <img src="${ctx}/account/tickets/qr?ticketId=${t.ticketId}" alt="Mã QR vé <c:out value='${t.ticketCode}'/>" loading="lazy">
              <span class="code"><c:out value="${t.ticketCode}"/></span>
              <small>${t.active ? 'Đưa mã này cho nhân viên để vào rạp' : 'Mã không còn dùng để soát vé'}</small>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>

  <c:if test="${totalPages > 1}">
    <nav class="pager" aria-label="Phân trang">
      <c:forEach var="n" begin="1" end="${totalPages}">
        <a class="${n == page ? 'active' : ''}" href="${ctx}/account/tickets?page=${n}${tab == 'combos' ? '&amp;tab=combos' : ''}" ${n == page ? 'aria-current="page"' : ''}>${n}</a>
      </c:forEach>
    </nav>
  </c:if>
</div>
<%@ include file="../layout/bottom.jspf" %>
