<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Dashboard - Nhân viên"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <h1>Dashboard Nhân viên bán vé</h1>
    <p>Quản lý bán vé, hoàn vé, và thông tin suất chiếu.</p>

    <c:if test="${not empty statsError}">
      <div class="dashboard-empty"><p><c:out value="${statsError}"/></p></div>
    </c:if>

    <c:if test="${not empty stats}">
      <section class="admin-kpis">
        <div class="admin-kpi admin-kpi-main">
          <span>Doanh thu bán tại quầy hôm nay</span>
          <strong><fmt:formatNumber value="${stats.counter_revenue}" groupingUsed="true"/> đ</strong>
          <small><c:out value="${stats.counter_tickets}"/> vé đã bán tại quầy</small>
        </div>
        <div class="admin-kpi">
          <span>Suất chiếu còn lại hôm nay</span>
          <strong><c:out value="${stats.showtimes_left}"/></strong>
          <small>tính từ bây giờ</small>
        </div>
        <div class="admin-kpi">
          <span>Vé đã soát hôm nay</span>
          <strong><c:out value="${stats.checked_in}"/></strong>
          <small><a href="${ctx}/staff/checkin">Mở trang soát vé</a></small>
        </div>
        <div class="admin-kpi">
          <span>Cần chú ý</span>
          <strong><c:out value="${stats.combos_low + stats.emails_pending}"/></strong>
          <small><c:out value="${stats.combos_low}"/> combo sắp hết · <c:out value="${stats.emails_pending}"/> thư chờ gửi</small>
        </div>
      </section>

      <section class="admin-charts">
        <div class="admin-card">
          <h2>Vé đã bán của các suất hôm nay</h2>
          <c:choose>
            <c:when test="${empty showtimeSales}"><p class="review-note">Hôm nay không còn suất chiếu nào.</p></c:when>
            <c:otherwise>
              <div class="bar-chart bar-chart-wide">
                <c:forEach var="bar" items="${showtimeSales}">
                  <div class="bar-chart-row">
                    <span class="bar-chart-label" title="${bar.label}"><c:out value="${bar.label}"/></span>
                    <div class="bar-chart-track"><div class="bar-chart-fill" style="width:${bar.percent}%"></div></div>
                    <strong class="bar-chart-value"><c:out value="${bar.value}"/></strong>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="admin-card">
          <h2>Tồn kho combo</h2>
          <c:choose>
            <c:when test="${empty comboStock}"><p class="review-note">Chưa có combo đang bán.</p></c:when>
            <c:otherwise>
              <div class="bar-chart">
                <c:forEach var="bar" items="${comboStock}">
                  <div class="bar-chart-row bar-chart-stock">
                    <span class="bar-chart-label" title="${bar.label}"><c:out value="${bar.label}"/></span>
                    <div class="bar-chart-track"><div class="bar-chart-fill ${bar.value <= 10 ? 'is-low' : ''}" style="width:${bar.percent}%"></div></div>
                    <strong class="bar-chart-value"><c:out value="${bar.value}"/></strong>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </section>
    </c:if>
  </div>
</main>
<%@ include file="../_footer.jspf" %>
