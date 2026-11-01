<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Quản lý voucher"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <div class="uip-head">
      <div>
        <h2>Quản lý voucher</h2>
      </div>
      <c:if test="${empty form}"><a class="btn btn-cta" href="${ctx}/manager/vouchers?action=new">+ Thêm voucher</a></c:if>
    </div>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <c:if test="${not empty form}">
      <form method="post" action="${ctx}/manager/vouchers" class="promo-form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="save">
        <input type="hidden" name="id" value="${empty form.voucher_id ? 0 : form.voucher_id}">
        <h3><c:out value="${empty form.voucher_id ? 'Thêm voucher mới' : 'Sửa voucher'}"/></h3>
        <div class="promo-grid">
          <div class="field"><label for="code">MÃ VOUCHER</label>
            <input id="code" name="code" type="text" maxlength="30" required value="<c:out value='${form.code}'/>" placeholder="VD: WELCOME10"></div>
          <div class="field"><label for="discountType">LOẠI GIẢM</label>
            <select id="discountType" name="discountType">
              <option value="Percent" ${form.discount_type == 'Percent' ? 'selected' : ''}>Theo phần trăm (%)</option>
              <option value="Amount" ${form.discount_type == 'Amount' ? 'selected' : ''}>Theo số tiền (VNĐ)</option>
            </select></div>
          <div class="field"><label for="discountValue">GIÁ TRỊ GIẢM</label>
            <input id="discountValue" name="discountValue" type="number" step="any" min="0" required
                   value="<fmt:formatNumber value='${form.discount_value}' groupingUsed='false' maxFractionDigits='2'/>"></div>
          <div class="field"><label for="maxDiscount">GIẢM TỐI ĐA (VNĐ)</label>
            <input id="maxDiscount" name="maxDiscount" type="number" min="0" value="<c:out value='${form.max_discount}'/>" placeholder="Không giới hạn"></div>
          <div class="field"><label for="minOrderAmount">ĐƠN TỐI THIỂU (VNĐ)</label>
            <input id="minOrderAmount" name="minOrderAmount" type="number" min="0" value="<c:out value='${form.min_order_amount}'/>"></div>
          <div class="field"><label for="minCumulativeSpending">CHI TIÊU TÍCH LŨY TỐI THIỂU (VNĐ)</label>
            <input id="minCumulativeSpending" name="minCumulativeSpending" type="number" min="0" value="<c:out value='${form.min_cumulative_spending}'/>"></div>
          <div class="field"><label for="usageLimit">TỔNG SỐ LƯỢT DÙNG</label>
            <input id="usageLimit" name="usageLimit" type="number" min="1" required value="<c:out value='${form.usage_limit}'/>"></div>
          <div class="field"><label for="perCustomerLimit">SỐ LƯỢT MỖI KHÁCH</label>
            <input id="perCustomerLimit" name="perCustomerLimit" type="number" min="1" required value="<c:out value='${form.per_customer_limit}'/>"></div>
          <div class="field"><label for="validFrom">HIỆU LỰC TỪ</label>
            <input id="validFrom" name="validFrom" type="date" required value="<c:out value='${form.valid_from}'/>"></div>
          <div class="field"><label for="validTo">ĐẾN HẾT NGÀY</label>
            <input id="validTo" name="validTo" type="date" required value="<c:out value='${form.valid_to}'/>"></div>
          <div class="field"><label for="status">TRẠNG THÁI</label>
            <select id="status" name="status">
              <option value="Allowed" ${form.status != 'Disabled' ? 'selected' : ''}>Cho phép sử dụng</option>
              <option value="Disabled" ${form.status == 'Disabled' ? 'selected' : ''}>Tắt</option>
            </select></div>
          <div class="field"><label for="description">MÔ TẢ</label>
            <input id="description" name="description" type="text" maxlength="200" value="<c:out value='${form.description}'/>"></div>
        </div>
        <button class="btn btn-primary" type="submit">Lưu voucher</button>
        <a class="btn btn-outline" href="${ctx}/manager/vouchers">Hủy</a>
      </form>
    </c:if>

    <c:choose>
      <c:when test="${empty vouchers}"><p class="sub">Chưa có voucher nào.</p></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="data">
          <thead><tr><th>Mã</th><th>Giảm</th><th>Điều kiện</th><th>Đã dùng</th><th>Hiệu lực</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
          <tbody>
          <c:forEach var="v" items="${vouchers}">
            <tr>
              <td><strong><c:out value="${v.code}"/></strong><br><span class="muted"><c:out value="${v.description}"/></span></td>
              <td>
                <c:choose>
                  <c:when test="${v.discount_type == 'Percent'}"><fmt:formatNumber value="${v.discount_value}" maxFractionDigits="2"/>%
                    <c:if test="${not empty v.max_discount}"><br><span class="muted">tối đa <fmt:formatNumber value="${v.max_discount}" groupingUsed="true"/>đ</span></c:if></c:when>
                  <c:otherwise><fmt:formatNumber value="${v.discount_value}" groupingUsed="true" maxFractionDigits="0"/>đ</c:otherwise>
                </c:choose>
              </td>
              <td>Đơn từ <fmt:formatNumber value="${v.min_order_amount}" groupingUsed="true"/>đ<br>
                  <span class="muted">Chi tiêu từ <fmt:formatNumber value="${v.min_cumulative_spending}" groupingUsed="true"/>đ</span></td>
              <td><c:out value="${v.used_count}"/>/<c:out value="${v.usage_limit}"/><br><span class="muted"><c:out value="${v.per_customer_limit}"/> lượt/khách</span></td>
              <td><c:out value="${v.valid_from}"/><br>→ <c:out value="${v.valid_to}"/></td>
              <td>
                <c:choose>
                  <c:when test="${v.status == 'Allowed'}"><span class="chip chip-success">Đang áp dụng</span></c:when>
                  <c:when test="${v.status == 'Disabled'}"><span class="chip chip-danger">Đã tắt</span></c:when>
                  <c:when test="${v.status == 'Used'}"><span class="chip">Hết lượt</span></c:when>
                  <c:otherwise><span class="chip"><c:out value="${v.status}"/></span></c:otherwise>
                </c:choose>
              </td>
              <td class="promo-actions">
                <a class="btn btn-soft btn-small" href="${ctx}/manager/vouchers?edit=${v.voucher_id}">Sửa</a>
                <form method="post" action="${ctx}/manager/vouchers">
                  <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="toggle">
                  <input type="hidden" name="id" value="${v.voucher_id}">
                  <input type="hidden" name="status" value="${v.status == 'Disabled' ? 'Allowed' : 'Disabled'}">
                  <button class="btn btn-outline btn-small" type="submit">${v.status == 'Disabled' ? 'Bật' : 'Tắt'}</button>
                </form>
                <c:if test="${v.used_count == 0}">
                  <form method="post" action="${ctx}/manager/vouchers" onsubmit="return confirm('Xóa voucher này?');">
                    <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${v.voucher_id}">
                    <button class="btn btn-danger btn-small" type="submit">Xóa</button>
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
</div></main>
<%@ include file="../_footer.jspf" %>
