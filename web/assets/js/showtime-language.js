// Form suất chiếu: ô "Ngôn ngữ phụ đề / lồng tiếng" chỉ liệt kê các ngôn ngữ đã khai báo ở phim đang chọn.
document.addEventListener("DOMContentLoaded", () => {
  const movie = document.getElementById("movieId");
  const language = document.getElementById("language");
  const hint = document.getElementById("language-hint");
  if (!movie || !language) return;

  const languagesOf = (option) => (option && option.dataset.languages ? option.dataset.languages : "")
    .split(",").map((s) => s.trim()).filter(Boolean);

  const render = () => {
    const option = movie.options[movie.selectedIndex];
    const list = movie.value ? languagesOf(option) : [];
    const keep = language.value || language.dataset.current || "";
    language.innerHTML = "";
    const placeholder = document.createElement("option");
    placeholder.value = "";
    placeholder.textContent = !movie.value ? "Chọn phim trước" : (list.length ? "Chọn ngôn ngữ" : "Phim chưa khai báo ngôn ngữ");
    language.appendChild(placeholder);
    list.forEach((name) => {
      const o = document.createElement("option");
      o.value = name;
      o.textContent = name.startsWith("Tiếng ") ? name.slice(6) : name;
      language.appendChild(o);
    });
    if (list.includes(keep)) language.value = keep;
    else if (list.length === 1) language.value = list[0];
    else if (list.includes("Tiếng Việt")) language.value = "Tiếng Việt";
    language.disabled = !list.length;
    if (hint) {
      hint.textContent = movie.value && !list.length
        ? "Phim này chưa có ngôn ngữ — hãy sửa phim và chọn ngôn ngữ trước."
        : "Chỉ chọn được các ngôn ngữ đã khai báo ở phim" + (list.length ? ": " + list.join(", ") + "." : ".");
    }
  };

  movie.addEventListener("change", render);
  render();
});
