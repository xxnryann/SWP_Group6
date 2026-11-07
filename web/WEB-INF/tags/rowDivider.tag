<%@ tag pageEncoding="UTF-8" body-content="empty" description="Nhãn phân khu khi loại ghế đổi giữa hai hàng." %>
<%@ attribute name="type" required="true" %>
<%@ attribute name="variant" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:choose>
  <c:when test="${variant == '4dx'}"></c:when>
  <c:when test="${variant == '3d' && type == 'VIP'}">
    <div class="sp-3d-banner"><span>♛ KHU VỰC VÀNG 3D PRIME GOLDEN ARC (HÀNG D - G)</span><b>SWEET SPOT</b></div>
  </c:when>
  <c:when test="${variant == '3d'}">
    <c:if test="${type == 'Couple'}"><div class="sp-3d-rule"></div></c:if>
  </c:when>
  <c:when test="${variant == 'imax' && type == 'VIP'}">
    <div class="sp-imax-divider"><span>★ VÙNG ÂM TRƯỜNG &amp; GÓC NHÌN HOÀNG GIA • ROYAL SWEET SPOT ZONE</span></div>
  </c:when>
  <c:when test="${variant == 'imax'}">
    <c:if test="${type == 'Couple'}"><div class="sp-imax-spacer"></div></c:if>
  </c:when>
  <c:when test="${type == 'VIP'}">
    <div class="sp-divider sp-divider-vip"><span>★ KHU VỰC GHẾ VIP (GÓC NHÌN TRUNG TÂM) ★</span></div>
  </c:when>
  <c:when test="${type == 'Couple'}">
    <div class="sp-divider sp-divider-couple"><span>♥ HÀNG GHẾ ĐÔI / COUPLE SWEETBOX SOFA ♥</span></div>
  </c:when>
</c:choose>
