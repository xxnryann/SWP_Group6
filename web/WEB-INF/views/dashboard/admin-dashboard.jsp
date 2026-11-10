<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Tổng quan"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div>
    <span class="eyebrow">Quản trị hệ thống</span>
    <h1 class="mt-8">Xin chào, <c:out value="${me.fullName}"/></h1>
    <p>Tình hình hoạt động của rạp: doanh thu, tài khoản, phòng chiếu và lịch chiếu sắp tới.</p>
  </div>
  <div class="cluster">
    <a class="btn" href="${ctx}/admin/system?tab=backup">${ic.database}Sao lưu dữ liệu</a>
    <a class="btn btn-primary" href="${ctx}/admin/rooms">${ic.door}Quản lý phòng chiếu</a>
  </div>
</div>

<c:if test="${not empty statsError}">
  <div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${statsError}"/></span></div>
</c:if>

<c:if test="${not empty stats}">
  <section class="stats" aria-label="Số liệu chính">
    <div class="stat featured">
      <div class="stat-icon">${ic.wallet}</div>
      <div class="stat-label">Doanh thu</div>
      <div class="stat-value money"><fmt:formatNumber value="${stats.revenue}" groupingUsed="true"/> đ</div>
      <div class="stat-meta"><c:out value="${stats.bookings_paid}"/> đơn đã thanh toán</div>
    </div>
    <div class="stat">
      <div class="stat-icon">${ic.users}</div>
      <div class="stat-label">Tổng tài khoản</div>
      <div class="stat-value"><c:out value="${stats.users_total}"/></div>
      <div class="stat-meta"><c:out value="${stats.customers}"/> khách · <c:out value="${stats.staff_accounts}"/> nhân sự · <c:out value="${stats.blocked}"/> bị khóa</div>
    </div>
    <div class="stat">
      <div class="stat-icon accent">${ic.film}</div>
      <div class="stat-label">Phim đang / sắp chiếu</div>
      <div class="stat-value"><c:out value="${stats.movies_active}"/></div>
      <div class="stat-meta"><c:out value="${stats.showtimes_upcoming}"/> suất chiếu sắp tới</div>
    </div>
    <div class="stat">
      <div class="stat-icon success">${ic.door}</div>
      <div class="stat-label">Phòng chiếu</div>
      <div class="stat-value"><c:out value="${stats.rooms}"/></div>
      <div class="stat-meta"><c:out value="${stats.seats}"/> ghế</div>
    </div>
  </section>

  <div class="split mt-24" style="grid-template-columns:minmax(0,1.6fr) minmax(0,1fr)">
    <section class="card">
      <div class="card-head">
        <div><h2>Suất chiếu 14 ngày tới</h2><p>Số suất đã lên lịch theo từng ngày</p></div>
        <a class="btn btn-sm btn-ghost" href="${ctx}/admin/room-showtimes">Xem lịch phòng ${ic.arrowRight}</a>
      </div>
      <div class="card-body">
        <div class="col-chart" role="img" aria-label="Biểu đồ số suất chiếu 14 ngày tới">
          <c:forEach var="bar" items="${showtimeBars}">
            <div class="col-chart-item" title="${bar.label}: ${bar.value} suất">
              <span class="col-chart-value"><c:out value="${bar.value}"/></span>
              <div class="col-chart-track"><div class="col-chart-fill" style="height:${bar.percent}%"></div></div>
              <span class="col-chart-label"><c:out value="${bar.label}"/></span>
            </div>
          </c:forEach>
        </div>
      </div>
    </section>
    <section class="card">
      <div class="card-head"><div><h2>Tài khoản theo vai trò</h2><p>Phân bổ người dùng hiện có</p></div></div>
      <div class="card-body">
        <div class="bar-list">
          <c:forEach var="bar" items="${roleBars}">
            <div class="bar-row">
              <span><c:out value="${bar.label}"/></span>
              <div class="bar-track"><div class="bar-fill" style="width:${bar.percent}%"></div></div>
              <strong><c:out value="${bar.value}"/></strong>
            </div>
          </c:forEach>
        </div>
        <a class="btn btn-soft btn-block mt-24" href="${ctx}/admin/users">${ic.users}Quản lý người dùng</a>
      </div>
    </section>
  </div>
</c:if>

<h2 class="mt-32 mb-16" style="font-size:var(--fs-h4)">Lối tắt</h2>
<div class="shortcuts">
  <a class="shortcut" href="${ctx}/admin/users"><span class="stat-icon">${ic.users}</span><div><strong>Người dùng</strong><span>Khóa, mở khóa, đặt lại mật khẩu</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/admin/rooms"><span class="stat-icon success">${ic.door}</span><div><strong>Phòng chiếu</strong><span>Thêm phòng, sơ đồ ghế</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/admin/room-showtimes"><span class="stat-icon accent">${ic.calendar}</span><div><strong>Lịch phòng chiếu</strong><span>Suất chiếu theo từng phòng</span></div>${ic.chevronRight}</a>
  <a class="shortcut" href="${ctx}/admin/system?tab=logs"><span class="stat-icon">${ic.list}</span><div><strong>Nhật ký hệ thống</strong><span>Lịch sử thao tác quản trị</span></div>${ic.chevronRight}</a>
</div>
<%@ include file="../layout/bottom.jspf" %>
