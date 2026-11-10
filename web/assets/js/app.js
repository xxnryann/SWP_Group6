/* CineStar UI v2 — hành vi dùng chung: toast, modal, menu, drawer, sidebar, mật khẩu, nút gửi form. */
(function () {
  'use strict';
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

  /* Toast: tự ẩn sau 3,5 giây. Giữ API window.showToast(msg, type) cho các trang cũ. */
  window.showToast = function (msg, type) {
    var stack = $('#toastStack');
    if (!stack || !msg) return;
    var t = document.createElement('div');
    t.className = 'toast' + (type ? ' toast-' + type : '');
    t.setAttribute('role', type === 'error' ? 'alert' : 'status');
    t.textContent = msg;
    stack.appendChild(t);
    setTimeout(function () { t.style.transition = 'opacity .25s'; t.style.opacity = '0'; }, 3200);
    setTimeout(function () { t.remove(); }, 3500);
  };
  var stack = $('#toastStack');
  if (stack && stack.dataset.flash) {
    var ft = stack.dataset.flashType;
    showToast(stack.dataset.flash, ft === 'error' ? 'error' : ft === 'success' ? 'success' : '');
  }
  $$('[data-toast]').forEach(function (a) {
    a.addEventListener('click', function (e) { e.preventDefault(); showToast(a.dataset.toast); });
  });

  /* Modal */
  var modal = $('#modal');
  window.openModal = function (title, body) {
    $('#modalTitle').textContent = title; $('#modalBody').textContent = body; modal.classList.add('open');
    var b = $('[data-modal-close]', modal); if (b) b.focus();
  };
  window.closeModal = function () { modal.classList.remove('open'); };
  if (modal) modal.addEventListener('click', function (e) {
    if (e.target === modal || e.target.hasAttribute('data-modal-close')) closeModal();
  });

  /* Menu tài khoản */
  var userMenu = $('#userMenu');
  if (userMenu) {
    var ub = $('button', userMenu);
    ub.addEventListener('click', function (e) {
      e.stopPropagation();
      var open = !userMenu.classList.contains('open');
      userMenu.classList.toggle('open', open); ub.setAttribute('aria-expanded', String(open));
    });
    document.addEventListener('click', function (e) {
      if (!userMenu.contains(e.target)) { userMenu.classList.remove('open'); ub.setAttribute('aria-expanded', 'false'); }
    });
  }

  /* Drawer di động (trang công khai) và sidebar (khung quản trị) dùng chung lớp nền */
  var backdrop = $('#drawerBackdrop');
  var menuBtn = $('#menuBtn'), drawer = $('#drawer'), drawerClose = $('#drawerClose');
  function setDrawer(open) {
    document.body.classList.toggle('drawer-open', open);
    if (drawer) { drawer.inert = !open; drawer.setAttribute('aria-hidden', String(!open)); }
    if (menuBtn) menuBtn.setAttribute('aria-expanded', String(open));
    if (open && drawerClose) drawerClose.focus();
  }
  if (menuBtn) menuBtn.addEventListener('click', function () { setDrawer(true); });
  if (drawerClose) drawerClose.addEventListener('click', function () { setDrawer(false); });
  var sideToggle = $('#sideToggle');
  function setSide(open) {
    document.body.classList.toggle('side-open', open);
    if (sideToggle) sideToggle.setAttribute('aria-expanded', String(open));
  }
  if (sideToggle) sideToggle.addEventListener('click', function () { setSide(!document.body.classList.contains('side-open')); });
  if (backdrop) backdrop.addEventListener('click', function () { setDrawer(false); setSide(false); });
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (modal) closeModal();
    setDrawer(false); setSide(false);
    if (userMenu) userMenu.classList.remove('open');
  });

  /* Đánh dấu mục menu đang mở: khớp tiền tố dài nhất */
  function markActive(links) {
    var here = location.pathname.replace(/\/$/, '');
    var best = null, bestLen = -1;
    links.forEach(function (a) {
      if (a.hasAttribute('data-nomatch')) return;
      var p = a.pathname.replace(/\/$/, '');
      if ((here === p || here.indexOf(p + '/') === 0) && p.length > bestLen) { best = a; bestLen = p.length; }
    });
    if (best) { best.classList.add('active'); best.setAttribute('aria-current', 'page'); }
  }
  markActive($$('#sideNav a'));
  markActive($$('#mainNav a'));

  /* Header đổ bóng khi cuộn */
  var header = $('#siteHeader');
  if (header) {
    var onScroll = function () { header.classList.toggle('is-scrolled', window.scrollY > 8); };
    window.addEventListener('scroll', onScroll, { passive: true }); onScroll();
  }

  /* Hiện/ẩn mật khẩu */
  $$('.pw-toggle').forEach(function (b) {
    b.addEventListener('click', function () {
      var i = b.parentElement.querySelector('input'), show = i.type === 'password';
      i.type = show ? 'text' : 'password'; b.textContent = show ? 'Ẩn' : 'Hiện';
      b.setAttribute('aria-pressed', String(show));
    });
  });

  /* Nút gửi hiện vòng quay, chống bấm đúp (form có data-loading hoặc novalidate) */
  $$('form[novalidate], form[data-loading]').forEach(function (f) {
    f.addEventListener('submit', function (e) {
      var b = f.querySelector('button[type=submit].btn');
      // Kiểm tra sau cùng: các listener khác (xác nhận, kiểm tra JS) có thể hủy việc gửi.
      if (b) setTimeout(function () { if (!e.defaultPrevented) { b.classList.add('loading'); b.disabled = true; } }, 0);
    });
  });

  /* Xác nhận trước khi gửi: <form data-confirm="Câu hỏi?"> */
  $$('form[data-confirm]').forEach(function (f) {
    f.addEventListener('submit', function (e) { if (!window.confirm(f.dataset.confirm)) e.preventDefault(); });
  });

  /* Lưu tên người dùng hiện tại (một số trang cũ đọc localStorage.currentUser) */
  try {
    var user = document.body.dataset.user;
    if (user) localStorage.setItem('currentUser', JSON.stringify({ name: user })); else localStorage.removeItem('currentUser');
  } catch (e) { /* trình duyệt chặn localStorage */ }
})();
