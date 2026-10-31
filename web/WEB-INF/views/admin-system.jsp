<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Quản lý hệ thống"/>
<%@ include file="_header.jspf" %>
<style>
  .sys-tabs { display: flex; gap: 8px; flex-wrap: wrap; margin: 12px 0 20px; border-bottom: 1px solid #e2e8f0; }
  .sys-tab { padding: 10px 16px; font-weight: 600; color: #64748b; border-bottom: 3px solid transparent; }
  .sys-tab.is-active { color: #1d4ed8; border-bottom-color: #1d4ed8; }
  .sys-config { display: grid; gap: 14px; max-width: 560px; }
  .sys-hint { color: #64748b; font-size: 13px; margin-top: 4px; }
  .sys-filter { display: flex; gap: 12px; flex-wrap: wrap; align-items: flex-end; margin-bottom: 16px; }
  .sys-filter .field { margin: 0; }
  .sys-path { word-break: break-all; font-size: 13px; }
</style>
<main class="page"><div class="container">
  <section class="panel">
    <h2>Quản lý hệ thống</h2>
    <nav class="sys-tabs" aria-label="Quản lý hệ thống">
      <a class="sys-tab ${tab == 'config' ? 'is-active' : ''}" href="${ctx}/admin/system?tab=config">Cấu hình chung</a>
      <a class="sys-tab ${tab == 'backup' ? 'is-active' : ''}" href="${ctx}/admin/system?tab=backup">Sao lưu dữ liệu</a>
      <a class="sys-tab ${tab == 'logs' ? 'is-active' : ''}" href="${ctx}/admin/system?tab=logs">Nhật ký hệ thống</a>
    </nav>

    <c:if test="${not empty error}"><p class="alert alert-error"><c:out value="${error}"/></p></c:if>

    <c:choose>
      <c:when test="${tab == 'config'}">
        <form method="post" action="${ctx}/admin/system" class="sys-config">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="saveConfig">
          <c:forEach var="cfg" items="${configs}">
            <c:set var="range" value="${configRanges[cfg.config_key]}"/>
            <div class="field">
              <label for="${cfg.config_key}"><c:out value="${cfg.description}"/></label>
              <c:choose>
                <c:when test="${not empty range}">
                  <input id="${cfg.config_key}" name="${cfg.config_key}" type="number" required
                         min="${range[0]}" max="${range[1]}" value="<c:out value='${cfg.config_value}'/>">
                  <p class="sys-hint">Từ ${range[0]} đến ${range[1]}</p>
                </c:when>
                <c:otherwise><input id="${cfg.config_key}" type="text" disabled value="<c:out value='${cfg.config_value}'/>"></c:otherwise>
              </c:choose>
            </div>
          </c:forEach>
          <div><button class="btn btn-primary" type="submit">Lưu cấu hình</button></div>
        </form>
      </c:when>

      <c:when test="${tab == 'backup'}">
        <p class="sub">Tạo bản sao lưu đầy đủ của CSDL. File được lưu trong thư mục sao lưu của SQL Server, không chặn người dùng đang thao tác.</p>
        <form method="post" action="${ctx}/admin/system" onsubmit="return confirm('Sao lưu CSDL ngay bây giờ?');" style="margin:14px 0 20px">
          <input type="hidden" name="_csrf" value="${csrf}">
          <input type="hidden" name="action" value="backup">
          <button class="btn btn-primary" type="submit">Sao lưu ngay</button>
        </form>
        <h3>Các lần sao lưu gần đây</h3>
        <c:choose>
          <c:when test="${empty backups}"><p class="sub">Chưa có bản sao lưu nào.</p></c:when>
          <c:otherwise>
            <div class="table-wrap"><table class="data">
              <thead><tr><th>Thời điểm</th><th>File</th><th>Dung lượng (MB)</th><th>Tài khoản SQL</th></tr></thead>
              <tbody>
              <c:forEach var="b" items="${backups}">
                <tr>
                  <td><c:out value="${b.finished_at}"/></td>
                  <td class="sys-path"><c:out value="${b.file_path}"/></td>
                  <td><c:out value="${b.size_mb}"/></td>
                  <td><c:out value="${b.sql_user}"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table></div>
          </c:otherwise>
        </c:choose>
      </c:when>

      <c:otherwise>
        <form method="get" action="${ctx}/admin/system" class="sys-filter">
          <input type="hidden" name="tab" value="logs">
          <div class="field"><label for="q">Từ khóa</label><input id="q" name="q" type="text" maxlength="100" placeholder="Hành động, chi tiết, người thực hiện" value="<c:out value='${q}'/>"></div>
          <div class="field"><label for="from">Từ ngày</label><input id="from" name="from" type="date" value="<c:out value='${from}'/>"></div>
          <div class="field"><label for="to">Đến ngày</label><input id="to" name="to" type="date" value="<c:out value='${to}'/>"></div>
          <button class="btn btn-primary" type="submit">Lọc</button>
        </form>
        <p class="sys-hint">Hiển thị tối đa ${logLimit} dòng mới nhất. Nhật ký chỉ để xem, không thể sửa hoặc xóa.</p>
        <c:choose>
          <c:when test="${empty logs}"><p class="sub">Không có nhật ký phù hợp.</p></c:when>
          <c:otherwise>
            <div class="table-wrap"><table class="data">
              <thead><tr><th>Thời điểm</th><th>Người thực hiện</th><th>Hành động</th><th>Chi tiết</th></tr></thead>
              <tbody>
              <c:forEach var="l" items="${logs}">
                <tr>
                  <td><c:out value="${l.created_at}"/></td>
                  <td><c:out value="${empty l.email ? 'Không xác định' : l.email}"/></td>
                  <td><c:out value="${l.action}"/></td>
                  <td><c:out value="${l.detail}"/></td>
                </tr>
              </c:forEach>
              </tbody>
            </table></div>
          </c:otherwise>
        </c:choose>
      </c:otherwise>
    </c:choose>
  </section>
</div></main>
<%@ include file="_footer.jspf" %>
