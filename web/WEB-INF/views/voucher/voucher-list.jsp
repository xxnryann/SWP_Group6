<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý voucher"/>
<%@ include file="../_header.jspf" %>
<style>
  .voucher-head { display:flex; justify-content:space-between; gap:16px; align-items:center; flex-wrap:wrap; margin-bottom:18px; }
  .voucher-head h1 { margin:0; } .voucher-head p { color:var(--slate-500); margin:5px 0 0; }
  .voucher-search { display:flex; gap:8px; margin-bottom:18px; } .voucher-search input { min-width:260px; }
  .voucher-table { width:100%; border-collapse:collapse; background:#fff; box-shadow:var(--shadow); border-radius:14px; overflow:hidden; }
  .voucher-table th,.voucher-table td { padding:13px 14px; text-align:left; border-bottom:1px solid var(--slate-100); vertical-align:top; }
  .voucher-table th { background:var(--slate-50); color:var(--slate-600); font-size:13px; }
  .voucher-table small { display:block; color:var(--slate-500); margin-top:4px; }
  .badge { display:inline-block; padding:3px 9px; border-radius:99px; font-size:12px; font-weight:700; background:#dbeafe; color:var(--brand); }
  .badge.off { background:var(--slate-200); color:var(--slate-600); }
  .actions { display:flex; gap:6px; align-items:center; } .actions form { margin:0; }
</style>
<main><section class="page"><div class="container">
  <div class="voucher-head"><div><h1>Quản lý voucher</h1><p>Quản lý các mã ưu đãi đang dùng trong thanh toán online.</p></div><a class="btn btn-cta" href="${ctx}/staff/voucher?action=add">+ Thêm voucher</a></div>
  <form class="voucher-search" method="get" action="${ctx}/staff/voucher"><input class="form-control" type="search" name="q" placeholder="Tìm mã hoặc mô tả..." value="<c:out value='${keyword}'/>"><button class="btn btn-outline" type="submit">Tìm</button></form>
  <div style="overflow:auto"><table class="voucher-table"><thead><tr><th>Mã</th><th>Giảm giá</th><th>Điều kiện</th><th>Thời hạn</th><th>Sử dụng</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>
    <c:forEach var="v" items="${voucherList}"><tr>
      <td><strong><c:out value="${v.code}"/></strong><small><c:out value="${v.description}"/></small></td>
      <td><c:out value="${v.discountType}"/>: <strong><c:out value="${v.discountValue}"/></strong><c:if test="${v.maxDiscount != null}"><small>Tối đa <c:out value="${v.maxDiscount}"/></small></c:if></td>
      <td>Tối thiểu đơn: <c:out value="${v.minOrderAmount}"/><small>Chi tiêu tích lũy: <c:out value="${v.minCumulativeSpending}"/></small></td>
      <td><c:out value="${v.validFrom}"/><small>đến <c:out value="${v.validTo}"/></small></td>
      <td><c:out value="${v.usedCount}"/> / <c:out value="${v.usageLimit}"/><small>Tối đa/khách: <c:out value="${v.perCustomerLimit}"/></small></td>
      <td><span class="badge ${!v.allowed ? 'off' : ''}"><c:out value="${v.status}"/></span></td>
      <td><div class="actions"><a class="btn btn-soft" href="${ctx}/staff/voucher?action=edit&id=${v.voucherId}">Sửa</a><c:if test="${v.allowed}"><form method="post" action="${ctx}/staff/voucher" onsubmit="return confirm('Vô hiệu hóa voucher này?')"><input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="${v.voucherId}"><button class="btn btn-outline" type="submit" style="color:var(--danger);border-color:var(--danger)">Xóa</button></form></c:if></div></td>
    </tr></c:forEach>
  </tbody></table></div>
  <c:if test="${empty voucherList}"><div class="uip-empty" style="margin-top:18px">Không có voucher nào.</div></c:if>
</div></section></main>
<%@ include file="../_footer.jspf" %>
