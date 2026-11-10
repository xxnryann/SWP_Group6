<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Voucher"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><h1>Quản lý voucher</h1><p>Mã giảm giá theo phần trăm hoặc số tiền, có điều kiện đơn tối thiểu, chi tiêu tích lũy và giới hạn lượt dùng.</p></div>
  <c:if test="${empty form}"><a class="btn btn-primary" href="${ctx}/manager/vouchers?action=new">${ic.plus}Thêm voucher</a></c:if>
</div>
<c:if test="${not empty error}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<c:if test="${not empty form}">
  <section class="card mb-24">
    <div class="card-head"><div><h2><c:out value="${empty form.voucher_id ? 'Thêm voucher mới' : 'Sửa voucher'}"/></h2></div></div>
    <form method="post" action="${ctx}/manager/vouchers">
      <div class="card-body form-grid" style="grid-template-columns:repeat(3,minmax(0,1fr))">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="save">
        <input type="hidden" name="id" value="${empty form.voucher_id ? 0 : form.voucher_id}">
        <div class="field"><label for="code">Mã voucher<span class="req">*</span></label><input id="code" name="code" type="text" maxlength="30" required value="<c:out value='${form.code}'/>" placeholder="WELCOME10" style="text-transform:uppercase"></div>
        <div class="field"><label for="discountType">Loại giảm</label>
          <select id="discountType" name="discountType">
            <option value="Percent" ${form.discount_type == 'Percent' ? 'selected' : ''}>Theo phần trăm (%)</option>
            <option value="Amount" ${form.discount_type == 'Amount' ? 'selected' : ''}>Theo số tiền (đ)</option>
          </select></div>
        <div class="field"><label for="discountValue">Giá trị giảm<span class="req">*</span></label><input id="discountValue" name="discountValue" type="number" step="any" min="0" required value="<fmt:formatNumber value='${form.discount_value}' groupingUsed='false' maxFractionDigits='2'/>"></div>
        <div class="field"><label for="maxDiscount">Giảm tối đa (đ)</label><input id="maxDiscount" name="maxDiscount" type="number" min="0" value="<c:out value='${form.max_discount}'/>" placeholder="Không giới hạn"></div>
        <div class="field"><label for="minOrderAmount">Đơn tối thiểu (đ)</label><input id="minOrderAmount" name="minOrderAmount" type="number" min="0" value="<c:out value='${form.min_order_amount}'/>"></div>
        <div class="field"><label for="minCumulativeSpending">Chi tiêu tích lũy tối thiểu (đ)</label><input id="minCumulativeSpending" name="minCumulativeSpending" type="number" min="0" value="<c:out value='${form.min_cumulative_spending}'/>"></div>
        <div class="field"><label for="usageLimit">Tổng số lượt dùng<span class="req">*</span></label><input id="usageLimit" name="usageLimit" type="number" min="1" required value="<c:out value='${form.usage_limit}'/>"></div>
        <div class="field"><label for="perCustomerLimit">Số lượt mỗi khách<span class="req">*</span></label><input id="perCustomerLimit" name="perCustomerLimit" type="number" min="1" required value="<c:out value='${form.per_customer_limit}'/>"></div>
        <div class="field"><label for="status">Trạng thái</label>
          <select id="status" name="status">
            <option value="Allowed" ${form.status != 'Disabled' ? 'selected' : ''}>Cho phép sử dụng</option>
            <option value="Disabled" ${form.status == 'Disabled' ? 'selected' : ''}>Tắt</option>
          </select></div>
        <div class="field"><label for="validFrom">Hiệu lực từ<span class="req">*</span></label><input id="validFrom" name="validFrom" type="date" required value="<c:out value='${form.valid_from}'/>"></div>
        <div class="field"><label for="validTo">Đến hết ngày<span class="req">*</span></label><input id="validTo" name="validTo" type="date" required value="<c:out value='${form.valid_to}'/>"></div>
        <div class="field"><label for="description">Mô tả</label><input id="description" name="description" type="text" maxlength="200" value="<c:out value='${form.description}'/>"></div>
      </div>
      <div class="card-foot">
        <a class="btn" href="${ctx}/manager/vouchers">Hủy</a>
        <button class="btn btn-primary" type="submit">${ic.check}Lưu voucher</button>
      </div>
    </form>
  </section>
