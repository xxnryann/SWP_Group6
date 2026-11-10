<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Kiểm duyệt đánh giá"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><h1>Kiểm duyệt đánh giá</h1><p>Chỉ xóa bình luận vi phạm; điểm sao của khách hàng luôn được giữ nguyên.</p></div>
</div>

<div class="split mb-24" style="grid-template-columns:minmax(0,1fr) minmax(0,1fr) minmax(0,2fr)">
  <div class="stat"><div class="stat-icon">${ic.star}</div><div class="stat-label">Tổng đánh giá phim đang chiếu</div><div class="stat-value">${summaryTotal}</div></div>
  <div class="stat"><div class="stat-icon success">${ic.message}</div><div class="stat-label">Bình luận đang hiển thị</div><div class="stat-value">${summaryComments}</div></div>
  <div class="card card-pad">
    <p class="stat-label mb-8">Điểm trung bình theo phim</p>
    <div class="stack" style="--gap:6px;max-height:120px;overflow:auto">
      <c:forEach var="movieSummary" items="${movieSummaries}">
        <div class="kv" style="padding:4px 0"><span class="truncate"><c:out value="${movieSummary.title}"/></span><strong><span class="stars">★</span> ${movieSummary.average_rating}/5 <span class="muted text-xs fw-600">(${movieSummary.review_count})</span></strong></div>
      </c:forEach>
    </div>
  </div>
</div>

<section class="card">
  <form class="toolbar" method="get" action="${ctx}/manage/reviews">
    <div class="field grow">
      <label for="fMovie">Phim đang chiếu</label>
      <select id="fMovie" name="movie"><option value="">Tất cả phim</option><c:forEach var="movieOption" items="${reviewMovies}"><option value="${movieOption.movie_id}" ${filterMovie == movieOption.movie_id ? 'selected' : ''}><c:out value="${movieOption.title}"/></option></c:forEach></select>
    </div>
    <div class="field"><label for="fRating">Số sao</label>
      <select id="fRating" name="rating"><option value="">Tất cả</option><c:forEach var="n" begin="1" end="5"><option value="${n}" ${filterRating == n ? 'selected' : ''}>${n} sao</option></c:forEach></select></div>
    <div class="field"><label for="fFrom">Từ ngày</label><input id="fFrom" type="date" name="from" value="${filterFrom}"></div>
    <div class="field"><label for="fTo">Đến ngày</label><input id="fTo" type="date" name="to" value="${filterTo}"></div>
    <div class="field"><label for="fStatus">Trạng thái</label>
      <select id="fStatus" name="status"><option value="">Tất cả</option><option value="visible" ${filterStatus == 'visible' ? 'selected' : ''}>Đang hiển thị</option><option value="deleted" ${filterStatus == 'deleted' ? 'selected' : ''}>Đã xóa bởi quản lý</option><option value="reported" ${filterStatus == 'reported' ? 'selected' : ''}>Có báo cáo</option></select></div>
    <button class="btn btn-primary" type="submit">${ic.filter}Lọc</button>
    <a class="btn btn-ghost" href="${ctx}/manage/reviews">Xóa lọc</a>
  </form>

  <div class="table-wrap">
    <table class="table">
      <thead><tr><th>Phim / Khách hàng</th><th>Sao</th><th>Bình luận</th><th>Trạng thái</th><th class="num">Báo cáo</th><th>Ngày</th><th class="actions">Thao tác</th></tr></thead>
      <tbody>
        <c:forEach var="review" items="${reviews}">
          <tr>
            <td><span class="cell-main"><c:out value="${review.movie_title}"/></span><span class="cell-sub"><c:out value="${review.customer_name}"/></span></td>
            <td class="nowrap"><span class="stars"><c:forEach begin="1" end="${review.rating}">★</c:forEach><span class="off"><c:forEach begin="${review.rating + 1}" end="5">★</c:forEach></span></span></td>
            <td class="text-sm" style="max-width:320px">
              <c:choose>
                <c:when test="${not empty review.comment}"><c:out value="${review.comment}"/></c:when>
                <c:otherwise><em class="muted">Nội dung đã ẩn</em></c:otherwise>
              </c:choose>
            </td>
            <td>
              <c:choose>
                <c:when test="${not empty review.moderated_at}"><span class="badge badge-danger">Đã xóa</span><span class="cell-sub"><c:out value="${review.moderated_by}"/> · <c:out value="${review.moderated_at}"/></span></c:when>
                <c:otherwise><span class="badge badge-success badge-dot">Hiển thị</span></c:otherwise>
              </c:choose>
            </td>
            <td class="num"><span class="badge ${review.report_count gt 0 ? 'badge-warning' : ''}"><c:out value="${review.report_count}"/></span></td>
            <td class="muted text-sm nowrap"><c:out value="${review.created_at}"/></td>
            <td class="actions">
              <c:if test="${not empty review.comment}">
                <form method="post" action="${ctx}/manage/reviews" class="js-moderate">
                  <input type="hidden" name="_csrf" value="${escapedCsrf}">
                  <input type="hidden" name="action" value="delete-comment">
                  <input type="hidden" name="id" value="${review.review_id}">
                  <input type="hidden" name="reason">
                  <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa bình luận</button>
                </form>
              </c:if>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty reviews}"><tr><td colspan="7"><div class="empty"><div class="empty-icon">${ic.message}</div><p>Chưa có đánh giá nào.</p></div></td></tr></c:if>
      </tbody>
    </table>
  </div>
</section>
<c:if test="${reviewPageCount > 1}">
  <nav class="pager" aria-label="Phân trang đánh giá">
    <c:forEach var="p" begin="1" end="${reviewPageCount}">
      <c:url var="pageUrl" value="/manage/reviews"><c:param name="page" value="${p}"/><c:param name="movie" value="${filterMovie}"/><c:param name="rating" value="${filterRating}"/><c:param name="from" value="${filterFrom}"/><c:param name="to" value="${filterTo}"/><c:param name="status" value="${filterStatus}"/></c:url>
      <a class="${p == reviewCurrentPage ? 'active' : ''}" href="<c:out value='${pageUrl}'/>">${p}</a>
    </c:forEach>
  </nav>
</c:if>
<script>
  document.querySelectorAll('form.js-moderate').forEach(function (f) {
    f.addEventListener('submit', function (e) {
      if (!confirm('Bạn có chắc muốn xóa bình luận này? Thao tác không thể hoàn tác, điểm sao vẫn được giữ nguyên.')) { e.preventDefault(); return; }
      var r = prompt('Nhập lý do xóa (spam, ngôn từ thô tục, nội dung vi phạm...):');
      if (!r || !r.trim()) { e.preventDefault(); return; }
      f.reason.value = r.trim();
    });
  });
</script>
<%@ include file="../layout/bottom.jspf" %>
