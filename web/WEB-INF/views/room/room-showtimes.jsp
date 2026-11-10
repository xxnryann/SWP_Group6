<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Lịch phòng chiếu"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .rs-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .rs-head h1 { margin: 0; }
  .rs-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .rs-layout { display: grid; grid-template-columns: 260px minmax(0, 1fr); gap: 20px; align-items: start; }
  .rs-rooms { background: #fff; border: 1px solid var(--slate-200); border-radius: var(--radius); overflow: hidden;
              position: sticky; top: 16px; max-height: calc(100vh - 32px); overflow-y: auto; }
  .rs-rooms h2 { font-size: 13px; text-transform: uppercase; letter-spacing: .04em; color: var(--slate-500);
                 margin: 0; padding: 12px 14px; border-bottom: 1px solid var(--slate-200); }
  .rs-room { display: flex; justify-content: space-between; align-items: center; gap: 8px; padding: 10px 14px;
             border-bottom: 1px solid var(--slate-100); color: var(--slate-800); text-decoration: none; }
  .rs-room:last-child { border-bottom: 0; }
  .rs-room:hover { background: var(--slate-50); }
  .rs-room.is-active { background: #dbeafe; box-shadow: inset 3px 0 0 var(--brand); }
  .rs-room-name { font-weight: 700; }
  .rs-room-meta { font-size: 12px; color: var(--slate-500); margin-top: 2px; }
  .rs-count { min-width: 30px; text-align: center; padding: 2px 8px; border-radius: 99px; font-size: 12px; font-weight: 700;
              background: var(--slate-100); color: var(--slate-600); }
  .rs-count.has { background: #d1fae5; color: var(--success); }
  .rs-card { background: #fff; border: 1px solid var(--slate-200); border-radius: var(--radius); padding: 18px; margin-bottom: 16px; }
  .rs-room-head { display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; align-items: flex-start; }
  .rs-room-head h2 { margin: 0 0 6px; font-size: 22px; }
  .rs-badges { display: flex; gap: 6px; flex-wrap: wrap; align-items: center; color: var(--slate-500); font-size: 14px; }
  .rs-badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .rs-type { background: #dbeafe; color: var(--brand); }
  .rs-on { background: #d1fae5; color: var(--success); }
  .rs-off { background: var(--slate-200); color: var(--slate-600); }
  .rs-stats { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin-top: 16px; }
  .rs-stat { background: var(--slate-50); border-radius: var(--radius); padding: 10px 12px; }
  .rs-stat b { display: block; font-size: 22px; font-variant-numeric: tabular-nums; color: var(--slate-800); }
  .rs-stat span { font-size: 12px; color: var(--slate-500); }
  .rs-tabs { display: inline-flex; border: 1px solid var(--slate-300); border-radius: var(--radius); overflow: hidden; }
  .rs-tabs a { padding: 8px 14px; font-size: 14px; color: var(--slate-600); text-decoration: none; border-right: 1px solid var(--slate-300); }
  .rs-tabs a:last-child { border-right: 0; }
  .rs-tabs a.is-active { background: var(--brand); color: #fff; font-weight: 600; }
  .rs-days { display: flex; gap: 8px; overflow-x: auto; padding: 14px 0 4px; }
  .rs-day { flex: 0 0 auto; min-width: 74px; text-align: center; padding: 8px 10px; border: 1px solid var(--slate-300);
            border-radius: var(--radius); text-decoration: none; color: var(--slate-700); background: #fff; line-height: 1.25; }
  .rs-day small { display: block; font-size: 11px; color: var(--slate-500); }
  .rs-day strong { display: block; font-size: 15px; }
  .rs-day:hover { border-color: var(--brand); }
  .rs-day.is-active { background: var(--brand); border-color: var(--brand); color: #fff; }
  .rs-day.is-active small { color: #dbeafe; }
  .rs-day-title { margin: 18px 0 8px; font-size: 15px; color: var(--slate-700); }
  .rs-phase { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; white-space: nowrap; }
  .rs-phase-UPCOMING { background: #dbeafe; color: var(--brand); }
  .rs-phase-NOW { background: #fef3c7; color: #b45309; }
  .rs-phase-FINISHED { background: var(--slate-200); color: var(--slate-600); }
  .rs-phase-CANCELLED { background: #fee2e2; color: var(--danger); }
  .rs-time { font-weight: 700; font-variant-numeric: tabular-nums; white-space: nowrap; }
  .rs-muted { color: var(--slate-500); font-size: 13px; }
  .rs-fill { display: flex; align-items: center; gap: 8px; min-width: 150px; }
  .rs-bar { flex: 1; height: 6px; border-radius: 99px; background: var(--slate-200); overflow: hidden; }
  .rs-bar i { display: block; height: 100%; background: var(--brand); border-radius: 99px; }
  .rs-fill span { font-size: 13px; font-variant-numeric: tabular-nums; white-space: nowrap; }
  .rs-empty { text-align: center; padding: 40px 20px; color: var(--slate-500); }
  @media (max-width: 860px) {
    .rs-layout { grid-template-columns: 1fr; }
    .rs-rooms { position: static; max-height: 260px; }
    .rs-stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  }
</style>
      <div class="rs-head">
        <div>
          <h1>Lịch phòng chiếu</h1>
          <p>Xem từng phòng chiếu và các suất chiếu đang được xếp trong phòng đó.</p>
        </div>
        <a class="btn btn-outline" href="${ctx}/admin/rooms">← Danh sách phòng</a>
      </div>

      <c:choose>
        <c:when test="${empty rooms}">
          <div class="rs-card rs-empty">Chưa có phòng chiếu nào.</div>
        </c:when>
        <c:otherwise>
      <div class="rs-layout">
        <%-- Cột trái: danh sách phòng, số bên phải = suất chiếu sắp tới --%>
        <nav class="rs-rooms" aria-label="Chọn phòng chiếu">
          <h2>Phòng chiếu (${rooms.size()})</h2>
          <c:forEach var="r" items="${rooms}">
            <a class="rs-room ${r.roomId == room.roomId ? 'is-active' : ''}"
               href="${ctx}/admin/room-showtimes?roomId=${r.roomId}&scope=${scope}"
               ${r.roomId == room.roomId ? 'aria-current="page"' : ''}>
              <div>
                <div class="rs-room-name"><c:out value="${r.roomName}"/></div>
                <div class="rs-room-meta"><c:out value="${r.roomType}"/> · <c:out value="${r.cinemaName}"/><c:if test="${not r.active}"> · Đã đóng</c:if></div>
              </div>
              <span class="rs-count ${r.upcomingShowtimes > 0 ? 'has' : ''}" title="Suất chiếu sắp tới">${r.upcomingShowtimes}</span>
            </a>
          </c:forEach>
        </nav>

        <div>
          <%-- Thông tin phòng + số liệu --%>
          <div class="rs-card">
            <div class="rs-room-head">
              <div>
                <h2><c:out value="${room.roomName}"/></h2>
                <div class="rs-badges">
                  <span class="rs-badge rs-type"><c:out value="${room.roomType}"/></span>
                  <span class="rs-badge ${room.active ? 'rs-on' : 'rs-off'}">${room.statusLabel}</span>
                  <span><c:out value="${room.cinemaName}"/></span>
                  <span>·</span>
                  <span>
                    <c:choose>
                      <c:when test="${room.hasLayout}">${room.usableSeats}/${room.seatCount} ghế dùng được</c:when>
                      <c:otherwise>Chưa có layout ghế</c:otherwise>
                    </c:choose>
                  </span>
                </div>
              </div>
              <div class="rm-actions" style="display:flex;gap:6px;flex-wrap:wrap">
                <a class="btn btn-soft btn-small" href="${ctx}/admin/seats?roomId=${room.roomId}">Layout &amp; ghế</a>
                <a class="btn btn-soft btn-small" href="${ctx}/admin/rooms?action=edit&id=${room.roomId}">Sửa phòng</a>
              </div>
            </div>
            <div class="rs-stats">
              <div class="rs-stat"><b>${totalShowtimes}</b><span>Suất chiếu (${scope == 'upcoming' ? 'sắp tới' : scope == 'past' ? 'đã qua' : 'tất cả'})</span></div>
              <div class="rs-stat"><b>${days.size()}</b><span>Ngày có suất</span></div>
              <div class="rs-stat"><b>${totalMovies}</b><span>Phim khác nhau</span></div>
              <div class="rs-stat"><b>${totalSold}</b><span>Vé đã bán</span></div>
            </div>
          </div>

          <%-- Danh sách suất chiếu --%>
          <div class="rs-card">
            <div class="rs-tabs" role="tablist" aria-label="Phạm vi">
              <a href="${ctx}/admin/room-showtimes?roomId=${room.roomId}&scope=upcoming" class="${scope == 'upcoming' ? 'is-active' : ''}">Sắp tới</a>
              <a href="${ctx}/admin/room-showtimes?roomId=${room.roomId}&scope=past" class="${scope == 'past' ? 'is-active' : ''}">Đã qua / đã hủy</a>
              <a href="${ctx}/admin/room-showtimes?roomId=${room.roomId}&scope=all" class="${scope == 'all' ? 'is-active' : ''}">Tất cả</a>
            </div>

            <c:choose>
              <c:when test="${empty days}">
                <div class="rs-empty">
                  Phòng này không có suất chiếu ${scope == 'upcoming' ? 'sắp tới' : scope == 'past' ? 'đã qua' : ''} nào.
                </div>
              </c:when>
              <c:otherwise>
                <div class="rs-days" aria-label="Chọn ngày">
                  <a class="rs-day ${showAllDays ? 'is-active' : ''}"
                     href="${ctx}/admin/room-showtimes?roomId=${room.roomId}&scope=${scope}&date=all">
                    <small>Mọi ngày</small><strong>${totalShowtimes}</strong><small>suất</small>
                  </a>
                  <c:forEach var="d" items="${days}">
                    <a class="rs-day ${d.selected ? 'is-active' : ''}"
                       href="${ctx}/admin/room-showtimes?roomId=${room.roomId}&scope=${scope}&date=${d.iso}">
                      <small>${d.today ? 'Hôm nay' : d.weekday}</small><strong>${d.dayMonth}</strong><small>${d.count} suất</small>
                    </a>
                  </c:forEach>
                </div>

                <c:forEach var="d" items="${visibleDays}">
                  <h3 class="rs-day-title">${d.weekday}, ${d.fullDate}<c:if test="${d.today}"> (hôm nay)</c:if> · ${d.count} suất</h3>
                  <div class="table-wrap">
                    <table class="data">
                      <thead>
                        <tr><th>Giờ chiếu</th><th>Phim</th><th>Trạng thái</th><th>Vé đã bán</th><th>Mã suất</th></tr>
                      </thead>
                      <tbody>
                        <c:forEach var="st" items="${d.showtimes}">
                          <tr>
                            <td class="rs-time">${st.timeRange}</td>
                            <td>
                              <strong><c:out value="${st.movieTitle}"/></strong>
                              <div class="rs-muted">${st.durationMinutes} phút<c:if test="${not empty st.ageRating}"> · <c:out value="${st.ageRating}"/></c:if></div>
                            </td>
                            <td><span class="rs-phase rs-phase-${st.phase}">${st.phaseLabel}</span></td>
                            <td>
                              <c:choose>
                                <c:when test="${room.seatCount > 0}">
                                  <c:set var="pct" value="${st.soldTickets * 100 / room.seatCount}"/>
                                  <div class="rs-fill">
                                    <div class="rs-bar"><i style="width:${pct > 100 ? 100 : pct}%"></i></div>
                                    <span>${st.soldTickets}/${room.seatCount}</span>
                                  </div>
                                </c:when>
                                <c:otherwise>${st.soldTickets}</c:otherwise>
                              </c:choose>
                            </td>
                            <td class="rs-muted">#${st.showtimeId}</td>
                          </tr>
                        </c:forEach>
                      </tbody>
                    </table>
                  </div>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </div>

          <%-- Lịch tất cả các phòng trong ngày đang chọn (timeline dùng chung với form thêm suất chiếu) --%>
          <div class="rs-card room-schedule" id="room-schedule" data-date="${scheduleDate}"
               data-url="${ctx}/admin/room-showtimes" data-room="<c:out value='${room.roomName}'/>">
            <div class="room-schedule-head">
              <h2>Lịch các phòng <span id="room-schedule-date"></span></h2>
              <ul class="room-schedule-legend">
                <li><i class="tl-swatch tl-busy"></i>Đã có suất</li>
                <li><i class="tl-swatch tl-free"></i>Trống</li>
                <li><i class="tl-swatch tl-past-show"></i>Suất đã qua</li>
                <li><i class="tl-swatch tl-past"></i>Giờ đã qua</li>
              </ul>
            </div>
            <p class="rs-muted" id="room-schedule-status">Đang tải lịch phòng…</p>
            <div class="room-schedule-scroll"><div class="room-schedule-board" id="room-schedule-board"></div></div>
          </div>
        </div>
      </div>
        </c:otherwise>
      </c:choose>
<c:if test="${not empty room}">
<link rel="stylesheet" href="${ctx}/assets/css/room-schedule.css?v=20261110-3">
<script src="${ctx}/assets/js/room-schedule.js?v=20261110-1"></script>
<script>
  (function () {
    var box = document.getElementById('room-schedule');
    if (!box || !window.RoomSchedule) return;
    var current = box.dataset.room;
    window.RoomSchedule.create({
      board: document.getElementById('room-schedule-board'),
      status: document.getElementById('room-schedule-status'),
      dateLabel: document.getElementById('room-schedule-date'),
      url: box.dataset.url,
      action: 'schedule',
      selectedRooms: function () { return [current]; }
    }).load(box.dataset.date);
  })();
</script>
</c:if>
<%@ include file="../layout/bottom.jspf" %>
