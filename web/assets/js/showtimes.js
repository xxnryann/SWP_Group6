(function () {
  // Suất chiếu là liên kết tới màn hình chọn ghế (/booking/seats).
  // Modal chỉ còn ý nghĩa với các nút thông tin không điều hướng.
  document.querySelectorAll('button[data-showtime-info]').forEach(function (button) {
    button.addEventListener('click', function () {
      window.openModal(
        button.dataset.movie,
        'Bắt đầu: ' + button.dataset.start
          + ' · Kết thúc dự kiến: ' + button.dataset.end
          + ' · Phòng chiếu: ' + button.dataset.room
      );
    });
  });
})();
