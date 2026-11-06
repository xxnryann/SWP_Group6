<%@ tag pageEncoding="UTF-8" body-content="empty" description="Cột thiết bị hiệu ứng 4DX ở hai bên sơ đồ ghế." %>
<%@ attribute name="wind" required="true" %>
<%@ attribute name="side" required="true" %>
<div class="sp-4dx-tower" aria-hidden="true">
  <span><svg viewBox="0 0 24 24"><path d="M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8a2.500 2.500 0 1 1-2.500 2.500"/></svg>WIND FX ${wind}</span>
  <span><svg viewBox="0 0 24 24"><path d="M13 2 5 14h6l-1 8 8-12h-6z"/></svg>STROBE ${side}1</span>
  <span><svg viewBox="0 0 24 24"><path d="M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11z"/></svg>RAIN/FOG ${side}</span>
  <span><svg viewBox="0 0 24 24"><path d="M3 8c3-3 6-3 9 0s6 3 9 0M3 13c3-3 6-3 9 0s6 3 9 0M3 18c3-3 6-3 9 0s6 3 9 0"/></svg>SCENT POD ${side}</span>
  <span><svg viewBox="0 0 24 24"><path d="M13 2 5 14h6l-1 8 8-12h-6z"/></svg>STROBE ${side}2</span>
</div>
