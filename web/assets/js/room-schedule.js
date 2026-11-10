/*
 * Timeline "Lịch các phòng" dùng chung (Manager: form thêm/sửa suất chiếu, Admin: Lịch phòng chiếu).
 * Tải JSON {open, close, rooms:[{room, shows:[{id,title,start,end,slotEnd,tickets}]}]} rồi vẽ mỗi phòng một hàng.
 *
 *   var tl = RoomSchedule.create({
 *     board, status, dateLabel,              // phần tử DOM
 *     url, action,                           // endpoint JSON: url?action=...&date=YYYY-MM-DD
 *     selectedRooms: function () { return [...] },   // tên phòng được tô sáng
 *     currentId: '123',                      // suất đang sửa (tô màu riêng)
 *     candidates: function (room) { return [{start, end, filmEnd, label}] },  // block xem trước (phút trong ngày)
 *     onData: function (data) {}             // nhận JSON sau mỗi lần tải
 *   });
 *   tl.load('2026-11-21'); tl.render();
 */
(function () {
  function pad(n) { return String(n).padStart(2, '0'); }
  function toMin(hhmm) { var p = String(hhmm).split(':').map(Number); return p[0] * 60 + p[1]; }
  function minLabel(m) { return pad(Math.floor(m / 60) % 24) + ':' + pad(m % 60); }
  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function create(opts) {
    var board = opts.board, status = opts.status, dateLabel = opts.dateLabel;
    var data = null, date = '', request = 0;

    function render() {
      if (!board || !data) return;
      var open = toMin(data.open);
      var close = Math.ceil(Math.max(toMin(data.close), open + 60) / 60) * 60;
      var span = close - open;
      function pct(m) { return ((Math.min(Math.max(m, open), close) - open) / span * 100) + '%'; }
      function widthPct(a, b) { return (Math.max(0, Math.min(b, close) - Math.max(a, open)) / span * 100) + '%'; }

      var now = new Date();
      var todayIso = now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate());
      var pastUntil = date === todayIso ? now.getHours() * 60 + now.getMinutes() : (date < todayIso ? close : open);
      var selected = opts.selectedRooms ? opts.selectedRooms() : [];

      board.replaceChildren();
      var axis = el('div', 'tl-axis');
      axis.appendChild(el('div'));
      var axisTrack = el('div', 'tl-axis-track');
      for (var h = open; h <= close; h += 60) {
        var tick = el('span', null, pad(Math.floor(h / 60)) + ':' + pad(h % 60));
        tick.style.left = pct(h);
        if (h === open) tick.style.transform = 'none';
        if (h === close) tick.style.transform = 'translateX(-100%)';
        axisTrack.appendChild(tick);
      }
      axis.appendChild(axisTrack);
      board.appendChild(axis);

      data.rooms.forEach(function (room) {
        var row = el('div', 'tl-row' + (selected.indexOf(room.room) !== -1 ? ' is-selected' : ''));
        row.appendChild(el('div', 'tl-room', room.room)).title = room.room;
        var track = el('div', 'tl-track');
        if (pastUntil > open) {
          var past = el('div', 'tl-past-zone');
          past.style.width = widthPct(open, pastUntil);
          track.appendChild(past);
        }
        for (var hh = open + 60; hh < close; hh += 60) {
          var line = el('div', 'tl-hour');
          line.style.left = pct(hh);
          track.appendChild(line);
        }
        room.shows.forEach(function (show) {
          var s = toMin(show.start), slot = toMin(show.slotEnd);
          if (slot < s) slot += 24 * 60;
          var isPast = s < pastUntil;
          var isCurrent = opts.currentId && String(show.id) === String(opts.currentId);
          var block = el('div', 'tl-show' + (isPast ? ' is-past' : '') + (isCurrent ? ' is-current' : ''));
          block.style.left = pct(s);
          block.style.width = widthPct(s, slot);
          block.appendChild(el('b', null, show.title));
          block.appendChild(el('small', null, show.start + '–' + show.slotEnd));
          block.title = show.title + '\nChiếu: ' + show.start + ' – ' + show.end
            + '\nKết thúc thực tế (gồm dọn phòng): ' + show.slotEnd
            + (show.tickets > 0 ? '\nĐã bán ' + show.tickets + ' vé' : '')
            + (isPast ? '\n(Suất đã qua)' : '') + (isCurrent ? '\n(Suất đang sửa)' : '');
          track.appendChild(block);
        });
        (opts.candidates ? opts.candidates(room.room) : []).forEach(function (c) {
          var preview = el('div', 'tl-candidate', 'Mới ' + c.label + '–' + minLabel(c.end));
          preview.style.left = pct(c.start);
          preview.style.width = widthPct(c.start, c.end);
          preview.title = 'Suất mới: ' + c.label + ' – ' + minLabel(c.filmEnd) + '\nKết thúc thực tế: ' + minLabel(c.end);
          track.appendChild(preview);
        });
        row.appendChild(track);
        board.appendChild(row);
      });
      var total = data.rooms.reduce(function (n, r) { return n + r.shows.length; }, 0);
      if (status) {
        status.textContent = total
          ? 'Giờ trên mỗi suất là giờ bắt đầu – kết thúc thực tế (gồm dọn phòng). Vùng xanh lá là giờ trống; '
            + 'rê chuột lên suất để xem chi tiết' + (opts.selectedRooms ? '; phòng đang chọn được tô sáng.' : '.')
          : 'Chưa có suất chiếu nào trong ngày này — mọi phòng đều trống.';
      }
    }

    async function load(newDate) {
      date = newDate || '';
      if (!board) return null;
      if (!date) {
        data = null;
        board.replaceChildren();
        if (status) status.textContent = 'Chọn ngày để xem lịch các phòng.';
        if (dateLabel) dateLabel.textContent = '';
        return null;
      }
      var p = date.split('-');
      if (dateLabel) dateLabel.textContent = 'ngày ' + p[2] + '/' + p[1] + '/' + p[0];
      var id = ++request;
      if (status) status.textContent = 'Đang tải lịch phòng…';
      var url = new URL(opts.url, window.location.href);
      url.searchParams.set('action', opts.action || 'room-schedule');
      url.searchParams.set('date', date);
      url.searchParams.set('_ts', String(Date.now()));
      try {
        var response = await fetch(url, { credentials: 'same-origin', cache: 'no-store' });
        if (response.status === 401) throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        if (!response.ok) throw new Error('Không tải được lịch phòng (HTTP ' + response.status + ').');
        var json = await response.json();
        if (id !== request) return data;
        data = json;
        if (opts.onData) opts.onData(data);
        render();
        return data;
      } catch (error) {
        if (id !== request) return data;
        board.replaceChildren();
        if (status) status.textContent = error.message;
        return null;
      }
    }

    return { load: load, render: render, data: function () { return data; } };
  }

  window.RoomSchedule = { create: create };
})();
