<%@ tag pageEncoding="UTF-8" body-content="scriptless" description="Khung sơ đồ phòng chiếu: màn hình, lối đi và cửa ra vào; thân thẻ là các hàng ghế." %>
<%@ attribute name="variant" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="seat" tagdir="/WEB-INF/tags" %>
<link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/seat-plan.css">
<c:choose>
  <c:when test="${variant == '4dx'}">
    <div class="sp-plan sp-4dx">
      <div class="sp-doors sp-4dx-top">
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM / EMERGENCY EXIT</span>
      </div>
      <div class="sp-screen">
        <svg viewBox="0 0 760 50" preserveAspectRatio="none" aria-hidden="true">
          <defs>
            <linearGradient id="sp4dxScreen" x1="0%" x2="100%" y1="0%" y2="0%">
              <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.3"></stop>
              <stop offset="50%" stop-color="#2563eb" stop-opacity="0.95"></stop>
              <stop offset="100%" stop-color="#38bdf8" stop-opacity="0.3"></stop>
            </linearGradient>
          </defs>
          <path d="M 30,46 Q 380,4 730,46" fill="none" stroke="url(#sp4dxScreen)" stroke-linecap="round" stroke-width="6"></path>
          <path d="M 40,48 Q 380,10 720,48" fill="none" opacity="0.7" stroke="#93c5fd" stroke-dasharray="6 4" stroke-width="1.5"></path>
        </svg>
        <span class="sp-screen-label"><i></i>MÀN HÌNH CONG 4DX IMMERSIVE</span>
        <span class="sp-screen-note">Khán giả hướng mắt nhìn về màn hình</span>
      </div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <seat:fxTower wind="01" side="L"/>
          <div class="sp-rows"><jsp:doBody/></div>
          <seat:fxTower wind="02" side="R"/>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-door-in"><b>LỐI VÀO / ENTRANCE</b><small>Cửa chính khán phòng →</small></span>
      </div>
    </div>
  </c:when>
  <c:when test="${variant == '3d'}">
    <div class="sp-plan sp-3d">
      <div class="sp-doors sp-3d-top">
        <span class="sp-door sp-3d-focus">TÂM ĐIỂM HỘI TỤ • VÒM CONG BÁN NGUYỆT</span>
        <span class="sp-door sp-door-exit">CỬA THOÁT HIỂM</span>
      </div>
      <div class="sp-screen">
        <svg viewBox="0 0 920 80" fill="none" aria-hidden="true">
          <defs>
            <linearGradient id="spSilverGlow" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stop-color="#93c5fd" stop-opacity="0.4"></stop>
              <stop offset="20%" stop-color="#38bdf8" stop-opacity="0.9"></stop>
              <stop offset="50%" stop-color="#ffffff"></stop>
              <stop offset="80%" stop-color="#38bdf8" stop-opacity="0.9"></stop>
              <stop offset="100%" stop-color="#93c5fd" stop-opacity="0.4"></stop>
            </linearGradient>
            <linearGradient id="spSilverBeams" x1="50%" y1="0%" x2="50%" y2="100%">
              <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.28"></stop>
              <stop offset="40%" stop-color="#818cf8" stop-opacity="0.10"></stop>
              <stop offset="100%" stop-color="#ffffff" stop-opacity="0"></stop>
            </linearGradient>
          </defs>
          <path d="M 40 60 Q 460 4 880 60 L 830 80 L 90 80 Z" fill="url(#spSilverBeams)"></path>
          <path d="M 40 60 Q 460 4 880 60" stroke="#0f172a" stroke-width="12" stroke-linecap="round"></path>
          <path d="M 40 60 Q 460 4 880 60" stroke="url(#spSilverGlow)" stroke-width="6" stroke-linecap="round"></path>
        </svg>
        <span class="sp-screen-label"><i></i>MÀN HÌNH CHIẾU 3D / SILVER SCREEN</span>
        <span class="sp-screen-note">Khán giả hướng mắt nhìn về màn hình</span>
      </div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-rows"><jsp:doBody/></div>
        </div>
      </div>
      <div class="sp-3d-slopes"><span>↑ Hành lang dốc cánh trái</span><span>Hành lang dốc cánh phải ↑</span></div>
      <div class="sp-exits">
        <span class="sp-door sp-imax-in"><b>LỐI VÀO CHÍNH / MAIN ENTRANCE</b></span>
      </div>
    </div>
  </c:when>
  <c:when test="${variant == 'imax'}">
    <div class="sp-plan sp-imax">
      <div class="sp-doors sp-imax-top">
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM KHẨN CẤP • CÁNH TRÁI</span>
        <span class="sp-imax-view"><i></i>TRỤC TÂM ĐIỂM IMAX</span>
        <span class="sp-door sp-door-exit">LỐI THOÁT HIỂM KHẨN CẤP • CÁNH PHẢI</span>
      </div>
      <div class="sp-screen">
        <svg viewBox="0 0 1000 180" preserveAspectRatio="none" fill="none" role="img" aria-label="Màn hình IMAX ba cánh">
          <defs>
            <linearGradient id="spImaxCenterBeam" x1="50%" y1="0%" x2="50%" y2="100%">
              <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.12"></stop>
              <stop offset="50%" stop-color="#0284c7" stop-opacity="0.04"></stop>
              <stop offset="100%" stop-color="#38bdf8" stop-opacity="0"></stop>
            </linearGradient>
            <linearGradient id="spImaxSideBeam" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.08"></stop>
              <stop offset="60%" stop-color="#0284c7" stop-opacity="0.02"></stop>
              <stop offset="100%" stop-color="#38bdf8" stop-opacity="0"></stop>
            </linearGradient>
            <linearGradient id="spImaxLine" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stop-color="#0284c7"></stop>
              <stop offset="15%" stop-color="#38bdf8"></stop>
              <stop offset="50%" stop-color="#7dd3fc"></stop>
              <stop offset="85%" stop-color="#38bdf8"></stop>
              <stop offset="100%" stop-color="#0284c7"></stop>
            </linearGradient>
          </defs>
          <polygon points="40,150 240,40 340,165 90,172" fill="url(#spImaxSideBeam)"></polygon>
          <polygon points="240,40 760,40 710,165 290,165" fill="url(#spImaxCenterBeam)"></polygon>
          <polygon points="760,40 960,150 910,172 660,165" fill="url(#spImaxSideBeam)"></polygon>
          <polyline points="38,150 240,40 760,40 962,150" stroke="#1e293b" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"></polyline>
          <polyline points="40,150 240,40 760,40 960,150" stroke="url(#spImaxLine)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"></polyline>
          <line x1="300" y1="40" x2="700" y2="40" stroke="#ffffff" stroke-width="1" stroke-linecap="round" stroke-opacity="0.8"></line>
        </svg>
      </div>
      <div class="sp-imax-ruler"><span>Hành lang LED trái</span><span>Hành lang LED phải</span></div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-rows"><jsp:doBody/></div>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-imax-in"><b>CỬA VÀO VIP LOUNGE • MAIN ENTRANCE</b><small>Cửa khán phòng IMAX</small></span>
        <span class="sp-door sp-imax-out"><b>LỐI RA RIÊNG BIỆT • PRIVATE EXIT</b><small>Thông ra sảnh chờ</small></span>
      </div>
    </div>
  </c:when>
  <c:otherwise>
    <div class="sp-plan">
      <div class="sp-screen">
        <svg viewBox="0 0 900 50" preserveAspectRatio="none" aria-hidden="true">
          <defs>
            <linearGradient id="spScreenGrad" x1="0" x2="1" y1="0" y2="0">
              <stop offset="0%" stop-color="#93c5fd"></stop>
              <stop offset="50%" stop-color="#2563eb"></stop>
              <stop offset="100%" stop-color="#93c5fd"></stop>
            </linearGradient>
          </defs>
          <path d="M 40 45 Q 450 6 860 45" fill="none" opacity="0.4" stroke="#cbd5e1" stroke-linecap="round" stroke-width="6"></path>
          <path d="M 40 44 Q 450 5 860 44" fill="none" stroke="url(#spScreenGrad)" stroke-linecap="round" stroke-width="4"></path>
        </svg>
        <span class="sp-screen-label">MÀN HÌNH CHIẾU / SCREEN</span>
        <span class="sp-screen-note">Khán giả hướng mắt nhìn về màn hình</span>
      </div>
      <div class="sp-doors">
        <span class="sp-door">↓ Lối đi khán phòng</span>
        <span class="sp-door sp-door-exit">LỐI RA / EXIT</span>
      </div>
      <div class="sp-scroll">
        <div class="sp-floor">
          <div class="sp-aisle" aria-hidden="true"><span>LỐI ĐI 01</span><span>BẬC THANG</span></div>
          <div class="sp-rows"><jsp:doBody/></div>
          <div class="sp-aisle" aria-hidden="true"><span>LỐI ĐI 02</span><span>BẬC THANG</span></div>
        </div>
      </div>
      <div class="sp-exits">
        <span class="sp-door sp-door-in"><b>LỐI VÀO / ENTRANCE</b><small>Cửa chính khán phòng →</small></span>
        <span class="sp-door sp-door-exit"><b>LỐI THOÁT HIỂM</b><small>↗ Cửa thoát hiểm</small></span>
      </div>
    </div>
  </c:otherwise>
</c:choose>
