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

  function updateEstimatedEnd() {
    var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
    var duration = Number(selectedMovie && selectedMovie.dataset.duration);
    var start = timeSelect.value;
    if (!start || !duration) {
      estimatedEnd.textContent = '';
      return;
    }
    var parts = start.split(':').map(Number);
    var endMinutes = parts[0] * 60 + parts[1] + duration;
    var hours = String(Math.floor(endMinutes / 60)).padStart(2, '0');
    var minutes = String(endMinutes % 60).padStart(2, '0');
    estimatedEnd.textContent = 'Kết thúc dự kiến: ' + hours + ':' + minutes;
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
      var windows = {
        '09:00': '11:30',
        '11:45': '14:15',
        '14:30': '17:00',
        '17:15': '19:45',
        '20:00': '22:30'
      };
      times.forEach(function (time) {
        var selectedMovie = movieSelect.options[movieSelect.selectedIndex];
        var duration = Number(selectedMovie.dataset.duration);
        var parts = time.split(':').map(Number);
        var endMinutes = parts[0] * 60 + parts[1] + duration;
        var end = String(Math.floor(endMinutes / 60)).padStart(2, '0')
          + ':' + String(endMinutes % 60).padStart(2, '0');
        var option = new Option(time + ' – ' + windows[time] + ' (phim kết thúc dự kiến ' + end + ')', time);
        timeSelect.add(option);
      });
      if (currentTime && times.indexOf(currentTime) !== -1) {
        timeSelect.value = currentTime;
      }
      currentTime = '';
      message.textContent = times.length
        ? 'Chỉ có 5 khung giờ cố định; giờ kết thúc dự kiến được tính theo thời lượng phim.'
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
