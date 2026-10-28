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
    var start = timeSelect.value;
    if (!start || !duration) {
      estimatedEnd.textContent = '';
      return;
    }
    estimatedEnd.textContent = 'Kết thúc dự kiến: ' + endTimeLabel(start, duration);
  }

  function resetOptions(label) {
    timeSelect.replaceChildren(new Option(label, ''));
    timeSelect.value = '';
    updateEstimatedEnd();
  }

  async function loadAvailableTimes() {
    var requestId = ++requestNumber;
    var movieId = movieSelect.value;
    var roomName = roomSelect.value;
    var date = dateInput.value;
    if (!movieId || !roomName || !date) {
      resetOptions('Chọn phim, phòng và ngày trước');
      message.textContent = 'Chọn phim, phòng và ngày để tải giờ còn trống.';
      return;
    }

    if (dateInput.min && date < dateInput.min) {
      resetOptions('Ngày chiếu đã qua');
      message.textContent = 'Ngày chiếu đã qua. Vui lòng chọn hôm nay hoặc một ngày trong tương lai.';
      return;
    }

    resetOptions('Đang kiểm tra giờ trống…');
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

      resetOptions(times.length ? 'Chọn giờ bắt đầu' : 'Không còn giờ phù hợp');
      var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
      var duration = Number(selectedMovie.dataset.duration);
      times.forEach(function (time) {
        var end = endTimeLabel(time, duration);
        var option = new Option(time + ' – ' + end, time);
        timeSelect.add(option);
      });
      if (currentTime && times.indexOf(currentTime) !== -1) {
        timeSelect.value = currentTime;
      }
      currentTime = '';
      message.textContent = times.length
        ? 'Các suất cách nhau 15 phút; giờ kết thúc dự kiến được tính theo thời lượng phim.'
        : 'Không có khung giờ trống phù hợp trong phòng này.';
      updateEstimatedEnd();
    } catch (error) {
      if (requestId !== requestNumber) return;
      resetOptions('Không tải được giờ chiếu');
      message.textContent = error.message;
    }
  }

  [movieSelect, roomSelect, dateInput].forEach(function (control) {
    control.addEventListener('change', loadAvailableTimes);
  });
  timeSelect.addEventListener('change', updateEstimatedEnd);
  loadAvailableTimes();
})();
