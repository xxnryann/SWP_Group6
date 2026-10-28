<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý voucher"/>
<%@ include file="../_header.jspf" %>
<style>
  .voucher-toolbar { display:flex; justify-content:space-between; align-items:flex-end; gap:18px; flex-wrap:wrap; margin-bottom:22px; }
  .voucher-toolbar h1 { margin:0; } .voucher-toolbar p { color:var(--slate-500); margin:6px 0 0; }
  .voucher-search { display:flex; gap:8px; width:min(100%, 430px); }
  .voucher-search input { flex:1; min-width:0; }
  .voucher-panel { background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow); overflow:hidden; }
  .voucher-panel-head { display:flex; justify-content:space-between; gap:12px; align-items:center; padding:16px 18px; border-bottom:1px solid var(--slate-200); background:var(--slate-50); }
  .voucher-panel-head strong { color:var(--slate-800); } .voucher-panel-head span { color:var(--slate-500); font-size:13px; }
  .voucher-table { width:100%; border-collapse:collapse; min-width:1020px; }
  .voucher-table th,.voucher-table td { padding:14px 16px; text-align:left; border-bottom:1px solid var(--slate-200); vertical-align:middle; }
  .voucher-table th { background:#f8fafc; color:var(--slate-600); font-size:12px; text-transform:uppercase; letter-spacing:.03em; white-space:nowrap; }
  .voucher-table tbody tr:hover { background:#f8fbff; } .voucher-table tbody tr:last-child td { border-bottom:0; }
  .voucher-code { font-weight:800; letter-spacing:.04em; color:var(--brand); } .voucher-description { display:block; max-width:210px; color:var(--slate-500); font-size:12px; margin-top:4px; }
  .voucher-main { font-weight:700; color:var(--slate-800); white-space:nowrap; } .voucher-meta { display:block; color:var(--slate-500); font-size:12px; margin-top:4px; white-space:nowrap; }
  .voucher-badge { display:inline-flex; padding:5px 10px; border-radius:999px; font-size:12px; font-weight:800; white-space:nowrap; background:#dcfce7; color:#166534; }
  .voucher-badge.off { background:#e2e8f0; color:#475569; } .voucher-badge.expired { background:#fee2e2; color:#991b1b; }
  .voucher-actions { display:flex; gap:7px; align-items:center; white-space:nowrap; } .voucher-actions form { margin:0; }
  .voucher-empty { padding:52px 20px; text-align:center; color:var(--slate-500); }
  @media (max-width:760px) { .voucher-toolbar { align-items:stretch; } .voucher-search { width:100%; } }
</style>
<main><section class="page"><div class="container">
  <div class="voucher-toolbar">
    <div><h1>Quản lý voucher</h1><p>Tạo và theo dõi mã giảm giá dùng cho các đơn đặt vé.</p></div>
    <form class="voucher-search" method="get" action="${ctx}/staff/voucher">
      <input class="form-control" type="search" name="q" placeholder="Tìm mã hoặc mô tả..." value="<c:out value='${keyword}'/>">
      <button class="btn btn-outline" type="submit">Tìm kiếm</button>
    </form>
    <a class="btn btn-cta" href="${ctx}/staff/voucher?action=add">+ Thêm voucher</a>
  </div>
  <div class="voucher-panel">
    <div class="voucher-panel-head"><strong>Danh sách mã giảm giá</strong><span>Kiểm tra thời hạn, lượt dùng và trạng thái</span></div>
    <c:choose><c:when test="${not empty voucherList}">
      <div style="overflow-x:auto"><table class="voucher-table"><thead><tr>
        <th>Mã voucher</th><th>Mức giảm</th><th>Điều kiện đơn hàng</th><th>Thời hạn</th><th>Lượt sử dụng</th><th>Trạng thái</th><th>Thao tác</th>
      </tr></thead><tbody>
      <c:forEach var="v" items="${voucherList}"><tr>
        <td><span class="voucher-code"><c:out value="${v.code}"/></span><span class="voucher-description"><c:out value="${v.description}"/></span></td>
        <td><span class="voucher-main"><c:choose><c:when test="${v.discountType == 'Percent'}"><c:out value="${v.discountValue}"/>%</c:when><c:otherwise><c:out value="${v.discountValue}"/> VNĐ</c:otherwise></c:choose></span><c:if test="${v.maxDiscount != null}"><span class="voucher-meta">Tối đa <c:out value="${v.maxDiscount}"/> VNĐ</span></c:if></td>
        <td><span class="voucher-main">Đơn từ <c:out value="${v.minOrderAmount}"/> VNĐ</span><span class="voucher-meta">Tích lũy từ <c:out value="${v.minCumulativeSpending}"/> VNĐ</span></td>
        <td><span class="voucher-main"><c:out value="${v.validFrom}"/></span><span class="voucher-meta">đến <c:out value="${v.validTo}"/></span></td>
        <td><span class="voucher-main"><c:out value="${v.usedCount}"/> / <c:out value="${v.usageLimit}"/></span><span class="voucher-meta">Mỗi khách: <c:out value="${v.perCustomerLimit}"/> lần</span></td>
        <td><span class="voucher-badge ${v.status == 'Disabled' ? 'off' : (v.status == 'Expired' ? 'expired' : '')}"><c:choose><c:when test="${v.status == 'Allowed'}">Đang hoạt động</c:when><c:when test="${v.status == 'Disabled'}">Đã tắt</c:when><c:when test="${v.status == 'Expired'}">Đã hết hạn</c:when><c:otherwise><c:out value="${v.status}"/></c:otherwise></c:choose></span></td>
        <td><div class="voucher-actions"><a class="btn btn-soft" href="${ctx}/staff/voucher?action=edit&id=${v.voucherId}">Sửa</a><c:if test="${v.allowed}"><form method="post" action="${ctx}/staff/voucher" onsubmit="return confirm('Bạn có chắc muốn vô hiệu hóa voucher này?')"><input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="${v.voucherId}"><button class="btn btn-outline" type="submit" style="color:var(--danger);border-color:var(--danger)">Tắt</button></form></c:if></div></td>
      </tr></c:forEach>
      </tbody></table></div>
    </c:when><c:otherwise><div class="voucher-empty">Chưa có voucher phù hợp với tìm kiếm.</div></c:otherwise></c:choose>
  </div>
</div></section></main>
<%@ include file="../_footer.jspf" %>
