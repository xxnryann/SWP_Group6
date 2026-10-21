<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý combo"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <h1>Quản lý combo bắp nước</h1>
      <p><a class="btn btn-cta" href="${ctx}/staff/combo?action=add">+ Thêm combo mới</a></p>

      <form method="get" action="${ctx}/staff/combo" class="filter-bar">
        <input type="search" name="q" placeholder="Tìm theo tên combo..." value="<c:out value='${keyword}'/>">
        <button class="btn btn-outline" type="submit">Tìm</button>
      </form>

      <table class="table">
        <thead>
          <tr><th>ID</th><th>Tên combo</th><th>Giá (VNĐ)</th><th>Tồn kho</th><th>Trạng thái</th><th>Thao tác</th></tr>
        </thead>
        <tbody>
          <c:forEach var="c" items="${comboList}">
            <tr>
              <td>${c.comboId}</td>
              <td><c:out value="${c.comboName}"/></td>
              <td>${c.price}</td>
              <td>${c.stock}</td>
              <td>${c.statusLabel}</td>
              <td>
                <a href="${ctx}/staff/combo?action=edit&id=${c.comboId}">Sửa</a> |
                <form method="post" action="${ctx}/staff/combo" style="display:inline"
                      onsubmit="return confirm('Xóa combo này?')">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${c.comboId}">
                  <button class="btn-link" type="submit">Xóa</button>
                </form>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
      <c:if test="${empty comboList}"><p>Không có combo nào.</p></c:if>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
