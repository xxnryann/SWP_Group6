<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty combo ? 'Thêm combo mới' : 'Sửa combo'}"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/staff/combo">${ic.chevronLeft}Danh sách combo</a><h1><c:out value="${pageTitle}"/></h1></div>
</div>
<div class="split" style="grid-template-columns:minmax(0,1fr) 300px">
  <section class="card">
    <form method="post" action="${ctx}/staff/combo">
      <div class="card-body form-grid">
        <c:if test="${not empty error}"><div class="alert alert-error full" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="id" value="${combo.comboId}">
        <div class="field full">
          <label for="f-name">Tên combo<span class="req">*</span></label>
          <input id="f-name" type="text" name="comboName" maxlength="100" required placeholder="Combo Solo (1 bắp + 1 nước)" value="<c:out value='${combo.comboName}'/>">
          <span class="hint">Tối đa 100 ký tự.</span>
        </div>
        <div class="field full">
          <label for="f-desc">Mô tả</label>
          <textarea id="f-desc" name="description" rows="3" placeholder="Thành phần của combo..."><c:out value="${combo.description}"/></textarea>
        </div>
        <div class="field">
          <label for="f-price">Giá (đ)<span class="req">*</span></label>
          <input id="f-price" type="number" name="price" min="0" step="1000" required value="${combo.price}">
        </div>
        <div class="field">
          <label for="f-status">Trạng thái</label>
          <select id="f-status" name="status">
            <option value="Active" ${combo.status == 'Active' ? 'selected' : ''}>Đang bán</option>
            <option value="Hidden" ${combo.status == 'Hidden' ? 'selected' : ''}>Ẩn khỏi menu</option>
          </select>
        </div>
        <div class="field full">
          <label for="f-image">Ảnh minh họa (URL)</label>
          <div class="input-group">${ic.image}<input id="f-image" type="url" name="imageUrl" maxlength="500" placeholder="https://example.com/combo.jpg" value="<c:out value='${combo.imageUrl}'/>"></div>
        </div>
      </div>
      <div class="card-foot">
        <a class="btn" href="${ctx}/staff/combo">Hủy</a>
        <button class="btn btn-primary" type="submit">${ic.check}Lưu combo</button>
      </div>
    </form>
  </section>
  <aside class="card card-pad sticky">
    <p class="label mb-8">Xem trước ảnh</p>
    <div style="aspect-ratio:16/10;border-radius:var(--r-md);overflow:hidden;background:var(--surface-3);display:grid;place-items:center;color:var(--subtle)">
      <c:choose>
        <c:when test="${combo.hasImage()}"><img id="image-preview" src="<c:out value='${combo.imageUrl}'/>" alt="Ảnh minh họa combo" style="width:100%;height:100%;object-fit:cover"></c:when>
        <c:otherwise><img id="image-preview" alt="Xem trước ảnh" hidden style="width:100%;height:100%;object-fit:cover"></c:otherwise>
      </c:choose>
    </div>
    <p class="hint mt-8">Ảnh hiện trên menu combo khi khách đặt vé và khi bán tại quầy.</p>
  </aside>
</div>
<script>
  (function () {
    var input = document.getElementById('f-image'), preview = document.getElementById('image-preview');
    if (!input || !preview) return;
    input.addEventListener('input', function () { var v = input.value.trim(); preview.src = v; preview.hidden = !v; });
    preview.addEventListener('error', function () { preview.hidden = true; });
  })();
</script>
<%@ include file="../layout/bottom.jspf" %>
