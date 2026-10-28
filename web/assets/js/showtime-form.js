(function () {
  var form = document.getElementById('showtime-form');
  if (!form) return;

  var movieSelect = document.getElementById('movieId');
  var roomSelect = document.getElementById('roomName');
  var dateInput = document.getElementById('showDate');
  var startSelect = document.getElementById('startTime');
  var endSelect = document.getElementById('endTime');
  var message = document.getElementById('showtime-availability-message');
  var durationMessage = document.getElementById('showtime-duration-message');
  var requestNumber = 0;
  var currentStart = startSelect.dataset.currentTime;
  var currentEnd = endSelect.dataset.currentTime;

  function toMinutes(value) {
    var parts = value.split(':').map(Number);
    return parts[0] * 60 + parts[1];
  }

  function toTime(minutes) {
    return String(Math.floor(minutes / 60)).padStart(2, '0') + ':' +
      String(minutes % 60).padStart(2, '0');
  }

  function resetEnd(label) {
    endSelect.replaceChildren(new Option(label, ''));
    endSelect.value = '';
  }

  function loadEndTimes() {
    var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
    var duration = Number(selectedMovie && selectedMovie.dataset.duration);
    var start = startSelect.value;
    resetEnd(start ? 'Chọn giờ kết thúc' : 'Chọn giờ bắt đầu trước');
    if (!start || !duration) {
      durationMessage.textContent = '';
      return;
    }
    var minimumEnd = toMinutes(start) + duration;
    var firstEnd = Math.ceil(minimumEnd / 5) * 5;
    for (var end = firstEnd; end <= 24 * 60; end += 5) {
      endSelect.add(new Option(toTime(end), toTime(end)));
    }
    if (currentEnd && endSelect.querySelector('option[value="' + currentEnd + '"]')) {
      endSelect.value = currentEnd;
    }
    currentEnd = '';
    durationMessage.textContent = 'Phim dài ' + duration + ' phút; có thể cộng thêm thời gian đệm.';
  }

  function resetStarts(label) {
    startSelect.replaceChildren(new Option(label, ''));
    startSelect.value = '';
    resetEnd('Chọn giờ bắt đầu trước');
  }

  async function loadAvailableTimes() {
    var requestId = ++requestNumber;
    var movieId = movieSelect.value;
    var roomName = roomSelect.value;
    var date = dateInput.value;
    if (!movieId || !roomName || !date) {
      resetStarts('Chọn phim, phòng và ngày trước');
      message.textContent = 'Chọn phim, phòng và ngày để tải giờ còn trống.';
      return;
    }
    if (dateInput.min && date < dateInput.min) {
      resetStarts('Ngày chiếu đã qua');
      message.textContent = 'Ngày chiếu đã qua. Vui lòng chọn hôm nay hoặc một ngày trong tương lai.';
      return;
    }

    resetStarts('Đang kiểm tra giờ trống…');
    message.textContent = 'Đang kiểm tra lịch chiếu của phòng...';
    var url = new URL(form.dataset.availabilityUrl, window.location.href);
    url.searchParams.set('action', 'available-times');
    url.searchParams.set('movieId', movieId);
    url.searchParams.set('roomName', roomName);
    url.searchParams.set('date', date);
    var showtimeId = form.querySelector('input[name="id"]');
    if (showtimeId) url.searchParams.set('id', showtimeId.value);

    try {
      var response = await fetch(url, { credentials: 'same-origin' });
      if (!response.ok) throw new Error('Không thể kiểm tra giờ chiếu còn trống.');
      var times = await response.json();
      if (requestId !== requestNumber) return;
      resetStarts(times.length ? 'Chọn giờ bắt đầu' : 'Không còn giờ phù hợp');
      times.forEach(function (time) {
        startSelect.add(new Option(time, time));
      });
      if (currentStart && times.indexOf(currentStart) !== -1) {
        startSelect.value = currentStart;
      }
      currentStart = '';
      message.textContent = times.length
        ? 'Chọn giờ bắt đầu theo mốc 5 phút, sau đó chọn giờ kết thúc.'
        : 'Không có giờ trống phù hợp trong phòng này.';
      loadEndTimes();
    } catch (error) {
      if (requestId !== requestNumber) return;
      resetStarts('Không tải được giờ chiếu');
      message.textContent = error.message;
    }
  }

  [movieSelect, roomSelect, dateInput].forEach(function (control) {
    control.addEventListener('change', loadAvailableTimes);
  });
  startSelect.addEventListener('change', loadEndTimes);
  loadAvailableTimes();
})();
