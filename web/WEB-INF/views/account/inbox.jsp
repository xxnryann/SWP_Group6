<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hộp thư"/>
<%@ include file="../_header.jspf" %>
<style>
  .inbox-list { display: flex; flex-direction: column; gap: 12px; margin-top: 16px; }
  .inbox-item { padding: 16px 20px; border: 1px solid #e2e8f0; border-left: 4px solid #1d4ed8; border-radius: 10px; background: #fff; }
  .inbox-item.is-success { border-left-color: #059669; }
  .inbox-item.is-danger { border-left-color: #dc2626; }
  .inbox-item.is-reminder { border-left-color: #f59e0b; }
  .inbox-item.is-voucher { border-left-color: #0891b2; }
  .inbox-tabs { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
  .inbox-title { display: flex; align-items: center; flex-wrap: wrap; gap: 8px; }
  .inbox-head { display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
  .inbox-head h3 { margin: 0; font-size: 16px; }
  .inbox-time { color: #64748b; font-size: 13px; }
  .inbox-item p { margin: 8px 0 0; }
  .inbox-meta { color: #64748b; font-size: 14px; }
</style>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Hộp thư</h2>
    <nav class="inbox-tabs" aria-label="Lọc thông báo">
      <a class="btn btn-small ${empty inboxType ? 'btn-primary' : 'btn-soft'}" href="${ctx}/account/inbox">Tất cả</a>
      <a class="btn btn-small ${inboxType == 'NewMovie' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/account/inbox?type=NewMovie">Phim mới</a>
      <a class="btn btn-small ${inboxType == 'Voucher' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/account/inbox?type=Voucher">Ưu đãi voucher</a>
    </nav>

    <c:choose>
      <c:when test="${empty notifications}">
        <p class="sub">
          <c:choose>
            <c:when test="${inboxType == 'NewMovie'}">Hiện chưa có phim mới.</c:when>
            <c:when test="${inboxType == 'Voucher'}">Hiện chưa có ưu đãi voucher dành cho bạn.</c:when>
            <c:otherwise>Bạn chưa có thông báo nào.</c:otherwise>
          </c:choose>
        </p>
      </c:when>
      <c:otherwise>
        <div class="inbox-list">
          <c:forEach var="n" items="${notifications}">
            <c:choose>
              <c:when test="${n.notif_type == 'ETicket'}">
                <c:set var="itemClass" value="is-success"/>
                <c:set var="itemTitle" value="Đặt vé thành công"/>
              </c:when>
              <c:when test="${n.notif_type == 'TicketCancelled' or n.notif_type == 'ComboCancelled'}">
                <c:set var="itemClass" value="is-danger"/>
                <c:set var="itemTitle" value="${n.subject}"/>
              </c:when>
              <c:when test="${n.notif_type == 'MovieCancelled'}">
                <c:set var="itemClass" value="is-danger"/>
                <c:set var="itemTitle" value="Phim bị hủy, bạn sẽ được hoàn tiền"/>
              </c:when>
              <c:when test="${n.notif_type == 'SeatChanged'}">
                <c:set var="itemClass" value="is-reminder"/>
                <c:set var="itemTitle" value="${n.subject}"/>
              </c:when>
              <c:when test="${n.notif_type == 'ReviewReminder'}">
                <c:set var="itemClass" value="is-success"/>
                <c:set var="itemTitle" value="${n.subject}"/>
              </c:when>
              <c:when test="${n.notif_type == 'ReviewModerated'}">
                <c:set var="itemClass" value=""/>
                <c:set var="itemTitle" value="${n.subject}"/>
              </c:when>
              <c:when test="${n.notif_type == 'NewMovie'}">
                <c:set var="itemClass" value=""/>
                <c:set var="itemTitle" value="${n.title}"/>
              </c:when>
              <c:when test="${n.notif_type == 'Voucher'}">
                <c:set var="itemClass" value="is-voucher"/>
                <c:set var="itemTitle" value="Mã ${n.voucher_code}"/>
              </c:when>
              <c:when test="${n.notif_type == 'ShowtimeReminder' and n.has_started == 1}">
                <c:set var="itemClass" value=""/>
                <c:set var="itemTitle" value="Nhắc lịch xem phim"/>
              </c:when>
              <c:otherwise>
                <c:set var="itemClass" value="is-reminder"/>
                <c:set var="itemTitle" value="Sắp đến giờ chiếu"/>
              </c:otherwise>
            </c:choose>
            <article class="inbox-item ${itemClass}">
              <div class="inbox-head">
                <h3 class="inbox-title">
                  <c:if test="${n.notif_type == 'NewMovie'}"><span class="chip">Phim mới</span></c:if>
                  <c:if test="${n.notif_type == 'Voucher'}"><span class="chip">Ưu đãi</span></c:if>
                  <c:out value="${itemTitle}"/>
                </h3>
                <span class="inbox-time"><c:out value="${n.created_at}"/></span>
              </div>
              <c:choose>
                <c:when test="${n.notif_type == 'Voucher'}">
                  <p><c:out value="${n.body}"/></p>
                  <c:choose>
                    <c:when test="${n.voucher_usable == 1}"><p><a class="btn btn-primary btn-small" href="${ctx}/promotions">Xem khuyến mãi</a></p></c:when>
                    <c:otherwise><p class="inbox-meta">Mã này hiện không áp dụng được.</p></c:otherwise>
                  </c:choose>
                </c:when>
                <c:when test="${n.notif_type == 'NewMovie'}">
                  <p><c:out value="${n.body}"/></p>
                  <c:if test="${n.movie_active == 1}"><p><a class="btn btn-primary btn-small" href="${ctx}/movies/detail?id=${n.movie_id}">Xem phim</a></p></c:if>
                </c:when>
                <c:when test="${empty n.title}"><p><c:out value="${n.body}"/></p></c:when>
                <c:when test="${n.notif_type == 'SeatChanged'}">
                  <p>Phim <strong><c:out value="${n.title}"/></strong>: <c:out value="${n.body}"/></p>
                </c:when>
                <c:when test="${n.notif_type == 'TicketCancelled' or n.notif_type == 'ComboCancelled'}">
                  <p><c:out value="${n.body}"/> Phim: <strong><c:out value="${n.title}"/></strong>.</p>
                </c:when>
                <c:when test="${n.notif_type == 'ETicket'}">
                  <p>Bạn đã đặt vé thành công phim <strong><c:out value="${n.title}"/></strong>.</p>
                </c:when>
                <c:when test="${n.notif_type == 'MovieCancelled'}">
                  <p>Phim <strong><c:out value="${n.title}"/></strong> bạn đã đặt bị hủy. Tiền vé sẽ được hoàn lại cho bạn.</p>
                </c:when>
                <c:when test="${n.notif_type == 'ReviewReminder'}">
                  <p>Bạn vừa xem xong phim <strong><c:out value="${n.title}"/></strong>.</p>
                  <c:choose>
                    <c:when test="${n.can_review == 1}"><p><a class="btn btn-primary btn-small" href="${ctx}/movies/detail?id=${n.movie_id}#reviews">Đánh giá ngay</a></p></c:when>
                    <c:otherwise><p class="inbox-meta">Bạn đã đánh giá phim này hoặc phim không còn nhận đánh giá.</p></c:otherwise>
                  </c:choose>
                </c:when>
                <c:when test="${n.notif_type == 'ReviewModerated'}">
                  <p><c:out value="${n.body}"/></p>
                </c:when>
                <c:otherwise>
                  <c:choose>
                    <c:when test="${n.has_started == 1}"><p>Suất chiếu phim <strong><c:out value="${n.title}"/></strong> đã bắt đầu.</p></c:when>
                    <c:otherwise><p>Phim <strong><c:out value="${n.title}"/></strong> sắp chiếu. Vui lòng đến trước giờ chiếu để soát vé.</p></c:otherwise>
                  </c:choose>
                </c:otherwise>
              </c:choose>
              <c:if test="${not empty n.start_time}">
                <p class="inbox-meta">
                  Suất chiếu: <c:out value="${n.start_time}"/>
                  <c:if test="${not empty n.room_name}"> · <c:out value="${n.room_name}"/></c:if>
                  <c:if test="${not empty n.booking_code}"> · Mã đơn: <c:out value="${n.booking_code}"/></c:if>
                </p>
              </c:if>
            </article>
          </c:forEach>
        </div>
        <c:if test="${notifications.size() >= inboxLimit}"><p class="sub">Đang hiển thị ${inboxLimit} thông báo gần nhất.</p></c:if>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
