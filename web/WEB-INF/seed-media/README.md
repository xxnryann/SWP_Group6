# seed-media — ảnh mẫu đi kèm repo (DEF-005)

`database/seed.sql` trỏ poster phim mẫu tới `/media/posters/<uuid>.<ext>`.
Khi file đó không có trong thư mục `media.upload.root` (máy vừa clone repo),
`MediaServlet` tìm tiếp ở đây:

```
web/WEB-INF/seed-media/posters/<uuid>.<ext>
web/WEB-INF/seed-media/avatars/<uuid>.<ext>
```

Vẫn không có ⇒ trả ảnh `assets/img/poster-placeholder.svg` ("Chưa có poster") thay vì ảnh vỡ.

**Việc cần làm:** người giữ ảnh gốc (máy dev `D:/SWP26/SWP_Group6/media/posters`)
copy đủ các file poster mà `seed.sql` dùng vào `posters/` ở đây rồi commit.
Danh sách tên file: chạy `grep -o "/media/posters/[^']*" database/seed.sql`.
