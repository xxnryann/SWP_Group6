<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Kiểm duyệt đánh giá"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="movie-page-heading">
    <div><p class="eyebrow">KHU VỰC QUẢN LÝ</p><h1>Kiểm duyệt đánh giá</h1>
      <p class="sub">Chỉ được xóa bình luận vi phạm; điểm sao của khách hàng luôn được giữ nguyên.</p></div>
    <a class="btn btn-outline" href="${ctx}/manage/movies">Quản lý phim</a>
  </section>
  <div class="table-wrap"><table class="data">
    <thead><tr><th>Phim</th><th>Khách hàng</th><th>Đánh giá sao</th><th>Bình luận</th><th>Ngày</th><th>Thao tác</th></tr></thead>
    <tbody>
      <c:forEach var="review" items="${reviews}">
        <tr>
          <td><strong><c:out value="${review.movie_title}"/></strong></td>
          <td><c:out value="${review.customer_name}"/></td>
          <td><span class="review-stars"><c:forEach begin="1" end="${review.rating}">★</c:forEach><c:forEach begin="${review.rating + 1}" end="5">☆</c:forEach></span></td>
          <td><c:choose><c:when test="${not empty review.comment}"><c:out value="${review.comment}"/></c:when><c:otherwise><em>Đã xóa bình luận</em></c:otherwise></c:choose></td>
          <td><c:out value="${review.created_at}"/></td>
          <td>
            <c:if test="${not empty review.comment}">
              <form method="post" action="${ctx}/manage/reviews" onsubmit="var r=prompt('Nhập lý do xóa bình luận:'); if (!r || !r.trim()) return false; this.reason.value=r.trim(); return confirm('Xóa bình luận này? Điểm sao vẫn được giữ nguyên.');">
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
      <c:if test="${empty reviews}"><tr><td colspan="6">Chưa có đánh giá nào.</td></tr></c:if>
    </tbody>
  </table></div>
</div></main>
<%@ include file="../_footer.jspf" %>
