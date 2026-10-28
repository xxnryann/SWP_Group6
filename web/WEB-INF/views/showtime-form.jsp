﻿﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${showtime.showtimeId == 0 ? 'ThÃªm suáº¥t chiáº¿u' : 'Sá»­a suáº¥t chiáº¿u'}"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
<c:set var="showDateValue" value="${empty showtime.inputDate ? defaultDate : showtime.inputDate}"/>
<c:set var="escapedShowDate"><c:out value="${showDateValue}"/></c:set>
<c:set var="escapedShowTime"><c:out value="${showtime.inputTime}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="container page">
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU Vá»°C QUáº¢N LÃ</p>
      <h1><c:out value="${pageTitle}"/></h1>
      <p class="sub">Giá» báº¯t Ä‘áº§u tá»± do theo má»‘c 15 phÃºt trong ngÃ y. Giá» káº¿t thÃºc Ä‘Æ°á»£c tÃ­nh báº±ng giá» báº¯t Ä‘áº§u cá»™ng thá»i lÆ°á»£ng phim, vÃ  má»—i phÃ²ng cÃ¡ch nhau tá»‘i thiá»ƒu 15 phÃºt Ä‘á»ƒ dá»n phÃ²ng.</p>
    </div>
  </section>
  <form class="panel showtime-form" id="showtime-form" method="post" action="${ctx}/manage/showtimes"
        data-availability-url="${ctx}/manage/showtimes">
    <input type="hidden" name="_csrf" value="${escapedCsrf}">
    <input type="hidden" name="action" value="save">
    <c:if test="${showtime.showtimeId > 0}"><input type="hidden" name="id" value="${escapedId}"></c:if>
    <div class="field">
      <label for="movieId">Phim</label>
      <select id="movieId" name="movieId" required>
        <option value="">Chá»n phim</option>
        <c:forEach var="movie" items="${movies}">
          <option value="<c:out value='${movie.movieId}'/>" data-duration="<c:out value='${movie.durationMinutes}'/>" <c:if test="${showtime.movieId == movie.movieId}">selected</c:if>>
            <c:out value="${movie.title}"/> (<c:out value="${movie.durationMinutes}"/> phÃºt)
          </option>
        </c:forEach>
      </select>
    </div>
    <div class="showtime-form-grid">
      <div class="field">
        <label for="roomName">PhÃ²ng chiáº¿u</label>
        <select id="roomName" name="roomName" required>
          <option value="">Chá»n phÃ²ng</option>
          <c:forEach var="room" items="${rooms}">
            <option value="<c:out value='${room}'/>" <c:if test="${showtime.roomName == room}">selected</c:if>><c:out value="${room}"/></option>
          </c:forEach>
        </select>
      </div>
      <div class="field">
        <label for="showDate">NgÃ y chiáº¿u</label>
        <input id="showDate" name="showDate" type="date" min="${todayDate}" value="${escapedShowDate}" required>
      </div>
      <div class="field">
        <label for="showTime">Giá» báº¯t Ä‘áº§u</label>
        <select id="showTime" name="showTime" required data-current-time="${escapedShowTime}">
          <option value="">Chá»n phim, phÃ²ng vÃ  ngÃ y trÆ°á»›c</option>
        </select>
        <small id="showtime-availability-message" role="status">Chá»n phim, phÃ²ng vÃ  ngÃ y Ä‘á»ƒ táº£i giá» cÃ²n trá»‘ng.</small>
        <small id="showtime-estimated-end"></small>
      </div>
    </div>
    <div class="form-actions">
      <a class="btn btn-outline" href="${ctx}/manage/showtimes">Há»§y</a>
      <button class="btn btn-primary" type="submit">LÆ°u suáº¥t chiáº¿u</button>
    </div>
  </form>
</main>

<script src="${ctx}/assets/js/showtime-form.js" defer></script>
<%@ include file="_footer.jspf" %>



