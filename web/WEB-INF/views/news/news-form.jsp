﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty news ? 'ÄÄƒng tin má»›i' : 'Sá»­a tin tá»©c'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-form-card { max-width: 860px; }
  .uip-form-card textarea { width: 100%; padding: 11px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                            background: #fff; color: var(--slate-800); font: 15px var(--font); outline: none; resize: vertical; }
  .uip-form-card textarea:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-actions { display: flex; gap: 10px; margin-top: 8px; }
  .uip-preview { margin-top: 10px; }
  .uip-preview img { max-width: 320px; width: 100%; border-radius: 10px; border: 1px solid var(--slate-200); }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="card uip-form-card">
        <h2><c:out value="${pageTitle}"/></h2>
        <p class="sub">BÃ i á»Ÿ tráº¡ng thÃ¡i â€œXuáº¥t báº£n ngayâ€ sáº½ xuáº¥t hiá»‡n ngay trÃªn trang Tin tá»©c cÃ´ng khai.</p>
        <c:if test="${not empty error}"><p class="alert alert-error">${error}</p></c:if>
        <form method="post" action="${ctx}/manager/news">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="id" value="${news.newsId}">

          <div class="field">
            <label for="f-title">TiÃªu Ä‘á» (tá»‘i Ä‘a 200 kÃ½ tá»±)</label>
            <input id="f-title" type="text" name="title" maxlength="200" required
                   placeholder="VD: Khai trÆ°Æ¡ng ráº¡p CineStar"
                   value="<c:out value='${news.title}'/>">
          </div>

          <div class="field">
            <label for="f-content">Ná»™i dung</label>
            <textarea id="f-content" name="content" rows="10" required
                      placeholder="Ná»™i dung bÃ i viáº¿t..."><c:out value="${news.content}"/></textarea>
          </div>

          <div class="field">
            <label for="f-thumb">Link áº£nh thumbnail</label>
            <input id="f-thumb" type="text" name="thumbnailUrl"
                   placeholder="https://... (Ä‘á»ƒ trá»‘ng sáº½ dÃ¹ng áº£nh máº·c Ä‘á»‹nh)"
                   value="<c:out value='${news.thumbnailUrl}'/>">
            <c:if test="${not empty news.thumbnailUrl}">
              <div class="uip-preview"><img src="<c:out value='${news.thumbnailUrl}'/>" alt="áº¢nh thumbnail hiá»‡n táº¡i"></div>
            </c:if>
          </div>

          <div class="field">
            <label for="f-status">Tráº¡ng thÃ¡i</label>
            <select id="f-status" name="status">
              <option value="Published" ${news.status == 'Published' ? 'selected' : ''}>Xuáº¥t báº£n ngay</option>
              <option value="Draft" ${news.status == 'Draft' ? 'selected' : ''}>LÆ°u báº£n nhÃ¡p</option>
              <option value="Hidden" ${news.status == 'Hidden' ? 'selected' : ''}>áº¨n khá»i trang tin</option>
            </select>
          </div>

          <div class="uip-actions">
            <button class="btn btn-cta" type="submit">LÆ°u bÃ i viáº¿t</button>
            <a class="btn btn-outline" href="${ctx}/manager/news">Há»§y</a>
          </div>
        </form>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



