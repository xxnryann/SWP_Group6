<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý thể loại"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../_header.jspf" %>

<main class="page"><div class="container">
  <section class="movie-page-heading">
    <div><h1>Quản lý thể loại</h1>
      <p class="sub">Tạo thể loại trước khi gán thể loại cho phim.</p></div>
    <a class="btn btn-outline" href="${ctx}/manage/movies">Quản lý phim</a>
  </section>
  <div class="dash-layout"><div>
    <form class="panel movie-form" method="post" action="${ctx}/manage/genres">
      <input type="hidden" name="_csrf" value="${escapedCsrf}">
      <input type="hidden" name="action" value="save">
      <input type="hidden" name="id" value="${editGenre.genreId}">
      <div class="movie-form-grid">
        <div class="field"><label for="genreName">Tên thể loại *</label>
          <input id="genreName" name="genreName" required minlength="2" maxlength="50"
                 pattern="[\p{L}\p{N}][\p{L}\p{N} &'().,/+-]*" value="<c:out value='${editGenre.genreName}'/>">
          <small class="field-note">Bắt buộc, từ 2 đến 50 ký tự.</small>
        </div>
        <div class="field"><label for="description">Mô tả</label>
          <input id="description" name="description" maxlength="200" value="<c:out value='${editGenre.description}'/>">
          <small class="field-note">Không bắt buộc, tối đa 200 ký tự.</small>
        </div>
      </div>
      <div class="movie-form-actions">
        <c:if test="${not empty editGenre}"><a class="btn btn-outline" href="${ctx}/manage/genres">Hủy sửa</a></c:if>
        <button class="btn btn-primary" type="submit"><c:choose><c:when test="${not empty editGenre}">Cập nhật</c:when><c:otherwise>Thêm thể loại</c:otherwise></c:choose></button>
      </div>
    </form>
    <div class="table-wrap"><table class="data"><thead><tr><th>Tên thể loại</th><th>Mô tả</th><th>Số phim đang dùng</th><th>Thao tác</th></tr></thead>
      <tbody><c:forEach var="genre" items="${genres}">
        <tr><td><strong><c:out value="${genre.genreName}"/></strong></td><td><c:out value="${genre.description}"/></td><td><c:out value="${genre.movieCount}"/></td><td>
          <a class="btn btn-soft btn-small" href="${ctx}/manage/genres?id=${genre.genreId}">Sửa</a>
          <form method="post" action="${ctx}/manage/genres" style="display:inline" onsubmit="return confirm('Xóa thể loại này?');">
            <input type="hidden" name="_csrf" value="${escapedCsrf}"><input type="hidden" name="action" value="delete">
            <input type="hidden" name="id" value="${genre.genreId}">
            <c:choose>
              <c:when test="${genre.movieCount gt 0}">
                <button class="btn btn-danger btn-small" type="button" disabled title="Đang được ${genre.movieCount} phim sử dụng">Xóa</button>
              </c:when>
              <c:otherwise><button class="btn btn-danger btn-small" type="submit">Xóa</button></c:otherwise>
            </c:choose>
          </form>
        </td></tr>
      </c:forEach><c:if test="${empty genres}"><tr><td colspan="4">Chưa có thể loại.</td></tr></c:if></tbody>
    </table></div>
  </div></div>
</div></main>
<%@ include file="../_footer.jspf" %>
