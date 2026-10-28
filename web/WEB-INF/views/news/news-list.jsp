﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quáº£n lÃ½ tin tá»©c"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-head { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; margin-bottom: 18px; }
  .uip-head h1 { margin: 0; }
  .uip-head p { color: var(--slate-500); margin: 4px 0 0; font-size: 14px; }
  .uip-filter { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-bottom: 18px; }
  .uip-filter .uip-search { margin-left: auto; display: flex; gap: 8px; }
  .uip-filter input[type=search] { padding: 9px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                                   font: 14px var(--font); min-width: 240px; outline: none; }
  .uip-filter input[type=search]:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-thumb { width: 56px; height: 40px; object-fit: cover; border-radius: 6px; vertical-align: middle; }
  .uip-thumb-ph { width: 56px; height: 40px; border-radius: 6px; display: inline-grid; place-items: center;
                   background: linear-gradient(135deg, var(--brand), var(--navy)); vertical-align: middle; font-size: 18px; }
  .uip-title { font-weight: 600; color: var(--navy); }
  .uip-badge { display: inline-block; padding: 3px 10px; border-radius: 99px; font-size: 12px; font-weight: 700; }
  .uip-badge-pub { background: #d1fae5; color: var(--success); }
  .uip-badge-draft { background: #fef3c7; color: #b45309; }
  .uip-badge-hidden { background: var(--slate-200); color: var(--slate-600); }
  .uip-actions { white-space: nowrap; }
  .uip-actions form { display: inline; }
  .uip-danger { color: var(--danger); }
  .uip-empty { text-align: center; padding: 44px 20px; color: var(--slate-500); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="uip-head">
        <div>
          <h1>Quáº£n lÃ½ tin tá»©c</h1>
          <p>ÄÄƒng, sá»­a vÃ  áº©n cÃ¡c bÃ i tin tá»©c hiá»ƒn thá»‹ á»Ÿ trang cÃ´ng khai.</p>
        </div>
        <a class="btn btn-cta" href="${ctx}/manager/news?action=add">+ ÄÄƒng tin má»›i</a>
      </div>

      <form method="get" action="${ctx}/manager/news" class="uip-filter">
        <a class="btn ${empty statusFilter ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news">Táº¥t cáº£</a>
        <a class="btn ${statusFilter == 'Published' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Published">ÄÃ£ xuáº¥t báº£n</a>
        <a class="btn ${statusFilter == 'Draft' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Draft">Báº£n nhÃ¡p</a>
        <a class="btn ${statusFilter == 'Hidden' ? 'btn-primary' : 'btn-soft'}" href="${ctx}/manager/news?status=Hidden">ÄÃ£ áº©n</a>
        <span class="uip-search">
          <input type="search" name="q" placeholder="TÃ¬m theo tiÃªu Ä‘á»..." value="<c:out value='${keyword}'/>">
          <c:if test="${not empty statusFilter}"><input type="hidden" name="status" value="${statusFilter}"></c:if>
          <button class="btn btn-outline" type="submit">TÃ¬m</button>
        </span>
      </form>

      <div class="table-wrap">
        <table class="data">
          <thead>
            <tr><th>áº¢nh</th><th>TiÃªu Ä‘á»</th><th>TÃ¡c giáº£</th><th>NgÃ y Ä‘Äƒng</th><th>Tráº¡ng thÃ¡i</th><th style="text-align:right">Thao tÃ¡c</th></tr>
          </thead>
          <tbody>
            <c:forEach var="n" items="${newsList}">
              <tr>
                <td>
                  <c:choose>
                    <c:when test="${not empty n.thumbnailUrl}"><img class="uip-thumb" src="<c:out value='${n.thumbnailUrl}'/>" alt=""></c:when>
                    <c:otherwise><span class="uip-thumb-ph">ðŸŽ¬</span></c:otherwise>
                  </c:choose>
                </td>
                <td><span class="uip-title"><c:out value="${n.title}"/></span></td>
                <td><c:out value="${n.authorName}"/></td>
                <td>${n.createdAtLabel}</td>
                <td>
                  <c:choose>
                    <c:when test="${n.status == 'Published'}"><span class="uip-badge uip-badge-pub">ÄÃ£ xuáº¥t báº£n</span></c:when>
                    <c:when test="${n.status == 'Draft'}"><span class="uip-badge uip-badge-draft">Báº£n nhÃ¡p</span></c:when>
                    <c:otherwise><span class="uip-badge uip-badge-hidden">ÄÃ£ áº©n</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="uip-actions" style="text-align:right">
                  <a href="${ctx}/manager/news?action=view&id=${n.newsId}">Xem</a> Â·
                  <a href="${ctx}/manager/news?action=edit&id=${n.newsId}">Sá»­a</a> Â·
                  <form method="post" action="${ctx}/manager/news"
                        onsubmit="return confirm('XÃ³a tin nÃ y?')">
                    <input type="hidden" name="_csrf" value="${csrf}">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="${n.newsId}">
                    <button class="btn-link uip-danger" type="submit">XÃ³a</button>
                  </form>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty newsList}">
              <tr><td colspan="6" class="uip-empty">KhÃ´ng cÃ³ tin tá»©c nÃ o. Báº¥m â€œ+ ÄÄƒng tin má»›iâ€ Ä‘á»ƒ táº¡o bÃ i Ä‘áº§u tiÃªn.</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



