<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý giá vé"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Quản lý giá vé</h2>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <form method="post" action="${ctx}/manager/prices">
      <input type="hidden" name="_csrf" value="${csrf}">
      <input type="hidden" name="action" value="savePrices">
      <div class="table-wrap"><table class="data price-table">
        <thead><tr><th>Loại ghế</th><th>Khung giờ</th><th>Ngày thường</th><th>Cuối tuần</th><th>Ngày lễ</th></tr></thead>
        <tbody>
        <c:forEach var="r" items="${matrix}">
          <tr>
            <td><strong><c:out value="${r.type_name}"/></strong></td>
            <td><c:out value="${r.slot_name}"/></td>
            <td><input type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Weekday" value="${r.weekday}" aria-label="Ngày thường"></td>
            <td><input type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Weekend" value="${r.weekend}" aria-label="Cuối tuần"></td>
            <td><input type="number" min="0" max="5000000" step="1000" name="p_${r.seat_type_id}_${r.slot_id}_Holiday" value="${r.holiday}" aria-label="Ngày lễ"></td>
          </tr>
        </c:forEach>
        </tbody>
      </table></div>
      <p style="margin-top:14px"><button class="btn btn-primary" type="submit">Lưu bảng giá</button></p>
    </form>
  </section>

  <section class="panel" style="margin-top:20px">
    <h2>Ngày lễ</h2>
    <form method="post" action="${ctx}/manager/prices" class="holiday-form">
      <input type="hidden" name="_csrf" value="${csrf}">
      <input type="hidden" name="action" value="addHoliday">
      <div class="field"><label for="holidayDate">NGÀY</label><input id="holidayDate" name="holidayDate" type="date" required></div>
      <div class="field"><label for="holidayName">TÊN NGÀY LỄ</label><input id="holidayName" name="holidayName" type="text" maxlength="100" required></div>
      <button class="btn btn-primary" type="submit">Thêm</button>
    </form>
    <c:if test="${not empty holidays}">
      <div class="table-wrap"><table class="data">
        <thead><tr><th>Ngày</th><th>Tên</th><th></th></tr></thead>
        <tbody>
        <c:forEach var="h" items="${holidays}">
          <tr>
            <td><c:out value="${h.holiday_date}"/></td><td><c:out value="${h.holiday_name}"/></td>
            <td>
              <form method="post" action="${ctx}/manager/prices" onsubmit="return confirm('Xóa ngày lễ này?');">
                <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="deleteHoliday">
                <input type="hidden" name="holidayDate" value="${h.holiday_date}">
                <button class="btn btn-danger btn-small" type="submit">Xóa</button>
              </form>
            </td>
          </tr>
        </c:forEach>
        </tbody>
      </table></div>
    </c:if>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
