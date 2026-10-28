﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quáº£n lÃ½ tÃ i khoáº£n"/>
<c:set var="parentTitle" value="Quáº£n trá»‹"/>
<c:set var="parentUrl" value="${pageContext.request.contextPath}/admin/users"/>
<%@ include file="_header.jspf" %>
<main class="page"><div class="container">
  <div class="dash-layout">
    <div>
  <section class="panel">
    <h2>Quáº£n lÃ½ tÃ i khoáº£n &amp; phÃ¢n quyá»n</h2>
    <p class="sub">KhÃ³a/má»Ÿ tÃ i khoáº£n vÃ  phÃ¢n quyá»n cho khÃ¡ch hÃ ng, nhÃ¢n viÃªn, quáº£n lÃ½ ráº¡p.</p>

    <form method="get" action="${ctx}/admin/users" class="row" style="margin-bottom:16px">
      <div class="field">
        <label for="q">TÃŒM KIáº¾M</label>
        <input id="q" name="q" type="text" placeholder="TÃªn, email hoáº·c SÄT" value="<c:out value='${q}'/>">
      </div>
      <div class="field">
        <label for="fRole">QUYá»€N</label>
        <select id="fRole" name="role">
          <option value="">Táº¥t cáº£</option>
          <c:forEach var="r" items="CUSTOMER,STAFF,MANAGER,ADMIN">
            <option value="${r}" ${fRole == r ? 'selected' : ''}>${r}</option>
          </c:forEach>
        </select>
      </div>
      <div class="field">
        <label for="fStatus">TRáº NG THÃI</label>
        <select id="fStatus" name="status">
          <option value="">Táº¥t cáº£</option>
          <c:forEach var="st" items="PENDING,ACTIVE,BLOCKED">
            <option value="${st}" ${fStatus == st ? 'selected' : ''}>${st}</option>
          </c:forEach>
        </select>
      </div>
      <div class="field" style="align-self:end"><button class="btn btn-primary" type="submit">Lá»c</button></div>
    </form>

    <c:choose>
      <c:when test="${empty users}"><p class="sub">KhÃ´ng cÃ³ tÃ i khoáº£n phÃ¹ há»£p.</p></c:when>
      <c:otherwise>
        <div class="table-wrap">
          <table class="data">
            <thead><tr><th>Há» tÃªn</th><th>Email</th><th>SÄT</th><th>Quyá»n</th><th>Tráº¡ng thÃ¡i</th><th>Thao tÃ¡c</th></tr></thead>
            <tbody>
            <c:forEach var="u" items="${users}">
              <c:set var="isSelf" value="${u.userId == sessionScope.authUser.userId}"/>
              <tr>
                <td><c:out value="${u.fullName}"/><c:if test="${isSelf}"> <span class="badge">Báº¡n</span></c:if></td>
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
                        <select name="value" aria-label="Quyá»n">
                          <c:forEach var="r" items="CUSTOMER,STAFF,MANAGER,ADMIN">
                            <option value="${r}" ${u.role == r ? 'selected' : ''}>${r}</option>
                          </c:forEach>
                        </select>
                        <button class="btn btn-soft" type="submit">LÆ°u</button>
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
                        ${u.status == 'BLOCKED' ? 'Má»Ÿ khÃ³a' : 'KhÃ³a'}
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



