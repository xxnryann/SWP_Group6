<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty voucher ? 'Thêm voucher' : 'Sửa voucher'}"/>
<%@ include file="../_header.jspf" %>
<main><section class="page"><div class="container" style="max-width:900px">
  <h1><c:out value="${pageTitle}"/></h1>
  <c:if test="${not empty error}"><div class="alert alert-error"><c:out value="${error}"/></div></c:if>
  <form method="post" action="${ctx}/staff/voucher" class="form-card">
    <input type="hidden" name="_csrf" value="${csrf}"><c:if test="${not empty voucher.voucherId}"><input type="hidden" name="id" value="${voucher.voucherId}"/></c:if>
    <div class="form-grid">
      <label>Mã voucher<input name="code" required maxlength="30" value="<c:out value='${voucher.code}'/>"></label>
      <label>Loại giảm giá<select name="discountType"><option value="Amount" ${voucher.discountType == 'Amount' ? 'selected' : ''}>Số tiền</option><option value="Percent" ${voucher.discountType == 'Percent' ? 'selected' : ''}>Phần trăm</option></select></label>
      <label>Giá trị giảm<input type="number" step="0.01" min="0.01" name="discountValue" required value="<c:out value='${voucher.discountValue}'/>"></label>
      <label>Giảm tối đa<input type="number" step="1" min="0" name="maxDiscount" value="<c:out value='${voucher.maxDiscount}'/>"></label>
      <label>Đơn tối thiểu<input type="number" step="1" min="0" name="minOrderAmount" required value="<c:out value='${voucher.minOrderAmount}'/>"></label>
      <label>Chi tiêu tích lũy tối thiểu<input type="number" step="1" min="0" name="minCumulativeSpending" required value="<c:out value='${voucher.minCumulativeSpending}'/>"></label>
      <label>Tổng lượt dùng<input type="number" min="1" name="usageLimit" required value="${empty voucher ? 1 : voucher.usageLimit}"></label>
      <label>Lượt dùng mỗi khách<input type="number" min="1" name="perCustomerLimit" required value="${empty voucher ? 1 : voucher.perCustomerLimit}"></label>
      <label>Hiệu lực từ<input type="date" name="validFrom" required value="<c:out value='${voucher.validFrom}'/>"></label>
      <label>Hiệu lực đến<input type="date" name="validTo" required value="<c:out value='${voucher.validTo}'/>"></label>
      <label>Trạng thái<select name="status"><c:forEach var="s" items="${voucherStatuses}"><option value="${s}" ${voucher.status == s ? 'selected' : ''}>${s}</option></c:forEach></select></label>
      <label class="form-full">Mô tả<textarea name="description" rows="3" maxlength="200"><c:out value="${voucher.description}"/></textarea></label>
    </div>
    <div style="display:flex;gap:8px;margin-top:18px"><button class="btn btn-cta" type="submit">Lưu voucher</button><a class="btn btn-outline" href="${ctx}/staff/voucher">Hủy</a></div>
  </form>
</div></section></main>
<%@ include file="../_footer.jspf" %>
