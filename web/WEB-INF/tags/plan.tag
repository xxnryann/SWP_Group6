<%@ tag pageEncoding="UTF-8" body-content="scriptless" description="Khung sơ đồ phòng chiếu: màn hình, lối đi và cửa ra vào; thân thẻ là các hàng ghế." %>
<%@ attribute name="variant" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="seat" tagdir="/WEB-INF/tags" %>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/seat-plan.css">
<c:choose>
  <c:when test="${variant == '4dx'}">
    <div class="sp-plan sp-4dx">
      <div class="sp-doors sp-4dx-top">
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM / EMERGENCY EXIT</span>
      </div>
      <seat:screen/>
      <div class="sp-scroll">
        <div class="sp-floor">
          <seat:fxTower wind="01" side="L"/>
          <div class="sp-rows"><jsp:doBody/></div>
          <seat:fxTower wind="02" side="R"/>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-door-in"><b>LỐI VÀO / ENTRANCE</b><small>Cửa chính khán phòng →</small></span>
      </div>
    </div>
  </c:when>
  <c:when test="${variant == '3d'}">
    <div class="sp-plan sp-3d">
      <div class="sp-doors sp-3d-top">
        <span class="sp-door sp-3d-focus">TÂM ĐIỂM HỘI TỤ • VÒM CONG BÁN NGUYỆT</span>
        <span class="sp-door sp-door-exit">CỬA THOÁT HIỂM</span>
      </div>
      <seat:screen/>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-rows"><jsp:doBody/></div>
        </div>
      </div>
      <div class="sp-3d-slopes"><span>↑ Hành lang dốc cánh trái</span><span>Hành lang dốc cánh phải ↑</span></div>
      <div class="sp-exits">
        <span class="sp-door sp-imax-in"><b>LỐI VÀO CHÍNH / MAIN ENTRANCE</b></span>
      </div>
    </div>
  </c:when>
  <c:when test="${variant == 'imax'}">
    <div class="sp-plan sp-imax">
      <div class="sp-doors sp-imax-top">
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM KHẨN CẤP • CÁNH TRÁI</span>
        <span class="sp-imax-view"><i></i>TRỤC TÂM ĐIỂM IMAX</span>
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM KHẨN CẤP • CÁNH PHẢI</span>
      </div>
      <seat:screen/>
      <div class="sp-imax-ruler"><span>Hành lang LED trái</span><span>Hành lang LED phải</span></div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-rows"><jsp:doBody/></div>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-imax-in"><b>CỬA VÀO VIP LOUNGE • MAIN ENTRANCE</b><small>Cửa khán phòng IMAX</small></span>
        <span class="sp-door sp-imax-out"><b>LỐI RA RIÊNG BIỆT • PRIVATE EXIT</b><small>Thông ra sảnh chờ</small></span>
      </div>
    </div>
  </c:when>
  <c:otherwise>
    <div class="sp-plan">
      <seat:screen/>
      <div class="sp-doors">
        <span class="sp-door">↓ Lối đi khán phòng</span>
        <span class="sp-door sp-door-exit">LỐI RA / EXIT</span>
      </div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-aisle" aria-hidden="true"><span>LỐI ĐI 01</span><span>BẬC THANG</span></div>
          <div class="sp-rows"><jsp:doBody/></div>
          <div class="sp-aisle" aria-hidden="true"><span>LỐI ĐI 02</span><span>BẬC THANG</span></div>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-door-in"><b>LỐI VÀO / ENTRANCE</b><small>Cửa chính khán phòng →</small></span>
        <span class="sp-door sp-door-exit"><b>LỐI THOÁT HIỂM</b><small>↗ Cửa thoát hiểm</small></span>
      </div>
    </div>
  </c:otherwise>
</c:choose>
