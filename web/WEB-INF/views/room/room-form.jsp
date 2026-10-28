﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${room.roomId > 0 ? 'Sá»­a phÃ²ng chiáº¿u' : 'ThÃªm phÃ²ng chiáº¿u'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .rm-form-card { max-width: 720px; }
  .rm-actions { display: flex; gap: 10px; margin-top: 8px; }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="card rm-form-card">
        <h2><c:out value="${pageTitle}"/></h2>
        <p class="sub">
          <c:choose>
            <c:when test="${room.roomId > 0}">Cáº­p nháº­t thÃ´ng tin phÃ²ng. Layout gháº¿ Ä‘Æ°á»£c thiáº¿t láº­p á»Ÿ mÃ n hÃ¬nh â€œLayout &amp; gháº¿â€.</c:when>
            <c:otherwise>Sau khi táº¡o phÃ²ng, báº¡n sáº½ Ä‘Æ°á»£c chuyá»ƒn sang mÃ n hÃ¬nh thiáº¿t láº­p layout gháº¿.</c:otherwise>
          </c:choose>
        </p>
        <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

        <form method="post" action="${ctx}/admin/rooms">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="save">
          <c:if test="${room.roomId > 0}"><input type="hidden" name="id" value="${room.roomId}"></c:if>

          <div class="field">
            <label for="f-cinema">Ráº¡p</label>
            <select id="f-cinema" name="cinemaId" required>
              <c:forEach var="cn" items="${cinemas}">
                <option value="${cn.cinemaId}" ${cn.cinemaId == room.cinemaId ? 'selected' : ''}><c:out value="${cn.cinemaName}"/></option>
              </c:forEach>
            </select>
          </div>

          <div class="field">
            <label for="f-name">TÃªn phÃ²ng (tá»‘i Ä‘a 50 kÃ½ tá»±)</label>
            <input id="f-name" type="text" name="roomName" maxlength="50" required
                   placeholder="VD: PhÃ²ng 3" value="<c:out value='${room.roomName}'/>">
          </div>

          <div class="row">
            <div class="field">
              <label for="f-type">Loáº¡i phÃ²ng</label>
              <select id="f-type" name="roomType" required>
                <c:forEach var="t" items="${roomTypes}">
                  <option value="${t}" ${t == room.roomType ? 'selected' : ''}>${t}</option>
                </c:forEach>
              </select>
            </div>
            <div class="field">
              <label for="f-cap">Sá»©c chá»©a (sá»‘ gháº¿)</label>
              <input id="f-cap" type="number" name="capacity" min="1" max="500" required
                     value="${room.capacity > 0 ? room.capacity : ''}" ${capacityLocked ? 'readonly' : ''}>
              <c:if test="${capacityLocked}">
                <div class="hint">PhÃ²ng Ä‘Ã£ cÃ³ layout nÃªn sá»©c chá»©a luÃ´n báº±ng sá»‘ gháº¿ thá»±c táº¿ (${room.seatCount}). Thay Ä‘á»•i á»Ÿ mÃ n hÃ¬nh Layout &amp; gháº¿.</div>
              </c:if>
            </div>
          </div>

          <c:if test="${room.roomId > 0}">
            <div class="field">
              <label for="f-status">Tráº¡ng thÃ¡i</label>
              <select id="f-status" name="status">
                <option value="Active" ${room.status == 'Active' ? 'selected' : ''}>Äang hoáº¡t Ä‘á»™ng</option>
                <option value="Closed" ${room.status == 'Closed' ? 'selected' : ''}>ÄÃ£ Ä‘Ã³ng</option>
              </select>
              <div class="hint">Chá»‰ Ä‘Ã³ng Ä‘Æ°á»£c phÃ²ng khi khÃ´ng cÃ²n suáº¥t chiáº¿u sáº¯p tá»›i.</div>
            </div>
          </c:if>

          <div class="rm-actions">
            <button class="btn btn-cta" type="submit">${room.roomId > 0 ? 'LÆ°u thay Ä‘á»•i' : 'Táº¡o phÃ²ng'}</button>
            <a class="btn btn-outline" href="${ctx}/admin/rooms">Há»§y</a>
          </div>
        </form>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



