<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hộp thư"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .inbox-item { display: grid; grid-template-columns: 44px minmax(0, 1fr); gap: 16px; padding: 18px 22px; border-bottom: 1px solid var(--line); }
  .inbox-item:last-child { border-bottom: 0; }
  .inbox-item .stat-icon { margin: 0; }
  .inbox-item h3 { font-size: 15.5px; }
  .inbox-item p { margin-top: 6px; font-size: 14.5px; }
  .inbox-meta { display: flex; flex-wrap: wrap; gap: 6px 14px; margin-top: 8px; color: var(--muted); font-size: 13px; }
</style>
<div class="${appShell ? '' : 'container'}">
  <div class="page-head"><div><h1>Hộp thư</h1><p>Thông báo vé, nhắc lịch chiếu, phim mới và ưu đãi dành cho bạn.</p></div></div>

  <section class="card">
    <div class="card-head">
      <div class="segmented" role="tablist" aria-label="Lọc thông báo">
        <a class="${empty inboxType ? 'active' : ''}" href="${ctx}/account/inbox">Tất cả</a>
        <a class="${inboxType == 'NewMovie' ? 'active' : ''}" href="${ctx}/account/inbox?type=NewMovie">Phim mới</a>
        <a class="${inboxType == 'Voucher' ? 'active' : ''}" href="${ctx}/account/inbox?type=Voucher">Ưu đãi</a>
      </div>
      <c:if test="${not empty notifications}"><span class="muted text-sm">${notifications.size()} thông báo</span></c:if>
    </div>

    <c:choose>
      <c:when test="${empty notifications}">
        <div class="empty"><div class="empty-icon">${ic.inbox}</div>
          <h3>
            <c:choose>
              <c:when test="${inboxType == 'NewMovie'}">Hiện chưa có phim mới</c:when>
              <c:when test="${inboxType == 'Voucher'}">Chưa có ưu đãi voucher dành cho bạn</c:when>
              <c:otherwise>Bạn chưa có thông báo nào</c:otherwise>
            </c:choose>
          </h3>
          <p>Thông báo mới sẽ xuất hiện ở đây.</p>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="n" items="${notifications}">
          <c:choose>
            <c:when test="${n.notif_type == 'ETicket'}"><c:set var="tone" value="success"/><c:set var="icon" value="${ic.ticket}"/><c:set var="itemTitle" value="Đặt vé thành công"/></c:when>
            <c:when test="${n.notif_type == 'TicketCancelled' or n.notif_type == 'ComboCancelled'}"><c:set var="tone" value="danger"/><c:set var="icon" value="${ic.x}"/><c:set var="itemTitle" value="${n.subject}"/></c:when>
            <c:when test="${n.notif_type == 'MovieCancelled'}"><c:set var="tone" value="danger"/><c:set var="icon" value="${ic.alert}"/><c:set var="itemTitle" value="Suất chiếu bị hủy, bạn được hoàn MyPoint"/></c:when>
            <c:when test="${n.notif_type == 'SeatChanged'}"><c:set var="tone" value="accent"/><c:set var="icon" value="${ic.swap}"/><c:set var="itemTitle" value="${n.subject}"/></c:when>
            <c:when test="${n.notif_type == 'ReviewReminder'}"><c:set var="tone" value="success"/><c:set var="icon" value="${ic.star}"/><c:set var="itemTitle" value="${n.subject}"/></c:when>
            <c:when test="${n.notif_type == 'ReviewModerated'}"><c:set var="tone" value=""/><c:set var="icon" value="${ic.message}"/><c:set var="itemTitle" value="${n.subject}"/></c:when>
            <c:when test="${n.notif_type == 'NewMovie'}"><c:set var="tone" value=""/><c:set var="icon" value="${ic.film}"/><c:set var="itemTitle" value="${n.title}"/></c:when>
            <c:when test="${n.notif_type == 'Voucher'}"><c:set var="tone" value="accent"/><c:set var="icon" value="${ic.tag}"/><c:set var="itemTitle" value="Mã ${n.voucher_code}"/></c:when>
            <c:when test="${n.notif_type == 'ShowtimeReminder' and n.has_started == 1}"><c:set var="tone" value=""/><c:set var="icon" value="${ic.clock}"/><c:set var="itemTitle" value="Nhắc lịch xem phim"/></c:when>
            <c:otherwise><c:set var="tone" value="accent"/><c:set var="icon" value="${ic.clock}"/><c:set var="itemTitle" value="Sắp đến giờ chiếu"/></c:otherwise>
          </c:choose>
          <article class="inbox-item">
            <span class="stat-icon ${tone}">${icon}</span>
            <div>
              <div class="cluster between" style="--gap:8px">
                <h3>
                  <c:if test="${n.notif_type == 'NewMovie'}"><span class="badge badge-brand">Phim mới</span> </c:if>
                  <c:if test="${n.notif_type == 'Voucher'}"><span class="badge badge-accent">Ưu đãi</span> </c:if>
                  <c:out value="${itemTitle}"/>
                </h3>
                <span class="muted text-xs nowrap"><c:out value="${n.created_at}"/></span>
              </div>
              <c:choose>
                <c:when test="${n.notif_type == 'Voucher'}">
                  <p><c:out value="${n.body}"/></p>
                  <c:choose>
                    <c:when test="${n.voucher_usable == 1}"><a class="btn btn-sm btn-soft mt-8" href="${ctx}/promotions">Xem khuyến mãi</a></c:when>
                    <c:otherwise><div class="inbox-meta">Mã này hiện không áp dụng được.</div></c:otherwise>
                  </c:choose>
                </c:when>
                <c:when test="${n.notif_type == 'NewMovie'}">
                  <p><c:out value="${n.body}"/></p>
                  <c:if test="${n.movie_active == 1}"><a class="btn btn-sm btn-soft mt-8" href="${ctx}/movies/detail?id=${n.movie_id}">Xem phim</a></c:if>
                </c:when>
                <c:when test="${empty n.title}"><p><c:out value="${n.body}"/></p></c:when>
                <c:when test="${n.notif_type == 'SeatChanged'}"><p>Phim <strong><c:out value="${n.title}"/></strong>: <c:out value="${n.body}"/></p></c:when>
                <c:when test="${n.notif_type == 'TicketCancelled' or n.notif_type == 'ComboCancelled'}"><p><c:out value="${n.body}"/> Phim: <strong><c:out value="${n.title}"/></strong>.</p></c:when>
                <c:when test="${n.notif_type == 'ETicket'}"><p>Bạn đã đặt vé thành công phim <strong><c:out value="${n.title}"/></strong>.</p></c:when>
                <c:when test="${n.notif_type == 'MovieCancelled'}"><p>Phim <strong><c:out value="${n.title}"/></strong> bạn đã đặt bị hủy. <c:out value="${n.body}"/> Xem tại <a href="${ctx}/account/points">Điểm MyPoint</a>.</p></c:when>
                <c:when test="${n.notif_type == 'ReviewReminder'}">
                  <p>Bạn vừa xem xong phim <strong><c:out value="${n.title}"/></strong>.</p>
                  <c:choose>
                    <c:when test="${n.can_review == 1}"><a class="btn btn-sm btn-accent mt-8" href="${ctx}/movies/detail?id=${n.movie_id}#reviews">${ic.star}Đánh giá ngay</a></c:when>
                    <c:otherwise><div class="inbox-meta">Bạn đã đánh giá phim này hoặc phim không còn nhận đánh giá.</div></c:otherwise>
                  </c:choose>
                </c:when>
                <c:when test="${n.notif_type == 'ReviewModerated'}"><p><c:out value="${n.body}"/></p></c:when>
                <c:otherwise>
                  <c:choose>
                    <c:when test="${n.has_started == 1}"><p>Suất chiếu phim <strong><c:out value="${n.title}"/></strong> đã bắt đầu.</p></c:when>
                    <c:otherwise><p>Phim <strong><c:out value="${n.title}"/></strong> sắp chiếu. Vui lòng đến trước giờ chiếu để soát vé.</p></c:otherwise>
                  </c:choose>
                </c:otherwise>
              </c:choose>
              <c:if test="${not empty n.start_time}">
                <div class="inbox-meta">
                  <span>Suất chiếu: <c:out value="${n.start_time}"/></span>
                  <c:if test="${not empty n.room_name}"><span><c:out value="${n.room_name}"/></span></c:if>
                  <c:if test="${not empty n.booking_code}"><span>Mã đơn: <c:out value="${n.booking_code}"/></span></c:if>
                </div>
              </c:if>
            </div>
          </article>
        </c:forEach>
        <c:if test="${notifications.size() >= inboxLimit}"><div class="card-foot" style="justify-content:flex-start"><span class="muted text-xs">Đang hiển thị ${inboxLimit} thông báo gần nhất.</span></div></c:if>
      </c:otherwise>
    </c:choose>
  </section>
</div>
<%@ include file="../layout/bottom.jspf" %>
