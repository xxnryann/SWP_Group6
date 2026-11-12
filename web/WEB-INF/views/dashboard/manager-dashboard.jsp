<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Tổng quan"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div>
    <span class="eyebrow">Quản lý rạp</span>
    <h1 class="mt-8">Xin chào, <c:out value="${me.fullName}"/></h1>
    <p>Phim, lịch chiếu, giá vé, voucher và tin tức của rạp trong một màn hình.</p>
  </div>
  <div class="cluster">
    <a class="btn" href="${ctx}/manage/showtimes">${ic.calendar}Lịch chiếu</a>
    <a class="btn btn-primary" href="${ctx}/manage/movies?action=new">${ic.plus}Thêm phim</a>
  </div>
</div>

<c:if test="${not empty statsError}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${statsError}"/></span></div></c:if>

<c:if test="${not empty stats}">
  <c:set var="revenueFilterAction" value="${ctx}/dashboard/manager"/>
  <%@ include file="_revenue_filter.jspf" %>
  <section class="stats">
    <a class="stat featured" href="${ctx}/dashboard/revenue?${rf.query}" title="Xem chi tiết các đơn tạo nên doanh thu">
      <div class="stat-icon">${ic.wallet}</div>
      <div class="stat-label">Doanh thu · <c:out value="${rf.typeLabel}"/></div>
      <div class="stat-value money"><fmt:formatNumber value="${revenue.revenue}" groupingUsed="true"/> đ</div>
      <div class="stat-meta"><c:out value="${revenue.bookings}"/> đơn đã thanh toán · <c:out value="${rf.periodLabel}"/></div>
      <span class="stat-link-hint">Xem chi tiết ${ic.arrowRight}</span>
    </a>
    <div class="stat">
      <div class="stat-icon accent">${ic.film}</div>
      <div class="stat-label">Phim đang chiếu</div>
      <div class="stat-value"><c:out value="${stats.movies_now}"/></div>
      <div class="stat-meta"><c:out value="${stats.movies_upcoming}"/> phim sắp chiếu</div>
    </div>
    <div class="stat">
      <div class="stat-icon">${ic.clock}</div>
      <div class="stat-label">Suất chiếu hôm nay</div>
      <div class="stat-value"><c:out value="${stats.showtimes_today}"/></div>
      <div class="stat-meta">còn lại từ bây giờ</div>
    </div>
    <div class="stat">
      <div class="stat-icon success">${ic.calendar}</div>
      <div class="stat-label">Suất chiếu sắp tới</div>
      <div class="stat-value"><c:out value="${stats.showtimes_upcoming}"/></div>
      <div class="stat-meta"><c:out value="${stats.news_published}"/> tin tức đang đăng</div>
    </div>
  </section>

  <div class="split mt-24" style="grid-template-columns:minmax(0,1.5fr) minmax(0,1fr)">
    <section class="card">
      <div class="card-head"><div><h2>Suất chiếu sắp tới theo phim</h2><p>Phim nào đang được xếp nhiều suất nhất</p></div><a class="btn btn-sm btn-ghost" href="${ctx}/manage/showtimes">Xem lịch ${ic.arrowRight}</a></div>
      <div class="card-body">
        <div class="bar-list">
          <c:forEach var="bar" items="${movieShowtimeBars}">
            <div class="bar-row" style="grid-template-columns:minmax(0,1.3fr) 1fr 40px">
              <span class="truncate" title="${bar.label}"><c:out value="${bar.label}"/></span>
              <div class="bar-track"><div class="bar-fill" style="width:${bar.percent}%;background:var(--brand-600)"></div></div>
              <strong><c:out value="${bar.value}"/></strong>
            </div>
          </c:forEach>
        </div>
      </div>
    </section>
    <section class="card">
      <div class="card-head"><div><h2>Phim theo trạng thái</h2></div></div>
      <div class="card-body">
        <div class="bar-list">
          <c:forEach var="bar" items="${movieStatusBars}">
            <div class="bar-row">
              <span><c:out value="${bar.label}"/></span>
              <div class="bar-track"><div class="bar-fill" style="width:${bar.percent}%"></div></div>
              <strong><c:out value="${bar.value}"/></strong>
            </div>
          </c:forEach>
        </div>
      </div>
    </section>
  </div>
</c:if>

<h2 class="mt-32 mb-16" style="font-size:var(--fs-h4)">Lối tắt</h2>
<div class="shortcuts">
  <a class="shortcut" href="${ctx}/manage/movies"><span class="stat-icon accent">${ic.film}</span><div><strong>Quản lý phim</strong><span>Thêm, sửa, ngừng chiếu</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/manage/showtimes"><span class="stat-icon">${ic.calendar}</span><div><strong>Lịch chiếu</strong><span>Tạo và sinh suất chiếu</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/manager/prices"><span class="stat-icon success">${ic.wallet}</span><div><strong>Giá vé</strong><span>Theo khung giờ và loại ghế</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/manager/vouchers"><span class="stat-icon accent">${ic.tag}</span><div><strong>Voucher</strong><span>Mã giảm giá cho khách</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/manage/reviews"><span class="stat-icon">${ic.message}</span><div><strong>Kiểm duyệt đánh giá</strong><span>Ẩn đánh giá vi phạm</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/manager/news"><span class="stat-icon">${ic.news}</span><div><strong>Tin tức</strong><span>Đăng bài, sự kiện</span></div>${ic.chevronRight}</a>
</div>
<%@ include file="../layout/bottom.jspf" %>
