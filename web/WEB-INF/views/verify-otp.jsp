<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Xác thực OTP"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <div class="eyebrow">Bước cuối cùng</div>
    <h1>Xác thực<br>tài khoản</h1>
    <p>Mã gồm 6 chữ số đã được gửi tới email của bạn và có hiệu lực trong vài phút.</p>
  </section>
      <div class="card">
      <h2>Nhập mã OTP</h2>
      <p class="sub">Gửi tới <strong><c:out value="${email}"/></strong></p>
      <c:if test="${not empty error}"><div class="alert alert-error" role="alert"><c:out value="${error}"/></div></c:if>
      <form method="post" action="${pageContext.request.contextPath}/verify-otp">
        <input type="hidden" name="_csrf" value="${csrf}">
        <div class="field">
          <input class="otp-input" name="otp" type="text" inputmode="numeric" pattern="\d{6}" maxlength="6"
                 autocomplete="one-time-code" placeholder="000000" required autofocus>
        </div>
        <button class="btn btn-cta btn-block" type="submit">Xác thực</button>
      </form>
      <form method="post" action="${pageContext.request.contextPath}/verify-otp" class="alt">
        <input type="hidden" name="_csrf" value="${csrf}">
        <input type="hidden" name="action" value="resend">
        Không nhận được mã? <button class="btn-link" type="submit">Gửi lại mã</button>
      </form>
    </div>
</div></div>
</main>
<%@ include file="_footer.jspf" %>



