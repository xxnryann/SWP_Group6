<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Chi tiết doanh thu"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div>
    <h1>Chi tiết doanh thu</h1>
    <p>Các đơn đã thanh toán tạo nên doanh thu: tài khoản nào, mua lúc nào, gồm những khoản gì. Đơn bị hủy và đã hoàn điểm không được tính.</p>
  </div>
  <div class="cluster">
    <a class="btn" href="${ctx}${roleDashboardPath}?${rf.query}">${ic.chevronLeft}Về tổng quan</a>
  </div>
</div>

<c:if test="${not empty statsError}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${statsError}"/></span></div></c:if>

<c:set var="revenueFilterAction" value="${ctx}/dashboard/revenue"/>
<%@ include file="_revenue_filter.jspf" %>

<c:if test="${not empty revenue}">
  <section class="stats mb-24" aria-label="Tổng hợp doanh thu">
    <div class="stat featured">
      <div class="stat-icon">${ic.wallet}</div>
      <div class="stat-label">Doanh thu · <c:out value="${rf.typeLabel}"/></div>
      <div class="stat-value money"><fmt:formatNumber value="${revenue.revenue}" groupingUsed="true"/> đ</div>
      <div class="stat-meta"><c:out value="${rf.typeNote}"/></div>
    </div>
    <div class="stat">
      <div class="stat-icon">${ic.ticket}</div>
      <div class="stat-label">Tiền vé phim</div>
      <div class="stat-value money"><fmt:formatNumber value="${revenue.ticket_total}" groupingUsed="true"/> đ</div>
      <div class="stat-meta"><c:out value="${revenue.tickets}"/> vé · <c:out value="${revenue.bookings}"/> đơn</div>
    </div>
    <div class="stat">
      <div class="stat-icon accent">${ic.popcorn}</div>
      <div class="stat-label">Bỏng nước</div>
      <div class="stat-value money"><fmt:formatNumber value="${revenue.combo_total}" groupingUsed="true"/> đ</div>
      <div class="stat-meta">Giá gốc combo đã bán</div>
    </div>
    <div class="stat">
      <div class="stat-icon danger">${ic.tag}</div>
      <div class="stat-label">Giảm giá</div>
      <div class="stat-value money">−<fmt:formatNumber value="${revenue.voucher_total + revenue.points_total}" groupingUsed="true"/> đ</div>
      <div class="stat-meta">Voucher −<fmt:formatNumber value="${revenue.voucher_total}" groupingUsed="true"/> đ · MyPoint −<fmt:formatNumber value="${revenue.points_total}" groupingUsed="true"/> đ</div>
    </div>
    <div class="stat">
      <div class="stat-icon success">${ic.coins}</div>
      <div class="stat-label">Thực thu</div>
      <div class="stat-value money"><fmt:formatNumber value="${revenue.actual_total}" groupingUsed="true"/> đ</div>
      <div class="stat-meta">Tiền khách thực trả</div>
    </div>
  </section>
</c:if>

<section class="card">
  <div class="card-head">
    <div>
      <h2>Lịch sử đơn</h2>
      <p><c:out value="${rf.periodLabel}"/> · <c:out value="${rf.typeLabel}"/><c:if test="${not empty rf.channel}"> · <c:out value="${rf.channel == 'Counter' ? 'Tại quầy' : 'Online'}"/></c:if></p>
    </div>
    <span class="badge"><c:out value="${rows.size()}"/> đơn</span>
  </div>
  <c:choose>
    <c:when test="${empty rows}">
      <div class="empty">
        <div class="empty-icon">${ic.wallet}</div>
        <h3>Chưa có đơn nào</h3>
        <p>Không có đơn đã thanh toán khớp bộ lọc. Thử nới khoảng ngày hoặc đổi loại doanh thu.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="table-wrap">
        <table class="table">
          <thead>
            <tr>
              <th>Đơn · thanh toán lúc</th>
              <th>Tài khoản</th>
              <th>Phim · suất chiếu</th>
              <th class="num">Vé</th>
              <th class="num">Bỏng nước</th>
              <th class="num">Giảm giá</th>
              <th class="num">Thực thu</th>
              <c:if test="${rf.type != 'actual'}"><th class="num" title="Số tiền của đơn được tính theo loại doanh thu đang lọc">Doanh thu</th></c:if>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="r" items="${rows}">
              <tr>
                <td class="nowrap"><strong class="text-ink"><c:out value="${r.bookingCode}"/></strong>
                  <span class="cell-sub"><c:out value="${r.paidAtDisplay}"/></span>
                  <span class="cell-sub"><c:choose><c:when test="${r.counter}"><span class="badge badge-accent">${ic.store}Tại quầy</span></c:when><c:otherwise><span class="badge badge-info">${ic.globe}Online</span></c:otherwise></c:choose></span></td>
                <td>
                  <c:choose>
                    <c:when test="${not empty r.customerName}">
                      <span class="cell-main"><c:out value="${r.customerName}"/></span>
                      <span class="cell-sub"><c:out value="${r.customerEmail}"/></span>
                    </c:when>
                    <c:otherwise><span class="cell-main">Khách vãng lai</span></c:otherwise>
                  </c:choose>
                  <c:if test="${not empty r.staffName}"><span class="cell-sub">NV bán: <c:out value="${r.staffName}"/></span></c:if>
                </td>
                <td>
                  <span class="cell-main"><c:out value="${r.movieTitle}"/></span>
                  <span class="cell-sub"><c:out value="${r.roomName}"/> · <c:out value="${r.showStartDisplay}"/></span>
                </td>
                <td class="num nowrap"><fmt:formatNumber value="${r.ticketTotal}" groupingUsed="true"/> đ<span class="cell-sub"><c:out value="${r.ticketCount}"/> vé</span></td>
                <td class="num nowrap"><c:choose><c:when test="${r.comboTotal > 0}"><fmt:formatNumber value="${r.comboTotal}" groupingUsed="true"/> đ</c:when><c:otherwise><span class="muted">—</span></c:otherwise></c:choose></td>
                <td class="num nowrap">
                  <c:choose>
                    <c:when test="${r.voucherDiscount == 0 and r.pointsDiscount == 0}"><span class="muted">—</span></c:when>
                    <c:otherwise>−<fmt:formatNumber value="${r.voucherDiscount + r.pointsDiscount}" groupingUsed="true"/> đ</c:otherwise>
                  </c:choose>
                  <c:if test="${r.voucherDiscount > 0}"><span class="cell-sub" title="Voucher −${r.voucherDiscount} đ"><c:out value="${r.voucherCode}"/></span></c:if>
                  <c:if test="${r.pointsDiscount > 0}"><span class="cell-sub" title="MyPoint −${r.pointsDiscount} đ">MyPoint <c:out value="${r.pointsUsed}"/> điểm</span></c:if>
                </td>
                <td class="num nowrap"><strong class="text-ink"><fmt:formatNumber value="${r.totalAmount}" groupingUsed="true"/> đ</strong></td>
                <c:if test="${rf.type != 'actual'}"><td class="num nowrap"><strong class="text-ink"><fmt:formatNumber value="${r.amount}" groupingUsed="true"/> đ</strong></td></c:if>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
      <c:if test="${rows.size() >= maxRows}">
        <div class="card-body"><p class="muted text-sm">Chỉ hiển thị <c:out value="${maxRows}"/> đơn mới nhất; số tổng ở trên vẫn tính đủ. Thu hẹp khoảng ngày để xem các đơn cũ hơn.</p></div>
      </c:if>
    </c:otherwise>
  </c:choose>
</section>
<%@ include file="../layout/bottom.jspf" %>
