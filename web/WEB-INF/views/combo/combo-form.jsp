<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty combo ? 'Thêm combo mới' : 'Sửa combo'}"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <h1><c:out value="${pageTitle}"/></h1>
      <c:if test="${not empty error}"><p class="alert alert-error">${error}</p></c:if>
      <form method="post" action="${ctx}/staff/combo" class="form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="id" value="${combo.comboId}">
        <p><label>Tên combo (tối đa 100 ký tự)<br>
          <input type="text" name="comboName" maxlength="100" value="<c:out value='${combo.comboName}'/>" required></label></p>
        <p><label>Mô tả<br>
          <textarea name="description" rows="4"><c:out value="${combo.description}"/></textarea></label></p>
        <p><label>Giá (VNĐ)<br>
          <input type="number" name="price" value="${combo.price}" min="0" step="1000" required></label></p>
        <p><label>Tồn kho<br>
          <input type="number" name="stock" value="${combo.stock}" min="0" required></label></p>
        <p><label>Trạng thái
          <select name="status">
            <option value="Active" ${combo.status == 'Active' ? 'selected' : ''}>Đang bán</option>
            <option value="Hidden" ${combo.status == 'Hidden' ? 'selected' : ''}>Ẩn khỏi menu</option>
          </select></label></p>
        <button class="btn btn-cta" type="submit">Lưu</button>
        <a class="btn btn-outline" href="${ctx}/staff/combo">Hủy</a>
      </form>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
