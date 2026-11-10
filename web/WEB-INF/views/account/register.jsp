<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng ký"/>
<c:set var="mainClass" value="p-0"/>
<%@ include file="../layout/top.jspf" %>
<div class="auth">
  <section class="auth-aside" aria-hidden="true">
    <a class="brand brand-light" href="${ctx}/home" tabindex="-1"><%@ include file="../_logo-mark.jspf" %><span>Cine<b>Star</b> Cinemas</span></a>
    <div>
      <span class="eyebrow">Đăng ký miễn phí</span>
      <h1>Trở thành<br>hội viên CineStar.</h1>
      <p>Một tài khoản để đặt vé, tích điểm và nhận ưu đãi mỗi lần ra rạp.</p>
    </div>
    <ul class="perks">
      <li>${ic.seat}Chọn ghế và đặt vé online trong vài bước</li>
      <li>${ic.coins}Tích điểm MyPoint sau mỗi lần mua vé</li>
      <li>${ic.star}Nhận thêm điểm khi đánh giá phim đã xem</li>
    </ul>
  </section>

  <div class="auth-body">
    <form class="auth-form form" method="post" action="${ctx}/register" novalidate>
      <div>
        <h2>Tạo tài khoản</h2>
        <p class="sub">Chúng tôi sẽ gửi mã OTP tới email để xác thực.</p>
      </div>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
        <label for="fullName">Họ và tên<span class="req">*</span></label>
        <input id="fullName" name="fullName" type="text" maxlength="100" autocomplete="name" required placeholder="Nguyễn Văn A" value="<c:out value='${form.fullName}'/>">
        <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
      </div>
      <div class="form-grid">
        <div class="field ${not empty errors.email ? 'has-error' : ''}">
          <label for="email">Email<span class="req">*</span></label>
          <input id="email" name="email" type="email" maxlength="150" autocomplete="email" required placeholder="ban@email.com" value="<c:out value='${form.email}'/>">
          <c:if test="${not empty errors.email}"><div class="error-text"><c:out value="${errors.email}"/></div></c:if>
        </div>
        <div class="field ${not empty errors.phone ? 'has-error' : ''}">
          <label for="phone">Số điện thoại<span class="req">*</span></label>
          <input id="phone" name="phone" type="tel" maxlength="12" autocomplete="tel" required placeholder="09xxxxxxxx" value="<c:out value='${form.phone}'/>">
          <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
        </div>
        <div class="field ${not empty errors.dob ? 'has-error' : ''}">
          <label for="dob">Ngày sinh</label>
          <input id="dob" name="dob" type="date" value="<c:out value='${form.dob}'/>">
          <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
        </div>
        <div class="field">
          <label for="gender">Giới tính</label>
          <select id="gender" name="gender">
            <option value="">Không chọn</option>
            <option value="MALE"   ${form.gender == 'MALE' ? 'selected' : ''}>Nam</option>
            <option value="FEMALE" ${form.gender == 'FEMALE' ? 'selected' : ''}>Nữ</option>
            <option value="OTHER"  ${form.gender == 'OTHER' ? 'selected' : ''}>Khác</option>
          </select>
        </div>
      </div>
      <div class="field ${not empty errors.password ? 'has-error' : ''}">
        <label for="password">Mật khẩu<span class="req">*</span></label>
        <div class="pw-wrap">
          <input id="password" name="password" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:choose>
          <c:when test="${not empty errors.password}"><div class="error-text"><c:out value="${errors.password}"/></div></c:when>
          <c:otherwise><div class="hint">Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.</div></c:otherwise>
        </c:choose>
      </div>
      <div class="field ${not empty errors.confirmPassword ? 'has-error' : ''}">
        <label for="confirmPassword">Nhập lại mật khẩu<span class="req">*</span></label>
        <div class="pw-wrap">
          <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
      </div>
      <button class="btn btn-primary btn-lg btn-block" type="submit">Tạo tài khoản</button>
      <p class="auth-alt">Đã có tài khoản? <a class="fw-600" href="${ctx}/login">Đăng nhập</a></p>
    </form>
  </div>
</div>
<%@ include file="../layout/bottom.jspf" %>
