<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Lịch sử vé"/>
<c:set var="parentTitle" value="Tài khoản"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/account/profile"/>
<c:set var="activeNav" value="tickets"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="account-grid">
    <%@ include file="_account_side.jspf" %>
    <section class="panel">
      <h2>Lịch sử vé</h2>
      <p class="sub">Các vé bạn đã đặt, mới nhất ở trên cùng.</p>
      <c:choose>
        <c:when test="${empty tickets}">
          <p class="sub">Bạn chưa có vé nào.</p>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="data">
              <thead><tr><th>Phim</th><th>Rạp / Phòng</th><th>Suất chiếu</th><th>Ghế</th><th>Tổng tiền</th><th>Trạng thái</th></tr></thead>
              <tbody>
              <c:forEach var="t" items="${tickets}">
                <tr>
                  <td><c:out value="${t.movieTitle}"/></td>
                  <td><c:out value="${t.cinemaName}"/> – <c:out value="${t.roomName}"/></td>
                  <td><c:out value="${t.showTime.toLocalDate()}"/> <c:out value="${t.showTime.toLocalTime().toString().substring(0,5)}"/></td>
                  <td><c:out value="${t.seats}"/></td>
                  <td><fmt:formatNumber value="${t.totalPrice}" pattern="#,##0"/> đ</td>
                  <td>
                    <c:choose>
                      <c:when test="${t.status == 'PAID'}">Đã thanh toán</c:when>
                      <c:when test="${t.status == 'USED'}">Đã sử dụng</c:when>
                      <c:otherwise>Đã hủy</c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>
