<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty voucher ? 'Thêm voucher' : 'Sửa voucher'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .voucher-form-wrap { max-width:980px; margin:0 auto; } .voucher-form-head { margin-bottom:20px; }
  .voucher-form-head h1 { margin:0; } .voucher-form-head p { color:var(--slate-500); margin:6px 0 0; }
  .voucher-form-card { background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow); overflow:hidden; }
  .voucher-section { padding:22px 24px; border-bottom:1px solid var(--slate-200); } .voucher-section:last-of-type { border-bottom:0; }
  .voucher-section h2 { margin:0 0 4px; font-size:18px; } .voucher-section p { margin:0 0 18px; color:var(--slate-500); font-size:13px; }
  .voucher-fields { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:16px 20px; }
  .voucher-field { display:flex; flex-direction:column; gap:6px; } .voucher-field.full { grid-column:1/-1; }
  .voucher-field label { font-weight:700; font-size:13px; color:var(--slate-700); } .voucher-field small { color:var(--slate-500); font-size:12px; }
  .voucher-field input,.voucher-field select,.voucher-field textarea { width:100%; box-sizing:border-box; }
  .voucher-actions { display:flex; gap:10px; padding:18px 24px; background:#f8fafc; }
  @media (max-width:680px) { .voucher-fields { grid-template-columns:1fr; } .voucher-field.full { grid-column:auto; } .voucher-section { padding:18px; } .voucher-actions { padding:16px 18px; } }
</style>
<main><section class="page"><div class="container voucher-form-wrap">
  <div class="voucher-form-head"><h1><c:out value="${pageTitle}"/></h1><p>Điền thông tin rõ ràng để voucher hiển thị đúng trong thanh toán.</p></div>
  <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>
  <form method="post" action="${ctx}/staff/voucher" class="voucher-form-card">
    <input type="hidden" name="_csrf" value="${csrf}"><c:if test="${not empty voucher.voucherId}"><input type="hidden" name="id" value="${voucher.voucherId}"/></c:if>
    <div class="voucher-section"><h2>Thông tin cơ bản</h2><p>Tên mã và nội dung hiển thị cho nhân viên, khách hàng.</p><div class="voucher-fields">
      <div class="voucher-field"><label for="voucher-code">Mã voucher</label><input id="voucher-code" name="code" required maxlength="30" placeholder="VD: WELCOME10" value="<c:out value='${voucher.code}'/>"><small>Tối đa 30 ký tự, không trùng mã khác.</small></div>
      <div class="voucher-field"><label for="voucher-status">Trạng thái</label><select id="voucher-status" name="status"><c:forEach var="s" items="${voucherStatuses}"><option value="${s}" ${voucher.status == s ? 'selected' : ''}><c:choose><c:when test="${s == 'Allowed'}">Đang hoạt động</c:when><c:when test="${s == 'Disabled'}">Đã tắt</c:when><c:when test="${s == 'Expired'}">Đã hết hạn</c:when><c:otherwise><c:out value="${s}"/></c:otherwise></c:choose></option></c:forEach></select></div>
      <div class="voucher-field full"><label for="voucher-description">Mô tả</label><textarea id="voucher-description" name="description" rows="3" maxlength="200" placeholder="VD: Giảm 10% cho khách hàng mới"><c:out value="${voucher.description}"/></textarea></div>
    </div></div>
    <div class="voucher-section"><h2>Mức giảm giá</h2><p>Chọn giảm theo số tiền hoặc theo phần trăm.</p><div class="voucher-fields">
      <div class="voucher-field"><label for="voucher-type">Loại giảm</label><select id="voucher-type" name="discountType"><option value="Amount" ${voucher.discountType == 'Amount' ? 'selected' : ''}>Số tiền (VNĐ)</option><option value="Percent" ${voucher.discountType == 'Percent' ? 'selected' : ''}>Phần trăm (%)</option></select></div>
      <div class="voucher-field"><label for="voucher-value">Giá trị giảm</label><input id="voucher-value" type="number" step="0.01" min="0.01" name="discountValue" required value="<c:out value='${voucher.discountValue}'/>"><small>Phần trăm không được lớn hơn 100.</small></div>
      <div class="voucher-field"><label for="voucher-max">Giảm tối đa (VNĐ)</label><input id="voucher-max" type="number" step="1" min="0" name="maxDiscount" value="<c:out value='${voucher.maxDiscount}'/>"><small>Có thể để trống nếu không giới hạn.</small></div>
    </div></div>
    <div class="voucher-section"><h2>Điều kiện và thời hạn</h2><p>Thiết lập điều kiện áp dụng và giới hạn sử dụng.</p><div class="voucher-fields">
      <div class="voucher-field"><label for="voucher-min-order">Đơn hàng tối thiểu (VNĐ)</label><input id="voucher-min-order" type="number" step="1" min="0" name="minOrderAmount" required value="<c:out value='${voucher.minOrderAmount}'/>"></div>
      <div class="voucher-field"><label for="voucher-min-spending">Chi tiêu tích lũy tối thiểu (VNĐ)</label><input id="voucher-min-spending" type="number" step="1" min="0" name="minCumulativeSpending" required value="<c:out value='${voucher.minCumulativeSpending}'/>"></div>
      <div class="voucher-field"><label for="voucher-limit">Tổng lượt sử dụng</label><input id="voucher-limit" type="number" min="1" name="usageLimit" required value="${empty voucher ? 1 : voucher.usageLimit}"></div>
      <div class="voucher-field"><label for="voucher-per-customer">Lượt dùng mỗi khách</label><input id="voucher-per-customer" type="number" min="1" name="perCustomerLimit" required value="${empty voucher ? 1 : voucher.perCustomerLimit}"></div>
      <div class="voucher-field"><label for="voucher-from">Có hiệu lực từ</label><input id="voucher-from" type="date" name="validFrom" required value="<c:out value='${voucher.validFrom}'/>"></div>
      <div class="voucher-field"><label for="voucher-to">Có hiệu lực đến</label><input id="voucher-to" type="date" name="validTo" required value="<c:out value='${voucher.validTo}'/>"></div>
    </div></div>
    <div class="voucher-actions"><button class="btn btn-cta" type="submit">Lưu voucher</button><a class="btn btn-outline" href="${ctx}/staff/voucher">Hủy</a></div>
  </form>
</div></section></main>
<%@ include file="../_footer.jspf" %>
