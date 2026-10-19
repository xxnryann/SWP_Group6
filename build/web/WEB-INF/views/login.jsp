<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng nhập"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <div class="eyebrow">Thành viên CineStar</div>
    <h1>Chào mừng<br>trở lại</h1>
    <p>Đăng nhập để quản lý vé, ghế yêu thích và đặc quyền hội viên của bạn.</p>
  </section>
      <form class="card" method="post" action="${pageContext.request.contextPath}/login" novalidate>
      <h2>Đăng nhập</h2>
      <p class="sub">Dùng email hoặc số điện thoại đã đăng ký.</p>
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert"><c:out value="${error}"/></div></c:if>
      <input type="hidden" name="_csrf" value="${csrf}">
      <div class="field">
        <label for="identifier">EMAIL / SỐ ĐIỆN THOẠI</label>
        <input id="identifier" name="identifier" type="text" autocomplete="username" required
               value="<c:out value='${identifier}'/>" autofocus>
      </div>
      <div class="field">
        <label for="password">MẬT KHẨU</label>
        <div class="pw-wrap">
          <input id="password" name="password" type="password" autocomplete="current-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
      </div>
      <button class="btn btn-cta btn-block" type="submit">Đăng nhập</button>
      <p class="alt">Chưa có tài khoản? <a href="${pageContext.request.contextPath}/register">Đăng ký ngay</a></p>
    </form>
</div></div>
</main>
<%@ include file="_footer.jspf" %>
