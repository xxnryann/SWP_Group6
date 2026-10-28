<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý combo"/>
<%@ include file="../_header.jspf" %>
<style>
  .combo-toolbar { display:flex; justify-content:space-between; align-items:flex-end; gap:18px; flex-wrap:wrap; margin-bottom:22px; }
  .combo-toolbar h1 { margin:0; } .combo-toolbar p { color:var(--slate-500); margin:6px 0 0; }
  .combo-search { display:flex; gap:8px; width:min(100%, 430px); } .combo-search input { flex:1; min-width:0; }
  .combo-panel { background:#fff; border:1px solid var(--slate-200); border-radius:16px; box-shadow:var(--shadow); overflow:hidden; }
  .combo-table { width:100%; border-collapse:collapse; min-width:850px; } .combo-table th,.combo-table td { padding:14px 16px; border-bottom:1px solid var(--slate-200); text-align:left; vertical-align:middle; }
  .combo-table th { background:#f8fafc; color:var(--slate-600); font-size:12px; text-transform:uppercase; letter-spacing:.03em; white-space:nowrap; }
  .combo-table tr:last-child td { border-bottom:0; } .combo-table tbody tr:hover { background:#f8fbff; }
  .combo-name { font-weight:800; color:var(--slate-800); } .combo-description { display:block; color:var(--slate-500); font-size:12px; max-width:280px; margin-top:4px; }
  .combo-price { font-weight:800; color:var(--cta); white-space:nowrap; } .combo-stock { font-weight:800; white-space:nowrap; } .combo-stock.ok { color:var(--success); } .combo-stock.low { color:#b45309; } .combo-stock.out { color:var(--danger); }
  .combo-status { display:inline-flex; padding:5px 10px; border-radius:999px; font-size:12px; font-weight:800; background:#dcfce7; color:#166534; white-space:nowrap; } .combo-status.off { background:#e2e8f0; color:#475569; }
  .combo-actions { display:flex; gap:7px; white-space:nowrap; } .combo-actions form { margin:0; }
</style>
<main><section class="page"><div class="container">
  <div class="combo-toolbar"><div><h1>Quản lý combo</h1><p>Theo dõi giá bán, trạng thái và số lượng combo còn trong kho.</p></div>
    <form class="combo-search" method="get" action="${ctx}/staff/combo"><input class="form-control" type="search" name="q" placeholder="Tìm tên combo..." value="<c:out value='${keyword}'/>"><button class="btn btn-outline" type="submit">Tìm kiếm</button></form>
    <a class="btn btn-cta" href="${ctx}/staff/combo?action=add">+ Thêm combo</a>
  </div>
  <div class="combo-panel"><div style="overflow-x:auto"><table class="combo-table"><thead><tr><th>Combo</th><th>Giá bán</th><th>Tồn kho hiện tại</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>
    <c:forEach var="c" items="${comboList}"><tr>
      <td><span class="combo-name"><c:out value="${c.comboName}"/></span><span class="combo-description"><c:out value="${c.description}"/></span></td>
      <td><span class="combo-price"><c:out value="${c.priceLabel}"/> VNĐ</span></td>
      <td><c:choose><c:when test="${c.stock == 0}"><span class="combo-stock out">Hết hàng (0 phần)</span></c:when><c:when test="${c.stock <= 10}"><span class="combo-stock low">Sắp hết — còn <c:out value="${c.stock}"/> phần</span></c:when><c:otherwise><span class="combo-stock ok">Còn <c:out value="${c.stock}"/> phần</span></c:otherwise></c:choose></td>
      <td><span class="combo-status ${!c.active ? 'off' : ''}"><c:choose><c:when test="${c.active}">Đang bán</c:when><c:otherwise>Đã ẩn</c:otherwise></c:choose></span></td>
      <td><div class="combo-actions"><a class="btn btn-soft" href="${ctx}/staff/combo?action=edit&id=${c.comboId}">Sửa</a><form method="post" action="${ctx}/staff/combo" onsubmit="return confirm('Bạn có chắc muốn xóa combo này?')"><input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="${c.comboId}"><button class="btn btn-outline" type="submit" style="color:var(--danger);border-color:var(--danger)">Xóa</button></form></div></td>
    </tr></c:forEach>
  </tbody></table></div><c:if test="${empty comboList}"><div style="padding:48px;text-align:center;color:var(--slate-500)">Chưa có combo nào.</div></c:if></div>
</div></section></main>
<%@ include file="../_footer.jspf" %>
