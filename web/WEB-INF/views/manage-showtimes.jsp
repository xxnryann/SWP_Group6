﻿<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quáº£n lÃ½ lá»‹ch chiáº¿u"/>
<c:set var="escapedCsrf"><c:out value="${csrf}"/></c:set>
<%@ include file="_header.jspf" %>

<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="movie-page-heading">
    <div>
      <p class="eyebrow">KHU Vá»°C QUáº¢N LÃ</p>
      <h1>Quáº£n lÃ½ lá»‹ch chiáº¿u</h1>
      <p class="sub">Táº¡o, cáº­p nháº­t hoáº·c xÃ³a suáº¥t chiáº¿u. Giá» báº¯t Ä‘áº§u tá»± do theo má»‘c 15 phÃºt, giá» káº¿t thÃºc tÃ­nh báº±ng giá» báº¯t Ä‘áº§u cá»™ng thá»i lÆ°á»£ng phim, má»—i phÃ²ng cÃ¡ch nhau tá»‘i thiá»ƒu 15 phÃºt.</p>
    </div>
    <div class="movie-actions">
      <a class="btn btn-soft" href="${ctx}/manage/showtimes?action=generate">Sinh lá»‹ch tá»± Ä‘á»™ng</a>
      <a class="btn btn-primary" href="${ctx}/manage/showtimes?action=new">ThÃªm suáº¥t chiáº¿u</a>
    </div>
  </section>

  <div class="table-wrap">
    <table class="data">
      <thead>
        <tr><th>Phim</th><th>NgÃ y chiáº¿u</th><th>Thá»i gian lá»‹ch chiáº¿u</th><th>PhÃ²ng chiáº¿u</th><th>Tráº¡ng thÃ¡i</th><th>Thao tÃ¡c</th></tr>
      </thead>
      <tbody>
        <c:forEach var="showtime" items="${showtimes}">
          <c:url var="editUrl" value="/manage/showtimes"><c:param name="id" value="${showtime.showtimeId}"/></c:url>
          <c:set var="escapedEditUrl"><c:out value="${editUrl}"/></c:set>
          <c:set var="escapedId"><c:out value="${showtime.showtimeId}"/></c:set>
          <tr>
            <td><strong><c:out value="${showtime.movieTitle}"/></strong></td>
            <td><c:out value="${showtime.scheduleDateDisplay}"/></td>
            <td><c:out value="${showtime.scheduleTimeDisplay}"/></td>
            <td><c:out value="${showtime.roomName}"/></td>
            <td><c:choose>
              <c:when test="${showtime.managementStatus == 'Scheduled'}">Äang má»Ÿ</c:when>
              <c:when test="${showtime.managementStatus == 'Pending'}">Chá»</c:when>
              <c:when test="${showtime.managementStatus == 'Maintenance'}">Báº£o trÃ¬</c:when>
              <c:otherwise>ÄÃ£ há»§y</c:otherwise>
            </c:choose></td>
            <td class="movie-actions">
              <a class="btn btn-soft btn-small" href="${escapedEditUrl}">Sá»­a</a>
              <form method="post" action="${ctx}/manage/showtimes" onsubmit="return confirm('Báº¡n cÃ³ cháº¯c muá»‘n xÃ³a suáº¥t chiáº¿u nÃ y?');">
                <input type="hidden" name="_csrf" value="${escapedCsrf}">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="${escapedId}">
                <button class="btn btn-danger btn-small" type="submit">XÃ³a</button>
              </form>
            </td>
          </tr>
        </c:forEach>
        <c:if test="${empty showtimes}"><tr><td colspan="6">ChÆ°a cÃ³ suáº¥t chiáº¿u. HÃ£y thÃªm suáº¥t chiáº¿u Ä‘áº§u tiÃªn.</td></tr></c:if>
      </tbody>
    </table>
  </div>
    </div>
  </div>
</div></main>

<%@ include file="_footer.jspf" %>


