(function () {
  var form = document.getElementById('showtime-form');
  if (!form) return;

  var movieSelect = document.getElementById('movieId');
  var roomSelect = document.getElementById('roomName');
  var dateInput = document.getElementById('showDate');
  var timeSelect = document.getElementById('showTime');
  var message = document.getElementById('showtime-availability-message');
  var estimatedEnd = document.getElementById('showtime-estimated-end');
  var requestNumber = 0;
  var currentTime = timeSelect.dataset.currentTime;

  function endTimeLabel(start, duration) {
    var parts = start.split(':').map(Number);
    var endMinutes = parts[0] * 60 + parts[1] + duration;
    return String(Math.floor(endMinutes / 60)).padStart(2, '0')
      + ':' + String(endMinutes % 60).padStart(2, '0');
  }

  function updateEstimatedEnd() {
    var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
    var duration = Number(selectedMovie && selectedMovie.dataset.duration);
    var selectedStart = timeSelect.querySelector('input[name="showTime"]:checked');
    var start = selectedStart ? selectedStart.value : '';
    if (!start || !duration) {
      estimatedEnd.textContent = '';
      return;
    }
    estimatedEnd.textContent = 'Kết thúc dự kiến: ' + endTimeLabel(start, duration);
  }

  async function loadAvailableTimes() {
    var requestId = ++requestNumber;
    var movieId = movieSelect.value;
    var roomNames = Array.from(roomSelect.querySelectorAll('input[name="roomName"]:checked')).map(function (input) { return input.value; });
    var date = dateInput.value;
    if (!movieId || !roomNames.length || !date) {
      timeSelect.replaceChildren(new Option('Chọn phim, phòng và ngày trước', ''));
      message.textContent = 'Chọn phim, phòng và ngày để tải giờ còn trống.';
      return;
    }

    if (dateInput.min && date < dateInput.min) {
      timeSelect.replaceChildren(new Option('Ngày chiếu đã qua', ''));
      message.textContent = 'Ngày chiếu đã qua. Vui lòng chọn hôm nay hoặc một ngày trong tương lai.';
      return;
    }

    timeSelect.replaceChildren(new Option('Đang kiểm tra giờ trống…', ''));
    message.textContent = 'Đang kiểm tra lịch chiếu của phòng...';
    var url = new URL(form.dataset.availabilityUrl, window.location.href);
    url.searchParams.set('action', 'available-times');
    url.searchParams.set('_ts', String(Date.now()));
    url.searchParams.set('movieId', movieId);
    var showtimeId = form.querySelector('input[name="id"]');

    try {
      var responses = await Promise.all(roomNames.map(function (roomName) {
        var roomUrl = new URL(url);
        roomUrl.searchParams.set('roomName', roomName);
        roomUrl.searchParams.set('date', date);
        if (showtimeId) roomUrl.searchParams.set('id', showtimeId.value);
        return fetch(roomUrl, { credentials: 'same-origin', cache: 'no-store' }).then(function (response) {
          if (response.status === 401) {
            throw new Error('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
          }
          if (!response.ok) throw new Error('Không thể kiểm tra giờ chiếu còn trống (HTTP ' + response.status + ').');
          return response.json();
        });
      }));
      var times = [];
      responses.forEach(function (roomTimes) {
        roomTimes.forEach(function (time) {
          if (times.indexOf(time) === -1) times.push(time);
        });
      });
      times.sort();
      if (requestId !== requestNumber) return;

      timeSelect.replaceChildren();
      var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
      var duration = Number(selectedMovie.dataset.duration);
      times.forEach(function (time) {
        var end = endTimeLabel(time, duration);
        var label = document.createElement('label');
        label.className = 'check';
        label.innerHTML = '<input type="checkbox" name="showTime" value="' + time + '"><span>' + time + ' – ' + end + '</span>';
        timeSelect.appendChild(label);
      });
      if (currentTime && times.indexOf(currentTime) !== -1) {
        var current = timeSelect.querySelector('input[value="' + currentTime + '"]');
        if (current) current.checked = true;
      }
      currentTime = '';
      message.textContent = times.length
        ? 'Đã hiển thị các giờ trống theo thời lượng phim và thời gian dọn phòng.'
        : 'Không có giờ trống chung cho các phòng đã chọn.';
      updateEstimatedEnd();
    } catch (error) {
      if (requestId !== requestNumber) return;
      timeSelect.replaceChildren(new Option('Không tải được giờ chiếu', ''));
      updateEstimatedEnd();
      message.textContent = error.message;
    }
  }

  movieSelect.addEventListener('change', loadAvailableTimes);
  dateInput.addEventListener('change', loadAvailableTimes);
  roomSelect.addEventListener('change', loadAvailableTimes);
  roomSelect.addEventListener('click', function (event) {
    if (event.target.matches('input[name="roomName"]')) {
      window.setTimeout(loadAvailableTimes, 0);
    }
  });
  timeSelect.addEventListener('change', updateEstimatedEnd);
  loadAvailableTimes();
})();
