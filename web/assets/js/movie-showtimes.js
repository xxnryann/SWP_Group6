/* Cua so "Mua ve" o danh sach phim: lich chieu theo ngay, bam gio chieu de chon ghe. */
(function () {
  var script = document.currentScript;
  var ctx = (script && script.getAttribute('data-ctx')) || '';
  var overlay = null;

  function el(tag, cls, text) {
    var node = document.createElement(tag);
    if (cls) node.className = cls;
    if (text != null) node.textContent = text;
    return node;
  }

  function close() {
    if (overlay) { overlay.remove(); overlay = null; }
    document.body.classList.remove('showtime-modal-open');
  }

  function open(title) {
    close();
    overlay = el('div', 'showtime-modal-overlay');
    var box = el('div', 'showtime-modal');
    var head = el('div', 'showtime-modal-head');
    head.appendChild(el('h3', null, 'LỊCH CHIẾU - ' + title));
    var x = el('button', 'showtime-modal-close', '×');
    x.type = 'button';
    x.setAttribute('aria-label', 'Đóng');
    x.addEventListener('click', close);
    head.appendChild(x);
    var body = el('div', 'showtime-modal-body');
    box.appendChild(head);
    box.appendChild(body);
    overlay.appendChild(box);
    overlay.addEventListener('click', function (e) { if (e.target === overlay) close(); });
    document.body.appendChild(overlay);
    document.body.classList.add('showtime-modal-open');
    return body;
  }

  function render(body, data) {
    body.textContent = '';
    body.appendChild(el('h2', 'showtime-cinema', data.cinema));
    if (data.upcoming) {
      body.appendChild(el('p', 'showtime-note', 'Phim sắp chiếu — ngày chiếu gần nhất'));
    }
    var tabs = el('div', 'showtime-tabs');
    var panels = el('div', 'showtime-panels');
    body.appendChild(tabs);
    body.appendChild(panels);

    data.days.forEach(function (day, index) {
      var tab = el('button', 'showtime-tab');
      tab.type = 'button';
      tab.appendChild(el('span', 'showtime-tab-day', String(day.day)));
      tab.appendChild(el('span', 'showtime-tab-sub', day.sub));
      var panel = el('div', 'showtime-panel');
      panel.hidden = true;
      day.groups.forEach(function (group) {
        panel.appendChild(el('h4', 'showtime-format', group.format));
        var row = el('div', 'showtime-times');
        group.times.forEach(function (t) {
          var cell = el('div', 'showtime-cell');
          var link = el('a', 'showtime-time', t.time);
          link.href = ctx + '/booking/seats?showtimeId=' + t.id;
          cell.appendChild(link);
          cell.appendChild(el('span', 'showtime-free', t.free + ' ghế trống'));
          row.appendChild(cell);
        });
        panel.appendChild(row);
      });
      function activate() {
        Array.prototype.forEach.call(tabs.children, function (n) { n.classList.remove('is-active'); });
        Array.prototype.forEach.call(panels.children, function (n) { n.hidden = true; });
        tab.classList.add('is-active');
        panel.hidden = false;
      }
      tab.addEventListener('click', activate);
      tabs.appendChild(tab);
      panels.appendChild(panel);
      if (index === 0) activate();
    });
  }

  // Trang chi tiet phim: hien lich chieu ngay trong trang (khong can mo cua so).
  var inline = document.getElementById('movie-showtimes-inline');
  if (inline) {
    var inlineBody = inline.querySelector('.movie-showtimes-body');
    fetch(ctx + '/movies/showtimes?id=' + encodeURIComponent(inline.getAttribute('data-movie-id')),
      { headers: { 'Accept': 'application/json' } })
      .then(function (r) {
        if (!r.ok) throw new Error('none');
        return r.json();
      })
      .then(function (data) { inline.hidden = false; render(inlineBody, data); })
      .catch(function () { inline.hidden = true; });
  }

  document.addEventListener('click', function (e) {
    var btn = e.target.closest ? e.target.closest('.js-buy-ticket') : null;
    if (!btn) return;
    var id = btn.getAttribute('data-movie-id');
    var card = btn.closest('.movie-card');
    var heading = card ? card.querySelector('h3') : null;
    var body = open(heading ? heading.textContent.trim() : '');
    body.appendChild(el('p', 'showtime-note', 'Đang tải lịch chiếu...'));
    fetch(ctx + '/movies/showtimes?id=' + encodeURIComponent(id), { headers: { 'Accept': 'application/json' } })
      .then(function (r) {
        if (!r.ok) throw new Error('none');
        return r.json();
      })
      .then(function (data) { render(body, data); })
      .catch(function () {
        body.textContent = '';
        body.appendChild(el('p', 'showtime-note', 'Phim này hiện chưa có suất chiếu.'));
      });
  });

  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });
})();
