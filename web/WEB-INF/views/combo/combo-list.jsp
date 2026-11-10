<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý combo"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .combo-card { display: flex; flex-direction: column; overflow: hidden; }
  .combo-thumb { position: relative; aspect-ratio: 16 / 10; display: grid; place-items: center; background: linear-gradient(135deg, var(--accent-50), var(--brand-50)); color: var(--accent-700); }
  .combo-thumb img { width: 100%; height: 100%; object-fit: cover; }
  .combo-thumb > svg { width: 44px; height: 44px; }
  .combo-thumb .badge { position: absolute; top: 10px; right: 10px; }
  .combo-card .card-body { display: flex; flex-direction: column; gap: 6px; flex: 1; }
  .combo-card p { color: var(--muted); font-size: 13.5px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .combo-price { color: var(--ink); font-size: 22px; font-weight: 800; letter-spacing: -.02em; margin-top: auto; padding-top: 6px; }
</style>
<div class="page-head">
  <div><h1>Quản lý combo bắp nước</h1><p>Thêm, sửa giá, ẩn hoặc xóa combo bán kèm vé.</p></div>
  <a class="btn btn-primary" href="${ctx}/staff/combo?action=add">${ic.plus}Thêm combo</a>
</div>

<section class="card mb-24">
  <form method="get" action="${ctx}/staff/combo" class="toolbar" style="border-bottom:0" role="search">
    <div class="field grow"><label for="q">Tìm kiếm</label><div class="input-group">${ic.search}<input id="q" type="search" name="q" placeholder="Tên combo" value="<c:out value='${keyword}'/>"></div></div>
    <button class="btn btn-primary" type="submit">Tìm</button>
    <c:if test="${not empty keyword}"><a class="btn btn-ghost" href="${ctx}/staff/combo">Xóa lọc</a></c:if>
  </form>
</section>

<c:choose>
  <c:when test="${empty comboList}"><div class="card empty"><div class="empty-icon">${ic.popcorn}</div><h3>Không có combo nào</h3><p>Bấm "Thêm combo" để tạo combo đầu tiên.</p></div></c:when>
  <c:otherwise>
    <div class="grid grid-auto" style="--min:250px">
      <c:forEach var="cb" items="${comboList}">
        <article class="card combo-card">
          <div class="combo-thumb">
            <c:choose>
              <c:when test="${cb.hasImage()}"><img src="<c:out value='${cb.imageUrl}'/>" alt=""></c:when>
              <c:otherwise>${ic.popcorn}</c:otherwise>
            </c:choose>
            <c:choose>
              <c:when test="${cb.active}"><span class="badge badge-success badge-dot">Đang bán</span></c:when>
              <c:otherwise><span class="badge badge-dark">Đã ẩn</span></c:otherwise>
            </c:choose>
          </div>
          <div class="card-body">
            <h3 style="font-size:17px"><c:out value="${cb.comboName}"/></h3>
            <p><c:out value="${cb.description}"/></p>
            <div class="combo-price">${cb.priceLabel} <span class="muted text-sm fw-600">đ</span></div>
          </div>
          <div class="card-foot" style="justify-content:space-between">
            <a class="btn btn-sm btn-soft" href="${ctx}/staff/combo?action=edit&id=${cb.comboId}">${ic.edit}Sửa</a>
            <form method="post" action="${ctx}/staff/combo" data-confirm="Xóa combo này?">
              <input type="hidden" name="_csrf" value="${csrf}">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="${cb.comboId}">
              <button class="btn btn-sm btn-danger" type="submit">${ic.trash}Xóa</button>
            </form>
          </div>
        </article>
      </c:forEach>
    </div>
  </c:otherwise>
</c:choose>
<%@ include file="../layout/bottom.jspf" %>
