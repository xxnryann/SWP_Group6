<%@ page isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Có lỗi xảy ra"/>
<c:set var="layout" value="public"/>
<%@ include file="layout/top.jspf" %>
<div class="container container-sm">
  <div class="card card-pad empty" style="margin:48px 0">
    <div class="empty-icon">${ic.alert}</div>
    <h3>Rất tiếc, đã có lỗi xảy ra</h3>
    <p>Trang bạn tìm không tồn tại hoặc hệ thống đang gặp sự cố. Vui lòng thử lại sau.</p>
    <div class="cluster mt-8" style="justify-content:center">
      <a class="btn btn-primary" href="${ctx}/home">${ic.home}Về trang chủ</a>
      <a class="btn" href="javascript:history.back()">${ic.chevronLeft}Quay lại</a>
    </div>
  </div>
</div>
<%@ include file="layout/bottom.jspf" %>
