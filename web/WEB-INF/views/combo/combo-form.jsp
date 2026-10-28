﻿﻿<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="${empty combo ? 'ThÃªm combo má»›i' : 'Sá»­a combo'}"/>
<%@ include file="../_header.jspf" %>
<style>
  .uip-form-card { max-width: 760px; }
  .uip-form-card textarea { width: 100%; padding: 11px 14px; border: 1px solid var(--slate-300); border-radius: var(--radius);
                            background: #fff; color: var(--slate-800); font: 15px var(--font); outline: none; resize: vertical; }
  .uip-form-card textarea:focus { border-color: var(--brand); box-shadow: 0 0 0 3px rgba(29,78,216,.18); }
  .uip-actions { display: flex; gap: 10px; margin-top: 8px; }
</style>
<main>
  <section class="page">
    <div class="container">
      <div class="dash-layout">
        <div>
      <div class="card uip-form-card">
        <h2><c:out value="${pageTitle}"/></h2>
        <p class="sub">Combo á»Ÿ tráº¡ng thÃ¡i â€œÄang bÃ¡nâ€ sáº½ xuáº¥t hiá»‡n á»Ÿ mÃ n hÃ¬nh bÃ¡n vÃ© táº¡i quáº§y vÃ  Ä‘áº·t vÃ© online.</p>
        <c:if test="${not empty error}"><p class="alert alert-error">${error}</p></c:if>
        <form method="post" action="${ctx}/staff/combo">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="id" value="${combo.comboId}">

          <div class="field">
            <label for="f-name">TÃªn combo (tá»‘i Ä‘a 100 kÃ½ tá»±)</label>
            <input id="f-name" type="text" name="comboName" maxlength="100" required
                   placeholder="VD: Combo Solo (1 báº¯p + 1 nÆ°á»›c)"
                   value="<c:out value='${combo.comboName}'/>">
          </div>

          <div class="field">
            <label for="f-desc">MÃ´ táº£</label>
            <textarea id="f-desc" name="description" rows="4"
                      placeholder="ThÃ nh pháº§n cá»§a combo..."><c:out value="${combo.description}"/></textarea>
          </div>

          <div class="row">
            <div class="field">
              <label for="f-price">GiÃ¡ (VNÄ)</label>
              <input id="f-price" type="number" name="price" min="0" step="1000" required
                     value="${combo.price}">
            </div>
            <div class="field">
              <label for="f-stock">Tá»“n kho</label>
              <input id="f-stock" type="number" name="stock" min="0" required
                     value="${combo.stock}">
            </div>
          </div>

          <div class="field">
            <label for="f-status">Tráº¡ng thÃ¡i</label>
            <select id="f-status" name="status">
              <option value="Active" ${combo.status == 'Active' ? 'selected' : ''}>Äang bÃ¡n</option>
              <option value="Hidden" ${combo.status == 'Hidden' ? 'selected' : ''}>áº¨n khá»i menu</option>
            </select>
          </div>

          <div class="uip-actions">
            <button class="btn btn-cta" type="submit">LÆ°u combo</button>
            <a class="btn btn-outline" href="${ctx}/staff/combo">Há»§y</a>
          </div>
        </form>
      </div>
        </div>
      </div>
    </div>
  </section>
</main>
<%@ include file="../_footer.jspf" %>



