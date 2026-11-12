<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${room.roomId > 0 ? 'Sửa phòng chiếu' : 'Thêm phòng chiếu'}"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div><a class="btn btn-ghost btn-sm mb-8" href="${ctx}/admin/rooms">${ic.chevronLeft}Danh sách phòng</a><h1><c:out value="${pageTitle}"/></h1>
    <p>${room.roomId > 0 ? 'Phòng 2D, 3D, IMAX và 4DX dùng sơ đồ ghế cố định, hệ thống tự tạo ghế khi lưu.' : 'Bước 1/2 · Nhập thông tin phòng. Bước tiếp theo: chọn hoặc tạo layout ghế.'}</p></div>
</div>
<section class="card" style="max-width:820px">
  <form method="post" action="${ctx}/admin/rooms">
    <div class="card-body form-grid">
      <c:if test="${not empty error}"><div class="alert alert-error full" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
      <input type="hidden" name="_csrf" value="${csrf}">
      <input type="hidden" name="action" value="save">
      <c:if test="${room.roomId > 0}"><input type="hidden" name="id" value="${room.roomId}"></c:if>
      <div class="field">
        <label for="f-cinema">Rạp<span class="req">*</span></label>
        <select id="f-cinema" name="cinemaId" required>
          <c:forEach var="cn" items="${cinemas}"><option value="${cn.cinemaId}" ${cn.cinemaId == room.cinemaId ? 'selected' : ''}><c:out value="${cn.cinemaName}"/></option></c:forEach>
        </select>
      </div>
      <div class="field">
        <label for="f-name">Tên phòng<span class="req">*</span></label>
        <input id="f-name" type="text" name="roomName" maxlength="50" required placeholder="Phòng 3" value="<c:out value='${room.roomName}'/>">
        <span class="hint">Tối đa 50 ký tự.</span>
      </div>
      <div class="field">
        <label for="f-type">Loại phòng<span class="req">*</span></label>
        <select id="f-type" name="roomType" required>
          <c:forEach var="t" items="${roomTypes}"><option value="<c:out value='${t}'/>" ${t == room.roomType ? 'selected' : ''}><c:out value="${t}"/></option></c:forEach>
          <option value="${newTypeOption}" ${room.roomType == newTypeOption ? 'selected' : ''}>+ Tạo loại phòng mới…</option>
        </select>
        <span class="hint">2D, 3D, IMAX, 4DX có layout ghế chuẩn. Loại mới dùng layout trong thư viện hoặc tự tạo ở bước sau.</span>
      </div>
      <div class="full form-grid" id="newTypeBox" style="padding:16px;border:1px dashed var(--line-strong);border-radius:var(--r-md);background:var(--surface-2)" hidden>
        <div class="field">
          <label for="f-newtype">Tên loại phòng mới<span class="req">*</span></label>
          <input id="f-newtype" type="text" name="newTypeName" maxlength="20" placeholder="ScreenX, Gold Class, 4D…" value="<c:out value='${newTypeName}'/>">
          <span class="hint">Tối đa 20 ký tự: chữ, số, khoảng trắng, + . _ -</span>
        </div>
        <div class="field">
          <label for="f-newtype-desc">Mô tả</label>
          <input id="f-newtype-desc" type="text" name="newTypeDesc" maxlength="200" placeholder="Màn hình 270°, ghế nằm…" value="<c:out value='${newTypeDesc}'/>">
        </div>
      </div>
      <c:choose>
      <c:when test="${room.roomId == 0}">
      <div class="full">
        <div class="alert alert-info">${ic.info}<span>Sức chứa được tính theo layout ghế bạn chọn ở bước 2: layout chuẩn của loại phòng,
          một layout trong thư viện, hoặc layout mới tự tạo.</span></div>
      </div>
      </c:when>
      <c:otherwise>
      <div class="field">
        <label for="f-cap">Sức chứa (số ghế)<span class="req">*</span></label>
        <input id="f-cap" type="number" name="capacity" min="1" max="500" required value="${room.capacity > 0 ? room.capacity : ''}" ${capacityLocked ? 'readonly' : ''}>
      </div>
      <div class="full">
        <c:choose>
          <c:when test="${capacityLocked}">
            <div class="alert alert-info">${ic.info}<span>Phòng đã có layout nên sức chứa luôn bằng số ghế thực tế (${room.seatCount}). Thay đổi ở màn hình Layout &amp; ghế.</span></div>
          </c:when>
          <c:otherwise>
            <div class="alert alert-info">${ic.info}
              <div>
                <span id="capHint">Là tổng số ghế khi thiết lập layout: hệ thống gợi ý số hàng × ghế mỗi hàng theo con số này (vd 55 → 5 hàng × 11 ghế).</span>
                <span id="capHint2D" hidden>Phòng 2D dùng layout cố định ${fixedSummary2d} Hệ thống tự tạo ghế khi lưu.</span>
                <span id="capHintIMAX" hidden>Phòng IMAX dùng layout cố định ${fixedSummaryImax} Hệ thống tự tạo ghế khi lưu.</span>
                <span id="capHint3D" hidden>Phòng 3D dùng layout cố định ${fixedSummary3d} Hệ thống tự tạo ghế khi lưu.</span>
                <span id="capHint4DX" hidden>Phòng 4DX dùng layout cố định ${fixedSummary4dx} Hệ thống tự tạo ghế khi lưu.</span>
              </div>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
      </c:otherwise>
      </c:choose>
      <c:if test="${room.roomId > 0}">
        <div class="field">
          <label for="f-status">Trạng thái</label>
          <select id="f-status" name="status">
            <option value="Active" ${room.status == 'Active' ? 'selected' : ''}>Đang hoạt động</option>
            <option value="Closed" ${room.status == 'Closed' ? 'selected' : ''}>Đã đóng</option>
          </select>
          <span class="hint">Chỉ đóng được phòng khi không còn suất chiếu sắp tới.</span>
        </div>
      </c:if>
    </div>
    <div class="card-foot">
      <a class="btn" href="${ctx}/admin/rooms">Hủy</a>
      <button class="btn btn-primary" type="submit">${room.roomId > 0 ? ic.check : ''}${room.roomId > 0 ? 'Lưu thay đổi' : 'Tiếp tục: chọn layout ghế →'}</button>
    </div>
  </form>
