<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" session="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%-- Trang mở từ mã QR qua tunnel công khai: proxy chỉ cho đi qua /ticket/view nên CSS phải nằm ngay trong trang. --%>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <meta name="theme-color" content="#2a4fd6">
  <title>Thông tin vé - CineStar Cinemas</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; min-height: 100vh; background: linear-gradient(180deg, #13235e 0, #2a4fd6 220px, #f5f7fb 220px); color: #1d2840;
           font: 15px/1.55 "Be Vietnam Pro", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
    main { max-width: 460px; margin: 0 auto; padding: 28px 18px 40px; }
    .brand { display: flex; align-items: center; gap: 10px; color: #fff; font-weight: 800; font-size: 19px; letter-spacing: -.04em; margin-bottom: 22px; }
    .brand b { color: #ffb52e; }
    .brand svg { width: 30px; height: 30px; }
    .ticket { position: relative; background: #fff; border-radius: 20px; box-shadow: 0 24px 56px -18px rgba(19, 35, 94, .4); overflow: hidden; }
    .ticket-top { padding: 22px 22px 18px; }
    .ticket-top small { color: #56627a; font-size: 12px; font-weight: 700; letter-spacing: .1em; text-transform: uppercase; }
    h1 { margin: 6px 0 10px; color: #0b1324; font-size: 22px; line-height: 1.25; letter-spacing: -.02em; }
    .status { display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px; border-radius: 999px; font-size: 12.5px; font-weight: 700; }
    .status::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
    .st-active { background: #e7f7ee; color: #0a7a44; }
    .st-used { background: #eef3ff; color: #2140b0; }
    .st-expired, .st-cancelled { background: #eef2f8; color: #56627a; }
    .perf { position: relative; height: 0; border-top: 2px dashed #e4e9f2; margin: 0 22px; }
    .perf::before, .perf::after { content: ""; position: absolute; top: -13px; width: 24px; height: 24px; border-radius: 50%; background: #f5f7fb; }
    .perf::before { left: -34px; } .perf::after { right: -34px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px 18px; padding: 18px 22px 22px; margin: 0; }
    .grid div.full { grid-column: 1 / -1; }
    dt { color: #8a95aa; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; }
    dd { margin: 2px 0 0; color: #0b1324; font-weight: 700; }
    .code { display: block; margin: 0 22px 22px; padding: 12px; border-radius: 12px; background: #f5f7fb; text-align: center;
            font-family: ui-monospace, Consolas, monospace; font-size: 18px; font-weight: 700; letter-spacing: .12em; color: #2140b0; }
    .note { margin: 18px 4px 0; color: #56627a; font-size: 13.5px; text-align: center; }
    .empty { padding: 32px 22px; text-align: center; }
    .empty p { color: #56627a; }
  </style>
</head>
<body>
<main>
  <div class="brand">
    <svg viewBox="0 0 34 34" aria-hidden="true"><path fill="#fff" d="M7 5h20a4 4 0 0 1 4 4v4.5a3.5 3.5 0 0 0 0 7V25a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4v-4.5a3.5 3.5 0 0 0 0-7V9a4 4 0 0 1 4-4z"/><path fill="#2a4fd6" d="M17 9.6l2.2 4.5 5 .7-3.6 3.5.9 5-4.5-2.4-4.5 2.4.9-5-3.6-3.5 5-.7z"/></svg>
    <span>Cine<b>Star</b> Cinemas</span>
  </div>
  <c:choose>
    <c:when test="${empty ticket}">
      <div class="ticket empty">
        <h1>Không tìm thấy vé</h1>
        <p>Mã QR không hợp lệ hoặc vé không còn tồn tại.</p>
      </div>
    </c:when>
    <c:otherwise>
      <article class="ticket">
        <div class="ticket-top">
          <small>Vé xem phim</small>
          <h1><c:out value="${ticket.movieTitle}"/></h1>
          <span class="status ${ticket.statusCss}"><c:out value="${ticket.statusLabel}"/></span>
        </div>
        <div class="perf"></div>
        <dl class="grid">
          <div><dt>Ngày chiếu</dt><dd><c:out value="${ticket.showDateLabel}"/></dd></div>
          <div><dt>Giờ chiếu</dt><dd><c:out value="${ticket.showHourLabel}"/></dd></div>
          <div><dt>Phòng</dt><dd><c:out value="${ticket.roomName}"/></dd></div>
          <div><dt>Ghế</dt><dd><c:out value="${ticket.seatDisplay}"/></dd></div>
          <div><dt>Thời lượng</dt><dd><c:out value="${ticket.durationMinutes}"/> phút</dd></div>
          <div><dt>Rạp</dt><dd><c:out value="${ticket.cinemaName}"/></dd></div>
          <c:if test="${not empty ticket.cinemaAddress}"><div class="full"><dt>Địa chỉ</dt><dd><c:out value="${ticket.cinemaAddress}"/></dd></div></c:if>
        </dl>
        <span class="code"><c:out value="${ticket.ticketCode}"/></span>
      </article>
      <p class="note">Đưa mã QR này cho nhân viên soát vé tại cửa phòng chiếu.</p>
    </c:otherwise>
  </c:choose>
</main>
</body>
</html>
