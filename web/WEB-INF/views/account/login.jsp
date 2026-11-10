<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng nhập"/>
<c:set var="mainClass" value="p-0"/>
<%@ include file="../layout/top.jspf" %>
<div class="auth">
  <section class="auth-aside" aria-hidden="true">
    <a class="brand brand-light" href="${ctx}/home" tabindex="-1"><%@ include file="../_logo-mark.jspf" %><span>Cine<b>Star</b> Cinemas</span></a>
    <div>
      <span class="eyebrow">Thành viên CineStar</span>
      <h1>Chào mừng<br>trở lại rạp.</h1>
      <p>Đăng nhập để giữ chỗ nhanh hơn, xem lại vé và dùng ưu đãi dành riêng cho bạn.</p>
    </div>
    <ul class="perks">
      <li>${ic.qr}Vé điện tử có mã QR, đưa ra là vào rạp</li>
      <li>${ic.inbox}Hộp thư nhắc lịch chiếu và báo hoàn tiền</li>
      <li>${ic.coins}Điểm MyPoint và voucher ở cùng một nơi</li>
    </ul>
  </section>

  <div class="auth-body">
    <form class="auth-form form" method="post" action="${ctx}/login" novalidate>
      <div>
        <h2>Đăng nhập</h2>
        <p class="sub">Dùng email hoặc số điện thoại đã đăng ký.</p>
      </div>
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
      <input type="hidden" name="_csrf" value="${csrf}">
      <div class="field">
        <label for="identifier">Email hoặc số điện thoại</label>
        <div class="input-group">${ic.user}
          <input id="identifier" name="identifier" type="text" autocomplete="username" required
                 placeholder="ban@email.com" value="<c:out value='${identifier}'/>" autofocus>
        </div>
      </div>
      <div class="field">
        <label for="password">Mật khẩu</label>
        <div class="pw-wrap">
          <input id="password" name="password" type="password" autocomplete="current-password" required placeholder="Nhập mật khẩu">
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
      </div>
      <button class="btn btn-primary btn-lg btn-block" type="submit">Đăng nhập</button>
      <p class="auth-alt">Chưa có tài khoản? <a class="fw-600" href="${ctx}/register">Đăng ký miễn phí</a></p>
    </form>
  </div>
</div>
<%@ include file="../layout/bottom.jspf" %>
