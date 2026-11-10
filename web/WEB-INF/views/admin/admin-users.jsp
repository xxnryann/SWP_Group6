<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Người dùng"/>
<%@ include file="../layout/top.jspf" %>
<style>
  .pw-reset { position: relative; display: inline-block; }
  .pw-reset > summary { list-style: none; }
  .pw-reset > summary::-webkit-details-marker { display: none; }
  .pw-pop { position: absolute; right: 0; top: calc(100% + 8px); z-index: 5; width: 280px; padding: 16px; text-align: left;
            background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-lg); box-shadow: var(--sh-lg); }
  .pw-pop .form { gap: 10px; }
  .pw-pop p { color: var(--muted); font-size: 12.5px; white-space: normal; }
</style>
<div class="page-head">
  <div>
    <h1>Quản lý người dùng</h1>
    <p>Tìm tài khoản, khóa hoặc mở khóa, đặt lại mật khẩu khi người dùng quên.</p>
  </div>
</div>

<section class="card">
  <form method="get" action="${ctx}/admin/users" class="toolbar" role="search">
    <div class="field grow">
      <label for="q">Tìm kiếm</label>
      <div class="input-group">${ic.search}<input id="q" name="q" type="search" placeholder="Tên, email hoặc số điện thoại" value="<c:out value='${q}'/>"></div>
    </div>
    <div class="field">
      <label for="fRole">Vai trò</label>
      <select id="fRole" name="role">
        <option value="">Tất cả vai trò</option>
        <c:forEach var="r" items="CUSTOMER,STAFF,MANAGER,ADMIN">
          <option value="${r}" ${fRole == r ? 'selected' : ''}>${r}</option>
        </c:forEach>
      </select>
    </div>
    <div class="field">
      <label for="fStatus">Trạng thái</label>
      <select id="fStatus" name="status">
        <option value="">Tất cả trạng thái</option>
        <c:forEach var="st" items="PENDING,ACTIVE,BLOCKED">
          <option value="${st}" ${fStatus == st ? 'selected' : ''}>${st}</option>
        </c:forEach>
      </select>
    </div>
    <button class="btn btn-primary" type="submit">${ic.filter}Lọc</button>
    <c:if test="${not empty q or not empty fRole or not empty fStatus}">
      <a class="btn btn-ghost" href="${ctx}/admin/users">Xóa lọc</a>
    </c:if>
  </form>

  <c:choose>
    <c:when test="${empty users}">
      <div class="empty"><div class="empty-icon">${ic.users}</div><h3>Không có tài khoản phù hợp</h3><p>Thử đổi từ khóa hoặc bỏ bớt bộ lọc.</p></div>
    </c:when>
    <c:otherwise>
      <div class="table-wrap">
        <table class="table">
          <thead><tr><th>Người dùng</th><th>Số điện thoại</th><th>Vai trò</th><th>Trạng thái</th><th class="actions">Thao tác</th></tr></thead>
          <tbody>
          <c:forEach var="u" items="${users}">
            <c:set var="isSelf" value="${u.userId == sessionScope.authUser.userId}"/>
            <tr>
              <td>
                <div class="person">
                  <span class="avatar">${empty u.fullName ? '?' : fn:toUpperCase(fn:substring(fn:trim(u.fullName), 0, 1))}</span>
                  <div>
                    <span class="cell-main"><c:out value="${u.fullName}"/></span><c:if test="${isSelf}"> <span class="badge badge-brand">Bạn</span></c:if>
                    <span class="cell-sub"><c:out value="${u.email}"/></span>
                  </div>
                </div>
              </td>
              <td class="nowrap"><c:out value="${u.phone}"/></td>
              <td>
                <c:choose>
                  <c:when test="${u.role == 'ADMIN'}"><span class="badge badge-dark"><c:out value="${u.role}"/></span></c:when>
                  <c:when test="${u.role == 'CUSTOMER'}"><span class="badge"><c:out value="${u.role}"/></span></c:when>
                  <c:otherwise><span class="badge badge-brand"><c:out value="${u.role}"/></span></c:otherwise>
                </c:choose>
              </td>
              <td>
                <c:choose>
                  <c:when test="${u.status == 'ACTIVE'}"><span class="badge badge-success badge-dot">Hoạt động</span></c:when>
                  <c:when test="${u.status == 'BLOCKED'}"><span class="badge badge-danger badge-dot">Bị khóa</span></c:when>
                  <c:otherwise><span class="badge badge-warning badge-dot">Chờ xác thực</span></c:otherwise>
                </c:choose>
              </td>
              <td class="actions">
                <c:if test="${not isSelf}">
                  <c:if test="${u.status != 'PENDING'}">
                    <form class="inline-form" method="post" action="${ctx}/admin/users"
                          data-confirm="${u.status == 'BLOCKED' ? 'Mở khóa' : 'Khóa'} tài khoản <c:out value='${u.email}'/>?">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="status">
                      <input type="hidden" name="userId" value="${u.userId}">
                      <input type="hidden" name="q" value="<c:out value='${q}'/>">
                      <input type="hidden" name="fRole" value="${fRole}">
                      <input type="hidden" name="fStatus" value="${fStatus}">
                      <input type="hidden" name="value" value="${u.status == 'BLOCKED' ? 'ACTIVE' : 'BLOCKED'}">
                      <c:choose>
                        <c:when test="${u.status == 'BLOCKED'}"><button class="btn btn-sm btn-soft" type="submit">${ic.unlock}Mở khóa</button></c:when>
                        <c:otherwise><button class="btn btn-sm btn-danger" type="submit">${ic.lock}Khóa</button></c:otherwise>
                      </c:choose>
                    </form>
                  </c:if>
                  <details class="pw-reset">
                    <summary class="btn btn-sm">${ic.key}Đổi mật khẩu</summary>
                    <div class="pw-pop">
                      <form class="form" method="post" action="${ctx}/admin/users">
                        <input type="hidden" name="_csrf" value="${csrf}">
                        <input type="hidden" name="action" value="password">
                        <input type="hidden" name="userId" value="${u.userId}">
                        <input type="hidden" name="q" value="<c:out value='${q}'/>">
                        <input type="hidden" name="fRole" value="${fRole}">
                        <input type="hidden" name="fStatus" value="${fStatus}">
                        <strong class="text-ink">Đặt mật khẩu mới</strong>
                        <p>Cho <c:out value="${u.email}"/>. Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.</p>
                        <div class="field">
                          <input name="newPassword" type="password" autocomplete="new-password" required minlength="8" maxlength="72"
                                 pattern="(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,72}" title="Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số."
                                 placeholder="Mật khẩu mới" aria-label="Mật khẩu mới cho ${u.email}">
                        </div>
                        <div class="field">
                          <input name="confirmPassword" type="password" autocomplete="new-password" required maxlength="72"
                                 placeholder="Nhập lại mật khẩu" aria-label="Nhập lại mật khẩu cho ${u.email}">
                        </div>
                        <button class="btn btn-primary btn-sm btn-block" type="submit">Lưu mật khẩu</button>
                      </form>
                    </div>
                  </details>
                </c:if>
              </td>
            </tr>
          </c:forEach>
          </tbody>
        </table>
      </div>
    </c:otherwise>
  </c:choose>
</section>
<script>
  /* Chỉ mở một ô đổi mật khẩu một lúc; bấm ra ngoài thì đóng. */
  document.querySelectorAll('.pw-reset').forEach(function (d) {
    d.addEventListener('toggle', function () {
      if (d.open) document.querySelectorAll('.pw-reset[open]').forEach(function (o) { if (o !== d) o.open = false; });
    });
  });
  document.addEventListener('click', function (e) {
    document.querySelectorAll('.pw-reset[open]').forEach(function (d) { if (!d.contains(e.target)) d.open = false; });
  });
</script>
<%@ include file="../layout/bottom.jspf" %>
