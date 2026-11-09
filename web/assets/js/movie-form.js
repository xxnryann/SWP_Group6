"use strict";

document.addEventListener("DOMContentLoaded", () => {
  const form = document.getElementById("movie-form");
  if (!form) return;

  const trailerUrlInput = document.getElementById("trailerUrl");
  const trailerPreview = document.getElementById("trailer-url-preview");
  const trailerFrame = document.getElementById("trailer-url-frame");
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

  const youtubeEmbedUrl = (value) => {
    try {
      const url = new URL(value.trim());
      const host = url.hostname.toLowerCase();
      let id = "";
      if (host === "youtu.be" || host === "www.youtu.be") {
        id = url.pathname.substring(1).split("/")[0];
      } else if (["youtube.com", "www.youtube.com", "m.youtube.com",
        "youtube-nocookie.com", "www.youtube-nocookie.com"].includes(host)) {
        if (url.pathname === "/watch") id = url.searchParams.get("v") || "";
        else if (url.pathname.startsWith("/embed/")) id = url.pathname.substring(7).split("/")[0];
        else if (url.pathname.startsWith("/shorts/")) id = url.pathname.substring(7).split("/")[0];
      }
      return /^[A-Za-z0-9_-]{6,20}$/.test(id)
        ? `https://www.youtube-nocookie.com/embed/${id}`
        : "";
    } catch (error) {
      return "";
    }
  };

  const updateTrailerPreview = () => {
    if (!trailerUrlInput || !trailerPreview || !trailerFrame) return;
    const embedUrl = youtubeEmbedUrl(trailerUrlInput.value);
    trailerFrame.src = embedUrl;
    trailerPreview.hidden = !embedUrl;
  };

  if (trailerUrlInput) {
    trailerUrlInput.addEventListener("input", updateTrailerPreview);
    updateTrailerPreview();
  }

  form.addEventListener("submit", (event) => {
    if (releaseDate.value && endDate.value && endDate.value < releaseDate.value) {
      endDate.setCustomValidity("Ngày kết thúc không được trước ngày khởi chiếu.");
      endDate.reportValidity();
      endDate.setCustomValidity("");
      event.preventDefault();
    }
    const genres = form.querySelectorAll('input[name="genreIds"]');
    if (genres.length > 0 && !Array.from(genres).some((input) => input.checked)) {
      event.preventDefault();
      genres[0].setCustomValidity("Hãy chọn ít nhất một thể loại phim.");
      genres[0].reportValidity();
      genres[0].setCustomValidity("");
    }
  });
});
