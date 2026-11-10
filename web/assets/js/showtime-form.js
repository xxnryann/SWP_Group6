(function () {
  var form = document.getElementById('showtime-form');
  if (!form) return;

  var movieSelect = document.getElementById('movieId');
  var roomSelect = document.getElementById('roomName');
  var dateInput = document.getElementById('showDate');
  var timesBox = document.getElementById('showTime');
  var message = document.getElementById('showtime-availability-message');
  var editingId = (form.querySelector('input[name="id"]') || {}).value || '';
  // Sửa suất: chọn sẵn đúng phòng + giờ hiện tại (chỉ lần tải đầu).
  var pendingRoom = timesBox.dataset.currentRoom || '';
  var pendingTime = timesBox.dataset.currentTime || '';

  /* ================= tiện ích thời gian ================= */
  function pad(n) { return String(n).padStart(2, '0'); }
  function toMin(hhmm) { var p = String(hhmm).split(':').map(Number); return p[0] * 60 + p[1]; }
  function minLabel(m) { return pad(Math.floor(m / 60) % 24) + ':' + pad(m % 60); }
  /** Phút trong ngày -> "07:15 AM" / "01:05 PM". */
  function ampm(m) {
    var h = Math.floor(m / 60) % 24;
    return pad(h % 12 === 0 ? 12 : h % 12) + ':' + pad(m % 60) + (h < 12 ? ' AM' : ' PM');
  }
  /* Block thực tế = phim + 15' dọn phòng, làm tròn lên mốc 5' (khớp ShowtimeRules.blockMinutes). */
  function blockMinutes(duration) {
    var remainder = (duration + 15) % 5;
    return duration + 15 + (remainder === 0 ? 0 : 5 - remainder);
  }
  function duration() {
    var opt = movieSelect.options[movieSelect.selectedIndex];
    return Number(opt && opt.dataset.duration) || 0;
  }
  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }
  function checkedRooms() {
    return Array.from(roomSelect.querySelectorAll('input[name="roomName"]:checked')).map(function (i) { return i.value; });
  }

  /* ================= giờ trống theo từng phòng ================= */
  // room -> { box, list, custom, note, request }
  var groups = new Map();
  var loadVersion = 0;   // tăng khi đổi phim/ngày: kết quả cũ bị bỏ qua

  function selectedTimesOf(room) {
    var g = groups.get(room);
    if (!g) return [];
    var times = Array.from(g.list.querySelectorAll('input[type="checkbox"]:checked')).map(function (i) { return i.value; });
    g.customTimes.forEach(function (t) { if (times.indexOf(t) === -1) times.push(t); });
    return times.sort();
  }

  /**
   * Kiểm tra một giờ nhập tay cho phòng: trong khung 07:00–23:55, chưa qua (hôm nay),
   * không đè suất có sẵn và không đè giờ khác đã chọn của cùng phòng. Trả về lỗi hoặc ''.
   */
  function customTimeError(room, time) {
    var d = duration();
    if (!d) return 'Chọn phim trước.';
    var s = toMin(time), blk = blockMinutes(d);
    var open = schedule ? toMin(schedule.open) : 7 * 60;
    var close = schedule ? toMin(schedule.close) : 23 * 60 + 55;
    if (s < open || s + d > close) {
      return 'Ngoài khung giờ: phim phải bắt đầu từ ' + ampm(open) + ' và kết thúc trước ' + ampm(close) + '.';
    }
    var now = new Date();
    var todayIso = now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate());
    if (dateInput.value === todayIso && s <= now.getHours() * 60 + now.getMinutes()) return 'Giờ này đã qua.';
    var info = schedule && schedule.rooms.find(function (r) { return r.room === room; });
    var shows = info ? info.shows : [];
    for (var i = 0; i < shows.length; i++) {
      if (String(shows[i].id) === String(editingId)) continue;
      var es = toMin(shows[i].start), ee = toMin(shows[i].slotEnd);
      if (ee < es) ee += 24 * 60;
      if (s < ee && es < s + blk) {
        return 'Trùng suất ' + shows[i].title + ' (' + shows[i].start + '–' + shows[i].slotEnd + ').';
      }
    }
    var others = selectedTimesOf(room);
    for (var j = 0; j < others.length; j++) {
      var os = toMin(others[j]);
      if (others[j] !== time && s < os + blk && os < s + blk) {
        return 'Trùng giờ ' + ampm(os) + ' đã chọn cho phòng này (mỗi suất chiếm ' + blk + ' phút gồm dọn phòng).';
      }
    }
    return '';
  }

  function renderChips(room) {
    var g = groups.get(room);
    if (!g) return;
    g.chips.replaceChildren();
    var d = duration();
    g.customTimes.slice().sort().forEach(function (t) {
      var chip = el('span', 'time-chip', ampm(toMin(t)) + ' – ' + ampm(toMin(t) + d)
        + ' (thực tế ' + ampm(toMin(t) + blockMinutes(d)) + ')');
      var remove = el('button', 'time-chip-remove', '×');
      remove.type = 'button';
      remove.title = 'Bỏ giờ ' + t;
      remove.addEventListener('click', function () {
        g.customTimes = g.customTimes.filter(function (x) { return x !== t; });
        renderChips(room);
        refreshCount(room);
        updateSummary();
      });
      chip.appendChild(remove);
      g.chips.appendChild(chip);
    });
  }

  function updateSummary() {
    var total = 0;
    groups.forEach(function (g, room) { total += selectedTimesOf(room).length; });
    if (!groups.size) {
      message.textContent = '';
    } else {
      message.textContent = total
        ? 'Đã chọn ' + total + ' suất chiếu. Mỗi giờ chỉ áp dụng cho đúng phòng của nó.'
        : 'Chọn giờ cho từng phòng (có thể chọn nhiều giờ).';
    }
    renderSchedule();
  }

  function createGroup(room) {
    var box = el('div', 'room-times');
    var head = el('div', 'room-times-head');
    head.appendChild(el('strong', null, room));
    var count = el('span', 'room-times-count');
    head.appendChild(count);
    box.appendChild(head);
    var list = el('div', 'room-times-list');
    box.appendChild(list);
    // Giờ nhập tay: chọn Giờ (01–12) + Phút (mốc 5') + AM/PM rồi bấm "Thêm"; mỗi giờ là 1 thẻ có nút ×.
    // Bên trong quy đổi sang 24 giờ (HH:mm) để kiểm tra và gửi lên server.
    var customRow = el('div', 'showtime-custom-time');
    customRow.appendChild(el('span', null, 'Giờ bắt đầu'));
    var hour = document.createElement('select');
    hour.setAttribute('aria-label', 'Giờ');
    for (var h = 1; h <= 12; h++) hour.appendChild(new Option(pad(h), String(h)));
    hour.value = '7';
    var minute = document.createElement('select');
    minute.setAttribute('aria-label', 'Phút');
    for (var m = 0; m < 60; m += 5) minute.appendChild(new Option(pad(m), pad(m)));
    var period = document.createElement('select');
    period.setAttribute('aria-label', 'AM/PM');
    period.appendChild(new Option('AM', 'AM'));
    period.appendChild(new Option('PM', 'PM'));
    var add = el('button', 'btn btn-outline btn-small', 'Thêm');
    add.type = 'button';
    customRow.appendChild(hour);
    customRow.appendChild(el('span', 'time-sep', ':'));
    customRow.appendChild(minute);
    customRow.appendChild(period);
    customRow.appendChild(add);
    box.appendChild(customRow);
    var chips = el('div', 'time-chips');
    box.appendChild(chips);
    var note = el('small', 'room-times-note');
    box.appendChild(note);
    var g = { box: box, list: list, chips: chips, customTimes: [], note: note, count: count };
    add.addEventListener('click', function () {
      var h12 = Number(hour.value) % 12;   // 12 AM = 00, 12 PM = 12
      var t = pad(period.value === 'PM' ? h12 + 12 : h12) + ':' + minute.value;
      if (selectedTimesOf(room).indexOf(t) !== -1) { note.textContent = 'Giờ ' + ampm(toMin(t)) + ' đã được chọn.'; return; }
      var err = customTimeError(room, t);
      if (err) { note.textContent = '⚠ ' + err; note.classList.add('is-error'); return; }
      note.textContent = '';
      note.classList.remove('is-error');
      g.customTimes.push(t);
      renderChips(room);
      refreshCount(room);
      updateSummary();
    });
    list.addEventListener('change', function (event) {
      var box2 = event.target;
      if (box2 && box2.checked) {
        var err2 = customTimeError(room, box2.value);
        if (err2) {
          box2.checked = false;
          note.textContent = '⚠ ' + err2;
          note.classList.add('is-error');
        } else {
          note.textContent = '';
          note.classList.remove('is-error');
        }
      }
      refreshCount(room);
      updateSummary();
    });
    return g;
  }

  function refreshCount(room) {
    var g = groups.get(room);
    if (!g) return;
    var n = selectedTimesOf(room).length;
    g.count.textContent = n ? 'Đã chọn ' + n : '';
  }

  async function loadGroup(room) {
    var g = groups.get(room);
    var version = loadVersion;
    var movieId = movieSelect.value;
    var date = dateInput.value;
    g.list.replaceChildren(el('span', 'muted', 'Đang kiểm tra giờ trống…'));
    g.note.textContent = '';
    var url = new URL(form.dataset.availabilityUrl, window.location.href);
    url.searchParams.set('action', 'available-times');
    url.searchParams.set('movieId', movieId);
    url.searchParams.set('roomName', room);
    url.searchParams.set('date', date);
    url.searchParams.set('_ts', String(Date.now()));
    if (editingId) url.searchParams.set('id', editingId);
    try {
      var response = await fetch(url, { credentials: 'same-origin', cache: 'no-store' });
      if (response.status === 401) throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      if (!response.ok) throw new Error('Không kiểm tra được giờ trống (HTTP ' + response.status + ').');
      var times = await response.json();
      if (version !== loadVersion || groups.get(room) !== g) return;   // phim/ngày đã đổi hoặc phòng đã bỏ
      g.list.replaceChildren();
      var d = duration();
      times.forEach(function (time) {
        var label = el('label', 'check');
        var input = document.createElement('input');
        input.type = 'checkbox';
        input.value = time;
        if (pendingRoom === room && pendingTime === time) input.checked = true;
        label.appendChild(input);
        var text = el('span', null, time + ' – ' + minLabel(toMin(time) + d) + ' ');
        text.appendChild(el('small', 'muted', '(thực tế: ' + minLabel(toMin(time) + blockMinutes(d)) + ')'));
        label.appendChild(text);
        g.list.appendChild(label);
      });
      if (pendingRoom === room && pendingTime && times.indexOf(pendingTime) === -1) {
        g.customTimes.push(pendingTime);   // giờ đang sửa không nằm trong gợi ý -> thành thẻ giờ khác
        renderChips(room);
      }
      if (pendingRoom === room) { pendingRoom = ''; pendingTime = ''; }
      if (!times.length) {
        g.list.replaceChildren(el('span', 'muted', 'Không còn khoảng trống đủ cho phim này.'));
        g.note.textContent = 'Có thể chọn giờ bắt đầu khác bên dưới nếu vẫn đủ thời gian.';
      }
      refreshCount(room);
      updateSummary();
    } catch (error) {
      if (version !== loadVersion || groups.get(room) !== g) return;
      g.list.replaceChildren(el('span', 'muted', error.message));
    }
  }

  /** Đồng bộ nhóm giờ với phòng đang tick. reset = true khi đổi phim/ngày (giờ cũ không còn đúng). */
  function syncGroups(reset) {
    if (reset) {
      loadVersion++;
      groups.clear();
    }
    var rooms = checkedRooms();
    if (!movieSelect.value || !dateInput.value || !rooms.length) {
      groups.clear();
      timesBox.replaceChildren(el('p', 'muted', 'Chọn phim, phòng và ngày để xem giờ trống của từng phòng.'));
      updateSummary();
      return;
    }
    if (dateInput.min && dateInput.value < dateInput.min) {
      groups.clear();
      timesBox.replaceChildren(el('p', 'muted', 'Ngày chiếu đã qua. Vui lòng chọn hôm nay hoặc một ngày sau.'));
      updateSummary();
      return;
    }
    // Bỏ nhóm của phòng không còn tick; giữ nguyên lựa chọn của phòng còn tick.
    Array.from(groups.keys()).forEach(function (room) {
      if (rooms.indexOf(room) === -1) groups.delete(room);
    });
    var toLoad = [];
    rooms.forEach(function (room) {
      if (!groups.has(room)) {
        groups.set(room, createGroup(room));
        toLoad.push(room);
      }
    });
    timesBox.replaceChildren();
    rooms.forEach(function (room) { timesBox.appendChild(groups.get(room).box); });
    toLoad.forEach(loadGroup);
    updateSummary();
  }

  /* Gửi form: mỗi giờ thành một cặp slot = "phòng|giờ". */
  form.addEventListener('submit', function (event) {
    form.querySelectorAll('input[type="hidden"][name="slot"]').forEach(function (i) { i.remove(); });
    var count = 0;
    groups.forEach(function (g, room) {
      selectedTimesOf(room).forEach(function (time) {
        var hidden = document.createElement('input');
        hidden.type = 'hidden';
        hidden.name = 'slot';
        hidden.value = room + '|' + time;
        form.appendChild(hidden);
        count++;
      });
    });
    if (!count) {
      event.preventDefault();
      message.textContent = 'Vui lòng chọn ít nhất một giờ chiếu cho phòng đã tick.';
      timesBox.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else if (editingId && count > 1) {
      event.preventDefault();
      message.textContent = 'Khi sửa suất chiếu, chỉ chọn một phòng và một giờ.';
    }
  });

  /* ================= Lịch các phòng trong ngày (timeline) ================= */
  var board = document.getElementById('room-schedule-board');
  var boardStatus = document.getElementById('room-schedule-status');
  var boardDate = document.getElementById('room-schedule-date');
  var schedule = null;
  var scheduleRequest = 0;

  function renderSchedule() {
    if (!board || !schedule) return;
    var open = toMin(schedule.open);
    var close = Math.ceil(Math.max(toMin(schedule.close), open + 60) / 60) * 60;
    var span = close - open;
    function pct(m) { return ((Math.min(Math.max(m, open), close) - open) / span * 100) + '%'; }
    function widthPct(a, b) { return (Math.max(0, Math.min(b, close) - Math.max(a, open)) / span * 100) + '%'; }

    var now = new Date();
    var todayIso = now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate());
    var nowMin = now.getHours() * 60 + now.getMinutes();
    var pastUntil = dateInput.value === todayIso ? nowMin : (dateInput.value < todayIso ? close : open);
    var d = duration();
    var selected = checkedRooms();

    board.replaceChildren();
    var axis = el('div', 'rs-axis');
    axis.appendChild(el('div'));
    var axisTrack = el('div', 'rs-axis-track');
    for (var h = open; h <= close; h += 60) {
      var tick = el('span', null, pad(Math.floor(h / 60)) + ':' + pad(h % 60));
      tick.style.left = pct(h);
      if (h === open) tick.style.transform = 'none';
      if (h === close) tick.style.transform = 'translateX(-100%)';
      axisTrack.appendChild(tick);
    }
    axis.appendChild(axisTrack);
    board.appendChild(axis);

    schedule.rooms.forEach(function (room) {
      var row = el('div', 'rs-row' + (selected.indexOf(room.room) !== -1 ? ' is-selected' : ''));
      row.appendChild(el('div', 'rs-room', room.room)).title = room.room;
      var track = el('div', 'rs-track');
      if (pastUntil > open) {
        var past = el('div', 'rs-past-zone');
        past.style.width = widthPct(open, pastUntil);
        track.appendChild(past);
      }
      for (var hh = open + 60; hh < close; hh += 60) {
        var line = el('div', 'rs-hour');
        line.style.left = pct(hh);
        track.appendChild(line);
      }
      room.shows.forEach(function (show) {
        var s = toMin(show.start), slot = toMin(show.slotEnd);
        if (slot < s) slot += 24 * 60;
        var isPast = s < pastUntil;   // suất đã bắt đầu (hôm nay) hoặc cả ngày đã qua
        var isCurrent = String(show.id) === String(editingId);
        var block = el('div', 'rs-show' + (isPast ? ' is-past' : '') + (isCurrent ? ' is-current' : ''));
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
      // Xem trước: chỉ các giờ đã chọn CỦA CHÍNH phòng này.
      if (d) {
        selectedTimesOf(room.room).forEach(function (t) {
          var cs = toMin(t), actual = cs + blockMinutes(d);
          var preview = el('div', 'rs-candidate', 'Mới ' + t + '–' + minLabel(actual));
          preview.style.left = pct(cs);
          preview.style.width = widthPct(cs, actual);
          preview.title = 'Suất mới: ' + t + ' – ' + minLabel(cs + d) + '\nKết thúc thực tế: ' + minLabel(actual);
          track.appendChild(preview);
        });
      }
      row.appendChild(track);
      board.appendChild(row);
    });
    var total = schedule.rooms.reduce(function (n, r) { return n + r.shows.length; }, 0);
    boardStatus.textContent = total
      ? 'Giờ trên mỗi suất là giờ bắt đầu – kết thúc thực tế (gồm dọn phòng). Vùng xanh lá là giờ trống; '
        + 'rê chuột lên suất để xem chi tiết; phòng đang chọn được tô sáng.'
      : 'Chưa có suất chiếu nào trong ngày này — mọi phòng đều trống.';
  }

  async function loadSchedule() {
    if (!board) return;
    var date = dateInput.value;
    if (!date) {
      board.replaceChildren();
      boardStatus.textContent = 'Chọn ngày chiếu để xem lịch các phòng.';
      boardDate.textContent = '';
      return;
    }
    var p = date.split('-');
    boardDate.textContent = 'ngày ' + p[2] + '/' + p[1] + '/' + p[0];
    var id = ++scheduleRequest;
    boardStatus.textContent = 'Đang tải lịch phòng…';
    var url = new URL(form.dataset.availabilityUrl, window.location.href);
    url.searchParams.set('action', 'room-schedule');
    url.searchParams.set('date', date);
    url.searchParams.set('_ts', String(Date.now()));
    try {
      var response = await fetch(url, { credentials: 'same-origin', cache: 'no-store' });
      if (response.status === 401) throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      if (!response.ok) throw new Error('Không tải được lịch phòng (HTTP ' + response.status + ').');
      var data = await response.json();
      if (id !== scheduleRequest) return;
      schedule = data;
      renderSchedule();
    } catch (error) {
      if (id !== scheduleRequest) return;
      board.replaceChildren();
      boardStatus.textContent = error.message;
    }
  }

  movieSelect.addEventListener('change', function () { syncGroups(true); });
  dateInput.addEventListener('change', function () { syncGroups(true); loadSchedule(); });
  roomSelect.addEventListener('change', function () { syncGroups(false); });
  syncGroups(true);
  loadSchedule();
})();
