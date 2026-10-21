<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý tin tức"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <h1>Quản lý tin tức</h1>
      <p><a class="btn btn-cta" href="${ctx}/manager/news?action=add">+ Đăng tin mới</a></p>

      <!-- Tab lọc trạng thái + tìm kiếm (theo mockup) -->
      <form method="get" action="${ctx}/manager/news" class="filter-bar">
        <a class="btn ${empty statusFilter ? 'btn-cta' : 'btn-outline'}" href="${ctx}/manager/news">Tất cả</a>
        <a class="btn ${statusFilter == 'Published' ? 'btn-cta' : 'btn-outline'}" href="${ctx}/manager/news?status=Published">Đã xuất bản</a>
        <a class="btn ${statusFilter == 'Draft' ? 'btn-cta' : 'btn-outline'}" href="${ctx}/manager/news?status=Draft">Bản nháp</a>
        <a class="btn ${statusFilter == 'Hidden' ? 'btn-cta' : 'btn-outline'}" href="${ctx}/manager/news?status=Hidden">Đã ẩn</a>
        <input type="search" name="q" placeholder="Tìm theo tiêu đề..." value="<c:out value='${keyword}'/>">
        <c:if test="${not empty statusFilter}"><input type="hidden" name="status" value="${statusFilter}"></c:if>
        <button class="btn btn-outline" type="submit">Tìm</button>
      </form>

      <table class="table">
        <thead>
          <tr><th>ID</th><th>Tiêu đề</th><th>Tác giả</th><th>Ngày đăng</th><th>Trạng thái</th><th>Thao tác</th></tr>
        </thead>
        <tbody>
          <c:forEach var="n" items="${newsList}">
            <tr>
              <td>${n.newsId}</td>
              <td><c:out value="${n.title}"/></td>
              <td><c:out value="${n.authorName}"/></td>
              <td>${n.createdAt}</td>
              <td>${n.statusLabel}</td>
              <td>
                <a href="${ctx}/manager/news?action=view&id=${n.newsId}">Xem</a> |
                <a href="${ctx}/manager/news?action=edit&id=${n.newsId}">Sửa</a> |
                <form method="post" action="${ctx}/manager/news" style="display:inline"
                      onsubmit="return confirm('Xóa tin này?')">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${n.newsId}">
                  <button class="btn-link" type="submit">Xóa</button>
                </form>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
      <c:if test="${empty newsList}"><p>Không có tin tức nào.</p></c:if>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
