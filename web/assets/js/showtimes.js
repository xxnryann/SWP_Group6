(function () {
  document.querySelectorAll('[data-showtime-info]').forEach(function (button) {
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
