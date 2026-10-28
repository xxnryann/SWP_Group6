<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Bảng giá vé"/>
<%@ include file="_header.jspf" %>
<fmt:setLocale value="vi_VN"/>
<main class="container" style="padding:32px 0">
  <h1>Bảng giá vé</h1>
  <p class="meta">Giá vé theo khung giờ chiếu, loại ghế và loại ngày. Đơn vị: VNĐ / ghế.</p>
  <c:choose>
    <c:when test="${empty priceRows}">
      <p>Chưa có cấu hình giá vé.</p>
    </c:when>
    <c:otherwise>
      <div class="table-wrap">
        <table class="data">
          <thead>
            <tr><th>Khung giờ</th><th>Loại ghế</th><th>Ngày thường</th><th>Cuối tuần</th><th>Ngày lễ</th></tr>
          </thead>
          <tbody>
            <c:forEach var="row" items="${priceRows}">
              <tr>
                <td><c:out value="${row.slotName}"/></td>
                <td><c:out value="${row.seatTypeName}"/></td>
                <td><c:choose><c:when test="${row.weekday != null}"><fmt:formatNumber value="${row.weekday}" pattern="#,##0"/></c:when><c:otherwise>—</c:otherwise></c:choose></td>
                <td><c:choose><c:when test="${row.weekend != null}"><fmt:formatNumber value="${row.weekend}" pattern="#,##0"/></c:when><c:otherwise>—</c:otherwise></c:choose></td>
                <td><c:choose><c:when test="${row.holiday != null}"><fmt:formatNumber value="${row.holiday}" pattern="#,##0"/></c:when><c:otherwise>—</c:otherwise></c:choose></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </c:otherwise>
  </c:choose>
</main>
<%@ include file="_footer.jspf" %>
