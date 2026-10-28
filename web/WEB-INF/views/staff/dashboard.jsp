<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Staff Dashboard"/>
<%@ include file="../_header.jspf" %>
<style>
  .staff-head { margin-bottom: 24px; }
  .staff-head h1 { margin-bottom: 8px; }
  .staff-head p { color: var(--slate-500); margin: 0; }
  .staff-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 18px; }
  .staff-card { display: flex; flex-direction: column; gap: 10px; min-height: 170px; padding: 24px; border: 1px solid var(--slate-200); border-radius: 16px; background: #fff; box-shadow: var(--shadow); }
  .staff-card .icon { font-size: 34px; }
  .staff-card h2 { margin: 0; font-size: 20px; }
  .staff-card p { color: var(--slate-500); margin: 0 0 8px; flex: 1; }
</style>
<main><section class="page"><div class="container">
  <div class="staff-head">
    <h1>Staff Dashboard</h1>
    <p>Xin chào <strong><c:out value="${sessionScope.authUser.fullName}"/></strong>. Chọn chức năng cần quản lý.</p>
  </div>
  <div class="staff-grid">
    <article class="staff-card"><div class="icon">🎟️</div><h2>Quản lý voucher</h2><p>Tạo, cập nhật, tìm kiếm và vô hiệu hóa mã ưu đãi.</p><a class="btn btn-cta" href="${ctx}/staff/voucher">Mở quản lý voucher</a></article>
    <article class="staff-card"><div class="icon">⭐</div><h2>Quản lý point</h2><p>Xem số dư MyPoint và cộng/trừ điểm thủ công cho khách hàng.</p><a class="btn btn-cta" href="${ctx}/staff/point">Mở quản lý point</a></article>
    <article class="staff-card"><div class="icon">🍿</div><h2>Quản lý combo</h2><p>Cập nhật giá, số lượng tồn kho, trạng thái và thông tin combo.</p><a class="btn btn-cta" href="${ctx}/staff/combo">Mở quản lý combo</a></article>
    <article class="staff-card"><div class="icon">🎫</div><h2>Đặt vé tại quầy</h2><p>Tiếp tục quy trình đặt vé trực tiếp tại rạp.</p><a class="btn btn-outline" href="${ctx}/staff/counter">Mở đặt vé</a></article>
    <c:if test="${sessionScope.authUser.role == 'MANAGER' || sessionScope.authUser.role == 'ADMIN'}">
      <article class="staff-card"><div class="icon">📰</div><h2>Quản lý tin tức</h2><p>Đăng, chỉnh sửa, ẩn hoặc xóa các bài viết tin tức của rạp.</p><a class="btn btn-cta" href="${ctx}/manager/news">Mở quản lý tin tức</a></article>
    </c:if>
  </div>
</div></section></main>
<%@ include file="../_footer.jspf" %>
