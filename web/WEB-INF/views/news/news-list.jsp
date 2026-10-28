<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý tin tức"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .uip-head h1 { margin: 0; }
  .uip-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .uip-filter { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-bottom: 18px; }
  .uip-filter .uip-search { margin-left: auto; display: flex; gap: 8px; }
  .uip-filter input[type=search] { padding: 9px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                                   font: 14px var(--font); min-width: 240px; outline: none; }
  .uip-filter input[type=search]:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-thumb { width: 56px; height: 40px; object-fit: cover; border-radius: 6px; vertical-align: middle; }
  .uip-thumb-ph { width: 56px; height: 40px; border-radius: 6px; display: inline-grid; place-items: center;
                   background: linear-gradient(135deg, var(--brand), var(--navy)); vertical-align: middle; font-size: 18px; }
  .uip-title { font-weight: 600; color: var(--navy); }
  .uip-badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .uip-badge-pub { background: #d1fae5; color: var(--success); }
  .uip-badge-draft { background: #fef3c7; color: #b45309; }
  .uip-badge-hidden { background: var(--slate-200); color: var(--slate-600); }
  .uip-actions { white-space: nowrap; }
  .uip-actions form { display: inline; }
  .uip-danger { color: var(--danger); }
  .uip-empty { text-align: center; padding: 44px 20px; color: var(--slate-500); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="uip-head">
        <div>
          <h1>Quản lý tin tức</h1>
          <p>Đăng, sửa và ẩn các bài tin tức hiển thị ở trang công khai.</p>
        </div>
        <a class="btn btn-cta" href="${ctx}/manager/news?action=add">+ Đăng tin mới</a>
      </div>

      <form method="get" action="${ctx}/manager/news" class="uip-filter">
        <a class="btn ${empty statusFilter ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news">Tất cả</a>
        <a class="btn ${statusFilter == 'Published' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Published">Đã xuất bản</a>
        <a class="btn ${statusFilter == 'Draft' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Draft">Bản nháp</a>
        <a class="btn ${statusFilter == 'Hidden' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Hidden">Đã ẩn</a>
        <span class="uip-search">
          <input type="search" name="q" placeholder="Tìm theo tiêu đề..." value="<c:out value='${keyword}'/>">
          <c:if test="${not empty statusFilter}"><input type="hidden" name="status" value="${statusFilter}"></c:if>
          <button class="btn btn-outline" type="submit">Tìm</button>
        </span>
      </form>

      <div class="table-wrap">
        <table class="data">
          <thead>
            <tr><th>Ảnh</th><th>Tiêu đề</th><th>Tác giả</th><th>Ngày đăng</th><th>Trạng thái</th><th style="text-align:right">Thao tác</th></tr>
          </thead>
          <tbody>
            <c:forEach var="n" items="${newsList}">
              <tr>
                <td>
                  <c:choose>
                    <c:when test="${not empty n.thumbnailUrl}"><img class="uip-thumb" src="${n.thumbnailUrl.startsWith('/') ? pageContext.request.contextPath : ''}<c:out value='${n.thumbnailUrl}'/>" alt=""></c:when>
                    <c:otherwise><span class="uip-thumb-ph">🎬</span></c:otherwise>
                  </c:choose>
                </td>
                <td><span class="uip-title"><c:out value="${n.title}"/></span></td>
                <td><c:out value="${n.authorName}"/></td>
                <td>${n.createdAtLabel}</td>
                <td>
                  <c:choose>
                    <c:when test="${n.status == 'Published'}"><span class="uip-badge uip-badge-pub">Đã xuất bản</span></c:when>
                    <c:when test="${n.status == 'Draft'}"><span class="uip-badge uip-badge-draft">Bản nháp</span></c:when>
                    <c:otherwise><span class="uip-badge uip-badge-hidden">Đã ẩn</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="uip-actions" style="text-align:right">
                  <a href="${ctx}/manager/news?action=view&id=${n.newsId}">Xem</a> ·
                  <a href="${ctx}/manager/news?action=edit&id=${n.newsId}">Sửa</a> ·
                  <form method="post" action="${ctx}/manager/news"
                        onsubmit="return confirm('Xóa tin này?')">
                    <input type="hidden" name="_csrf" value="${csrf}">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${n.newsId}">
                    <button class="btn-link uip-danger" type="submit">Xóa</button>
                  </form>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty newsList}">
              <tr><td colspan="6" class="uip-empty">Không có tin tức nào. Bấm “+ Đăng tin mới” để tạo bài đầu tiên.</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



