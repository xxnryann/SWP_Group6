/* Chuyển động vừa phải, JS thuần, không thư viện.
   - Header đổi bóng khi cuộn xuống.
   - Thẻ nội dung hiện dần khi vào khung nhìn (IntersectionObserver).
   Người dùng bật prefers-reduced-motion thì không thêm hiệu ứng nào. */
(function () {
  'use strict';

  var header = document.querySelector('.site-header');
  if (header) {
    var onScroll = function () {
      header.classList.toggle('is-scrolled', window.scrollY > 8);
    };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce || !('IntersectionObserver' in window)) return;

  var SELECTOR = '.card, .panel, .feature, .movie-card, .mv-card, .home-movie-card, .admin-kpi, .admin-card, .pr-block, .st-movie, .voucher-card';
  var items = Array.prototype.slice.call(document.querySelectorAll(SELECTOR));
  if (!items.length) return;

  document.documentElement.classList.add('motion-on');

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      var el = entry.target;
      el.classList.add('is-visible');
      io.unobserve(el);
      window.setTimeout(function () {
        el.classList.remove('reveal', 'is-visible');
        el.style.removeProperty('--reveal-delay');
      }, 1000);
    });
    // threshold 0: khung rat cao (vd lich su ve dai) khong bao gio lot du mot ti le vao man hinh, se bi an mai.
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0 });

  items.forEach(function (el) {
    // Thứ tự xuất hiện tính theo anh em cùng cha (từng lưới/cột), không theo thứ tự cả trang.
    var siblings = Array.prototype.filter.call(el.parentElement.children, function (c) {
      return c.matches(SELECTOR);
    });
    var i = siblings.indexOf(el);
    el.classList.add('reveal');
    el.style.setProperty('--reveal-delay', (i % 6) * 70 + 'ms');
    io.observe(el);
  });
})();
