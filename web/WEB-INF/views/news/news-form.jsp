<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty news ? 'Đăng tin mới' : 'Sửa tin tức'}"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manager/news">${ic.chevronLeft}Danh sách tin</a><h1><c:out value="${pageTitle}"/></h1></div>
</div>
<form method="post" action="${ctx}/manager/news">
  <div class="split" style="grid-template-columns:minmax(0,1fr) 320px">
    <section class="card">
      <div class="card-body form">
        <c:if test="${not empty error}"><div class="alert alert-error" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="id" value="${news.newsId}">
        <div class="field">
          <label for="f-title">Tiêu đề<span class="req">*</span></label>
          <input id="f-title" type="text" name="title" maxlength="200" required placeholder="Khai trương rạp CineStar" value="<c:out value='${news.title}'/>">
          <span class="hint">Tối đa 200 ký tự.</span>
        </div>
        <div class="field">
          <label for="f-content">Nội dung<span class="req">*</span></label>
          <textarea id="f-content" name="content" rows="14" required placeholder="Nội dung bài viết..."><c:out value="${news.content}"/></textarea>
        </div>
      </div>
    </section>
    <aside class="stack sticky" style="--gap:16px">
      <section class="card">
        <div class="card-body form">
          <div class="field">
            <label for="f-status">Trạng thái</label>
            <select id="f-status" name="status">
              <option value="Published" ${news.status == 'Published' ? 'selected' : ''}>Xuất bản ngay</option>
              <option value="Draft" ${news.status == 'Draft' ? 'selected' : ''}>Lưu bản nháp</option>
              <option value="Hidden" ${news.status == 'Hidden' ? 'selected' : ''}>Ẩn khỏi trang tin</option>
            </select>
          </div>
          <div class="field">
            <label for="f-thumb">Link ảnh thumbnail</label>
            <input id="f-thumb" type="text" name="thumbnailUrl" placeholder="https://..." value="<c:out value='${news.thumbnailUrl}'/>">
            <span class="hint">Để trống sẽ dùng ảnh mặc định.</span>
          </div>
          <c:if test="${not empty news.thumbnailUrl}">
            <img src="${news.thumbnailUrl.startsWith('/') ? ctx : ''}<c:out value='${news.thumbnailUrl}'/>" alt="Ảnh thumbnail hiện tại" style="width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:var(--r-md)">
          </c:if>
        </div>
        <div class="card-foot">
          <a class="btn" href="${ctx}/manager/news">Hủy</a>
          <button class="btn btn-primary" type="submit">${ic.check}Lưu bài viết</button>
        </div>
      </section>
    </aside>
  </div>
</form>
<%@ include file="../layout/bottom.jspf" %>
