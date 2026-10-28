<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý point"/>
<%@ include file="../_header.jspf" %>
<style>
  .point-head { display:flex;justify-content:space-between;gap:16px;align-items:center;flex-wrap:wrap;margin-bottom:18px; } .point-head h1{margin:0}.point-head p{margin:5px 0 0;color:var(--slate-500)}
  .point-search{display:flex;gap:8px;margin-bottom:18px}.point-search input{min-width:260px}
  .point-table{width:100%;border-collapse:collapse;background:#fff;box-shadow:var(--shadow);border-radius:14px;overflow:hidden}.point-table th,.point-table td{padding:14px;border-bottom:1px solid var(--slate-100);text-align:left}.point-table th{background:var(--slate-50);font-size:13px;color:var(--slate-600)}
  .point-form{display:flex;gap:6px;align-items:center}.point-form input{width:100px}.point-form button{white-space:nowrap}
</style>
<main><section class="page"><div class="container">
  <div class="point-head"><div><h1>Quản lý point</h1><p>Cộng điểm dùng số dương, trừ điểm dùng số âm. Không cho phép số dư âm.</p></div></div>
  <form class="point-search" method="get" action="${ctx}/staff/point"><input class="form-control" type="search" name="q" placeholder="Tìm tên hoặc email..." value="<c:out value='${keyword}'/>"><button class="btn btn-outline" type="submit">Tìm</button></form>
  <div style="overflow:auto"><table class="point-table"><thead><tr><th>Khách hàng</th><th>Email</th><th>Số dư point</th><th>Điều chỉnh</th></tr></thead><tbody>
    <c:forEach var="p" items="${pointCustomers}"><tr><td><strong><c:out value="${p.fullName}"/></strong><small>#<c:out value="${p.customerId}"/></small></td><td><c:out value="${p.email}"/></td><td><strong><c:out value="${p.pointBalance}"/></strong></td><td><form class="point-form" method="post" action="${ctx}/staff/point"><input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="customerId" value="${p.customerId}"><input class="form-control" type="number" name="points" required placeholder="+/- điểm"><button class="btn btn-cta" type="submit">Cập nhật</button></form></td></tr></c:forEach>
  </tbody></table></div>
  <c:if test="${empty pointCustomers}"><div class="uip-empty" style="margin-top:18px">Không có khách hàng nào.</div></c:if>
</div></section></main>
<%@ include file="../_footer.jspf" %>
