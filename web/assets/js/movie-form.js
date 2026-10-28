"use strict";

document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("movie-form");
  if (!form) return;

  const posterInput = document.getElementById("posterFile");
  const posterPreview = document.getElementById("poster-preview");
  const posterEmpty = document.getElementById("poster-preview-empty");
  const trailerInput = document.getElementById("trailerFile");
  const releaseDate = document.getElementById("releaseDate");
  const endDate = document.getElementById("endDate");
  let automaticEndDate = "";
  let endDateManuallyEdited = false;

  const oneMonthAfter = (value) => {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (!match) return "";
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;
    const lastDay = new Date(nextYear, nextMonth, 0).getDate();
    return `${nextYear}-${String(nextMonth).padStart(2, "0")}-${String(Math.min(day, lastDay)).padStart(2, "0")}`;
  };

  const updateDefaultEndDate = () => {
    if (endDateManuallyEdited) return;
    automaticEndDate = oneMonthAfter(releaseDate.value);
    endDate.value = automaticEndDate;
  };

  automaticEndDate = oneMonthAfter(releaseDate.value);
  endDateManuallyEdited = endDate.value !== "" && endDate.value !== automaticEndDate;
  updateDefaultEndDate();
  releaseDate.addEventListener("change", updateDefaultEndDate);
  endDate.addEventListener("input", () => {
    endDateManuallyEdited = endDate.value !== automaticEndDate;
  });

  const validateFile = (input, extensions, label) => {
    if (!input) return true;
    const file = input.files && input.files[0];
    if (!file) return true;
    const extension = file.name.split(".").pop().toLowerCase();
    const maxBytes = Number(input.dataset.maxBytes);
    if (!extensions.includes(extension)) {
      input.setCustomValidity(`${label}: định dạng tệp không được hỗ trợ.`);
      input.reportValidity();
      input.setCustomValidity("");
      input.value = "";
      return false;
    }
    if (file.size > maxBytes) {
      input.setCustomValidity(`${label}: tệp vượt quá giới hạn cho phép.`);
      input.reportValidity();
      input.setCustomValidity("");
      input.value = "";
      return false;
    }
    return true;
  };

  if (posterInput) {
    posterInput.addEventListener("change", () => {
      if (!validateFile(posterInput, ["jpg", "jpeg", "png", "webp"], "Poster")) return;
      const file = posterInput.files[0];
      if (!file) return;
      posterPreview.src = URL.createObjectURL(file);
      posterPreview.hidden = false;
      posterEmpty.hidden = true;
    });
  }

  if (trailerInput) {
    trailerInput.addEventListener("change", () => {
      validateFile(trailerInput, ["mp4", "webm"], "Video trailer");
    });
  }

  form.addEventListener("submit", (event) => {
    if (!validateFile(posterInput, ["jpg", "jpeg", "png", "webp"], "Poster")
        || !validateFile(trailerInput, ["mp4", "webm"], "Video trailer")) {
      event.preventDefault();
      return;
    }
    if (releaseDate.value && endDate.value && endDate.value < releaseDate.value) {
      endDate.setCustomValidity("Ngày kết thúc không được trước ngày khởi chiếu.");
      endDate.reportValidity();
      endDate.setCustomValidity("");
      event.preventDefault();
    }
  });
});
