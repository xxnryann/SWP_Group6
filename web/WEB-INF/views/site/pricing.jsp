<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Bảng giá vé"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>
<fmt:setLocale value="vi_VN"/>
<section class="hero-band">
  <div class="container">
    <span class="eyebrow">Minh bạch, dễ chọn</span>
    <h1>Bảng giá vé</h1>
    <p>Giá vé theo loại ghế, khung giờ bắt đầu suất chiếu và loại ngày. Số tiền cuối cùng hiển thị ở bước chọn ghế.</p>
  </div>
</section>

<div class="container mt-32">
  <c:choose>
    <c:when test="${empty priceRows}">
      <div class="card empty"><div class="empty-icon">${ic.wallet}</div><h3>Chưa có cấu hình giá vé</h3></div>
    </c:when>
    <c:otherwise>
      <div class="stack" style="--gap:22px">
        <c:forEach var="g" items="${priceGroups}">
          <section class="card">
            <div class="card-head">
              <div class="cluster" style="--gap:12px">
                <span class="stat-icon" style="margin:0">${ic.seat}</span>
                <h2>
                  <c:choose>
                    <c:when test="${g.key == 'Standard'}">Ghế thường</c:when>
                    <c:when test="${g.key == 'Couple'}">Ghế đôi</c:when>
                    <c:otherwise>Ghế <c:out value="${g.key}"/></c:otherwise>
                  </c:choose>
                </h2>
              </div>
              <c:if test="${g.key == 'Couple'}"><span class="badge badge-accent">Bán theo cặp · giá mỗi ghế</span></c:if>
            </div>
            <div class="table-wrap">
              <table class="table price-table">
                <thead><tr><th>Khung giờ</th><th>Thứ 2 – Thứ 6</th><th>Thứ 7, Chủ nhật</th><th>Ngày lễ</th></tr></thead>
                <tbody>
                  <c:forEach var="row" items="${g.value}">
                    <tr>
                      <td><span class="cell-main"><c:out value="${row.slotName}"/></span><span class="cell-sub"><c:out value="${row.slotRange}"/></span></td>
                      <td class="money"><c:choose><c:when test="${row.weekday != null}"><fmt:formatNumber value="${row.weekday}" pattern="#,##0"/>đ</c:when><c:otherwise><span class="muted">—</span></c:otherwise></c:choose></td>
                      <td class="money"><c:choose><c:when test="${row.weekend != null}"><fmt:formatNumber value="${row.weekend}" pattern="#,##0"/>đ</c:when><c:otherwise><span class="muted">—</span></c:otherwise></c:choose></td>
                      <td class="money"><c:choose><c:when test="${row.holiday != null}"><fmt:formatNumber value="${row.holiday}" pattern="#,##0"/>đ</c:when><c:otherwise><span class="muted">—</span></c:otherwise></c:choose></td>
                    </tr>
                  </c:forEach>
                </tbody>
              </table>
            </div>
          </section>
        </c:forEach>
        <div class="alert alert-info">${ic.info}
          <div>
            <strong>Lưu ý</strong>
            <ul style="margin:6px 0 0;padding-left:18px">
              <li>Giá vé tính theo từng ghế (VNĐ), theo khung giờ bắt đầu suất chiếu, loại ghế và loại ngày.</li>
              <li>Ghế đôi bán theo cặp, giá trong bảng là giá của mỗi ghế.</li>
              <li>Giá có thể thay đổi theo thời điểm; số tiền cuối cùng là số hiển thị ở bước chọn ghế.</li>
            </ul>
          </div>
        </div>
        <div class="text-center"><a class="btn btn-primary btn-lg" href="${ctx}/showtimes">${ic.ticket}Xem lịch chiếu và đặt vé</a></div>
      </div>
    </c:otherwise>
  </c:choose>
</div>
<div style="height:56px"></div>
<%@ include file="../layout/bottom.jspf" %>