</section>
<script>
  (function () {
    /* Hiện ô nhập loại phòng mới khi chọn "+ Tạo loại phòng mới…". */
    var type = document.getElementById('f-type'), box = document.getElementById('newTypeBox');
    var name = document.getElementById('f-newtype');
    function syncNewType() {
      var on = type.value === '${newTypeOption}';
      box.hidden = !on;
      name.required = on;
      if (on && !name.value) name.focus();
    }
    type.addEventListener('change', syncNewType);
    syncNewType();
  })();
</script>
<c:if test="${not capacityLocked && room.roomId > 0}">
  <script>
    (function () {
      var type = document.getElementById('f-type'), cap = document.getElementById('f-cap'), free = document.getElementById('capHint');
      var fixed = {
        '2D': { capacity: '${fixedCapacity2d}', hint: document.getElementById('capHint2D') },
        '3D': { capacity: '${fixedCapacity3d}', hint: document.getElementById('capHint3D') },
        'IMAX': { capacity: '${fixedCapacityImax}', hint: document.getElementById('capHintIMAX') },
        '4DX': { capacity: '${fixedCapacity4dx}', hint: document.getElementById('capHint4DX') }
      };
      function sync() {
        var current = fixed[type.value];
        if (current) cap.value = current.capacity;
        cap.readOnly = !!current; free.hidden = !!current;
        Object.keys(fixed).forEach(function (k) { fixed[k].hint.hidden = fixed[k] !== current; });
      }
      type.addEventListener('change', sync);
      sync();
    })();
  </script>
</c:if>
<%@ include file="../layout/bottom.jspf" %>
