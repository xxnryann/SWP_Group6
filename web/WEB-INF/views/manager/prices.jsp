<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Giá vé"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .price-input { width: 130px; min-height: 40px !important; padding: 8px 10px !important; text-align: right; font-variant-numeric: tabular-nums; }
</style>
<div class="page-head">
  <div><h1>Quản lý giá vé</h1><p>Giá mỗi ghế theo loại ghế, khung giờ bắt đầu suất chiếu và loại ngày (thường, cuối tuần, lễ).</p></div>
</div>
<c:if test="${not empty error}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<div class="split" style="grid-template-columns:minmax(0,1fr) 360px">
  <section class="card">
    <div class="card-head"><div><h2>Bảng giá</h2><p>Đơn vị: đồng, bước 1.000đ</p></div></div>
    <form method="post" action="${ctx}/manager/prices">
      <input type="hidden" name="_csrf" value="${csrf}">
      <input type="hidden" name="action" value="savePrices">
      <div class="table-wrap"><table class="table">
        <thead><tr><th>Loại ghế</th><th>Khung giờ</th><th class="num">Ngày thường</th><th class="num">Cuối tuần</th><th class="num">Ngày lễ</th></tr></thead>
        <tbody>
          <c:forEach var="r" items="${matrix}">
            <tr>
              <td><span class="name cluster" style="--gap:8px"><i class="seat-type-dot t-${r.type_name}"></i><strong class="text-ink"><c:out value="${r.type_name}"/></strong></span></td>
              <td><c:out value="${r.slot_name}"/></td>
              <td class="num"><div class="field"><input class="price-input" type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Weekday" value="${r.weekday}" aria-label="${r.type_name} ${r.slot_name} ngày thường"></div></td>
              <td class="num"><div class="field"><input class="price-input" type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Weekend" value="${r.weekend}" aria-label="${r.type_name} ${r.slot_name} cuối tuần"></div></td>
              <td class="num"><div class="field"><input class="price-input" type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Holiday" value="${r.holiday}" aria-label="${r.type_name} ${r.slot_name} ngày lễ"></div></td>
            </tr>
          </c:forEach>
        </tbody>
      </table></div>
      <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Lưu bảng giá</button></div>
    </form>
  </section>

  <section class="card sticky">
    <div class="card-head"><div><h2>Ngày lễ</h2><p>Ngày áp dụng giá lễ</p></div></div>
    <div class="card-body">
      <form method="post" action="${ctx}/manager/prices" class="form">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="addHoliday">
        <div class="field"><label for="holidayDate">Ngày<span class="req">*</span></label><input id="holidayDate" name="holidayDate" type="date" required></div>
        <div class="field"><label for="holidayName">Tên ngày lễ<span class="req">*</span></label><input id="holidayName" name="holidayName" type="text" maxlength="100" required placeholder="Quốc khánh"></div>
        <button class="btn btn-soft" type="submit">${ic.plus}Thêm ngày lễ</button>
      </form>
    </div>
    <c:if test="${not empty holidays}">
      <div class="table-wrap" style="border-top:1px solid var(--line)"><table class="table">
        <tbody>
          <c:forEach var="h" items="${holidays}">
            <tr>
              <td><span class="cell-main"><c:out value="${h.holiday_name}"/></span><span class="cell-sub"><c:out value="${h.holiday_date}"/></span></td>
              <td class="actions">
                <form method="post" action="${ctx}/manager/prices" data-confirm="Xóa ngày lễ này?">
                  <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="deleteHoliday">
                  <input type="hidden" name="holidayDate" value="${h.holiday_date}">
                  <button class="btn btn-xs btn-danger btn-icon" type="submit" aria-label="Xóa ngày lễ <c:out value='${h.holiday_name}'/>">${ic.trash}</button>
                </form>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table></div>
    </c:if>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
