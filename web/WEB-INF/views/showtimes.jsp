<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Lịch chiếu"/>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">CINESTAR CINEMAS</p>
      <h1>Lịch chiếu</h1>
      <p class="sub">Xem các suất chiếu đang mở theo ngày.</p>
    </div>
    <c:if test="${isManager}">
      <a class="btn btn-primary" href="${ctx}/manage/showtimes">Quản lý lịch chiếu</a>
    </c:if>
  </section>

  <form class="panel showtime-filters" method="get" action="${ctx}/showtimes">
    <div class="field">
      <label for="showtime-date">Ngày chiếu</label>
      <input id="showtime-date" type="date" name="date" value="<c:out value='${selectedDate}'/>">
    </div>
    <button class="btn btn-cta" type="submit">Xem lịch</button>
  </form>

  <c:choose>
    <c:when test="${empty showtimeGroups}">
      <div class="movie-list-empty">
        <p>Không có suất chiếu nào cho ngày này.</p>
      </div>
    </c:when>
    <c:otherwise>
      <div class="movie-list">
        <c:forEach var="group" items="${showtimeGroups}">
          <article class="movie-card">
            <div class="movie-card-poster">
              <c:choose>
                <c:when test="${not empty group.movie.posterDisplayUrl}">
                  <img src="${group.movie.uploadedPoster ? ctx : ''}${group.movie.posterDisplayUrl}" alt="Poster phim ${group.movie.title}" loading="lazy">
                </c:when>
                <c:otherwise>
                  <div class="poster-placeholder">Chưa có poster</div>
                </c:otherwise>
              </c:choose>
            </div>
            <div class="movie-card-content">
              <h3><c:out value="${group.movie.title}"/></h3>
              <p class="meta">
                <c:if test="${not empty group.movie.genres}"><c:out value="${group.movie.genres}"/> · </c:if>
                <c:out value="${group.movie.durationMinutes}"/> phút
              </p>
              <p class="rating">
                <strong><c:out value="${group.movie.ageRating}"/></strong>
              </p>
              <div class="showtimes-list">
                <c:forEach var="showtime" items="${group.showtimes}">
                  <c:choose>
                    <c:when test="${empty sessionScope.authUser or sessionScope.authUser.role == 'CUSTOMER'}">
                      <c:url var="bookingUrl" value="/booking/seats">
                        <c:param name="showtimeId" value="${showtime.showtimeId}"/>
                      </c:url>
                      <a class="showtime-btn" href="${bookingUrl}" data-start="<c:out value='${showtime.startTimeOnly}'/>">
                        <c:out value="${showtime.startTimeOnly}"/>
                      </a>
                    </c:when>
                    <c:otherwise>
                      <span class="showtime-btn"><c:out value="${showtime.startTimeOnly}"/></span>
                    </c:otherwise>
                  </c:choose>
                </c:forEach>
              </div>
            </div>
          </article>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="_footer.jspf" %>