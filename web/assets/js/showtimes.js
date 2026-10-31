/* Trang lịch chiếu: làm mờ và khóa các suất đã bắt đầu của ngày hôm nay (theo giờ máy người xem).
   Máy chủ vẫn kiểm tra lại khi đặt vé. */
(function () {
  var page = document.querySelector('.st-page');
  if (!page) return;
  var now = new Date();
  var pad = function (n) { return (n < 10 ? '0' : '') + n; };
  var today = now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate());
  if (page.dataset.date !== today) return;
  var time = pad(now.getHours()) + ':' + pad(now.getMinutes());

  document.querySelectorAll('.st-time[data-start]').forEach(function (el) {
    if (el.dataset.start > time) return;
    el.classList.add('is-past');
    el.title = 'Suất này đã bắt đầu';
    if (el.tagName === 'A') {
      el.setAttribute('aria-disabled', 'true');
      el.setAttribute('tabindex', '-1');
      el.addEventListener('click', function (e) { e.preventDefault(); });
    }
  });
})();
