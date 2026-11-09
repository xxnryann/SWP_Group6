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
              <c:choose>
                <c:when test="${capacityLocked}">
                  <div class="hint">Phòng đã có layout nên sức chứa luôn bằng số ghế thực tế (${room.seatCount}). Thay đổi ở màn hình Layout &amp; ghế.</div>
                </c:when>
                <c:otherwise>
                  <div class="hint" id="capHint">Là tổng số ghế khi thiết lập layout: hệ thống gợi ý số hàng × ghế mỗi hàng theo con số này (vd 55 → 5 hàng × 11 ghế).</div>
                  <div class="hint" id="capHint2D" hidden>Phòng 2D dùng layout cố định ${fixedSummary2d} Hệ thống tự tạo ghế khi lưu.</div>
                  <div class="hint" id="capHintIMAX" hidden>Phòng IMAX dùng layout cố định ${fixedSummaryImax} Hệ thống tự tạo ghế khi lưu.</div>
                  <div class="hint" id="capHint3D" hidden>Phòng 3D dùng layout cố định ${fixedSummary3d} Hệ thống tự tạo ghế khi lưu.</div>
                  <div class="hint" id="capHint4DX" hidden>Phòng 4DX dùng layout cố định ${fixedSummary4dx} Hệ thống tự tạo ghế khi lưu.</div>
                  <script>
                    (function () {
                      var type = document.getElementById('f-type'), cap = document.getElementById('f-cap');
                      var free = document.getElementById('capHint');
                      var fixed = {
                        '2D': { capacity: '${fixedCapacity2d}', hint: document.getElementById('capHint2D') },
                        '3D': { capacity: '${fixedCapacity3d}', hint: document.getElementById('capHint3D') },
                        'IMAX': { capacity: '${fixedCapacityImax}', hint: document.getElementById('capHintIMAX') },
                        '4DX': { capacity: '${fixedCapacity4dx}', hint: document.getElementById('capHint4DX') }
                      };
                      function sync() {
                        var current = fixed[type.value];
                        if (current) cap.value = current.capacity;
                        cap.readOnly = !!current;
                        free.hidden = !!current;
                        Object.keys(fixed).forEach(function (k) { fixed[k].hint.hidden = fixed[k] !== current; });
                      }
                      type.addEventListener('change', sync);
                      sync();
                    })();
                  </script>
                </c:otherwise>
              </c:choose>
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



