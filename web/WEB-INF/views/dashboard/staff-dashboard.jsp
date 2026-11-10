<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Tổng quan"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div>
    <span class="eyebrow">Ca làm việc hôm nay</span>
    <h1 class="mt-8">Xin chào, <c:out value="${me.fullName}"/></h1>
    <p>Bán vé tại quầy, soát vé ở cửa phòng chiếu và theo dõi tồn kho combo.</p>
  </div>
  <div class="cluster">
    <a class="btn" href="${ctx}/staff/checkin">${ic.scan}Soát vé</a>
    <a class="btn btn-primary" href="${ctx}/staff/counter">${ic.store}Bán vé tại quầy</a>
  </div>
</div>

<c:if test="${not empty statsError}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${statsError}"/></span></div></c:if>

<c:if test="${not empty stats}">
  <section class="stats">
    <div class="stat featured">
      <div class="stat-icon">${ic.wallet}</div>
      <div class="stat-label">Doanh thu tại quầy hôm nay</div>
      <div class="stat-value money"><fmt:formatNumber value="${stats.counter_revenue}" groupingUsed="true"/> đ</div>
      <div class="stat-meta"><c:out value="${stats.counter_tickets}"/> vé đã bán tại quầy</div>
    </div>
    <div class="stat">
      <div class="stat-icon accent">${ic.calendar}</div>
      <div class="stat-label">Suất chiếu còn lại hôm nay</div>
      <div class="stat-value"><c:out value="${stats.showtimes_left}"/></div>
      <div class="stat-meta">tính từ bây giờ</div>
    </div>
    <div class="stat">
      <div class="stat-icon success">${ic.scan}</div>
      <div class="stat-label">Vé đã soát hôm nay</div>
      <div class="stat-value"><c:out value="${stats.checked_in}"/></div>
      <div class="stat-meta"><a href="${ctx}/staff/checkin">Mở trang soát vé →</a></div>
    </div>
  </section>

  <div class="grid grid-2 mt-24">
    <section class="card">
      <div class="card-head"><div><h2>Vé đã bán theo suất hôm nay</h2><p>Các suất còn lại trong ngày</p></div></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${empty showtimeSales}"><div class="empty" style="padding:24px"><div class="empty-icon">${ic.calendar}</div><p>Hôm nay không còn suất chiếu nào.</p></div></c:when>
          <c:otherwise>
            <div class="bar-list">
              <c:forEach var="bar" items="${showtimeSales}">
                <div class="bar-row" style="grid-template-columns:minmax(0,1.4fr) 1fr 36px">
                  <span class="truncate" title="${bar.label}"><c:out value="${bar.label}"/></span>
                  <div class="bar-track"><div class="bar-fill" style="width:${bar.percent}%;background:var(--brand-600)"></div></div>
                  <strong><c:out value="${bar.value}"/></strong>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </section>
    <section class="card">
      <div class="card-head"><div><h2>Tồn kho combo</h2><p>Dưới 10 phần sẽ được tô đỏ</p></div><a class="btn btn-sm btn-ghost" href="${ctx}/staff/combo">Quản lý ${ic.arrowRight}</a></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${empty comboStock}"><div class="empty" style="padding:24px"><div class="empty-icon">${ic.popcorn}</div><p>Chưa có combo đang bán.</p></div></c:when>
          <c:otherwise>
            <div class="bar-list">
              <c:forEach var="bar" items="${comboStock}">
                <div class="bar-row" style="grid-template-columns:minmax(0,1.4fr) 1fr 36px">
                  <span class="truncate" title="${bar.label}"><c:out value="${bar.label}"/></span>
                  <div class="bar-track"><div class="bar-fill" style="width:${bar.percent}%;background:${bar.value <= 10 ? 'var(--danger)' : 'var(--success)'}"></div></div>
                  <strong class="${bar.value <= 10 ? 'text-danger' : ''}"><c:out value="${bar.value}"/></strong>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </section>
  </div>
</c:if>

<h2 class="mt-32 mb-16" style="font-size:var(--fs-h4)">Lối tắt</h2>
<div class="shortcuts">
  <a class="shortcut" href="${ctx}/staff/counter"><span class="stat-icon">${ic.store}</span><div><strong>Bán vé tại quầy</strong><span>Chọn suất, ghế, combo và thu tiền</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/staff/checkin"><span class="stat-icon success">${ic.scan}</span><div><strong>Soát vé</strong><span>Nhập mã hoặc quét QR</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/staff/seat-change"><span class="stat-icon accent">${ic.swap}</span><div><strong>Đổi ghế</strong><span>Đổi ghế cho vé đã bán</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/staff/combo"><span class="stat-icon">${ic.popcorn}</span><div><strong>Quản lý combo</strong><span>Giá, tồn kho, trạng thái</span></div>${ic.chevronRight}</a>
</div>
<%@ include file="../layout/bottom.jspf" %>
