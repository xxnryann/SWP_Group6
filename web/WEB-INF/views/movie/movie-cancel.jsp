<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hủy phim"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Hủy phim &amp; hoàn tiền: <c:out value="${movie.title}"/></h2>
    <p class="sub">Hành động này không thể hoàn tác. Các suất chiếu tương lai sẽ bị hủy, vé chưa sử dụng được hoàn tiền, MyPoint/voucher được hoàn lại và phim chuyển sang trạng thái ngừng chiếu.</p>

    <div class="admin-kpis">
      <div class="admin-kpi"><span>Suất chiếu bị hủy</span><strong><c:out value="${cancelShowtimes.size()}"/></strong></div>
      <div class="admin-kpi"><span>Vé đã bán sẽ hoàn tiền</span><strong><c:out value="${cancelTickets}"/></strong></div>
      <div class="admin-kpi"><span>Khách hàng nhận hoàn tiền</span><strong><c:out value="${cancelSummary.customerCount}"/></strong></div>
      <div class="admin-kpi"><span>Tổng tiền hoàn dự kiến</span><strong><c:out value="${cancelSummary.refundAmount}"/> đ</strong></div>
    </div>

    <c:choose>
      <c:when test="${empty cancelShowtimes}">
        <p class="alert alert-info">Phim này không còn suất chiếu sắp tới. Dùng chức năng "Ngừng chiếu" nếu chỉ muốn chuyển trạng thái phim.</p>
      </c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="data">
          <thead><tr><th>Suất chiếu</th><th>Phòng</th><th>Vé đã bán</th></tr></thead>
          <tbody>
          <c:forEach var="s" items="${cancelShowtimes}">
            <tr><td><c:out value="${s.start_time}"/></td><td><c:out value="${s.room_name}"/></td>
                <td><c:out value="${s.booked_tickets}"/></td></tr>
          </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>

    <form method="post" action="${ctx}/manage/movies" class="movie-cancel-actions"
          onsubmit="return confirm('Sẽ hủy ${cancelSummary.ticketCount} vé và hoàn ${cancelSummary.refundAmount} đồng cho ${cancelSummary.customerCount} khách. Bạn có chắc chắn?');">
      <input type="hidden" name="_csrf" value="${csrf}">
      <input type="hidden" name="action" value="cancelMovie">
      <input type="hidden" name="id" value="${movie.movieId}">
      <label class="field" for="cancelReason">Lý do hủy phim *</label>
      <textarea id="cancelReason" name="reason" maxlength="200" required rows="3"
                placeholder="Nhập lý do để lưu vào nhật ký thao tác (tối đa 200 ký tự)"></textarea>
      <a class="btn btn-outline" href="${ctx}/manage/movies">Quay lại</a>
      <button class="btn btn-danger" type="submit">Xác nhận hủy phim</button>
    </form>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
