<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty news ? 'Đăng tin mới' : 'Sửa tin tức'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-form-card { max-width: 860px; }
  .uip-form-card textarea { width: 100%; padding: 11px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                            background: #fff; color: var(--slate-800); font: 15px var(--font); outline: none; resize: vertical; }
  .uip-form-card textarea:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-actions { display: flex; gap: 10px; margin-top: 8px; }
  .uip-preview { margin-top: 10px; }
  .uip-preview img { max-width: 320px; width: 100%; border-radius: 10px; border: 1px solid var(--slate-200); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="card uip-form-card">
        <h2><c:out value="${pageTitle}"/></h2>
        <p class="sub">Bài ở trạng thái “Xuất bản ngay” sẽ xuất hiện ngay trên trang Tin tức công khai.</p>
        <c:if test="${not empty error}"><p class="alert alert-error">${error}</p></c:if>
        <form method="post" action="${ctx}/manager/news">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="id" value="${news.newsId}">

          <div class="field">
            <label for="f-title">Tiêu đề (tối đa 200 ký tự)</label>
            <input id="f-title" type="text" name="title" maxlength="200" required
                   placeholder="VD: Khai trương rạp CineStar"
                   value="<c:out value='${news.title}'/>">
          </div>

          <div class="field">
            <label for="f-content">Nội dung</label>
            <textarea id="f-content" name="content" rows="10" required
                      placeholder="Nội dung bài viết..."><c:out value="${news.content}"/></textarea>
          </div>

          <div class="field">
            <label for="f-thumb">Link ảnh thumbnail</label>
            <input id="f-thumb" type="text" name="thumbnailUrl"
                   placeholder="https://... (để trống sẽ dùng ảnh mặc định)"
                   value="<c:out value='${news.thumbnailUrl}'/>">
            <c:if test="${not empty news.thumbnailUrl}">
              <div class="uip-preview"><img src="<c:out value='${news.thumbnailUrl}'/>" alt="Ảnh thumbnail hiện tại"></div>
            </c:if>
          </div>

          <div class="field">
            <label for="f-status">Trạng thái</label>
            <select id="f-status" name="status">
              <option value="Published" ${news.status == 'Published' ? 'selected' : ''}>Xuất bản ngay</option>
              <option value="Draft" ${news.status == 'Draft' ? 'selected' : ''}>Lưu bản nháp</option>
              <option value="Hidden" ${news.status == 'Hidden' ? 'selected' : ''}>Ẩn khỏi trang tin</option>
            </select>
          </div>

          <div class="uip-actions">
            <button class="btn btn-cta" type="submit">Lưu bài viết</button>
            <a class="btn btn-outline" href="${ctx}/manager/news">Hủy</a>
          </div>
        </form>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
