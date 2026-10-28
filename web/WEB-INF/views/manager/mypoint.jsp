<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Cấu hình MyPoint"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Cấu hình điểm thưởng MyPoint</h2>
    <p class="sub">Quy định tỷ lệ tích điểm trên đơn đã thanh toán, giá trị quy đổi của 1 điểm và tỷ lệ tối đa được dùng điểm để giảm giá. Cấu hình mới có hiệu lực từ hôm nay và thay thế cấu hình cũ.</p>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <form method="post" action="${ctx}/manager/mypoint" class="promo-form">
      <input type="hidden" name="_csrf" value="${csrf}">
      <div class="promo-grid">
        <div class="field"><label for="earnRatePercent">TÍCH ĐIỂM (% GIÁ TRỊ ĐƠN)</label>
          <input id="earnRatePercent" name="earnRatePercent" type="number" step="0.01" min="0" max="100" required
                 value="${not empty configs ? configs[0].earn_rate_percent : 5}"></div>
        <div class="field"><label for="pointValueVnd">1 ĐIỂM = (VNĐ)</label>
          <input id="pointValueVnd" name="pointValueVnd" type="number" min="1" required
                 value="${not empty configs ? configs[0].point_value_vnd : 1000}"></div>
        <div class="field"><label for="maxRedeemPercent">DÙNG ĐIỂM TỐI ĐA (% GIÁ TRỊ ĐƠN)</label>
          <input id="maxRedeemPercent" name="maxRedeemPercent" type="number" step="0.01" min="0" max="100" required
                 value="${not empty configs ? configs[0].max_redeem_percent : 20}"></div>
      </div>
      <button class="btn btn-primary" type="submit">Áp dụng cấu hình mới</button>
    </form>

    <h3 style="margin-top:28px">Lịch sử cấu hình</h3>
    <div class="table-wrap"><table class="data">
      <thead><tr><th>Có hiệu lực từ</th><th>Tích điểm</th><th>1 điểm</th><th>Dùng tối đa</th><th>Trạng thái</th><th>Người cập nhật</th></tr></thead>
      <tbody>
      <c:forEach var="cfg" items="${configs}">
        <tr>
          <td><c:out value="${cfg.effective_from}"/></td>
          <td><fmt:formatNumber value="${cfg.earn_rate_percent}" maxFractionDigits="2"/>%</td>
          <td><fmt:formatNumber value="${cfg.point_value_vnd}" groupingUsed="true"/>đ</td>
          <td><fmt:formatNumber value="${cfg.max_redeem_percent}" maxFractionDigits="2"/>%</td>
          <td><c:choose><c:when test="${cfg.is_active}"><span class="chip chip-success">Đang áp dụng</span></c:when>
                        <c:otherwise><span class="chip">Cũ</span></c:otherwise></c:choose></td>
          <td><c:out value="${cfg.updated_by_name}"/></td>
        </tr>
      </c:forEach>
      </tbody>
    </table></div>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
