<%@ tag pageEncoding="UTF-8" body-content="empty" description="Vạch ngăn khi loại ghế đổi giữa hai hàng; không ghi chữ mô tả khu vực ghế." %>
<%@ attribute name="type" required="true" %>
<%@ attribute name="variant" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:if test="${variant == '3d' && type == 'Couple'}"><div class="sp-3d-rule"></div></c:if>
