<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Trang chủ"/>
<%@ include file="_header.jspf" %>
<main>
  <section class="hero-home">
    <div class="container">
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Đặt vé xem phim<br>nhanh chóng, tiện lợi</h1>
      <p class="lead">Chọn rạp, chọn suất chiếu và tận hưởng những bộ phim bom tấn với âm thanh Dolby Atmos.</p>
      <c:if test="${empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/register">Đăng ký thành viên</a>
        <a class="btn btn-outline" href="${pageContext.request.contextPath}/login">Đăng nhập</a>
      </c:if>
      <c:if test="${not empty sessionScope.authUser}">
        <a class="btn btn-cta" href="${pageContext.request.contextPath}/account/profile">Tài khoản của tôi</a>
      </c:if>
    </div>
  </section>
  <section class="page">
    <div class="container">
      <div class="feature-grid">
        <div class="feature"><div class="ico">🎬</div><h3>Phim bom tấn</h3><p>Cập nhật suất chiếu mới nhất tại rạp CineStar.</p></div>
        <div class="feature"><div class="ico">🔊</div><h3>Chất lượng đỉnh cao</h3><p>Phòng chiếu 2D, 3D, IMAX và Dolby Atmos cho trải nghiệm trọn vẹn.</p></div>
        <div class="feature"><div class="ico">🎁</div><h3>Ưu đãi thành viên</h3><p>Tích điểm mỗi lần mua vé và nhận khuyến mãi dành riêng cho hội viên.</p></div>
      </div>
    </div>
  </section>
</main>
<%@ include file="_footer.jspf" %>
