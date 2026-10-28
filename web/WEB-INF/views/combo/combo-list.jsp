<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý combo"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .uip-head h1 { margin: 0; }
  .uip-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .uip-search { display: flex; gap: 8px; margin-bottom: 20px; }
  .uip-search input[type=search] { padding: 9px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                                   font: 14px var(--font); min-width: 260px; outline: none; background: #fff; }
  .uip-search input[type=search]:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 20px; }
  .uip-ccard { background: #fff; border: 1px solid var(--slate-200); border-radius: 14px; overflow: hidden;
               box-shadow: var(--shadow); display: flex; flex-direction: column; }
  .uip-ccard .uip-top { background: linear-gradient(135deg, #fff7ed, #ffedd5); padding: 22px; text-align: center;
                        font-size: 46px; position: relative; }
  .uip-ccard .uip-status { position: absolute; top: 12px; right: 12px; }
  .uip-ccard .uip-body { padding: 16px 18px 18px; display: flex; flex-direction: column; gap: 8px; flex: 1; }
  .uip-ccard h3 { margin: 0; font-size: 17px; }
  .uip-desc { color: var(--slate-500); font-size: 13.5px; margin: 0; display: -webkit-box; -webkit-line-clamp: 2;
              -webkit-box-orient: vertical; overflow: hidden; }
  .uip-price { color: var(--cta); font-weight: 800; font-size: 22px; }
  .uip-price-wrap small { color: var(--slate-500); font-weight: 600; font-size: 13px; }
  .uip-stock { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .uip-stock-ok { background: #d1fae5; color: var(--success); }
  .uip-stock-low { background: #fef3c7; color: #b45309; }
  .uip-stock-out { background: #fee2e2; color: var(--danger); }
  .uip-badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .uip-badge-on { background: #dbeafe; color: var(--brand); }
  .uip-badge-off { background: var(--slate-200); color: var(--slate-600); }
  .uip-actions { margin-top: auto; display: flex; gap: 8px; padding-top: 12px; border-top: 1px solid var(--slate-100); }
  .uip-actions form { display: inline; }
  .uip-empty { text-align: center; padding: 52px 20px; background: #fff; border: 1px dashed var(--slate-300);
               border-radius: 14px; color: var(--slate-500); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="uip-head">
        <div>
          <h1>Quản lý combo bắp nước</h1>
          <p>Cập nhật giá và tồn kho các combo bán kèm vé tại rạp (SRS: Staff cập nhật tồn kho &amp; giá combo).</p>
        </div>
        <a class="btn btn-cta" href="${ctx}/staff/combo?action=add">+ Thêm combo mới</a>
      </div>

      <form method="get" action="${ctx}/staff/combo" class="uip-search">
        <input type="search" name="q" placeholder="Tìm theo tên combo..." value="<c:out value='${keyword}'/>">
        <button class="btn btn-outline" type="submit">Tìm</button>
      </form>

      <div class="uip-grid">
        <c:forEach var="c" items="${comboList}">
          <article class="uip-ccard">
            <div class="uip-top">🍿
              <span class="uip-status">
                <c:choose>
                  <c:when test="${c.active}"><span class="uip-badge uip-badge-on">Đang bán</span></c:when>
                  <c:otherwise><span class="uip-badge uip-badge-off">Đã ẩn</span></c:otherwise>
                </c:choose>
              </span>
            </div>
            <div class="uip-body">
              <h3><c:out value="${c.comboName}"/></h3>
              <p class="uip-desc"><c:out value="${c.description}"/></p>
              <div class="uip-price-wrap"><span class="uip-price">${c.priceLabel}</span> <small>VNĐ</small></div>
              <div>
                <c:choose>
                  <c:when test="${c.stock == 0}"><span class="uip-stock uip-stock-out">Hết hàng</span></c:when>
                  <c:when test="${c.stock <= 10}"><span class="uip-stock uip-stock-low">Sắp hết · còn ${c.stock}</span></c:when>
                  <c:otherwise><span class="uip-stock uip-stock-ok">Còn ${c.stock} phần</span></c:otherwise>
                </c:choose>
              </div>
              <div class="uip-actions">
                <a class="btn btn-soft" href="${ctx}/staff/combo?action=edit&id=${c.comboId}">Sửa</a>
                <form method="post" action="${ctx}/staff/combo"
                      onsubmit="return confirm('Xóa combo này?')">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${c.comboId}">
                  <button class="btn btn-outline" type="submit" style="color:var(--danger);border-color:var(--danger)">Xóa</button>
                </form>
              </div>
            </div>
          </article>
        </c:forEach>
      </div>
      <c:if test="${empty comboList}"><div class="uip-empty">🍿<br>Không có combo nào.</div></c:if>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
