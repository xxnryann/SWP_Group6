<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Xác thực OTP"/>
<c:set var="mainClass" value="p-0"/>
<%@ include file="../layout/top.jspf" %>
<div class="auth">
  <section class="auth-aside" aria-hidden="true">
    <a class="brand brand-light" href="${ctx}/home" tabindex="-1"><%@ include file="../_logo-mark.jspf" %><span>Cine<b>Star</b> Cinemas</span></a>
    <div>
      <span class="eyebrow">Bước cuối cùng</span>
      <h1>Xác thực<br>tài khoản.</h1>
      <p>Mã gồm 6 chữ số đã được gửi tới email của bạn và có hiệu lực trong vài phút.</p>
    </div>
    <ul class="perks">
      <li>${ic.mail}Kiểm tra cả thư mục Spam hoặc Quảng cáo</li>
      <li>${ic.shield}Không chia sẻ mã OTP cho bất kỳ ai</li>
    </ul>
  </section>

  <div class="auth-body">
    <div class="auth-form">
      <h2>Nhập mã OTP</h2>
      <p class="sub">Đã gửi tới <strong class="text-ink"><c:out value="${email}"/></strong></p>
      <c:if test="${not empty error}"><div class="alert alert-error mb-16" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>
      <form class="form" method="post" action="${ctx}/verify-otp" data-loading>
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="field">
          <label class="sr-only" for="otp">Mã OTP</label>
          <input class="otp-input" id="otp" name="otp" type="text" inputmode="numeric" pattern="\d{6}" maxlength="6"
                 autocomplete="one-time-code" placeholder="000000" required autofocus>
        </div>
        <button class="btn btn-primary btn-lg btn-block" type="submit">Xác thực</button>
      </form>
      <form class="auth-alt" method="post" action="${ctx}/verify-otp">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="resend">
        Không nhận được mã? <button class="link-btn" type="submit">Gửi lại mã</button>
      </form>
    </div>
  </div>
</div>
<%@ include file="../layout/bottom.jspf" %>
