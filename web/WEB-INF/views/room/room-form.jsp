<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${room.roomId > 0 ? 'Sửa phòng chiếu' : 'Thêm phòng chiếu'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .rm-form-card { max-width: 720px; }
  .rm-actions { display: flex; gap: 10px; margin-top: 8px; }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="card rm-form-card">
        <h2><c:out value="${pageTitle}"/></h2>
        <p class="sub">
          <c:choose>
            <c:when test="${room.roomId > 0}">Cập nhật thông tin phòng. Layout ghế được thiết lập ở màn hình “Layout &amp; ghế”.</c:when>
            <c:otherwise>Sau khi tạo phòng, bạn sẽ được chuyển sang màn hình thiết lập layout ghế.</c:otherwise>
          </c:choose>
        </p>
        <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

        <form method="post" action="${ctx}/admin/rooms">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="save">
          <c:if test="${room.roomId > 0}"><input type="hidden" name="id" value="${room.roomId}"></c:if>

          <div class="field">
            <label for="f-cinema">Rạp</label>
            <select id="f-cinema" name="cinemaId" required>
              <c:forEach var="cn" items="${cinemas}">
                <option value="${cn.cinemaId}" ${cn.cinemaId == room.cinemaId ? 'selected' : ''}><c:out value="${cn.cinemaName}"/></option>
              </c:forEach>
            </select>
          </div>

          <div class="field">
            <label for="f-name">Tên phòng (tối đa 50 ký tự)</label>
            <input id="f-name" type="text" name="roomName" maxlength="50" required
                   placeholder="VD: Phòng 3" value="<c:out value='${room.roomName}'/>">
          </div>

          <div class="row">
            <div class="field">
              <label for="f-type">Loại phòng</label>
              <select id="f-type" name="roomType" required>
                <c:forEach var="t" items="${roomTypes}">
                  <option value="${t}" ${t == room.roomType ? 'selected' : ''}>${t}</option>
                </c:forEach>
              </select>
            </div>
            <div class="field">
              <label for="f-cap">Sức chứa (số ghế)</label>
              <input id="f-cap" type="number" name="capacity" min="1" max="500" required
                     value="${room.capacity > 0 ? room.capacity : ''}" ${capacityLocked ? 'readonly' : ''}>
              <c:if test="${capacityLocked}">
                <div class="hint">Phòng đã có layout nên sức chứa luôn bằng số ghế thực tế (${room.seatCount}). Thay đổi ở màn hình Layout &amp; ghế.</div>
              </c:if>
            </div>
          </div>

          <c:if test="${room.roomId > 0}">
            <div class="field">
              <label for="f-status">Trạng thái</label>
              <select id="f-status" name="status">
                <option value="Active" ${room.status == 'Active' ? 'selected' : ''}>Đang hoạt động</option>
                <option value="Closed" ${room.status == 'Closed' ? 'selected' : ''}>Đã đóng</option>
              </select>
              <div class="hint">Chỉ đóng được phòng khi không còn suất chiếu sắp tới.</div>
            </div>
          </c:if>

          <div class="rm-actions">
            <button class="btn btn-cta" type="submit">${room.roomId > 0 ? 'Lưu thay đổi' : 'Tạo phòng'}</button>
            <a class="btn btn-outline" href="${ctx}/admin/rooms">Hủy</a>
          </div>
        </form>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>
