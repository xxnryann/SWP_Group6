<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng ký"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
<div class="auth-wrap">
  <section class="auth-hero">
    <a class="logo auth-logo" href="${pageContext.request.contextPath}/home"><%@ include file="../_logo-mark.jspf" %><span>Cine<b>Star</b> Cinemas</span></a>
    <div class="auth-hero-body">
      <div class="eyebrow">Đăng ký miễn phí</div>
      <h1>Trở thành<br>hội viên</h1>
      <p>Tạo tài khoản để đặt vé nhanh hơn và nhận ưu đãi dành cho hội viên.</p>
    </div>
    <ul class="auth-perks">
      <li>Chọn ghế và đặt vé online trong vài bước</li>
      <li>Tích điểm MyPoint sau mỗi lần mua vé</li>
      <li>Nhận thêm điểm khi đánh giá phim đã xem</li>
    </ul>
    <div class="auth-hero-art"><%@ include file="../_logo-mark.jspf" %></div>
  </section>
      <form class="card" method="post" action="${pageContext.request.contextPath}/register" novalidate>
      <h2>Tạo tài khoản</h2>
      <p class="sub">Chúng tôi sẽ gửi mã OTP tới email để xác thực.</p>
      <input type="hidden" name="_csrf" value="${csrf}">

      <div class="field ${not empty errors.fullName ? 'has-error' : ''}">
        <label for="fullName">HỌ VÀ TÊN</label>
        <input id="fullName" name="fullName" type="text" maxlength="100" required value="<c:out value='${form.fullName}'/>">
        <c:if test="${not empty errors.fullName}"><div class="error-text"><c:out value="${errors.fullName}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.email ? 'has-error' : ''}">
        <label for="email">EMAIL</label>
        <input id="email" name="email" type="email" maxlength="150" autocomplete="email" required value="<c:out value='${form.email}'/>">
        <c:if test="${not empty errors.email}"><div class="error-text"><c:out value="${errors.email}"/></div></c:if>
      </div>
      <div class="field ${not empty errors.phone ? 'has-error' : ''}">
        <label for="phone">SỐ ĐIỆN THOẠI</label>
        <input id="phone" name="phone" type="tel" maxlength="12" autocomplete="tel" required value="<c:out value='${form.phone}'/>">
        <c:if test="${not empty errors.phone}"><div class="error-text"><c:out value="${errors.phone}"/></div></c:if>
      </div>
      <div class="row">
        <div class="field ${not empty errors.dob ? 'has-error' : ''}">
          <label for="dob">NGÀY SINH</label>
          <input id="dob" name="dob" type="date" value="<c:out value='${form.dob}'/>">
          <c:if test="${not empty errors.dob}"><div class="error-text"><c:out value="${errors.dob}"/></div></c:if>
        </div>
        <div class="field">
          <label for="gender">GIỚI TÍNH</label>
          <select id="gender" name="gender">
            <option value="">—</option>
            <option value="MALE"   ${form.gender == 'MALE' ? 'selected' : ''}>Nam</option>
            <option value="FEMALE" ${form.gender == 'FEMALE' ? 'selected' : ''}>Nữ</option>
            <option value="OTHER"  ${form.gender == 'OTHER' ? 'selected' : ''}>Khác</option>
          </select>
        </div>
      </div>
      <div class="field ${not empty errors.password ? 'has-error' : ''}">
        <label for="password">MẬT KHẨU</label>
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
        <label for="confirmPassword">NHẬP LẠI MẬT KHẨU</label>
        <div class="pw-wrap">
          <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password" required>
          <button class="pw-toggle" type="button" aria-label="Hiện/ẩn mật khẩu">Hiện</button>
        </div>
        <c:if test="${not empty errors.confirmPassword}"><div class="error-text"><c:out value="${errors.confirmPassword}"/></div></c:if>
      </div>
      <button class="btn btn-cta btn-block" type="submit">Đăng ký</button>
      <p class="alt">Đã có tài khoản? <a href="${pageContext.request.contextPath}/login">Đăng nhập</a></p>
    </form>
</div></div>
</main>
<%@ include file="../_footer.jspf" %>



