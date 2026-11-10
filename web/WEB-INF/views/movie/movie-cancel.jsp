<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hủy phim"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/manage/movies">${ic.chevronLeft}Quản lý phim</a><h1>Hủy phim &amp; hoàn tiền</h1><p class="text-ink fw-600"><c:out value="${movie.title}"/></p></div>
</div>
<div class="alert alert-error mb-24">${ic.alert}<span><strong>Hành động này không thể hoàn tác.</strong> Các suất chiếu tương lai sẽ bị hủy, vé chưa sử dụng được hoàn tiền, MyPoint và voucher được hoàn lại, phim chuyển sang ngừng chiếu.</span></div>

<section class="stats mb-24">
  <div class="stat"><div class="stat-icon">${ic.calendar}</div><div class="stat-label">Suất chiếu bị hủy</div><div class="stat-value"><c:out value="${cancelShowtimes.size()}"/></div></div>
  <div class="stat"><div class="stat-icon accent">${ic.ticket}</div><div class="stat-label">Vé sẽ hoàn tiền</div><div class="stat-value"><c:out value="${cancelTickets}"/></div></div>
  <div class="stat"><div class="stat-icon success">${ic.users}</div><div class="stat-label">Khách nhận hoàn tiền</div><div class="stat-value"><c:out value="${cancelSummary.customerCount}"/></div></div>
  <div class="stat"><div class="stat-icon danger">${ic.wallet}</div><div class="stat-label">Tổng tiền hoàn dự kiến</div><div class="stat-value money"><c:out value="${cancelSummary.refundAmount}"/> đ</div></div>
</section>

<div class="split" style="grid-template-columns:minmax(0,1fr) 380px">
  <section class="card">
    <div class="card-head"><div><h2>Suất chiếu bị ảnh hưởng</h2></div></div>
    <c:choose>
      <c:when test="${empty cancelShowtimes}"><div class="card-body"><div class="alert alert-info">${ic.info}<span>Phim này không còn suất chiếu sắp tới. Dùng "Ngừng chiếu" nếu chỉ muốn đổi trạng thái phim.</span></div></div></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="table">
          <thead><tr><th>Suất chiếu</th><th>Phòng</th><th class="num">Vé đã bán</th></tr></thead>
          <tbody>
            <c:forEach var="s" items="${cancelShowtimes}">
              <tr><td class="nowrap"><c:out value="${s.start_time}"/></td><td><c:out value="${s.room_name}"/></td><td class="num fw-700"><c:out value="${s.booked_tickets}"/></td></tr>
            </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>
  </section>
  <section class="card sticky">
    <form method="post" action="${ctx}/manage/movies"
          data-confirm="Sẽ hủy ${cancelSummary.ticketCount} vé và hoàn ${cancelSummary.refundAmount} đồng cho ${cancelSummary.customerCount} khách. Bạn có chắc chắn?">
      <div class="card-body form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="cancelMovie">
        <input type="hidden" name="id" value="${movie.movieId}">
        <div class="field">
          <label for="cancelReason">Lý do hủy phim<span class="req">*</span></label>
          <textarea id="cancelReason" name="reason" maxlength="200" required rows="4" placeholder="Lưu vào nhật ký thao tác, tối đa 200 ký tự"></textarea>
        </div>
      </div>
      <div class="card-foot">
        <a class="btn" href="${ctx}/manage/movies">Quay lại</a>
        <button class="btn btn-danger-solid" type="submit">Xác nhận hủy phim</button>
      </div>
    </form>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