</c:if>

<section class="card">
  <c:choose>
    <c:when test="${empty vouchers}"><div class="empty"><div class="empty-icon">${ic.tag}</div><h3>Chưa có voucher nào</h3></div></c:when>
    <c:otherwise>
      <div class="table-wrap"><table class="table">
        <thead><tr><th>Mã</th><th>Giảm</th><th>Điều kiện</th><th>Đã dùng</th><th>Hiệu lực</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
        <tbody>
          <c:forEach var="v" items="${vouchers}">
            <tr>
              <td><span class="voucher-code"><c:out value="${v.code}"/></span><span class="cell-sub" style="max-width:220px"><c:out value="${v.description}"/></span></td>
              <td class="nowrap">
                <c:choose>
                  <c:when test="${v.discount_type == 'Percent'}"><strong class="text-ink"><fmt:formatNumber value="${v.discount_value}" maxFractionDigits="2"/>%</strong><c:if test="${not empty v.max_discount}"><span class="cell-sub">tối đa <fmt:formatNumber value="${v.max_discount}" groupingUsed="true"/>đ</span></c:if></c:when>
                  <c:otherwise><strong class="text-ink"><fmt:formatNumber value="${v.discount_value}" groupingUsed="true" maxFractionDigits="0"/>đ</strong></c:otherwise>
                </c:choose>
              </td>
              <td class="text-sm">Đơn từ <fmt:formatNumber value="${v.min_order_amount}" groupingUsed="true"/>đ<span class="cell-sub">Chi tiêu từ <fmt:formatNumber value="${v.min_cumulative_spending}" groupingUsed="true"/>đ</span></td>
              <td class="nowrap"><strong class="text-ink"><c:out value="${v.used_count}"/></strong>/<c:out value="${v.usage_limit}"/><span class="cell-sub"><c:out value="${v.per_customer_limit}"/> lượt/khách</span></td>
              <td class="nowrap text-sm"><c:out value="${v.valid_from}"/><span class="cell-sub">→ <c:out value="${v.valid_to}"/></span></td>
              <td>
                <c:choose>
                  <c:when test="${v.status == 'Allowed'}"><span class="badge badge-success badge-dot">Đang áp dụng</span></c:when>
                  <c:when test="${v.status == 'Disabled'}"><span class="badge badge-danger badge-dot">Đã tắt</span></c:when>
                  <c:when test="${v.status == 'Used'}"><span class="badge badge-dot">Hết lượt</span></c:when>
                  <c:otherwise><span class="badge"><c:out value="${v.status}"/></span></c:otherwise>
                </c:choose>
              </td>
              <td class="actions">
                <a class="btn btn-xs btn-soft" href="${ctx}/manager/vouchers?edit=${v.voucher_id}">${ic.edit}Sửa</a>
                <form class="inline-form" method="post" action="${ctx}/manager/vouchers">
                  <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="toggle">
                  <input type="hidden" name="id" value="${v.voucher_id}">
                  <input type="hidden" name="status" value="${v.status == 'Disabled' ? 'Allowed' : 'Disabled'}">
                  <button class="btn btn-xs" type="submit">${v.status == 'Disabled' ? 'Bật' : 'Tắt'}</button>
                </form>
                <c:if test="${v.used_count == 0}">
                  <form class="inline-form" method="post" action="${ctx}/manager/vouchers" data-confirm="Xóa voucher này?">
                    <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${v.voucher_id}">
                    <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button>
                  </form>
                </c:if>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table></div>
    </c:otherwise>
  </c:choose>
</section>
<%@ include file="../layout/bottom.jspf" %>
