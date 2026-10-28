<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý phòng chiếu"/>
<%@ include file="../_header.jspf" %>
<style>
  .rm-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .rm-head h1 { margin: 0; }
  .rm-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .rm-search { display: flex; gap: 8px; margin-bottom: 20px; }
  .rm-search input[type=search] { padding: 9px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                                  font: 14px var(--font); min-width: 260px; outline: none; background: #fff; }
  .rm-search input[type=search]:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .rm-badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .rm-on { background: #d1fae5; color: var(--success); }
  .rm-off { background: var(--slate-200); color: var(--slate-600); }
  .rm-type { background: #dbeafe; color: var(--brand); }
  .rm-warn { color: #b45309; font-weight: 600; }
  .rm-muted { color: var(--slate-500); font-size: 13px; }
  .rm-actions { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
  .rm-actions form { display: inline-flex; }
  .rm-empty { text-align: center; padding: 40px 20px; color: var(--slate-500); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="rm-head">
        <div>
          <h1>Quản lý phòng chiếu</h1>
          <p>Tạo phòng chiếu, thiết lập thông tin phòng (tên, loại phòng, sức chứa) và layout ghế.</p>
        </div>
        <a class="btn btn-cta" href="${ctx}/admin/rooms?action=new">+ Thêm phòng chiếu</a>
      </div>

      <form method="get" action="${ctx}/admin/rooms" class="rm-search">
        <input type="search" name="q" placeholder="Tìm theo tên phòng..." value="<c:out value='${keyword}'/>">
        <button class="btn btn-outline" type="submit">Tìm</button>
      </form>

      <div class="table-wrap">
        <table class="data">
          <thead>
            <tr>
              <th>Phòng</th><th>Rạp</th><th>Loại</th><th>Sức chứa</th><th>Ghế</th>
              <th>Suất sắp tới</th><th>Trạng thái</th><th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="r" items="${rooms}">
              <tr>
                <td><strong><c:out value="${r.roomName}"/></strong></td>
                <td><c:out value="${r.cinemaName}"/></td>
                <td><span class="rm-badge rm-type"><c:out value="${r.roomType}"/></span></td>
                <td>${r.capacity}</td>
                <td>
                  <c:choose>
                    <c:when test="${r.hasLayout}">
                      ${r.seatCount} ghế
                      <c:if test="${r.maintenanceCount > 0}">
                        <div class="rm-warn">${r.maintenanceCount} đang bảo trì</div>
                      </c:if>
                    </c:when>
                    <c:otherwise><span class="rm-warn">Chưa có layout</span></c:otherwise>
                  </c:choose>
                </td>
                <td>${r.upcomingShowtimes}</td>
                <td>
                  <c:choose>
                    <c:when test="${r.active}"><span class="rm-badge rm-on">${r.statusLabel}</span></c:when>
                    <c:otherwise><span class="rm-badge rm-off">${r.statusLabel}</span></c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <div class="rm-actions">
                    <a class="btn btn-primary btn-small" href="${ctx}/admin/seats?roomId=${r.roomId}">Layout &amp; ghế</a>
                    <a class="btn btn-soft btn-small" href="${ctx}/admin/rooms?action=edit&id=${r.roomId}">Sửa</a>
                    <form method="post" action="${ctx}/admin/rooms"
                          onsubmit="return confirm('${r.active ? 'Đóng' : 'Mở lại'} phòng này?')">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="toggle">
                      <input type="hidden" name="id" value="${r.roomId}">
                      <button class="btn btn-outline btn-small" type="submit">${r.active ? 'Đóng phòng' : 'Mở lại'}</button>
                    </form>
                    <form method="post" action="${ctx}/admin/rooms"
                          onsubmit="return confirm('Xóa phòng này cùng toàn bộ ghế? Chỉ xóa được khi phòng chưa có suất chiếu hay vé.')">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="delete">
                      <input type="hidden" name="id" value="${r.roomId}">
                      <button class="btn btn-danger btn-small" type="submit">Xóa</button>
                    </form>
                  </div>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty rooms}">
              <tr><td colspan="8" class="rm-empty">Chưa có phòng chiếu nào.</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
      <p class="rm-muted" style="margin-top:12px">
        Phòng đã có suất chiếu hoặc vé không thể xóa — hãy dùng “Đóng phòng” (chỉ đóng được khi không còn suất chiếu sắp tới).
      </p>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



