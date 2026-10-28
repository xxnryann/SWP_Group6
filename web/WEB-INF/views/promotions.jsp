<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Khuyến mãi"/>
<%@ include file="_header.jspf" %>
<fmt:setLocale value="vi_VN"/>
<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Khuyến mãi</h1>
      <p class="sub">Các mã voucher đang áp dụng. Nhập mã khi thanh toán để được giảm giá.</p>
    </div>
  </section>

  <c:choose>
    <c:when test="${empty vouchers}">
      <div class="movie-list-empty"><p>Hiện chưa có voucher nào đang áp dụng.</p></div>
    </c:when>
    <c:otherwise>
      <div class="voucher-grid">
        <c:forEach var="v" items="${vouchers}">
          <article class="voucher-card">
            <div class="voucher-value">
              <c:choose>
                <c:when test="${v.discount_type == 'Percent'}">
                  <strong>-<fmt:formatNumber value="${v.discount_value}" pattern="#,##0.##"/>%</strong>
                </c:when>
                <c:otherwise>
                  <strong>-<fmt:formatNumber value="${v.discount_value}" pattern="#,##0"/>đ</strong>
                </c:otherwise>
              </c:choose>
              <span>GIẢM GIÁ</span>
            </div>
            <div class="voucher-body">
              <p class="voucher-code"><c:out value="${v.code}"/></p>
              <p class="voucher-desc"><c:out value="${v.description}"/></p>
              <ul class="voucher-terms">
                <c:if test="${v.discount_type == 'Percent' and not empty v.max_discount}">
                  <li>Giảm tối đa <fmt:formatNumber value="${v.max_discount}" pattern="#,##0"/>đ</li>
                </c:if>
                <c:if test="${not empty v.min_order_amount and v.min_order_amount > 0}">
                  <li>Đơn tối thiểu <fmt:formatNumber value="${v.min_order_amount}" pattern="#,##0"/>đ</li>
                </c:if>
                <c:if test="${not empty v.min_cumulative_spending and v.min_cumulative_spending > 0}">
                  <li>Dành cho khách chi tiêu từ <fmt:formatNumber value="${v.min_cumulative_spending}" pattern="#,##0"/>đ</li>
                </c:if>
                <li>Hạn dùng: <c:out value="${v.valid_from_txt}"/> – <c:out value="${v.valid_to_txt}"/></li>
                <c:if test="${not empty v.usage_limit}">
                  <li>Còn <c:out value="${v.usage_limit - v.used_count}"/> lượt</li>
                </c:if>
              </ul>
            </div>
          </article>
        </c:forEach>
      </div>
      <c:if test="${empty sessionScope.authUser}">
        <p class="voucher-hint"><a href="${ctx}/login">Đăng nhập</a> để dùng voucher khi đặt vé.</p>
      </c:if>
    </c:otherwise>
  </c:choose>
</main>
<%@ include file="_footer.jspf" %>
