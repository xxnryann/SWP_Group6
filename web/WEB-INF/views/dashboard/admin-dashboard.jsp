<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Dashboard - Quản trị"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <h1>Dashboard Quản trị viên</h1>
    <p>Quản lý người dùng, quyền hạn, và hệ thống.</p>

    <c:if test="${not empty statsError}">
      <div class="dashboard-empty"><p><c:out value="${statsError}"/></p></div>
    </c:if>

    <c:if test="${not empty stats}">
      <section class="admin-kpis">
        <div class="admin-kpi admin-kpi-main">
          <span>Doanh thu</span>
          <strong><fmt:formatNumber value="${stats.revenue}" groupingUsed="true"/> đ</strong>
          <small><c:out value="${stats.bookings_paid}"/> đơn đã thanh toán</small>
        </div>
        <div class="admin-kpi">
          <span>Tổng tài khoản</span>
          <strong><c:out value="${stats.users_total}"/></strong>
          <small><c:out value="${stats.customers}"/> khách · <c:out value="${stats.staff_accounts}"/> nhân sự · <c:out value="${stats.blocked}"/> bị khóa</small>
        </div>
        <div class="admin-kpi">
          <span>Phim đang/sắp chiếu</span>
          <strong><c:out value="${stats.movies_active}"/></strong>
          <small><c:out value="${stats.showtimes_upcoming}"/> suất chiếu sắp tới</small>
        </div>
        <div class="admin-kpi">
          <span>Phòng chiếu</span>
          <strong><c:out value="${stats.rooms}"/></strong>
          <small><c:out value="${stats.seats}"/> ghế</small>
        </div>
      </section>

      <section class="admin-charts">
        <div class="admin-card">
          <h2>Suất chiếu 14 ngày tới</h2>
          <div class="col-chart">
            <c:forEach var="bar" items="${showtimeBars}">
              <div class="col-chart-item" title="${bar.label}: ${bar.value} suất">
                <span class="col-chart-value"><c:out value="${bar.value}"/></span>
                <div class="col-chart-track"><div class="col-chart-fill" style="height:${bar.percent}%"></div></div>
                <span class="col-chart-label"><c:out value="${bar.label}"/></span>
              </div>
            </c:forEach>
          </div>
        </div>
        <div class="admin-card">
          <h2>Tài khoản theo vai trò</h2>
          <div class="bar-chart">
            <c:forEach var="bar" items="${roleBars}">
              <div class="bar-chart-row">
                <span class="bar-chart-label"><c:out value="${bar.label}"/></span>
                <div class="bar-chart-track"><div class="bar-chart-fill" style="width:${bar.percent}%"></div></div>
                <strong class="bar-chart-value"><c:out value="${bar.value}"/></strong>
              </div>
            </c:forEach>
          </div>
        </div>
      </section>
    </c:if>
  </div>
</main>
<%@ include file="../_footer.jspf" %>
