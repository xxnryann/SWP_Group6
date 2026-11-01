<%@ page isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Có lỗi xảy ra"/>
<%@ include file="_header.jspf" %>
<main>
  <div class="container error-box">
    <h2>Rất tiếc, đã có lỗi xảy ra</h2>
    <p>Trang bạn tìm không tồn tại hoặc hệ thống đang gặp sự cố. Vui lòng thử lại sau.</p>
    <a class="btn btn-cta" href="${pageContext.request.contextPath}/home">Về trang chủ</a>
  </div>
</main>
<%@ include file="_footer.jspf" %>