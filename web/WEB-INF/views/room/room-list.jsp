<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Phòng chiếu"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .slot { display: flex; gap: 8px; padding: 4px 0; border-bottom: 1px dashed var(--line); font-size: 13px; white-space: nowrap; }
  .slot:last-child { border-bottom: 0; }
  .slot b { color: var(--brand-700); font-variant-numeric: tabular-nums; }
  .room-actions { display: grid; grid-template-columns: repeat(2, auto); justify-content: end; gap: 6px; min-width: 220px; }
  .slot .truncate { max-width: 150px; }
  .room-actions form, .room-actions form .btn { width: 100%; }
  .table td:first-child .cell-main { white-space: nowrap; }
  .toolbar .field.sm { flex: 0 1 150px; }
</style>
<div class="page-head">
  <div><h1>Quản lý phòng chiếu</h1><p>Tối đa 13 phòng. Phòng đã có suất chiếu hoặc vé không xóa được, hãy dùng "Đóng phòng" khi không còn suất sắp tới.</p></div>
  <c:choose>
    <c:when test="${roomLimitReached}">
      <button class="btn btn-primary" type="button" id="roomLimitBtn" data-message="<c:out value='${roomLimitMessage}'/>" data-auto-open="${showRoomLimit}">${ic.plus}Thêm phòng chiếu</button>
    </c:when>
    <c:otherwise><a class="btn btn-primary" href="${ctx}/admin/rooms?action=new">${ic.plus}Thêm phòng chiếu</a></c:otherwise>
  </c:choose>
</div>

