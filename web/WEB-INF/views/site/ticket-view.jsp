<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <title>Thông tin vé - CineStar Cinemas</title>
  <style>
    body { margin: 0; background: #fff; color: #111827; font: 16px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
    main { max-width: 520px; margin: 0 auto; padding: 28px 20px 40px; }
    h1 { font-size: 20px; margin: 0 0 4px; }
    .brand { color: #6b7280; font-size: 14px; margin: 0 0 20px; }
    .status { display: inline-block; padding: 3px 12px; border-radius: 999px; font-size: 13px; font-weight: 700; margin-bottom: 18px; }
    .st-active { background: #dcfce7; color: #166534; }
    .st-used { background: #dbeafe; color: #1e40af; }
    .st-expired, .st-cancelled { background: #f3f4f6; color: #6b7280; }
    dl { margin: 0; }
    .row { display: grid; grid-template-columns: 120px 1fr; gap: 12px; padding: 11px 0; border-top: 1px solid #e5e7eb; }
    .row:first-child { border-top: 0; }
    dt { color: #6b7280; }
    dd { margin: 0; font-weight: 600; }
    .code { font-family: ui-monospace, Consolas, monospace; letter-spacing: .04em; }
    .note { margin-top: 22px; color: #6b7280; font-size: 14px; }
  </style>
</head>
<body>
<main>
  <c:choose>
    <c:when test="${empty ticket}">
      <h1>Không tìm thấy vé</h1>
      <p class="brand">CineStar Cinemas</p>
      <p>Mã QR không hợp lệ hoặc vé không còn tồn tại.</p>
    </c:when>
    <c:otherwise>
      <h1>Vé xem phim</h1>
      <p class="brand">CineStar Cinemas</p>
      <span class="status ${ticket.statusCss}"><c:out value="${ticket.statusLabel}"/></span>
      <dl>
        <div class="row"><dt>Phim</dt><dd><c:out value="${ticket.movieTitle}"/></dd></div>
        <div class="row"><dt>Ngày chiếu</dt><dd><c:out value="${ticket.showDateLabel}"/></dd></div>
        <div class="row"><dt>Giờ chiếu</dt><dd><c:out value="${ticket.showHourLabel}"/></dd></div>
        <div class="row"><dt>Thời lượng</dt><dd><c:out value="${ticket.durationMinutes}"/> phút</dd></div>
        <div class="row"><dt>Rạp</dt><dd><c:out value="${ticket.cinemaName}"/></dd></div>
        <c:if test="${not empty ticket.cinemaAddress}">
          <div class="row"><dt>Địa chỉ</dt><dd><c:out value="${ticket.cinemaAddress}"/></dd></div>
        </c:if>
        <div class="row"><dt>Phòng chiếu</dt><dd><c:out value="${ticket.roomName}"/></dd></div>
        <div class="row"><dt>Ghế</dt><dd><c:out value="${ticket.seatDisplay}"/></dd></div>
        <div class="row"><dt>Mã vé</dt><dd class="code"><c:out value="${ticket.ticketCode}"/></dd></div>
      </dl>
      <p class="note">Đưa mã QR này cho nhân viên soát vé tại rạp.</p>
    </c:otherwise>
  </c:choose>
</main>
</body>
</html>
