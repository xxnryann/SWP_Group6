<%@ tag pageEncoding="UTF-8" body-content="empty" trimDirectiveWhitespaces="true" description="Mở khung một cụm ghế 4DX kèm nhãn cụm; trang gọi tự đóng thẻ div sau ghế cuối của cụm." %>
<%@ attribute name="row" required="true" %>
<%@ attribute name="number" required="true" type="java.lang.Integer" %>
<%@ attribute name="couple" required="true" type="java.lang.Boolean" %>
<%@ attribute name="seatType" required="true" %>
<%@ attribute name="zone" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="gold" value="${zone == 'core'}"/>
<c:choose>
  <c:when test="${couple && gold}"><c:set var="podName" value="CENTER VIP CP"/></c:when>
  <c:when test="${couple}"><c:set var="podName" value="CP POD ${row}${number}-${number + 1}"/></c:when>
  <c:when test="${gold}"><c:set var="podName" value="POD ${row}${number}-${number + 3} GOLD"/></c:when>
  <c:otherwise><c:set var="podName" value="POD ${row}${number}-${number + 3}"/></c:otherwise>
</c:choose>
<div class="sp-block sp-pod sp-pod-${seatType}${gold ? ' sp-pod-gold' : ''}" data-pod="${podName}">
