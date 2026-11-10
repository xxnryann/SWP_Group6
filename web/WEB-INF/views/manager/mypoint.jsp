<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="MyPoint"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><h1>Cấu hình điểm thưởng MyPoint</h1><p>Tỉ lệ tích điểm trên giá trị đơn và giá trị quy đổi của mỗi điểm khi khách thanh toán.</p></div>
</div>
<c:if test="${not empty error}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<div class="split" style="grid-template-columns:380px minmax(0,1fr)">
  <section class="card sticky">
    <div class="card-head"><div><h2>Cấu hình mới</h2><p>Áp dụng ngay cho các đơn tiếp theo</p></div></div>
    <form method="post" action="${ctx}/manager/mypoint">
      <div class="card-body form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="field">
          <label for="earnRatePercent">Tích điểm (% giá trị đơn)<span class="req">*</span></label>
          <input id="earnRatePercent" name="earnRatePercent" type="number" step="0.01" min="0" max="100" required value="${not empty configs ? configs[0].earn_rate_percent : 5}">
        </div>
        <div class="field">
          <label for="pointValueVnd">Giá trị 1 điểm (đ)<span class="req">*</span></label>
          <input id="pointValueVnd" name="pointValueVnd" type="number" min="1" required value="${not empty configs ? configs[0].point_value_vnd : 1000}">
        </div>
        <p class="hint">Khách dùng được toàn bộ điểm đang có, tối đa bằng số tiền còn phải thanh toán.</p>
      </div>
      <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Áp dụng cấu hình</button></div>
    </form>
  </section>
  <section class="card">
    <div class="card-head"><div><h2>Lịch sử cấu hình</h2></div></div>
    <div class="table-wrap"><table class="table">
      <thead><tr><th>Có hiệu lực từ</th><th class="num">Tích điểm</th><th class="num">1 điểm</th><th>Trạng thái</th><th>Người cập nhật</th></tr></thead>
      <tbody>
        <c:forEach var="cfg" items="${configs}">
          <tr>
            <td class="nowrap text-sm"><c:out value="${cfg.effective_from}"/></td>
            <td class="num fw-700"><fmt:formatNumber value="${cfg.earn_rate_percent}" maxFractionDigits="2"/>%</td>
            <td class="num fw-700"><fmt:formatNumber value="${cfg.point_value_vnd}" groupingUsed="true"/>đ</td>
            <td><c:choose><c:when test="${cfg.is_active}"><span class="badge badge-success badge-dot">Đang áp dụng</span></c:when><c:otherwise><span class="badge">Cũ</span></c:otherwise></c:choose></td>
            <td><c:out value="${cfg.updated_by_name}"/></td>
          </tr>
        </c:forEach>
        <c:if test="${empty configs}"><tr><td colspan="5"><div class="empty"><div class="empty-icon">${ic.coins}</div><p>Chưa có cấu hình.</p></div></td></tr></c:if>
      </tbody>
    </table></div>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