<section class="card">
  <form method="get" action="${ctx}/admin/rooms" class="toolbar" role="search">
    <div class="field grow"><label for="q">Tên phòng</label><div class="input-group">${ic.search}<input id="q" type="search" name="q" placeholder="Tìm theo tên phòng" value="<c:out value='${keyword}'/>"></div></div>
    <div class="field sm"><label for="fDate">Lịch ngày</label><input id="fDate" type="date" name="date" value="${scheduleDate}"></div>
    <div class="field sm"><label for="fRoom">Sắp xếp</label>
      <select id="fRoom" name="room" onchange="this.form.submit()">
        <option value="">Mặc định</option>
        <option value="name_asc" ${param.room == 'name_asc' ? 'selected' : ''}>Tên A - Z</option>
        <option value="name_desc" ${param.room == 'name_desc' ? 'selected' : ''}>Tên Z - A</option>
        <option value="number_desc" ${param.room == 'number_desc' ? 'selected' : ''}>Số phòng lớn - bé</option>
        <option value="number_asc" ${param.room == 'number_asc' ? 'selected' : ''}>Số phòng bé - lớn</option>
      </select></div>
    <div class="field sm"><label for="fType">Loại</label>
      <select id="fType" name="type" onchange="this.form.submit()">
        <option value="">Tất cả</option>
        <c:forEach var="t" items="${roomTypes}"><option value="${t}" ${param.type == t ? 'selected' : ''}>${t}</option></c:forEach>
      </select></div>
    <div class="field sm"><label for="fCap">Sức chứa</label>
      <select id="fCap" name="capacity" onchange="this.form.submit()">
        <option value="">Mặc định</option>
        <option value="desc" ${param.capacity == 'desc' ? 'selected' : ''}>Lớn - bé</option>
        <option value="asc" ${param.capacity == 'asc' ? 'selected' : ''}>Bé - lớn</option>
      </select></div>
    <div class="field sm"><label for="fUp">Suất sắp tới</label>
      <select id="fUp" name="upcoming" onchange="this.form.submit()">
        <option value="">Mặc định</option>
        <option value="desc" ${param.upcoming == 'desc' ? 'selected' : ''}>Nhiều - ít</option>
        <option value="asc" ${param.upcoming == 'asc' ? 'selected' : ''}>Ít - nhiều</option>
      </select></div>
    <div class="field sm"><label for="fSt">Trạng thái</label>
      <select id="fSt" name="status" onchange="this.form.submit()">
        <option value="">Tất cả</option>
        <option value="Active" ${param.status == 'Active' ? 'selected' : ''}>Đang hoạt động</option>
        <option value="Closed" ${param.status == 'Closed' ? 'selected' : ''}>Đã đóng</option>
      </select></div>
    <button class="btn btn-primary" type="submit">${ic.filter}Lọc</button>
    <c:if test="${not empty keyword or not empty param.room or not empty param.type or not empty param.capacity or not empty param.upcoming or not empty param.status}">
      <a class="btn btn-ghost" href="${ctx}/admin/rooms">Xóa lọc</a>
    </c:if>
  </form>

  <div class="table-wrap">
    <table class="table">
      <thead><tr><th>Phòng</th><th>Loại</th><th class="num">Ghế</th><th>Lịch chiếu ${scheduleDate}</th><th class="num">Sắp tới</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
      <tbody>
        <c:forEach var="r" items="${rooms}">
          <tr>
            <td><span class="cell-main"><c:out value="${r.roomName}"/></span><span class="cell-sub"><c:out value="${r.cinemaName}"/></span></td>
            <td><span class="badge badge-brand"><c:out value="${r.roomType}"/></span></td>
            <td class="num">
              <c:choose>
                <c:when test="${r.hasLayout}"><strong class="text-ink">${r.seatCount}</strong><span class="cell-sub">sức chứa ${r.capacity}</span><c:if test="${r.maintenanceCount > 0}"><span class="badge badge-warning mt-4">${r.maintenanceCount} bảo trì</span></c:if></c:when>
                <c:otherwise><span class="badge badge-warning">Chưa có layout</span></c:otherwise>
              </c:choose>
            </td>
            <td style="min-width:200px">
              <c:choose>
                <c:when test="${empty r.schedule}"><span class="muted text-sm">Không có suất chiếu</span></c:when>
                <c:otherwise><c:forEach var="slot" items="${r.schedule}"><div class="slot"><b>${slot.scheduleTimeDisplay}</b><span class="truncate"><c:out value="${slot.movieTitle}"/></span></div></c:forEach></c:otherwise>
              </c:choose>
            </td>
            <td class="num"><a class="fw-700" href="${ctx}/admin/room-showtimes?roomId=${r.roomId}">${r.upcomingShowtimes}</a></td>
            <td>
              <c:choose>
                <c:when test="${r.active}"><span class="badge badge-success badge-dot">${r.statusLabel}</span></c:when>
                <c:otherwise><span class="badge badge-dot">${r.statusLabel}</span></c:otherwise>
              </c:choose>
            </td>
            <td>
              <div class="room-actions">
                <a class="btn btn-xs btn-primary" href="${ctx}/admin/seats?roomId=${r.roomId}">${ic.seat}Layout &amp; ghế</a>
                <a class="btn btn-xs" href="${ctx}/admin/room-showtimes?roomId=${r.roomId}">${ic.calendar}Suất chiếu</a>
                <a class="btn btn-xs btn-soft" href="${ctx}/admin/rooms?action=edit&id=${r.roomId}">${ic.edit}Sửa</a>
                <form method="post" action="${ctx}/admin/rooms" data-confirm="${r.active ? 'Đóng' : 'Mở lại'} phòng này?">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="toggle">
                  <input type="hidden" name="id" value="${r.roomId}">
                  <button class="btn btn-xs" type="submit">${r.active ? 'Đóng phòng' : 'Mở lại'}</button>
                </form>
                <form method="post" action="${ctx}/admin/rooms" data-confirm="Xóa phòng này cùng toàn bộ ghế? Chỉ xóa được khi phòng chưa có suất chiếu hay vé.">
                  <input type="hidden" name="_csrf" value="${csrf}">
                  <input type="hidden" name="action" value="delete">
                  <input type="hidden" name="id" value="${r.roomId}">
                  <button class="btn btn-xs btn-danger" type="submit">${ic.trash}Xóa</button>
                </form>
              </div>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty rooms}"><tr><td colspan="7"><div class="empty"><div class="empty-icon">${ic.door}</div><p>Không có phòng chiếu phù hợp.</p></div></td></tr></c:if>
      </tbody>
    </table>
  </div>
</section>
<c:if test="${roomLimitReached}">
  <script>
    (function () {
      var btn = document.getElementById('roomLimitBtn');
      function showLimit() { openModal('Không thể thêm phòng chiếu', btn.dataset.message); }
      btn.addEventListener('click', showLimit);
      if (btn.dataset.autoOpen === 'true') window.addEventListener('load', showLimit);
    })();
  </script>
</c:if>
<%@ include file="../layout/bottom.jspf" %>
