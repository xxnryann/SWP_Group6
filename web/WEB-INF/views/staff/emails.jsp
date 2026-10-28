<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Hộp thư đi"/>
<%@ include file="../_header.jspf" %>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Hộp thư đi</h2>
    <p class="sub">Email vé điện tử, nhắc lịch chiếu và thông báo hủy suất. Hệ thống tự gửi mỗi phút; nếu chưa cấu hình <code>mail.host</code> thư chỉ được ghi vào log (chế độ thử nghiệm).</p>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <div class="admin-kpis">
      <div class="admin-kpi"><span>Đang chờ</span><strong><c:out value="${counts.pending}"/></strong></div>
      <div class="admin-kpi"><span>Đã gửi</span><strong><c:out value="${counts.sent}"/></strong></div>
      <div class="admin-kpi"><span>Gửi lỗi</span><strong><c:out value="${counts.failed}"/></strong></div>
    </div>

    <div class="outbox-actions">
      <form method="get" action="${ctx}/staff/emails">
        <select name="status" aria-label="Lọc trạng thái" onchange="this.form.submit()">
          <option value="">Tất cả</option>
          <option value="Pending" ${status == 'Pending' ? 'selected' : ''}>Đang chờ</option>
          <option value="Sent" ${status == 'Sent' ? 'selected' : ''}>Đã gửi</option>
          <option value="Failed" ${status == 'Failed' ? 'selected' : ''}>Gửi lỗi</option>
        </select>
      </form>
      <form method="post" action="${ctx}/staff/emails">
        <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="dispatch">
        <button class="btn btn-primary" type="submit">Gửi ngay thư đang chờ</button>
      </form>
      <form method="post" action="${ctx}/staff/emails">
        <input type="hidden" name="_csrf" value="${csrf}"><input type="hidden" name="action" value="retry">
        <button class="btn btn-outline" type="submit">Gửi lại thư lỗi</button>
      </form>
    </div>

    <c:choose>
      <c:when test="${empty emails}"><p class="sub">Chưa có email nào.</p></c:when>
      <c:otherwise>
        <div class="table-wrap"><table class="data">
          <thead><tr><th>#</th><th>Loại</th><th>Người nhận</th><th>Tiêu đề</th><th>Trạng thái</th><th>Tạo lúc</th><th>Gửi lúc</th></tr></thead>
          <tbody>
          <c:forEach var="e" items="${emails}">
            <tr>
              <td><c:out value="${e.notif_id}"/></td>
              <td><c:out value="${e.notif_type}"/></td>
              <td><c:out value="${e.email}"/></td>
              <td><c:out value="${e.subject}"/></td>
              <td>
                <c:choose>
                  <c:when test="${e.status == 'Sent'}"><span class="chip chip-success">Đã gửi</span></c:when>
                  <c:when test="${e.status == 'Failed'}"><span class="chip chip-danger">Lỗi</span></c:when>
                  <c:otherwise><span class="chip">Đang chờ</span></c:otherwise>
                </c:choose>
              </td>
              <td><c:out value="${e.created_at}"/></td>
              <td><c:out value="${e.sent_at}"/></td>
            </tr>
          </c:forEach>
          </tbody>
        </table></div>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="../_footer.jspf" %>
