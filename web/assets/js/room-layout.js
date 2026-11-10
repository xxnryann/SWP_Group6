/* Thêm phòng chiếu — bước 2: xem trước layout, chọn layout và trình tạo layout mới.
   Định dạng layout (giống SeatLayout.layout_data): hàng cách nhau bởi '/', S = thường, V = VIP,
   C = ghế đôi (luôn theo cặp "CC"); '_' chỉ dùng trong bản xem trước để vẽ hành lang. */
(function () {
  'use strict';

  /* ===================== Bản xem trước thu nhỏ ===================== */
  function drawThumb(el) {
    var data = el.getAttribute('data-layout') || '';
    var rows = data ? data.split('/') : [];
    el.textContent = '';
    var screen = document.createElement('span');
    screen.className = 't-screen';
    el.appendChild(screen);
    if (!rows.length) return;

    var widest = 0;
    rows.forEach(function (r) {
      var w = 0;
      for (var i = 0; i < r.length; i++) w += r.charAt(i) === '_' ? 0.8 : 1;
      widest = Math.max(widest, w);
    });
    var width = (el.clientWidth || 230) - 16 - 16;          /* trừ padding + 2 lối đi */
    var height = 150 - 20 - 11;                              /* trừ padding + màn hình */
    var d = Math.floor(Math.min(9, (width - widest) / widest, (height - 2 * rows.length) / rows.length));
    d = Math.max(2, d);

    var body = document.createElement('span');
    body.className = 't-body';
    var list = document.createElement('span');
    list.className = 't-rows';
    rows.forEach(function (r) {
      var line = document.createElement('span');
      line.className = 't-row';
      for (var i = 0; i < r.length; i++) {
        var ch = r.charAt(i), dot = document.createElement('i');
        if (ch === 'C') { dot.className = 'c c2'; i++; }    /* một cặp ghế đôi */
        else if (ch === 'V') dot.className = 'v';
        else if (ch === '_') dot.className = 'g';
        line.appendChild(dot);
      }
      list.appendChild(line);
    });
    list.style.setProperty('--d', d + 'px');
    var aL = document.createElement('span'), aR = document.createElement('span');
    aL.className = aR.className = 't-aisle';
    body.appendChild(aL); body.appendChild(list); body.appendChild(aR);
    el.appendChild(body);
  }
  Array.prototype.forEach.call(document.querySelectorAll('.lp-thumb[data-layout]'), drawThumb);

  /* ===================== Chọn layout cho phòng ===================== */
  var createForm = document.getElementById('createForm');
  var selName = document.getElementById('selName'), selSeats = document.getElementById('selSeats');
  function syncChoice() {
    var r = createForm.querySelector('input[name="layout"]:checked');
    selName.textContent = r ? r.getAttribute('data-name') : '—';
    selSeats.textContent = r ? '· ' + r.getAttribute('data-seats') + ' ghế' : '';
  }
  createForm.addEventListener('change', syncChoice);
  createForm.addEventListener('submit', function (e) {
    if (!createForm.querySelector('input[name="layout"]:checked')) {
      e.preventDefault();
      alert('Vui lòng chọn một layout ghế.');
    }
  });
  syncChoice();
  var checked = createForm.querySelector('input[name="layout"]:checked');
  if (checked && checked.value !== 'std') checked.closest('.lp-card').scrollIntoView({ block: 'center' });

  /* ===================== Trình tạo layout ===================== */
  var editor = document.getElementById('editor');
  var MAX_ROWS = +editor.getAttribute('data-max-rows') || 26;
  var MAX_COLS = +editor.getAttribute('data-max-cols') || 30;
  var MAX_SEATS = +editor.getAttribute('data-max-seats') || 500;
  var rowsIn = document.getElementById('le-rows'), colsIn = document.getElementById('le-cols');
  var work = document.getElementById('leWork'), rowsBox = document.getElementById('leRows');
  var stage = document.getElementById('leStage'), marquee = document.getElementById('leMarquee');
  var msg = document.getElementById('leMsg'), pop = document.getElementById('lePop');
  var btnBulk = document.getElementById('btnBulk'), bulkBar = document.getElementById('bulkBar');
  var bulkCount = document.getElementById('bulkCount');
  var saveForm = document.getElementById('saveForm'), nameIn = document.getElementById('le-name');
  document.body.appendChild(pop);                             /* toạ độ theo trang */

  var existingNames = Array.prototype.map.call(document.querySelectorAll('#layoutNames li'), function (li) {
    return li.textContent.trim().toLowerCase();
  });

  var TYPE_LABEL = { U: 'Chưa gán loại', S: 'Ghế thường', V: 'Ghế VIP', C: 'Ghế đôi' };
  /* state.rows[i].cells[j] = { id, col, t }: col là cột gốc trên lưới; ghế đôi (t = 'C') chiếm 2 cột col, col + 1. */
  var state = { cols: 0, rows: [] };
  var nextId = 1;
  var selected = {};       /* id → true (chế độ Sửa nhiều) */
  var missing = {};        /* id → true (ghế chưa gán khi bấm Lưu) */
  var openId = null;       /* ghế đang mở menu */
  var bulk = false;

  function cell(col, t) { return { id: nextId++, col: col, t: t }; }

  function find(id) {
    for (var r = 0; r < state.rows.length; r++) {
      var cells = state.rows[r].cells;
      for (var i = 0; i < cells.length; i++) if (cells[i].id === id) return { r: r, i: i, c: cells[i] };
    }
    return null;
  }

  function labelOf(pos) {
    var n = 1, cells = state.rows[pos.r].cells;
    for (var i = 0; i < pos.i; i++) n += cells[i].t === 'C' ? 2 : 1;
    var row = String.fromCharCode(65 + pos.r);
    return pos.c.t === 'C' ? row + n + '–' + row + (n + 1) : row + n;
  }

  function counts() {
    var k = { S: 0, V: 0, C: 0, U: 0 };
    state.rows.forEach(function (row) { row.cells.forEach(function (c) { k[c.t]++; }); });
    k.total = k.S + k.V + k.U + 2 * k.C;
    return k;
  }

  function showMsg(type, text) {
    msg.className = 'alert alert-' + type + ' le-msg';
    msg.textContent = text;
    msg.hidden = false;
  }
  function hideMsg() { msg.hidden = true; }

  /* ---------- vẽ sơ đồ (luôn căn giữa nhờ flex: hàng ngắn tự vào giữa, 2 lối đi bám hai bên khối ghế) ---------- */
  function seatButton(c, number, extraClass) {
    var b = document.createElement('button');
    b.type = 'button';
    b.className = 'seat' + (extraClass || '');
    if (c.t === 'V') b.setAttribute('data-type', 'VIP');
    else if (c.t === 'C') b.setAttribute('data-type', 'Couple');
    else if (c.t === 'U') b.className += ' t-Unassigned';
    if (selected[c.id]) b.className += ' le-sel';
    if (missing[c.id]) b.className += ' le-missing';
    if (openId === c.id) b.className += ' le-open';
    b.setAttribute('data-cell', c.id);
    b.textContent = number;
    return b;
  }

  function render() {
    rowsBox.textContent = '';
    state.rows.forEach(function (row, r) {
      var label = String.fromCharCode(65 + r);
      var line = document.createElement('div');
      line.className = 'sp-line';
      line.setAttribute('data-row', label);
      var seatRow = document.createElement('div');
      seatRow.className = 'seat-row';
      var l1 = document.createElement('span'), l2 = document.createElement('span');
      l1.className = l2.className = 'row-label';
      l1.textContent = l2.textContent = label;
      seatRow.appendChild(l1);
      var n = 1;
      row.cells.forEach(function (c) {
        if (c.t === 'C') {
          var left = seatButton(c, n, ' pair-l'), right = seatButton(c, n + 1, ' pair-r');
          var title = 'Ghế đôi ' + label + n + '–' + label + (n + 1);
          left.title = right.title = title;
          seatRow.appendChild(left); seatRow.appendChild(right);
          n += 2;
        } else {
          var b = seatButton(c, n);
          b.title = label + n + ' · ' + TYPE_LABEL[c.t];
          seatRow.appendChild(b);
          n++;
        }
      });
      seatRow.appendChild(l2);
      line.appendChild(seatRow);
      rowsBox.appendChild(line);
    });
    var k = counts();
    document.getElementById('stS').textContent = k.S;
    document.getElementById('stV').textContent = k.V;
    document.getElementById('stC').textContent = k.C;
    document.getElementById('stU').textContent = k.U;
    document.getElementById('stT').textContent = k.total;
    var nSel = Object.keys(selected).length;
    bulkCount.textContent = nSel ? 'Đã chọn ' + nSel + ' ghế' : 'Kéo chuột để quét chọn một vùng ghế';
  }

  /* ---------- tạo lưới ---------- */
  function generate(rows, cols) {
    state = { cols: cols, rows: [] };
    for (var r = 0; r < rows; r++) {
      var cells = [];
      for (var c = 0; c < cols; c++) cells.push(cell(c, 'U'));
      state.rows.push({ cells: cells });
    }
    selected = {}; missing = {}; openId = null;
    work.hidden = false;
    hideMsg();
    render();
  }

  /* Nạp lại layout đã vẽ (khi server báo lỗi lúc lưu). */
  function load(data) {
    var rows = data.split('/'), cols = 0;
    state = { cols: 0, rows: [] };
    rows.forEach(function (r) {
      var cells = [], col = 0;
      for (var i = 0; i < r.length; i++) {
        var ch = r.charAt(i);
        if (ch === 'C' && r.charAt(i + 1) === 'C') { cells.push(cell(col, 'C')); col += 2; i++; }
        else { cells.push(cell(col, ch === 'V' ? 'V' : ch === 'S' ? 'S' : 'U')); col++; }
      }
      cols = Math.max(cols, col);
      if (cells.length) state.rows.push({ cells: cells });
    });
    state.cols = cols;
    rowsIn.value = state.rows.length;
    colsIn.value = cols;
    work.hidden = false;
    render();
  }

  function isDirty() {
    return state.rows.some(function (row) {
      return row.cells.length !== state.cols || row.cells.some(function (c) { return c.t !== 'U'; });
    });
  }

  document.getElementById('btnGrid').addEventListener('click', function () {
    var rows = parseInt(rowsIn.value, 10), cols = parseInt(colsIn.value, 10);
    if (!(rows >= 1 && rows <= MAX_ROWS)) { work.hidden = false; showMsg('error', 'Số hàng phải từ 1 đến ' + MAX_ROWS + ' (A–Z).'); return; }
    if (!(cols >= 1 && cols <= MAX_COLS)) { work.hidden = false; showMsg('error', 'Số cột phải từ 1 đến ' + MAX_COLS + '.'); return; }
    if (rows * cols > MAX_SEATS) { work.hidden = false; showMsg('error', 'Lưới ' + rows + ' × ' + cols + ' = ' + rows * cols + ' ghế, vượt quá tối đa ' + MAX_SEATS + ' ghế.'); return; }
    if (state.rows.length && isDirty() && !confirm('Tạo lưới mới sẽ xóa sơ đồ đang chỉnh. Tiếp tục?')) return;
    generate(rows, cols);
  });

  /* ---------- thao tác trên một ghế ---------- */
  function setType(id, t) {
    var p = find(id);
    if (!p) return;
    var cells = state.rows[p.r].cells, c = p.c;
    delete missing[id];
    if (c.t === 'C') {
      if (t === 'C') return;
      /* Tách ghế đôi thành 2 ghế đơn cùng loại vừa chọn. */
      cells.splice(p.i, 1, cell(c.col, t), cell(c.col + 1, t));
      showMsg('success', 'Đã tách ghế đôi thành 2 ghế ' + (t === 'V' ? 'VIP' : 'thường') + '.');
    } else if (t === 'C') {
      var right = cells[p.i + 1], reason = null;
      if (!right) reason = c.col >= state.cols - 1 ? 'ghế ở cuối hàng, không còn ghế bên phải' : 'ghế bên phải đã bị xóa';
      else if (right.col !== c.col + 1) reason = 'ghế bên phải đã bị xóa';
      else if (right.t === 'C') reason = 'ghế bên phải đã là ghế đôi';
      if (reason) { showMsg('error', 'Không thể ghép ghế đôi: ' + reason + '.'); return; }
      delete selected[right.id]; delete missing[right.id];
      cells.splice(p.i, 2, cell(c.col, 'C'));
      showMsg('success', 'Đã ghép ghế ' + labelOf(p) + ' với ghế bên phải thành 1 ghế đôi.');
    } else {
      c.t = t;
      hideMsg();
    }
    delete selected[id];
    render();
  }

  function removeSeat(id) {
    var p = find(id);
    if (!p || p.c.t === 'C') return;
    var label = labelOf(p);
    state.rows[p.r].cells.splice(p.i, 1);
    if (!state.rows[p.r].cells.length) state.rows.splice(p.r, 1);   /* hàng trống: bỏ hàng, các hàng sau dồn lên */
    delete selected[id]; delete missing[id];
    showMsg('info', 'Đã xóa ghế ' + label + '. Các ghế còn lại trong hàng đã dồn lại và căn giữa.');
    render();
  }

  /* ---------- menu chọn loại ghế ---------- */
  function closePop() {
    if (openId === null) return;
    pop.hidden = true;
    openId = null;
    render();
  }

  function popItem(text, icon, onClick, opts) {
    var b = document.createElement('button');
    b.type = 'button';
    b.setAttribute('role', 'menuitem');
    if (icon !== null) { var i = document.createElement('i'); if (icon) i.className = icon; b.appendChild(i); }
    b.appendChild(document.createTextNode(text));
    if (opts && opts.on) b.className = 'on';
    if (opts && opts.cls) b.className += ' ' + opts.cls;
    if (opts && opts.disabled) b.disabled = true;
    b.addEventListener('click', function () { pop.hidden = true; openId = null; onClick(); });
    pop.appendChild(b);
  }

  function openPop(id, anchor) {
    var p = find(id);
    if (!p) return;
    openId = id;
    pop.textContent = '';
    var h = document.createElement('h4');
    h.textContent = (p.c.t === 'C' ? 'Ghế đôi ' : 'Ghế ') + labelOf(p) + ' · ' + TYPE_LABEL[p.c.t];
    pop.appendChild(h);
    if (p.c.t === 'C') {
      popItem('Đổi về ghế thường (tách 2 ghế)', '', function () { setType(id, 'S'); });
      popItem('Đổi về ghế VIP (tách 2 ghế)', 'v', function () { setType(id, 'V'); });
      pop.appendChild(document.createElement('hr'));
      popItem('Xóa ghế', null, function () {}, { disabled: true, cls: 'del' });
      var s = document.createElement('small');
      s.textContent = 'Muốn xóa ghế đôi, hãy đổi về ghế đơn trước.';
      pop.appendChild(s);
    } else {
      popItem('Ghế thường', '', function () { setType(id, 'S'); }, { on: p.c.t === 'S' });
      popItem('Ghế VIP', 'v', function () { setType(id, 'V'); }, { on: p.c.t === 'V' });
      popItem('Ghế đôi (ghép với ghế bên phải)', 'c', function () { setType(id, 'C'); });
      pop.appendChild(document.createElement('hr'));
      popItem('Xóa ghế', null, function () { removeSeat(id); }, { cls: 'del' });
    }
    pop.hidden = false;
    var r = anchor.getBoundingClientRect();
    var left = r.left + window.scrollX, top = r.bottom + window.scrollY + 6;
    var w = pop.offsetWidth;
    left = Math.max(8, Math.min(left, window.scrollX + document.documentElement.clientWidth - w - 8));
    pop.style.left = left + 'px';
    pop.style.top = top + 'px';
    render();
  }

  rowsBox.addEventListener('click', function (e) {
    if (bulk) return;                                      /* chế độ Sửa nhiều xử lý ở pointerup */
    var b = e.target.closest('button.seat');
    if (!b) return;
    e.stopPropagation();
    var id = +b.getAttribute('data-cell');
    if (openId === id) { closePop(); return; }
    openPop(id, b);
  });
  document.addEventListener('mousedown', function (e) {
    if (openId !== null && !pop.contains(e.target) && !e.target.closest('#leRows button.seat')) closePop();
  });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closePop(); });
  window.addEventListener('resize', function () { if (openId !== null) closePop(); });

  /* ---------- chế độ Sửa nhiều: kéo chuột quét vùng chữ nhật ---------- */
  function setBulk(on) {
    bulk = on;
    btnBulk.setAttribute('aria-pressed', on ? 'true' : 'false');
    btnBulk.textContent = on ? 'Tắt sửa nhiều' : 'Sửa nhiều';
    bulkBar.hidden = !on;
    stage.classList.toggle('bulk', on);
    if (!on) selected = {};
    closePop();
    hideMsg();
    if (on) showMsg('info', 'Sửa nhiều: nhấn giữ và kéo chuột để quét chọn ghế, rồi gán Thường hoặc VIP cho cả vùng. Ghế đôi phải chỉnh từng ghế.');
    render();
  }
  btnBulk.addEventListener('click', function () { setBulk(!bulk); });

  var drag = null;
  stage.addEventListener('pointerdown', function (e) {
    if (!bulk || e.button !== 0) return;
    var s = stage.getBoundingClientRect();
    drag = { x: e.clientX, y: e.clientY, sx: s.left, sy: s.top, moved: false, target: e.target.closest('button.seat') };
    stage.setPointerCapture(e.pointerId);
    e.preventDefault();
  });
  stage.addEventListener('pointermove', function (e) {
    if (!drag) return;
    var x1 = Math.min(drag.x, e.clientX), y1 = Math.min(drag.y, e.clientY);
    var x2 = Math.max(drag.x, e.clientX), y2 = Math.max(drag.y, e.clientY);
    if (!drag.moved && x2 - x1 < 4 && y2 - y1 < 4) return;
    drag.moved = true;
    drag.box = { l: x1, t: y1, r: x2, b: y2 };
    marquee.hidden = false;
    marquee.style.left = (x1 - drag.sx) + 'px';
    marquee.style.top = (y1 - drag.sy) + 'px';
    marquee.style.width = (x2 - x1) + 'px';
    marquee.style.height = (y2 - y1) + 'px';
  });
  function endDrag() {
    if (!drag) return;
    var d = drag;
    drag = null;
    marquee.hidden = true;
    var skipped = 0, added = 0;
    if (!d.moved) {
      /* bấm một ghế: bật/tắt chọn */
      if (d.target) {
        var id = +d.target.getAttribute('data-cell'), p = find(id);
        if (p && p.c.t === 'C') skipped++;
        else if (p) { if (selected[id]) delete selected[id]; else { selected[id] = true; added++; } }
      }
    } else {
      var seen = {};
      Array.prototype.forEach.call(rowsBox.querySelectorAll('button.seat'), function (b) {
        var r = b.getBoundingClientRect();
        if (r.right < d.box.l || r.left > d.box.r || r.bottom < d.box.t || r.top > d.box.b) return;
        var id = +b.getAttribute('data-cell');
        if (seen[id]) return;
        seen[id] = true;
        var p = find(id);
        if (!p) return;
        if (p.c.t === 'C') skipped++;
        else if (!selected[id]) { selected[id] = true; added++; }
      });
    }
    if (skipped) showMsg('info', 'Bỏ qua ' + skipped + ' ghế đôi: chế độ Sửa nhiều chỉ gán Thường/VIP, ghế đôi phải chỉnh từng ghế.');
    else if (added) hideMsg();
    render();
  }
  stage.addEventListener('pointerup', endDrag);
  stage.addEventListener('pointercancel', endDrag);

  Array.prototype.forEach.call(bulkBar.querySelectorAll('[data-bulk]'), function (btn) {
    btn.addEventListener('click', function () {
      var t = btn.getAttribute('data-bulk'), n = 0;
      Object.keys(selected).forEach(function (key) {
        var p = find(+key);
        if (p && p.c.t !== 'C') { p.c.t = t; delete missing[p.c.id]; n++; }
      });
      selected = {};
      if (n) showMsg('success', 'Đã gán ' + n + ' ghế thành ' + (t === 'V' ? 'ghế VIP' : 'ghế thường') + '.');
      else showMsg('error', 'Chưa chọn ghế nào. Hãy kéo chuột để quét chọn một vùng ghế.');
      render();
    });
  });
  document.getElementById('btnBulkClear').addEventListener('click', function () { selected = {}; hideMsg(); render(); });

  /* ---------- lưu layout ---------- */
  saveForm.addEventListener('submit', function (e) {
    var name = nameIn.value.trim(), k = counts(), err = null;
    var old = document.getElementById('serverErr');
    if (old) old.remove();
    if (!state.rows.length || k.total === 0) err = 'Layout chưa có ghế nào. Hãy tạo lưới ghế trước.';
    else if (k.U > 0) {
      missing = {};
      state.rows.forEach(function (row) { row.cells.forEach(function (c) { if (c.t === 'U') missing[c.id] = true; }); });
      err = 'Còn ' + k.U + ' ghế chưa gán loại (đang được đánh dấu đỏ). Hãy gán loại cho tất cả ghế trước khi lưu.';
    } else if (k.total > MAX_SEATS) err = 'Layout tối đa ' + MAX_SEATS + ' ghế (đang có ' + k.total + ').';
    else if (!name) err = 'Vui lòng đặt tên cho layout.';
    else if (existingNames.indexOf(name.toLowerCase()) >= 0) err = 'Tên layout "' + name + '" đã có trong thư viện. Hãy đặt tên khác.';
    if (err) {
      e.preventDefault();
      showMsg('error', err);
      render();
      if (k.U > 0) stage.scrollIntoView({ behavior: 'smooth', block: 'center' });
      else if (!name || existingNames.indexOf(name.toLowerCase()) >= 0) nameIn.focus();
      return;
    }
    document.getElementById('layoutData').value = state.rows.map(function (row) {
      return row.cells.map(function (c) { return c.t === 'C' ? 'CC' : c.t; }).join('');
    }).join('/');
  });

  /* ---------- mở / đóng trình tạo ---------- */
  function openEditor() {
    editor.hidden = false;
    editor.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
  document.getElementById('btnNewLayout').addEventListener('click', openEditor);
  document.getElementById('btnCloseEditor').addEventListener('click', function () { closePop(); editor.hidden = true; });

  if (editor.getAttribute('data-open') === 'true') {
    editor.hidden = false;
    var initial = editor.getAttribute('data-initial') || '';
    if (initial) load(initial);
    setTimeout(function () { editor.scrollIntoView({ block: 'start' }); }, 0);
  }
})();
