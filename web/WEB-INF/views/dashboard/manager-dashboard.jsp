<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Dashboard - Quản lý"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <h1>Dashboard Quản lý rạp</h1>
    <p>Quản lý suất chiếu, phim, và lịch biểu.</p>

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
          <span>Phim đang chiếu</span>
          <strong><c:out value="${stats.movies_now}"/></strong>
          <small><c:out value="${stats.movies_upcoming}"/> phim sắp chiếu</small>
        </div>
        <div class="admin-kpi">
          <span>Suất chiếu hôm nay</span>
          <strong><c:out value="${stats.showtimes_today}"/></strong>
          <small>còn lại từ bây giờ</small>
        </div>
        <div class="admin-kpi">
          <span>Suất chiếu sắp tới</span>
          <strong><c:out value="${stats.showtimes_upcoming}"/></strong>
          <small><c:out value="${stats.news_published}"/> tin tức đang đăng</small>
        </div>
      </section>

      <section class="admin-charts">
        <div class="admin-card">
          <h2>Suất chiếu sắp tới theo phim</h2>
          <div class="bar-chart bar-chart-wide">
            <c:forEach var="bar" items="${movieShowtimeBars}">
              <div class="bar-chart-row">
                <span class="bar-chart-label" title="${bar.label}"><c:out value="${bar.label}"/></span>
                <div class="bar-chart-track"><div class="bar-chart-fill" style="width:${bar.percent}%"></div></div>
                <strong class="bar-chart-value"><c:out value="${bar.value}"/></strong>
              </div>
            </c:forEach>
          </div>
        </div>
        <div class="admin-card">
          <h2>Phim theo trạng thái</h2>
          <div class="bar-chart">
            <c:forEach var="bar" items="${movieStatusBars}">
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
