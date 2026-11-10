<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="seat" tagdir="/WEB-INF/tags" %>
<c:set var="pageTitle" value="Chọn layout ghế"/>
<%@ include file="../layout/top.jspf" %>
<link rel="stylesheet" href="${ctx}/assets/css/seat-plan.css">
<link rel="stylesheet" href="${ctx}/assets/css/room-layout.css">

<div class="page-head">
  <div>
    <a class="btn btn-ghost btn-sm mb-8" href="${ctx}/admin/rooms?action=new&draft=1">${ic.chevronLeft}Bước 1: thông tin phòng</a>
    <h1>Chọn layout ghế</h1>
    <p>Bước 2/2 · <b><c:out value="${draft.roomName}"/></b> · <c:out value="${cinemaName}"/> · Phòng <c:out value="${draft.roomType}"/>.
       Chọn layout đề xuất, một layout trong thư viện, hoặc tạo layout mới.</p>
  </div>
</div>
<c:if test="${not empty error}"><div class="alert alert-error mb-16" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<form id="createForm" method="post" action="${ctx}/admin/room-layout">
  <input type="hidden" name="_csrf" value="${csrf}">
  <input type="hidden" name="action" value="create">

  <section class="card lp-section">
    <div class="card-head"><div><h2>Layout đề xuất</h2><p>Layout chuẩn của phòng <c:out value="${draft.roomType}"/>, dùng ngay không cần chỉnh.</p></div></div>
    <div class="card-body lp-grid">
      <label class="lp-card">
        <input type="radio" name="layout" value="std" ${selected == 'std' ? 'checked' : ''} data-name="Layout chuẩn ${draft.roomType}" data-seats="${standardCapacity}">
        <span class="lp-thumb" data-layout="<c:out value='${standardData}'/>"></span>
        <span class="lp-info">
          <span class="lp-title">Layout chuẩn <c:out value="${draft.roomType}"/> <span class="lp-badge">Đề xuất</span></span>
          <span class="lp-seats">${standardCapacity} ghế</span>
          <span class="lp-desc"><c:out value="${standardSummary}"/></span>
        </span>
      </label>
    </div>
  </section>

  <section class="card lp-section">
    <div class="card-head"><div><h2>Thư viện layout đã lưu</h2><p>Layout đã tạo trước đó, chọn lại để dùng cho phòng này.</p></div></div>
    <div class="card-body lp-grid">
      <c:forEach var="l" items="${layouts}">
        <label class="lp-card">
          <input type="radio" name="layout" value="${l.layoutId}" ${selectedId == l.layoutId ? 'checked' : ''} data-name="<c:out value='${l.layoutName}'/>" data-seats="${l.seatCount}">
          <span class="lp-thumb" data-layout="<c:out value='${l.layoutData}'/>"></span>
          <span class="lp-info">
            <span class="lp-title"><c:out value="${l.layoutName}"/><c:if test="${not empty l.roomType}"> <span class="lp-type"><c:out value="${l.roomType}"/></span></c:if></span>
            <span class="lp-seats">${l.seatCount} ghế · ${l.rowCount} hàng</span>
            <span class="lp-desc">${l.standardCount} thường · ${l.vipCount} VIP · ${l.couplePairs} cặp ghế đôi</span>
          </span>
        </label>
      </c:forEach>
      <button type="button" class="lp-card lp-new" id="btnNewLayout">
        <span class="lp-plus" aria-hidden="true">+</span>
        <span class="lp-title">Tạo layout mới</span>
        <span class="lp-desc">Nhập số hàng × số cột rồi gán loại cho từng ghế</span>
      </button>
    </div>
    <c:if test="${empty layouts}"><p class="lp-empty">Thư viện chưa có layout nào. Bấm “+ Tạo layout mới” để tạo layout đầu tiên.</p></c:if>
  </section>

  <div class="card lp-actions">
    <span>Đã chọn: <b id="selName">—</b> <span id="selSeats" class="lp-muted"></span></span>
    <span class="lp-actions-btns">
      <a class="btn" href="${ctx}/admin/rooms">Hủy</a>
      <button class="btn btn-primary" type="submit">${ic.check}Lưu phòng</button>
    </span>
  </div>
</form>

