// Form suất chiếu — hình thức ngôn ngữ:
//  - Nguyên bản: âm thanh gốc, ngôn ngữ = ngôn ngữ gốc của phim (ngôn ngữ của quốc gia sản xuất).
//  - Phụ đề / Lồng tiếng: chỉ chọn ngôn ngữ KHÁC ngôn ngữ gốc (tiếng Việt + các ngôn ngữ của phim).
//    Ví dụ phim Việt Nam không có "Phụ đề Việt" hay "Lồng tiếng Việt".
//  - Suất mới: phim tiếng Việt gốc -> Nguyên bản; phim nước ngoài -> Lồng tiếng Việt (rạp ở Việt Nam).
document.addEventListener("DOMContentLoaded", () => {
  const movie = document.getElementById("movieId");
  const mode = document.getElementById("languageMode");
  const language = document.getElementById("language");
  const hint = document.getElementById("language-hint");
  if (!movie || !mode || !language) return;

  const VIETNAMESE = "Tiếng Việt";
  const isEdit = !!language.dataset.current;
  const short = (name) => (name.startsWith("Tiếng ") ? name.slice(6) : name);
  const selected = () => movie.options[movie.selectedIndex];
  const languagesOf = (o) => (o && o.dataset.languages ? o.dataset.languages : "")
    .split(",").map((s) => s.trim()).filter(Boolean);
  const originalOf = (o) => (o && o.dataset.original) || "";
  const origOption = mode.querySelector('option[value="Orig"]');

  const fillLanguages = (list, keep) => {
    language.innerHTML = "";
    const placeholder = document.createElement("option");
    placeholder.value = "";
    placeholder.textContent = !movie.value ? "Chọn phim trước" : (list.length ? "Chọn ngôn ngữ" : "Không có ngôn ngữ phù hợp");
    language.appendChild(placeholder);
    list.forEach((name) => {
      const o = document.createElement("option");
      o.value = name;
      o.textContent = short(name);
      language.appendChild(o);
    });
    if (list.includes(keep)) language.value = keep;
    else if (list.includes(VIETNAMESE)) language.value = VIETNAMESE;
    else if (list.length) language.value = list[0];
  };

  // Vẽ lại ô ngôn ngữ theo hình thức đang chọn.
  const renderLanguages = (keep) => {
    const option = selected();
    const original = originalOf(option);
    if (origOption) origOption.disabled = !original;
    if (mode.value === "Orig" && !original) mode.value = "Sub";
    let list;
    if (!movie.value) list = [];
    else if (mode.value === "Orig") list = [original];
    else list = languagesOf(option).filter((l) => l !== original);
    fillLanguages(list, keep);
    language.disabled = !list.length || mode.value === "Orig";
    // Ô bị khóa không được gửi đi -> giữ một bản ẩn để form vẫn có giá trị ngôn ngữ.
    let shadow = document.getElementById("language-shadow");
    if (mode.value === "Orig") {
      if (!shadow) {
        shadow = document.createElement("input");
        shadow.type = "hidden";
        shadow.id = "language-shadow";
        shadow.name = "language";
        language.after(shadow);
      }
      shadow.value = original;
    } else if (shadow) {
      shadow.remove();
    }
    if (hint) {
      if (!movie.value) hint.textContent = "Chọn phim để xem các ngôn ngữ.";
      else if (mode.value === "Orig") hint.textContent = "Nguyên bản: chiếu đúng âm thanh gốc " + short(original) + ", không phụ đề / lồng tiếng.";
      else if (!list.length) hint.textContent = "Phim chưa có ngôn ngữ nào khác ngôn ngữ gốc để " + (mode.value === "Dub" ? "lồng tiếng" : "làm phụ đề") + ".";
      else hint.textContent = (mode.value === "Dub" ? "Lồng tiếng" : "Phụ đề") + " phải khác ngôn ngữ gốc"
        + (original ? " (" + short(original) + ")" : "") + ". Chọn được: " + list.map(short).join(", ") + ".";
    }
  };

  // Suất mới: phim tiếng Việt gốc -> Nguyên bản; phim nước ngoài -> Lồng tiếng Việt.
  const applyDefaults = () => {
    const original = originalOf(selected());
    mode.value = original === VIETNAMESE ? "Orig" : "Dub";
    renderLanguages("");
  };

  movie.addEventListener("change", applyDefaults);
  mode.addEventListener("change", () => renderLanguages(language.value));
  if (isEdit) renderLanguages(language.dataset.current);
  else if (movie.value) applyDefaults();
  else renderLanguages("");
});
