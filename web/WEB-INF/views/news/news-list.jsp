<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý tin tức"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .news-thumb-sm { width: 72px; height: 46px; border-radius: var(--r-xs); object-fit: cover; background: var(--surface-3); display: grid; place-items: center; color: var(--subtle); flex: none; }
  .news-thumb-sm svg { width: 20px; height: 20px; }
</style>
<div class="page-head">
  <div><h1>Quản lý tin tức</h1><p>Đăng bài, lưu nháp hoặc ẩn tin khỏi trang tin tức công khai.</p></div>
  <a class="btn btn-primary" href="${ctx}/manager/news?action=add">${ic.plus}Đăng tin mới</a>
</div>
<section class="card">
  <form method="get" action="${ctx}/manager/news" class="toolbar" role="search">
    <div class="segmented" style="align-self:flex-end">
      <a class="${empty statusFilter ? 'active' : ''}" href="${ctx}/manager/news">Tất cả</a>
      <a class="${statusFilter == 'Published' ? 'active' : ''}" href="${ctx}/manager/news?status=Published">Đã xuất bản</a>
      <a class="${statusFilter == 'Draft' ? 'active' : ''}" href="${ctx}/manager/news?status=Draft">Bản nháp</a>
      <a class="${statusFilter == 'Hidden' ? 'active' : ''}" href="${ctx}/manager/news?status=Hidden">Đã ẩn</a>
    </div>
    <div class="field grow"><label for="q">Tìm kiếm</label><div class="input-group">${ic.search}<input id="q" type="search" name="q" placeholder="Tiêu đề bài viết" value="<c:out value='${keyword}'/>"></div></div>
    <c:if test="${not empty statusFilter}"><input type="hidden" name="status" value="${statusFilter}"></c:if>
    <button class="btn btn-primary" type="submit">Tìm</button>
  </form>
  <div class="table-wrap">
    <table class="table">
      <thead><tr><th>Bài viết</th><th>Tác giả</th><th>Ngày đăng</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
      <tbody>
        <c:forEach var="n" items="${newsList}">
          <tr>
            <td>
              <div class="person">
                <c:choose>
                  <c:when test="${not empty n.thumbnailUrl}"><img class="news-thumb-sm" src="${n.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${n.thumbnailUrl}'/>" alt=""></c:when>
                  <c:otherwise><span class="news-thumb-sm">${ic.news}</span></c:otherwise>
                </c:choose>
                <span class="cell-main" style="max-width:380px"><c:out value="${n.title}"/></span>
              </div>
            </td>
            <td><c:out value="${n.authorName}"/></td>
            <td class="muted text-sm nowrap">${n.createdAtLabel}</td>
            <td>
              <c:choose>
                <c:when test="${n.status == 'Published'}"><span class="badge badge-success badge-dot">Đã xuất bản</span></c:when>
                <c:when test="${n.status == 'Draft'}"><span class="badge badge-warning badge-dot">Bản nháp</span></c:when>
                <c:otherwise><span class="badge badge-dot">Đã ẩn</span></c:otherwise>
              </c:choose>
            </td>
            <td class="actions">
              <a class="btn btn-xs btn-ghost" href="${ctx}/manager/news?action=view&id=${n.newsId}">${ic.eye}Xem</a>
              <a class="btn btn-xs btn-soft" href="${ctx}/manager/news?action=edit&id=${n.newsId}">${ic.edit}Sửa</a>
              <form class="inline-form" method="post" action="${ctx}/manager/news" data-confirm="Xóa tin này?">
                <input type="hidden" name="_csrf" value="${csrf}">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${n.newsId}">
                <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button>
              </form>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty newsList}"><tr><td colspan="5"><div class="empty"><div class="empty-icon">${ic.news}</div><p>Không có tin tức nào. Bấm "Đăng tin mới" để tạo bài đầu tiên.</p></div></td></tr></c:if>
      </tbody>
    </table>
  </div>
</section>
<%@ include file="../layout/bottom.jspf" %>
