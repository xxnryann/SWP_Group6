<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Dashboard - Khách hàng"/>
<%@ include file="../_header.jspf" %>
<main class="dashboard">
  <div class="container">
    <h1>Dashboard Khách hàng</h1>
    
    <section class="dashboard-section">
      <h2>Phim đang chiếu</h2>
      <c:choose>
        <c:when test="${empty nowShowingMovies}">
          <div class="dashboard-empty">
            <p>Không có phim đang chiếu lúc này.</p>
          </div>
        </c:when>
        <c:otherwise>
          <div class="dashboard-movie-grid">
            <c:forEach var="item" items="${nowShowingMovies}">
              <c:set var="movie" value="${item.movie}"/>
              <c:set var="posterSrc"><c:out value="${movie.posterDisplayUrl}"/></c:set>
              <c:set var="movieTitle"><c:out value="${movie.title}"/></c:set>
              <c:url var="detailUrl" value="/movies/detail"><c:param name="id" value="${movie.movieId}"/></c:url>
              <c:set var="escapedDetailUrl"><c:out value="${detailUrl}"/></c:set>
              <article class="dashboard-movie-card">
                <a class="dashboard-movie-card-main" href="${escapedDetailUrl}">
                  <div class="dashboard-movie-poster">
                    <c:choose>
                      <c:when test="${not empty movie.posterDisplayUrl}">
                        <c:choose>
                          <c:when test="${movie.uploadedPoster}"><img src="${ctx}${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:when>
                          <c:otherwise><img src="${posterSrc}" alt="Poster phim ${movieTitle}" loading="lazy"></c:otherwise>
                        </c:choose>
                      </c:when>
                      <c:otherwise><div class="poster-placeholder">Chưa có poster</div></c:otherwise>
                    </c:choose>
                    <span class="badge"><c:out value="${movie.ageRating}"/></span>
                  </div>
                  <div class="dashboard-movie-info">
                    <h3><c:out value="${movie.title}"/></h3>
                    <p class="dashboard-movie-meta">
                      <c:if test="${not empty movie.genres}"><c:out value="${movie.genres}"/></c:if>
                      <c:if test="${not empty movie.genres}"> · </c:if>
                      <c:out value="${movie.durationMinutes}"/> phút
                    </p>
                    <c:choose>
                      <c:when test="${not empty item.nextShowtimeLabel}">
                        <p class="dashboard-movie-showtime">Suất gần nhất: <strong><c:out value="${item.nextShowtimeLabel}"/></strong></p>
                      </c:when>
                      <c:otherwise>
                        <p class="dashboard-movie-showtime is-muted">Chưa có lịch chiếu</p>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </a>
                <a class="btn btn-primary dashboard-movie-buy" href="${ctx}/showtimes">Mua vé</a>
              </article>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
    
    <section class="dashboard-section">
      <h2>Tài khoản của tôi</h2>
      <nav class="dashboard-links">
        <a href="${ctx}/account/profile">Thông tin cá nhân</a>
        <a href="${ctx}/account/password">Đổi mật khẩu</a>
        <a href="${ctx}/tickets">Lịch sử vé</a>
        <a href="${ctx}/points">Điểm thành viên</a>
      </nav>
    </section>
  </div>
</main>
<%@ include file="../_footer.jspf" %>
