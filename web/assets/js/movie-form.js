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

  // Ô ngôn ngữ: dropdown giống ô Quốc gia nhưng chọn được nhiều (giữ <select multiple> ẩn để gửi form).
  const languageSelect = form.querySelector('select[name="spokenLanguage"]');
  if (languageSelect) enhanceMultiSelect(languageSelect);
});

/**
 * Biến <select multiple> thành dropdown giống ô select thường: ô đóng hiện các mục đã chọn,
 * bấm mở danh sách và bấm từng dòng để chọn / bỏ chọn (không cần giữ Ctrl).
 * Select gốc vẫn nằm trong form (ẩn) nên server nhận dữ liệu như cũ.
 */
function enhanceMultiSelect(select) {
  const placeholder = select.dataset.placeholder || "Chọn";
  const wrap = document.createElement("div");
  wrap.className = "ms";
  const toggle = document.createElement("button");
  toggle.type = "button";
  toggle.className = "ms-toggle";
  toggle.setAttribute("aria-haspopup", "listbox");
  toggle.setAttribute("aria-expanded", "false");
  const panel = document.createElement("ul");
  panel.className = "ms-panel";
  panel.setAttribute("role", "listbox");
  panel.setAttribute("aria-multiselectable", "true");
  panel.hidden = true;

  Array.from(select.options).forEach((opt, i) => {
    const li = document.createElement("li");
    li.className = "ms-option";
    li.setAttribute("role", "option");
    li.dataset.index = String(i);
    li.tabIndex = -1;
    const box = document.createElement("span");
    box.className = "ms-box";
    box.setAttribute("aria-hidden", "true");
    li.append(box, document.createTextNode(opt.textContent.trim()));
    panel.appendChild(li);
  });

  const items = () => Array.from(panel.querySelectorAll(".ms-option"));
  const sync = () => {
    const picked = Array.from(select.options).filter((o) => o.selected).map((o) => o.textContent.trim());
    toggle.textContent = picked.length ? picked.join(", ") : placeholder;
    toggle.title = picked.join(", ");
    items().forEach((li) => {
      const on = select.options[Number(li.dataset.index)].selected;
      li.classList.toggle("is-selected", on);
      li.setAttribute("aria-selected", on ? "true" : "false");
    });
  };
  const open = (show) => {
    panel.hidden = !show;
    toggle.setAttribute("aria-expanded", show ? "true" : "false");
    wrap.classList.toggle("is-open", show);
  };
  const pick = (li) => {
    const opt = select.options[Number(li.dataset.index)];
    opt.selected = !opt.selected;
    select.dispatchEvent(new Event("change", { bubbles: true }));
    sync();
  };
  const focusFirst = () => {
    const first = panel.querySelector(".is-selected") || panel.querySelector(".ms-option");
    if (first) first.focus();
  };

  toggle.addEventListener("click", () => open(panel.hidden));
  toggle.addEventListener("keydown", (e) => {
    if (e.key === "ArrowDown" || e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      open(true);
      focusFirst();
    }
  });
  panel.addEventListener("click", (e) => {
    const li = e.target.closest(".ms-option");
    if (li) pick(li);
  });
  panel.addEventListener("keydown", (e) => {
    const list = items();
    const i = list.indexOf(document.activeElement);
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      e.preventDefault();
      const next = list[Math.max(0, Math.min(list.length - 1, i + (e.key === "ArrowDown" ? 1 : -1)))];
      if (next) next.focus();
    } else if ((e.key === " " || e.key === "Enter") && i >= 0) {
      e.preventDefault();
      pick(list[i]);
    } else if (e.key === "Escape" || e.key === "Tab") {
      open(false);
      if (e.key === "Escape") toggle.focus();
    }
  });
  document.addEventListener("click", (e) => {
    if (!wrap.contains(e.target)) open(false);
  });

  // Select gốc bị ẩn nên không dùng được required của trình duyệt -> tự kiểm tra khi gửi form.
  const required = select.required;
  select.required = false;
  if (required && select.form) {
    select.form.addEventListener("submit", (e) => {
      if (select.selectedOptions.length === 0) {
        e.preventDefault();
        wrap.classList.add("is-invalid");
        toggle.focus();
        open(true);
      }
    });
    select.addEventListener("change", () => wrap.classList.remove("is-invalid"));
  }

  select.parentNode.insertBefore(wrap, select);
  select.hidden = true;
  wrap.append(toggle, panel, select);
  if (select.id) {
    toggle.id = select.id + "-toggle";
    const label = document.querySelector('label[for="' + select.id + '"]');
    if (label) label.htmlFor = toggle.id;
  }
  sync();
}
