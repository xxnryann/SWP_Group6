// Form suất chiếu:
//  - Ô "Ngôn ngữ phụ đề / lồng tiếng" chỉ liệt kê các ngôn ngữ đã khai báo ở phim đang chọn.
//  - Rạp ở Việt Nam: suất mới mặc định "Lồng tiếng" + tiếng Việt; tiếng Việt luôn chọn được.
document.addEventListener("DOMContentLoaded", () => {
  const movie = document.getElementById("movieId");
  const mode = document.getElementById("languageMode");
  const language = document.getElementById("language");
  const hint = document.getElementById("language-hint");
  if (!movie || !language) return;

  const isEdit = !!language.dataset.current;
  const DEFAULT_LANGUAGE = "Tiếng Việt";
  const short = (name) => (name.startsWith("Tiếng ") ? name.slice(6) : name);

  const selected = () => movie.options[movie.selectedIndex];
  const languagesOf = (option) => (option && option.dataset.languages ? option.dataset.languages : "")
    .split(",").map((s) => s.trim()).filter(Boolean);

  const render = (applyDefaults) => {
    const option = selected();
    const list = movie.value ? languagesOf(option) : [];
    const keep = applyDefaults ? "" : (language.value || language.dataset.current || "");
    language.innerHTML = "";
    const placeholder = document.createElement("option");
    placeholder.value = "";
    placeholder.textContent = !movie.value ? "Chọn phim trước" : (list.length ? "Chọn ngôn ngữ" : "Phim chưa khai báo ngôn ngữ");
    language.appendChild(placeholder);
    list.forEach((name) => {
      const o = document.createElement("option");
      o.value = name;
      o.textContent = short(name);
      language.appendChild(o);
    });
    if (list.includes(keep)) language.value = keep;
    else if (list.includes(DEFAULT_LANGUAGE)) language.value = DEFAULT_LANGUAGE;
    else if (list.length) language.value = list[0];
    if (applyDefaults && mode) mode.value = "Dub";
    language.disabled = !list.length;
    if (hint) {
      hint.textContent = movie.value && !list.length
        ? "Phim này chưa có ngôn ngữ — hãy sửa phim và chọn ngôn ngữ trước."
        : "Mặc định lồng tiếng Việt. Chọn được: " + list.map(short).join(", ") + " (tiếng Việt + ngôn ngữ đã chọn khi tạo phim).";
    }
  };

  movie.addEventListener("change", () => render(true));
  render(!isEdit);
});
