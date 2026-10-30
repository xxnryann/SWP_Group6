<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý tài khoản"/>
<c:set var="parentTitle" value="Quản trị"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/admin/users"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="panel">
    <h2>Quản lý tài khoản &amp; phân quyền</h2>

    <form method="get" action="${ctx}/admin/users" class="row" style="margin-bottom:16px">
      <div class="field">
        <label for="q">TÌM KIẾM</label>
        <input id="q" name="q" type="text" placeholder="Tên, email hoặc SĐT" value="<c:out value='${q}'/>">
      </div>
      <div class="field">
        <label for="fRole">QUYỀN</label>
        <select id="fRole" name="role">
          <option value="">Tất cả</option>
          <c:forEach var="r" items="CUSTOMER,STAFF,MANAGER,ADMIN">
            <option value="${r}" ${fRole == r ? 'selected' : ''}>${r}</option>
          </c:forEach>
        </select>
      </div>
      <div class="field">
        <label for="fStatus">TRẠNG THÁI</label>
        <select id="fStatus" name="status">
          <option value="">Tất cả</option>
          <c:forEach var="st" items="PENDING,ACTIVE,BLOCKED">
            <option value="${st}" ${fStatus == st ? 'selected' : ''}>${st}</option>
          </c:forEach>
        </select>
      </div>
      <div class="field" style="align-self:end"><button class="btn btn-primary" type="submit">Lọc</button></div>
    </form>

    <c:choose>
      <c:when test="${empty users}"><p class="sub">Không có tài khoản phù hợp.</p></c:when>
      <c:otherwise>
        <div class="table-wrap">
          <table class="data">
            <thead><tr><th>Họ tên</th><th>Email</th><th>SĐT</th><th>Quyền</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
            <tbody>
            <c:forEach var="u" items="${users}">
              <c:set var="isSelf" value="${u.userId == sessionScope.authUser.userId}"/>
              <tr>
                <td><c:out value="${u.fullName}"/><c:if test="${isSelf}"> <span class="badge">Bạn</span></c:if></td>
                <td><c:out value="${u.email}"/></td>
                <td><c:out value="${u.phone}"/></td>
                <td>
                  <c:choose>
                    <c:when test="${isSelf}"><c:out value="${u.role}"/></c:when>
                    <c:otherwise>
                      <form method="post" action="${ctx}/admin/users" style="display:flex;gap:6px">
                        <input type="hidden" name="_csrf" value="${csrf}">
                        <input type="hidden" name="action" value="role">
                        <input type="hidden" name="userId" value="${u.userId}">
                        <input type="hidden" name="q" value="<c:out value='${q}'/>">
                        <input type="hidden" name="fRole" value="${fRole}">
                        <input type="hidden" name="fStatus" value="${fStatus}">
                        <select name="value" aria-label="Quyền">
                          <c:forEach var="r" items="CUSTOMER,STAFF,MANAGER,ADMIN">
                            <option value="${r}" ${u.role == r ? 'selected' : ''}>${r}</option>
                          </c:forEach>
                        </select>
                        <button class="btn btn-soft" type="submit">Lưu</button>
                      </form>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td><c:out value="${u.status}"/></td>
                <td>
                  <c:if test="${not isSelf and u.status != 'PENDING'}">
                    <form method="post" action="${ctx}/admin/users">
                      <input type="hidden" name="_csrf" value="${csrf}">
                      <input type="hidden" name="action" value="status">
                      <input type="hidden" name="userId" value="${u.userId}">
                      <input type="hidden" name="q" value="<c:out value='${q}'/>">
                      <input type="hidden" name="fRole" value="${fRole}">
                      <input type="hidden" name="fStatus" value="${fStatus}">
                      <input type="hidden" name="value" value="${u.status == 'BLOCKED' ? 'ACTIVE' : 'BLOCKED'}">
                      <button class="btn ${u.status == 'BLOCKED' ? 'btn-primary' : 'btn-outline'}" type="submit">
                        ${u.status == 'BLOCKED' ? 'Mở khóa' : 'Khóa'}
                      </button>
                    </form>
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
    </div>
  </div>
</div></main>
<%@ include file="_footer.jspf" %>



