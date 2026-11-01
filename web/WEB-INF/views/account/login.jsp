<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng nhập"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <a class="logo auth-logo" href="${pageContext.request.contextPath}/home"><%@ include file="../_logo-mark.jspf" %><span>Cine<b>Star</b> Cinemas</span></a>
    <div class="auth-hero-body">
      <div class="eyebrow">Thành viên CineStar</div>
      <h1>Chào mừng<br>trở lại</h1>
      <p>Đăng nhập để xem vé, nhận thông báo và dùng ưu đãi của bạn.</p>
    </div>
    <ul class="auth-perks">
      <li>Vé điện tử có mã QR, đưa ra là vào rạp</li>
      <li>Hộp thư nhắc lịch chiếu và báo hoàn tiền</li>
      <li>Điểm MyPoint và voucher trong một nơi</li>
    </ul>
    <div class="auth-hero-art"><%@ include file="../_logo-mark.jspf" %></div>
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
<%@ include file="../_footer.jspf" %>



