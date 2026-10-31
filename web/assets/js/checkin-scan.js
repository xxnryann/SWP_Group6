/* Soát vé: đọc mã QR từ camera hoặc từ ảnh rồi gửi form. Máy quét USB nhập như bàn phím nên dùng ô nhập sẵn có. */
(function () {
  var form = document.getElementById('checkinForm');
  var input = document.getElementById('ticketCode');
  var cameraBtn = document.getElementById('qrCameraBtn');
  var imageInput = document.getElementById('qrImage');
  var statusEl = document.getElementById('qrStatus');
  var video = document.getElementById('qrVideo');
  var canvas = document.createElement('canvas');
  var context = canvas.getContext('2d', { willReadFrequently: true });

  var CAMERA_FLAG = 'checkinCameraOn';
  var LAST_CODE = 'checkinLastCode';
  var LAST_TIME = 'checkinLastTime';
  var SAME_CODE_PAUSE_MS = 5000;   // vé vừa soát vẫn còn trước camera: chưa đọc lại ngay
  var stream = null;

  // Máy quét USB gõ đè lên mã cũ thay vì nối thêm vào cuối.
  input.select();

  function setStatus(text) {
    statusEl.textContent = text;
  }

  function decode(width, height) {
    var image = context.getImageData(0, 0, width, height);
    var result = window.jsQR(image.data, width, height, { inversionAttempts: 'attemptBoth' });
    return result && result.data ? result.data.trim() : '';
  }

  function submitCode(code) {
    sessionStorage.setItem(LAST_CODE, code);
    sessionStorage.setItem(LAST_TIME, String(Date.now()));
    input.value = code;
    form.submit();
  }

  function isJustScanned(code) {
    return code === sessionStorage.getItem(LAST_CODE)
        && Date.now() - Number(sessionStorage.getItem(LAST_TIME) || 0) < SAME_CODE_PAUSE_MS;
  }

  function stopCamera() {
    if (stream) stream.getTracks().forEach(function (track) { track.stop(); });
    stream = null;
    video.hidden = true;
    cameraBtn.textContent = 'Quét bằng camera';
  }

  function scanFrame() {
    if (!stream) return;
    if (video.readyState === video.HAVE_ENOUGH_DATA) {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      var code = decode(canvas.width, canvas.height);
      if (code && !isJustScanned(code)) {
        setStatus('Đã đọc mã ' + code);
        stopCamera();
        submitCode(code);
        return;
      }
    }
    requestAnimationFrame(scanFrame);
  }

  function startCamera() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      setStatus('Trình duyệt chỉ cho dùng camera trên HTTPS hoặc localhost. Hãy chọn ảnh mã QR hoặc dùng máy quét.');
      sessionStorage.removeItem(CAMERA_FLAG);
      return;
    }
    navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } }).then(function (media) {
      stream = media;
      video.srcObject = media;
      video.hidden = false;
      cameraBtn.textContent = 'Tắt camera';
      sessionStorage.setItem(CAMERA_FLAG, '1');
      setStatus('Đưa mã QR vào khung hình.');
      return video.play();
    }).then(function () {
      requestAnimationFrame(scanFrame);
    }).catch(function () {
      stopCamera();
      sessionStorage.removeItem(CAMERA_FLAG);
      setStatus('Không mở được camera. Hãy cấp quyền camera, chọn ảnh mã QR hoặc dùng máy quét.');
    });
  }

  cameraBtn.addEventListener('click', function () {
    if (stream) {
      stopCamera();
      sessionStorage.removeItem(CAMERA_FLAG);
      setStatus('');
    } else {
      startCamera();
    }
  });

  imageInput.addEventListener('change', function () {
    var file = imageInput.files[0];
    if (!file) return;
    var url = URL.createObjectURL(file);
    var image = new Image();
    image.onload = function () {
      canvas.width = image.naturalWidth;
      canvas.height = image.naturalHeight;
      context.drawImage(image, 0, 0);
      URL.revokeObjectURL(url);
      var code = decode(canvas.width, canvas.height);
      if (code) submitCode(code);
      else setStatus('Không đọc được mã QR trong ảnh này.');
    };
    image.onerror = function () {
      URL.revokeObjectURL(url);
      setStatus('File đã chọn không phải ảnh hợp lệ.');
    };
    image.src = url;
    imageInput.value = '';
  });

  // Tiếp tục quét vé kế tiếp sau khi trang tải lại, nếu nhân viên chưa tắt camera.
  if (sessionStorage.getItem(CAMERA_FLAG)) startCamera();
})();
