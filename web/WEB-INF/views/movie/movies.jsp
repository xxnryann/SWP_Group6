<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Phim"/>
<c:set var="mainClass" value="main-flush"/>
<%@ include file="../layout/top.jspf" %>

<section class="hero-band">
  <div class="container">
    <div class="cluster between" style="align-items:flex-end">
      <div>
        <span class="eyebrow">CineStar Cinemas</span>
        <h1>Danh sách phim</h1>
        <p>Phim đang chiếu và sắp ra mắt tại rạp. Chọn phim, chọn suất chiếu và đặt vé chỉ với vài bước.</p>
      </div>
      <c:if test="${canManageMovies}"><a class="btn btn-primary" href="${ctx}/manage/movies">${ic.settings}Quản lý phim</a></c:if>
    </div>
  </div>
</section>

<div class="container mt-32">
  <c:if test="${showStatusFilter}">
    <nav class="tabs" aria-label="Trạng thái phim" style="margin-bottom:18px">
      <c:url var="tabAll" value="/movies"><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabNow" value="/movies"><c:param name="status" value="NowShowing"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabSoon" value="/movies"><c:param name="status" value="Upcoming"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <c:url var="tabEnded" value="/movies"><c:param name="status" value="Stopped"/><c:if test="${not empty selectedGenre}"><c:param name="genre" value="${selectedGenre}"/></c:if></c:url>
      <a class="${empty selectedStatus ? 'active' : ''}" href="${tabAll}">Tất cả</a>
      <a class="${selectedStatus == 'NowShowing' ? 'active' : ''}" href="${tabNow}">Đang chiếu</a>
      <a class="${selectedStatus == 'Upcoming' ? 'active' : ''}" href="${tabSoon}">Sắp chiếu</a>
      <c:if test="${not hideEndedFilter}"><a class="${selectedStatus == 'Stopped' ? 'active' : ''}" href="${tabEnded}">Đã kết thúc</a></c:if>
    </nav>

    <div class="chips mb-24" aria-label="Thể loại">
      <c:url var="genreAll" value="/movies"><c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if></c:url>
      <a class="chip ${empty selectedGenre ? 'active' : ''}" href="${genreAll}">Mọi thể loại</a>
      <c:forEach var="genre" items="${genres}">
        <c:url var="genreUrl" value="/movies">
          <c:if test="${not empty selectedStatus}"><c:param name="status" value="${selectedStatus}"/></c:if>
          <c:param name="genre" value="${genre.genreId}"/>
        </c:url>
        <a class="chip ${selectedGenre == genre.genreId ? 'active' : ''}" href="${genreUrl}"><c:out value="${genre.genreName}"/></a>
      </c:forEach>
    </div>
  </c:if>

  <c:choose>
    <c:when test="${empty movies}">
      <div class="card empty"><div class="empty-icon">${ic.film}</div><h3>Không có phim nào phù hợp</h3><p>Thử chọn trạng thái hoặc thể loại khác.</p></div>
    </c:when>
    <c:otherwise>
      <p class="muted text-sm mb-16"><c:out value="${fn:length(movies)}"/> phim</p>
      <div class="movie-grid">
        <c:forEach var="movie" items="${movies}">
          <c:set var="mv" value="${movie}"/><c:set var="mvNext" value=""/>
          <%-- Không hiện nút "Mua vé" ở danh sách phim: khách đặt vé qua trang Lịch chiếu. --%>
          <c:set var="mvCta" value="detail"/>
          <%@ include file="../layout/movie-card.jspf" %>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</div>

<%@ include file="../layout/bottom.jspf" %>
