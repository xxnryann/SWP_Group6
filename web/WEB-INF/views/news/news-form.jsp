<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty news ? 'Đăng tin mới' : 'Sửa tin tức'}"/>
<%@ include file="../_header.jspf" %>
<main>
  <section class="page">
    <div class="container">
      <h1><c:out value="${pageTitle}"/></h1>
      <c:if test="${not empty error}"><p class="alert alert-error">${error}</p></c:if>
      <form method="post" action="${ctx}/manager/news" class="form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="id" value="${news.newsId}">
        <p><label>Tiêu đề (tối đa 200 ký tự)<br>
          <input type="text" name="title" maxlength="200" value="<c:out value='${news.title}'/>" required></label></p>
        <p><label>Nội dung<br>
          <textarea name="content" rows="10" required><c:out value="${news.content}"/></textarea></label></p>
        <p><label>Link ảnh thumbnail<br>
          <input type="text" name="thumbnailUrl" value="<c:out value='${news.thumbnailUrl}'/>"></label></p>
        <p><label>Trạng thái
          <select name="status">
            <option value="Published" ${news.status == 'Published' ? 'selected' : ''}>Xuất bản ngay</option>
            <option value="Draft" ${news.status == 'Draft' ? 'selected' : ''}>Lưu bản nháp</option>
            <option value="Hidden" ${news.status == 'Hidden' ? 'selected' : ''}>Ẩn khỏi trang tin</option>
          </select></label></p>
        <button class="btn btn-cta" type="submit">Lưu</button>
        <a class="btn btn-outline" href="${ctx}/manager/news">Hủy</a>
      </form>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
