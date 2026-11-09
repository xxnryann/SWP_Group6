<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Kiểm duyệt đánh giá"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="movie-page-heading">
    <div><p class="eyebrow">KHU VỰC QUẢN LÝ</p><h1>Kiểm duyệt đánh giá</h1>
      <p class="sub">Chỉ được xóa bình luận vi phạm; điểm sao của khách hàng luôn được giữ nguyên.</p></div>
  </section>
  <div class="review-stats">
    <div class="review-stat-card"><span>Tổng đánh giá phim đang chiếu:</span><strong>${summaryTotal}</strong></div>
    <div class="review-stat-card"><span>Bình luận đang hiển thị:</span><strong>${summaryComments}</strong></div>
    <div class="review-stat-card review-stat-movies">
      <span>Điểm trung bình theo phim:</span>
      <c:forEach var="movieSummary" items="${movieSummaries}">
        <div class="movie-rating-summary"><strong><c:out value="${movieSummary.title}"/>:</strong><span>★ ${movieSummary.average_rating}/5 (${movieSummary.review_count} đánh giá)</span></div>
      </c:forEach>
    </div>
  </div>
  <form class="panel review-filters" method="get" action="${ctx}/manage/reviews">
    <label class="review-filter-field">Phim đang chiếu:
      <select name="movie"><option value="">Tất cả phim</option><c:forEach var="movieOption" items="${reviewMovies}"><option value="${movieOption.movie_id}" <c:if test="${filterMovie == movieOption.movie_id}">selected</c:if>><c:out value="${movieOption.title}"/></option></c:forEach></select>
    </label>
    <label class="review-filter-field">Số sao:
      <select name="rating"><option value="">Tất cả sao</option><c:forEach var="n" begin="1" end="5"><option value="${n}" <c:if test="${filterRating == n}">selected</c:if>>${n} sao</option></c:forEach></select>
    </label>
    <label class="review-filter-field">Từ ngày:<input type="date" name="from" value="${filterFrom}"></label>
    <label class="review-filter-field">Đến ngày:<input type="date" name="to" value="${filterTo}"></label>
    <label class="review-filter-field">Trạng thái:
      <select name="status"><option value="">Tất cả trạng thái</option><option value="visible" <c:if test="${filterStatus == 'visible'}">selected</c:if>>Đang hiển thị</option><option value="deleted" <c:if test="${filterStatus == 'deleted'}">selected</c:if>>Đã xóa bởi quản lý</option><option value="reported" <c:if test="${filterStatus == 'reported'}">selected</c:if>>Có báo cáo</option></select>
    </label>
    <button class="btn btn-primary btn-small" type="submit">Lọc</button><a class="btn btn-outline btn-small" href="${ctx}/manage/reviews">Xóa lọc</a>
  </form>
  <div class="table-wrap"><table class="data">
    <thead><tr><th>Phim</th><th>Khách hàng</th><th>Đánh giá sao</th><th>Bình luận</th><th>Trạng thái</th><th>Báo cáo</th><th>Ngày đánh giá</th><th>Người xử lý</th><th>Thao tác</th></tr></thead>
    <tbody>
      <c:forEach var="review" items="${reviews}">
        <tr>
          <td><strong><c:out value="${review.movie_title}"/></strong></td>
          <td><c:out value="${review.customer_name}"/></td>
          <td><span class="review-stars"><c:forEach begin="1" end="${review.rating}">★</c:forEach><c:forEach begin="${review.rating + 1}" end="5">☆</c:forEach></span></td>
          <td><c:choose><c:when test="${not empty review.comment}"><details><summary>Xem bình luận</summary><p><c:out value="${review.comment}"/></p></details></c:when><c:otherwise><em>Nội dung đã ẩn</em></c:otherwise></c:choose></td>
          <td><c:choose><c:when test="${not empty review.moderated_at}">Đã xóa bởi quản lý</c:when><c:otherwise>Đang hiển thị</c:otherwise></c:choose></td>
          <td><c:out value="${review.report_count}"/></td>
          <td><c:out value="${review.created_at}"/></td>
          <td><c:out value="${review.moderated_by}"/> <c:out value="${review.moderated_at}"/></td>
          <td>
            <c:if test="${not empty review.comment}">
              <form method="post" action="${ctx}/manage/reviews" onsubmit="if (!confirm('Bạn có chắc muốn xóa bình luận này? Thao tác không thể hoàn tác, điểm sao vẫn được giữ nguyên.')) return false; var r=prompt('Nhập lý do xóa (spam, ngôn từ thô tục, nội dung vi phạm...):'); if (!r || !r.trim()) return false; this.reason.value=r.trim(); return true;">
                <input type="hidden" name="_csrf" value="${escapedCsrf}">
                <input type="hidden" name="action" value="delete-comment">
                <input type="hidden" name="id" value="${review.review_id}">
                <input type="hidden" name="reason">
                <button class="btn btn-danger btn-small" type="submit">Xóa bình luận</button>
              </form>
            </c:if>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty reviews}"><tr><td colspan="9">Chưa có đánh giá nào.</td></tr></c:if>
    </tbody>
  </table></div>
  <c:if test="${reviewPageCount > 1}"><nav class="pagination"><c:forEach var="p" begin="1" end="${reviewPageCount}"><c:url var="pageUrl" value="/manage/reviews"><c:param name="page" value="${p}"/><c:param name="movie" value="${filterMovie}"/><c:param name="rating" value="${filterRating}"/><c:param name="from" value="${filterFrom}"/><c:param name="to" value="${filterTo}"/><c:param name="status" value="${filterStatus}"/></c:url><a class="btn btn-small ${p == reviewCurrentPage ? 'btn-primary' : 'btn-outline'}" href="${pageUrl}">${p}</a></c:forEach></nav></c:if>
</div></main>
<%@ include file="../_footer.jspf" %>