<%-- ================= Trình tạo layout mới ================= --%>
<section class="card lp-section" id="editor" hidden
         data-max-rows="${maxRows}" data-max-cols="${maxCols}" data-max-seats="${maxSeats}"
         data-initial="<c:out value='${editorData}'/>" data-open="${not empty editorError}">
  <div class="card-head">
    <div><h2>Tạo layout mới</h2><p>Bước 1: nhập kích thước · Bước 2: sinh lưới ghế · Bước 3: bấm vào từng ghế để gán loại.</p></div>
    <button type="button" class="btn btn-ghost btn-sm" id="btnCloseEditor">${ic.x}Đóng</button>
  </div>
  <div class="card-body">
    <div class="le-size">
      <div class="field">
        <label for="le-rows">Số hàng (1–${maxRows})</label>
        <input id="le-rows" type="number" min="1" max="${maxRows}" value="8">
      </div>
      <div class="field">
        <label for="le-cols">Số cột (1–${maxCols})</label>
        <input id="le-cols" type="number" min="1" max="${maxCols}" value="12">
      </div>
      <button type="button" class="btn btn-soft" id="btnGrid">${ic.grid}Tạo lưới ghế</button>
    </div>

    <div id="leWork" hidden>
      <div class="le-toolbar">
        <button type="button" class="btn btn-outline btn-sm" id="btnBulk" aria-pressed="false">Sửa nhiều</button>
        <span class="le-bulk" id="bulkBar" hidden>
          <span class="le-muted" id="bulkCount">Kéo chuột để quét chọn một vùng ghế</span>
          <button type="button" class="btn btn-sm" data-bulk="S">Gán Thường</button>
          <button type="button" class="btn btn-sm le-btn-vip" data-bulk="V">Gán VIP</button>
          <button type="button" class="btn btn-ghost btn-sm" id="btnBulkClear">Bỏ chọn</button>
        </span>
      </div>

      <div class="sp-legend">
        <span><i class="l-una"></i>Chưa gán</span>
        <span><i></i>Ghế thường</span>
        <span><i class="l-vip"></i>Ghế VIP</span>
        <span><i class="l-cpl"></i>Ghế đôi</span>
        <span><i class="l-aisle"></i>Lối đi</span>
        <span><i class="l-sel"></i>Đang chọn</span>
      </div>

      <div class="le-stats" aria-live="polite">
        <span class="le-stat"><b id="stS">0</b>Thường</span>
        <span class="le-stat vip"><b id="stV">0</b>VIP</span>
        <span class="le-stat cpl"><b id="stC">0</b>Ghế đôi (cặp)</span>
        <span class="le-stat una"><b id="stU">0</b>Chưa gán</span>
        <span class="le-stat total"><b id="stT">0</b>Tổng số ghế</span>
      </div>

      <div class="alert le-msg" id="leMsg" role="alert" hidden></div>

      <div class="le-stage" id="leStage">
        <div class="sp-plan le-plan">
          <seat:screen/>
          <div class="sp-scroll">
            <div class="sp-floor">
              <div class="sp-aisle le-aisle" aria-hidden="true"><span>LỐI ĐI</span><span>↓</span></div>
              <div class="sp-rows" id="leRows"></div>
              <div class="sp-aisle le-aisle" aria-hidden="true"><span>LỐI ĐI</span><span>↓</span></div>
            </div>
          </div>
        </div>
        <div class="le-marquee" id="leMarquee" hidden></div>
      </div>
      <p class="le-muted le-tip">Bấm vào một ghế để chọn loại (Thường / VIP / Ghế đôi) hoặc xóa ghế. Ghế đôi ghép ghế đó với ghế ngay bên phải;
        muốn xóa ghế đôi hãy đổi về ghế đơn trước. Sơ đồ luôn tự căn giữa so với màn hình.</p>

      <form id="saveForm" class="le-save" method="post" action="${ctx}/admin/room-layout">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="saveLayout">
        <input type="hidden" name="layoutData" id="layoutData">
        <div class="field">
          <label for="le-name">Tên layout<span class="req">*</span></label>
          <input id="le-name" type="text" name="layoutName" maxlength="100" placeholder="Phòng 2D nhỏ 80 ghế" value="<c:out value='${editorName}'/>">
        </div>
        <button class="btn btn-primary" type="submit">${ic.check}Lưu layout vào thư viện</button>
      </form>
      <c:if test="${not empty editorError}"><div class="alert alert-error mt-12" id="serverErr" role="alert">${ic.alert}<span><c:out value="${editorError}"/></span></div></c:if>
    </div>
  </div>
</section>

<div class="le-pop" id="lePop" role="menu" hidden></div>
<ul id="layoutNames" hidden><c:forEach var="l" items="${layouts}"><li><c:out value="${l.layoutName}"/></li></c:forEach></ul>
<script src="${ctx}/assets/js/room-layout.js"></script>
<%@ include file="../layout/bottom.jspf" %>
