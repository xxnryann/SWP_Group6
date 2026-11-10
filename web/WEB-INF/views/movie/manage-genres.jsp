<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý thể loại"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/movies">${ic.chevronLeft}Quản lý phim</a><h1>Quản lý thể loại</h1><p>Tạo thể loại trước khi gán cho phim. Không xóa được thể loại đang có phim dùng.</p></div>
</div>
<div class="split" style="grid-template-columns:340px minmax(0,1fr)">
  <section class="card sticky">
    <div class="card-head"><div><h2>${not empty editGenre ? 'Sửa thể loại' : 'Thêm thể loại'}</h2></div></div>
    <form method="post" action="${ctx}/manage/genres">
      <div class="card-body form">
        <input type="hidden" name="_csrf" value="${escapedCsrf}">
        <input type="hidden" name="action" value="save">
        <input type="hidden" name="id" value="${editGenre.genreId}">
        <div class="field">
          <label for="genreName">Tên thể loại<span class="req">*</span></label>
          <input id="genreName" name="genreName" required minlength="2" maxlength="50" pattern="[\p{L}\p{N}][\p{L}\p{N} &'().,/+-]*" value="<c:out value='${editGenre.genreName}'/>">
          <span class="hint">Từ 2 đến 50 ký tự.</span>
        </div>
        <div class="field">
          <label for="description">Mô tả</label>
          <input id="description" name="description" maxlength="200" value="<c:out value='${editGenre.description}'/>">
          <span class="hint">Tối đa 200 ký tự.</span>
        </div>
      </div>
      <div class="card-foot">
        <c:if test="${not empty editGenre}"><a class="btn" href="${ctx}/manage/genres">Hủy sửa</a></c:if>
        <button class="btn btn-primary" type="submit">${not empty editGenre ? 'Cập nhật' : 'Thêm thể loại'}</button>
      </div>
    </form>
  </section>
  <section class="card">
    <div class="table-wrap">
      <table class="table">
        <thead><tr><th>Tên thể loại</th><th>Mô tả</th><th class="num">Số phim</th><th class="actions">Thao tác</th></tr></thead>
        <tbody>
          <c:forEach var="genre" items="${genres}">
            <tr>
              <td class="cell-main"><c:out value="${genre.genreName}"/></td>
              <td class="muted text-sm"><c:out value="${genre.description}"/></td>
              <td class="num"><span class="badge ${genre.movieCount gt 0 ? 'badge-brand' : ''}"><c:out value="${genre.movieCount}"/></span></td>
              <td class="actions">
                <a class="btn btn-xs btn-soft" href="${ctx}/manage/genres?id=${genre.genreId}">${ic.edit}Sửa</a>
                <form class="inline-form" method="post" action="${ctx}/manage/genres" data-confirm="Xóa thể loại này?">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}"><input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${genre.genreId}">
                  <c:choose>
                    <c:when test="${genre.movieCount gt 0}"><button class="btn btn-xs btn-danger" type="button" disabled title="Đang được ${genre.movieCount} phim sử dụng">${ic.trash}Xóa</button></c:when>
                    <c:otherwise><button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button></c:otherwise>
                  </c:choose>
                </form>
              </td>
            </tr>
          </c:forEach>
          <c:if test="${empty genres}"><tr><td colspan="4"><div class="empty"><div class="empty-icon">${ic.list}</div><p>Chưa có thể loại.</p></div></td></tr></c:if>
        </tbody>
      </table>
    </div>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
