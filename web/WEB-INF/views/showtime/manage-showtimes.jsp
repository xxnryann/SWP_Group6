<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><h1>Quản lý lịch chiếu</h1><p>Các suất chưa tới giờ chiếu; suất đã bắt đầu được ẩn và không thể sửa/xóa. Suất chưa bán vé được sửa và xóa bình thường. Suất đã bán vé không sửa được nhưng vẫn hủy được (bắt buộc nhập lý do): khách được hoàn MyPoint (tiền vé + combo + MyPoint đã dùng) kèm voucher đền bù và nhận thông báo.</p></div>
  <div class="cluster">
    <a class="btn btn-primary" href="${ctx}/manage/showtimes?action=new">${ic.plus}Thêm suất chiếu</a>
  </div>
</div>

<section class="card">
  <form class="toolbar" method="get" action="${ctx}/manage/showtimes" role="search">
    <div class="field grow"><label for="f-q">Phim</label><div class="input-group">${ic.search}<input id="f-q" type="search" name="q" value="<c:out value='${filterQ}'/>" placeholder="Tên phim"></div></div>
    <div class="field"><label for="f-date">Ngày chiếu</label><input id="f-date" type="date" name="date" value="${filterDate}"></div>
    <div class="field"><label for="f-from">Giờ từ</label><input id="f-from" type="time" name="timeFrom" value="${filterTimeFrom}"></div>
    <div class="field"><label for="f-to">Giờ đến</label><input id="f-to" type="time" name="timeTo" value="${filterTimeTo}"></div>
    <button class="btn btn-primary" type="submit">${ic.filter}Tìm</button>
    <c:if test="${isFiltered}"><a class="btn btn-ghost" href="${ctx}/manage/showtimes">Xóa lọc</a></c:if>
  </form>
  <c:if test="${isFiltered}"><div class="card-body" style="padding-top:12px;padding-bottom:0"><p class="muted text-sm">Tìm thấy <strong class="text-ink">${showtimes.size()}</strong> suất chiếu phù hợp.</p></div></c:if>
  <div class="table-wrap">
    <table class="table">
      <thead><tr><th>Phim</th><th>Ngày</th><th>Giờ chiếu</th><th>Phòng</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
      <tbody>
        <c:forEach var="showtime" items="${showtimes}">
          <c:url var="editUrl" value="/manage/showtimes"><c:param name="id" value="${showtime.showtimeId}"/></c:url>
          <c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
          <tr>
            <td class="cell-main"><c:out value="${showtime.movieTitle}"/></td>
            <td class="nowrap"><c:out value="${showtime.scheduleDateDisplay}"/></td>
            <td class="nowrap"><strong class="text-ink"><c:out value="${showtime.startTimeOnly}"/> – <c:out value="${showtime.endTimeOnly}"/></strong><span class="cell-sub">Dọn phòng xong: <c:out value="${showtime.slotEndTimeOnly}"/></span></td>
            <td><span class="badge">${ic.door}<c:out value="${showtime.roomName}"/></span><c:if test="${not empty showtime.languageShort}"><span class="cell-sub"><c:out value="${showtime.languageShort}"/></span></c:if></td>
            <td>
              <c:choose>
                <c:when test="${showtime.managementStatus == 'Scheduled'}"><span class="badge badge-success badge-dot">Đang mở</span></c:when>
                <c:when test="${showtime.managementStatus == 'Pending'}"><span class="badge badge-warning badge-dot">Chờ</span></c:when>
                <c:when test="${showtime.managementStatus == 'Maintenance'}"><span class="badge badge-accent badge-dot">Bảo trì</span></c:when>
                <c:otherwise><span class="badge badge-danger badge-dot">Đã hủy</span></c:otherwise>
              </c:choose>
            </td>
            <td class="actions">
              <c:choose>
                <c:when test="${showtime.started}"><button class="btn btn-xs" type="button" disabled title="Suất chiếu đã bắt đầu, không thể sửa hoặc xóa">${ic.lock}Đã bắt đầu</button></c:when>
                <c:when test="${showtime.lockedByPurchasedTickets}"><button class="btn btn-xs" type="button" disabled title="Suất chiếu đã có ${showtime.purchasedTicketCount} vé được mua">${ic.lock}Sửa</button></c:when>
                <c:otherwise><a class="btn btn-xs btn-soft" href="<c:out value='${editUrl}'/>">${ic.edit}Sửa</a></c:otherwise>
              </c:choose>
              <c:choose>
                <c:when test="${showtime.purchasedTicketCount > 0}">
                  <%-- Suất đã bán vé: hủy suất kèm lý do -> hoàn MyPoint + voucher đền bù cho khách --%>
                  <form class="inline-form js-cancel-showtime" method="post" action="${ctx}/manage/showtimes" data-tickets="${showtime.purchasedTicketCount}">
                    <input type="hidden" name="_csrf" value="${escapedCsrf}">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${escapedId}">
                    <input type="hidden" name="reason">
                    <button class="btn btn-xs btn-danger nowrap" type="submit" title="Đã bán ${showtime.purchasedTicketCount} vé: hủy suất và hoàn MyPoint + voucher đền bù">${ic.x}Hủy suất</button>
                  </form>
                </c:when>
                <c:otherwise>
                  <form class="inline-form js-delete-showtime" method="post" action="${ctx}/manage/showtimes" data-confirm="Bạn có chắc muốn xóa suất chiếu này?">
                    <input type="hidden" name="_csrf" value="${escapedCsrf}">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${escapedId}">
                    <input type="hidden" name="reason">
                    <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button>
                  </form>
                </c:otherwise>
              </c:choose>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty showtimes}"><tr><td colspan="6"><div class="empty"><div class="empty-icon">${ic.calendar}</div><p><c:choose><c:when test="${isFiltered}">Không có suất chiếu nào khớp bộ lọc.</c:when><c:otherwise>Không có suất chiếu sắp tới. Hãy thêm suất chiếu mới.</c:otherwise></c:choose></p></div></td></tr></c:if>
      </tbody>
    </table>
  </div>
</section>
<script>
  // Hủy suất đã bán vé: bắt buộc nhập lý do (gửi kèm thông báo cho khách), giống ẩn bình luận.
  document.querySelectorAll('form.js-cancel-showtime').forEach(function (f) {
    f.addEventListener('submit', function (e) {
      var r = prompt('Suất chiếu đã bán ' + f.dataset.tickets + ' vé. Khách sẽ được hoàn MyPoint (tiền vé + combo + MyPoint đã dùng) '
        + 'và nhận voucher đền bù.\n\nNhập lý do hủy suất chiếu (sự cố máy chiếu, mất điện, thay đổi lịch...):');
      if (!r || !r.trim()) { e.preventDefault(); return; }
      f.reason.value = r.trim();
    });
  });
</script>
<%@ include file="../layout/bottom.jspf" %>
