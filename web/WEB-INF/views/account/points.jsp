<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Điểm MyPoint"/>
<%@ include file="../layout/top.jspf" %>
<div class="${appShell ? '' : 'container'}">
  <div class="page-head"><div><h1>Điểm MyPoint</h1><p>Tích điểm sau mỗi đơn và dùng điểm để giảm tiền ở lần đặt vé sau. Vé đã thanh toán không thể hủy/hoàn tiền do lỗi từ phía khách hàng; chỉ khi rạp hủy suất chiếu do sự cố, giá trị đơn mới được hoàn thành MyPoint kèm một lượt voucher đền bù.</p></div></div>
  <div class="split" style="grid-template-columns:minmax(0,1fr) 360px">
    <section class="card">
      <div class="card-head"><div><h2>Lịch sử điểm</h2><p>Các lần cộng và trừ điểm gần đây</p></div></div>
      <c:choose>
        <c:when test="${empty history}">
          <div class="empty"><div class="empty-icon">${ic.coins}</div><h3>Chưa có giao dịch điểm</h3><p>Đặt vé đầu tiên để bắt đầu tích điểm.</p></div>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="table">
              <thead><tr><th>Thời gian</th><th>Nội dung</th><th class="num">Điểm</th></tr></thead>
              <tbody>
              <c:forEach var="p" items="${history}">
                <tr>
                  <td class="nowrap muted text-sm"><c:out value="${p.createdAt.toLocalDate()}"/> <c:out value="${p.createdAt.toLocalTime().toString().substring(0,5)}"/></td>
                  <td><c:out value="${p.reason}"/></td>
                  <td class="num"><span class="badge ${p.points > 0 ? 'badge-success' : 'badge-danger'}"><c:if test="${p.points > 0}">+</c:if><c:out value="${p.points}"/></span></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>

    <aside class="stack sticky" style="--gap:16px">
      <div class="stat featured">
        <div class="stat-icon">${ic.coins}</div>
        <div class="stat-label">Số điểm hiện có</div>
        <div class="stat-value" style="font-size:40px"><fmt:formatNumber value="${points}" groupingUsed="true"/></div>
        <c:if test="${not empty pointConfig}"><div class="stat-meta">≈ <fmt:formatNumber value="${points * pointConfig.pointValueVnd}" groupingUsed="true"/> đ khi dùng để thanh toán</div></c:if>
      </div>
      <c:if test="${not empty pointConfig}">
        <section class="card card-pad">
          <h3 class="mb-16" style="font-size:var(--fs-h4)">Cách tích và dùng điểm</h3>
          <ol class="steps">
            <li>Mỗi đơn thanh toán thành công được cộng <strong><fmt:formatNumber value="${pointConfig.earnRatePercent}" maxFractionDigits="2"/>%</strong> giá trị đơn, quy ra điểm.</li>
            <li>1 điểm = <strong><fmt:formatNumber value="${pointConfig.pointValueVnd}" groupingUsed="true"/> đ</strong>.</li>
            <li>Nhập điểm ở bước thanh toán: voucher áp trước, điểm áp sau trên số tiền còn lại.</li>
            <li>Suất chiếu bị hủy do sự cố: hoàn (tiền vé + bắp nước + giá trị MyPoint đã dùng − phần giảm voucher) ÷ <fmt:formatNumber value="${pointConfig.pointValueVnd}" groupingUsed="true"/> đ điểm, làm tròn xuống; điểm đã tích từ đơn bị hủy được thu hồi. Voucher đền bù xem tại tab <a href="${ctx}/account/vouchers">Voucher</a>.</li>
          </ol>
        </section>
      </c:if>
    </aside>
  </div>
</div>
<%@ include file="../layout/bottom.jspf" %>
