<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Quản lý hệ thống"/>
<%@ include file="../layout/top.jspf" %>
<div class="page-head">
  <div>
    <h1>Quản lý hệ thống</h1>
    <p>Cấu hình tham số, sao lưu cơ sở dữ liệu và tra cứu nhật ký thao tác của quản trị viên, quản lý và nhân viên.</p>
  </div>
</div>

<nav class="tabs" aria-label="Quản lý hệ thống">
  <a class="${tab == 'config' ? 'active' : ''}" href="${ctx}/admin/system?tab=config">Cấu hình</a>
  <a class="${tab == 'backup' ? 'active' : ''}" href="${ctx}/admin/system?tab=backup">Sao lưu dữ liệu</a>
  <a class="${tab == 'logs' ? 'active' : ''}" href="${ctx}/admin/system?tab=logs">Nhật ký hệ thống</a>
</nav>

<c:if test="${not empty error}"><div class="alert alert-error mb-24" role="alert">${ic.alert}<span><c:out value="${error}"/></span></div></c:if>

<c:choose>
  <c:when test="${tab == 'config'}">
    <section class="card">
      <div class="card-head"><div><h2>Tham số hệ thống</h2><p>Áp dụng ngay cho các thao tác mới (hủy vé, soát vé, giữ ghế, email nhắc lịch). Mọi lần lưu đều được ghi nhật ký.</p></div></div>
      <c:choose>
        <c:when test="${empty configs}">
          <div class="empty"><div class="empty-icon">${ic.list}</div><h3>Chưa có tham số nào</h3><p>Bảng SystemConfig đang trống.</p></div>
        </c:when>
        <c:otherwise>
          <form method="post" action="${ctx}/admin/system" data-confirm="Lưu cấu hình hệ thống?" data-loading>
            <input type="hidden" name="_csrf" value="${csrf}">
            <input type="hidden" name="action" value="saveConfig">
            <div class="table-wrap">
              <table class="table">
                <thead><tr><th>Tham số</th><th>Mô tả</th><th style="width:180px">Giá trị</th><th class="nowrap">Khoảng hợp lệ</th></tr></thead>
                <tbody>
                <c:forEach var="cf" items="${configs}">
                  <tr>
                    <td><label for="cfg-${cf.config_key}"><code class="text-sm"><c:out value="${cf.config_key}"/></code></label></td>
                    <td class="text-sm"><c:out value="${cf.description}"/></td>
                    <td><input id="cfg-${cf.config_key}" name="<c:out value='${cf.config_key}'/>" type="number" required step="1" min="${cf.min}" max="${cf.max}" value="<c:out value='${cf.config_value}'/>" style="width:120px"></td>
                    <td class="muted text-sm nowrap">${cf.min} – ${cf.max}</td>
                  </tr>
                </c:forEach>
                </tbody>
              </table>
            </div>
            <div class="card-foot"><button class="btn btn-primary" type="submit">${ic.check}Lưu cấu hình</button></div>
          </form>
        </c:otherwise>
      </c:choose>
    </section>
  </c:when>
  <c:when test="${tab == 'backup'}">
    <section class="card card-pad mb-24">
      <div class="cluster between">
        <div class="cluster" style="--gap:16px">
          <span class="stat-icon" style="margin:0">${ic.database}</span>
          <div>
            <h2 style="font-size:var(--fs-h4)">Sao lưu toàn bộ CSDL</h2>
            <p class="muted text-sm mt-4">File .bak được lưu trong thư mục sao lưu của SQL Server. Người dùng vẫn thao tác bình thường trong lúc sao lưu.</p>
          </div>
        </div>
        <form method="post" action="${ctx}/admin/system" data-confirm="Sao lưu CSDL ngay bây giờ?" data-loading>
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="backup">
          <button class="btn btn-primary" type="submit">${ic.download}Sao lưu ngay</button>
        </form>
      </div>
    </section>

    <section class="card">
      <div class="card-head"><div><h2>Các lần sao lưu gần đây</h2><p>20 bản mới nhất</p></div></div>
      <c:choose>
        <c:when test="${empty backups}">
          <div class="empty"><div class="empty-icon">${ic.database}</div><h3>Chưa có bản sao lưu nào</h3><p>Bấm "Sao lưu ngay" để tạo bản đầu tiên.</p></div>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="table">
              <thead><tr><th>Thời điểm</th><th>File</th><th class="num">Dung lượng</th><th>Tài khoản SQL</th></tr></thead>
              <tbody>
              <c:forEach var="b" items="${backups}">
                <tr>
                  <td class="nowrap"><c:out value="${b.finished_at}"/></td>
                  <td><code class="text-sm" style="word-break:break-all"><c:out value="${b.file_path}"/></code></td>
                  <td class="num"><c:out value="${b.size_mb}"/> MB</td>
                  <td><c:out value="${b.sql_user}"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </section>
  </c:when>

  <c:otherwise>
    <section class="card">
      <form method="get" action="${ctx}/admin/system" class="toolbar" role="search">
        <input type="hidden" name="tab" value="logs">
        <div class="field grow">
          <label for="q">Từ khóa</label>
          <div class="input-group">${ic.search}<input id="q" name="q" type="search" maxlength="100" placeholder="Hành động, chi tiết, người thực hiện" value="<c:out value='${q}'/>"></div>
        </div>
        <div class="field"><label for="from">Từ ngày</label><input id="from" name="from" type="date" value="<c:out value='${from}'/>"></div>
        <div class="field"><label for="to">Đến ngày</label><input id="to" name="to" type="date" value="<c:out value='${to}'/>"></div>
        <button class="btn btn-primary" type="submit">${ic.filter}Lọc</button>
      </form>
      <c:choose>
        <c:when test="${empty logs}">
          <div class="empty"><div class="empty-icon">${ic.list}</div><h3>Không có nhật ký phù hợp</h3><p>Thử đổi từ khóa hoặc khoảng ngày.</p></div>
        </c:when>
        <c:otherwise>
          <div class="table-wrap">
            <table class="table">
              <thead><tr><th>Thời điểm</th><th>Người thực hiện</th><th>Hành động</th><th>Chi tiết</th></tr></thead>
              <tbody>
              <c:forEach var="l" items="${logs}">
                <tr>
                  <td class="nowrap muted text-sm"><c:out value="${l.created_at}"/></td>
                  <td>
                    <c:choose>
                      <c:when test="${empty l.email}"><span class="muted">Không xác định</span></c:when>
                      <c:otherwise><span class="cell-main"><c:out value="${empty l.full_name ? l.email : l.full_name}"/></span><span class="cell-sub"><c:out value="${l.email}"/></span></c:otherwise>
                    </c:choose>
                  </td>
                  <td><span class="badge ${fn:contains(l.action, 'LOGIN') ? '' : 'badge-brand'}"><c:out value="${l.action}"/></span></td>
                  <td class="text-sm" style="max-width:480px"><c:out value="${l.detail}"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table>
          </div>
          <div class="card-foot" style="justify-content:flex-start"><span class="muted text-xs">Hiển thị tối đa ${logLimit} dòng mới nhất. Nhật ký chỉ để xem, không thể sửa hoặc xóa.</span></div>
        </c:otherwise>
      </c:choose>
    </section>
  </c:otherwise>
</c:choose>
<%@ include file="../layout/bottom.jspf" %>
