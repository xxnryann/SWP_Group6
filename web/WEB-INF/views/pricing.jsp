<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Giá vé"/>
<%@ include file="_header.jspf" %>
<fmt:setLocale value="vi_VN"/>
<main class="container page pr-page">
  <h1 class="pr-title">GIÁ VÉ RẠP CINESTAR CINEMAS</h1>

  <c:choose>
    <c:when test="${empty priceRows}">
      <div class="movie-list-empty"><p>Chưa có cấu hình giá vé.</p></div>
    </c:when>
    <c:otherwise>
      <div class="pr-board">
        <c:forEach var="g" items="${priceGroups}">
          <section class="pr-block">
            <h2 class="pr-block-title">
              <c:choose>
                <c:when test="${g.key == 'Standard'}">Ghế thường</c:when>
                <c:when test="${g.key == 'Couple'}">Ghế đôi</c:when>
                <c:otherwise>Ghế <c:out value="${g.key}"/></c:otherwise>
              </c:choose>
            </h2>
            <div class="table-wrap">
              <table class="pr-table">
                <thead>
                  <tr><th>Khung giờ</th><th>Thứ 2 – Thứ 6</th><th>Thứ 7, Chủ nhật</th><th>Ngày lễ</th></tr>
                </thead>
                <tbody>
                  <c:forEach var="row" items="${g.value}">
                    <tr>
                      <td class="pr-slot"><strong><c:out value="${row.slotName}"/></strong><small><c:out value="${row.slotRange}"/></small></td>
                      <td><c:choose><c:when test="${row.weekday != null}"><fmt:formatNumber value="${row.weekday}" pattern="#,##0"/>đ</c:when><c:otherwise>—</c:otherwise></c:choose></td>
                      <td><c:choose><c:when test="${row.weekend != null}"><fmt:formatNumber value="${row.weekend}" pattern="#,##0"/>đ</c:when><c:otherwise>—</c:otherwise></c:choose></td>
                      <td><c:choose><c:when test="${row.holiday != null}"><fmt:formatNumber value="${row.holiday}" pattern="#,##0"/>đ</c:when><c:otherwise>—</c:otherwise></c:choose></td>
                    </tr>
                  </c:forEach>
                </tbody>
              </table>
            </div>
          </section>
        </c:forEach>
      </div>
      <ul class="pr-notes">
        <li>Giá vé tính theo từng ghế (đơn vị: VNĐ), áp dụng theo khung giờ bắt đầu suất chiếu, loại ghế và loại ngày.</li>
        <li>Ghế đôi được bán theo cặp. Giá ghi ở bảng là giá của mỗi ghế.</li>
        <li>Giá vé có thể thay đổi theo từng thời điểm; số tiền cuối cùng là số hiển thị ở bước chọn ghế.</li>
      </ul>
    </c:otherwise>
  </c:choose>
</main>
<%@ include file="_footer.jspf" %>
