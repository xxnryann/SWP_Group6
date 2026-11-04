# Cập nhật hệ thống Layout Ghế Rạp

## Tóm tắt thay đổi

Đã hoàn thành các yêu cầu sau:

### ✅ Yêu cầu 1: Thêm lối đi bên phải rạp
- Thêm lối đi dọc màu xám với viền nét đứt
- Hiển thị nhãn "LỐI ĐI" theo chiều dọc
- Responsive: tự động thu gọn trên màn hình nhỏ
- Không ảnh hưởng đến chức năng ghế hiện có

### ✅ Yêu cầu 2: Ghế mặc định màu xám khi tạo phòng
- Tạo loại ghế mới: **Unassigned** (chưa chọn loại)
- Tất cả ghế mặc định là Unassigned khi tạo phòng mới
- Dropdown hiển thị "Chọn loại ghế" khi chưa được thiết lập
- Admin có thể đổi loại ghế sau bằng chức năng "Đổi loại"

### ✅ Màu sắc và hiển thị theo loại ghế

#### Màu sắc
- **Unassigned** (chưa chọn): Xám nhạt (#f1f5f9)
- **Standard** (ghế thường): Xanh lá nhạt (#ecfdf5)
- **VIP**: Vàng/Cam (#fef3c7)
- **Couple** (ghế đôi): Hồng (#fce7f3)
- **Maintenance** (bảo trì): Xám kẻ sọc

#### Hiển thị ghế Couple
- 2 ghế gắn liền vào nhau (margin âm)
- Ghế lẻ: bo tròn bên trái, thẳng bên phải
- Ghế chẵn: thẳng bên trái, bo tròn bên phải
- Viền giữa mỏng hơn (border-width: 1px)

---

## Các file đã thay đổi

### 1. Database Migration
**File:** `database/add_unassigned_seat_type.sql`

```sql
-- Thêm loại ghế Unassigned
INSERT INTO dbo.SeatType(type_name, is_couple, description) 
VALUES (N'Unassigned', 0, N'Chưa chọn loại ghế (cần admin thiết lập)');
```

**Cách chạy:**
```bash
sqlcmd -S "tcp:localhost,1433" -U sa -P 123 -d CinemaWebDB -i database/add_unassigned_seat_type.sql
```

### 2. Frontend (JSP)
**File:** `web/WEB-INF/views/room/seat-layout.jsp`

**Thay đổi CSS:**
- Thêm class `.aisle-right` cho lối đi
- Thêm màu cho ghế Unassigned (`.t-Unassigned`)
- Cập nhật legend hiển thị loại ghế mới

**Thay đổi HTML:**
- Thêm `<div class="aisle-right">LỐI ĐI</div>` sau mỗi hàng ghế
- Cập nhật dropdown với option "Chọn loại ghế"
- Ẩn option "Unassigned" trong dropdown (chỉ dùng làm default)

### 3. Backend (Java)
**File:** `src/java/com/cinema/controller/room/ManageSeatsServlet.java`

**Thay đổi:**
- Method `defaultTypeIdForRow()`: trả về `Unassigned` thay vì `Standard`
- Fallback chain: Unassigned → Standard → loại đầu tiên

---

## Hướng dẫn sử dụng

### Bước 1: Chạy Database Migration
```bash
cd SWP_Group6-feature-cinema-full-update
sqlcmd -S "tcp:localhost,1433" -U sa -P 123 -d CinemaWebDB -i database/add_unassigned_seat_type.sql
```

### Bước 2: Tạo phòng chiếu mới
1. Đăng nhập với tài khoản Admin
2. Vào **Quản lý phòng chiếu** → **Thêm phòng mới**
3. Nhập thông tin phòng (tên, loại, sức chứa)
4. Lưu phòng

### Bước 3: Thiết lập layout ghế
1. Vào trang **Layout ghế** của phòng vừa tạo
2. Nhập số hàng (1-26) và số ghế mỗi hàng (1-30)
3. Bấm **Áp dụng layout**
4. Tất cả ghế sẽ hiển thị màu xám (Unassigned)

### Bước 4: Đổi loại ghế
1. Mỗi hàng ghế có dropdown **"Chọn loại ghế"**
2. Chọn loại mong muốn:
   - **Standard**: Ghế thường (màu xanh lá nhạt)
   - **VIP**: Ghế VIP (màu vàng/cam)
   - **Couple**: Ghế đôi (màu hồng, 2 ghế gắn liền)
3. Bấm **Đổi loại**
4. Ghế sẽ tự động đổi màu và hiển thị theo loại mới

**Lưu ý cho ghế Couple:**
- Số ghế mỗi hàng phải là số CHẴN
- Ghế phải đánh số liên tục từ 1
- Không có ghế nào đang bảo trì
- Hệ thống tự động ghép cặp: 1-2, 3-4, 5-6, ...

---

## Demo hiển thị

```
         MÀN HÌNH
         
A  [A1] [A2] [A3] [A4] [A5]  │LỐI ĐI│  [Chọn loại ▾] [Đổi loại]
                               │     │
B  [B1] [B2] [B3] [B4] [B5]  │     │  [Standard   ▾] [Đổi loại]
                               │     │
C  [C1] [C2] [C3] [C4] [C5]  │     │  [VIP        ▾] [Đổi loại]
                               │     │
D  [D1===D2] [D3===D4] [D5]  │     │  [Couple     ▾] [Đổi loại]
```

**Chú thích:**
- `[A1]` xám = Unassigned
- `[B1]` xanh = Standard  
- `[C1]` vàng = VIP
- `[D1===D2]` hồng = Couple (gắn liền)
- `│LỐI ĐI│` = Lối đi dọc

---

## Tính năng đã có sẵn (không thay đổi)

✅ Bảo trì ghế (chọn nhiều ghế → Bảo trì)
✅ Mở lại ghế bảo trì
✅ Ghế đôi tự động xử lý cả cặp khi bảo trì
✅ Không cho phép bảo trì/đổi loại khi ghế có vé còn hiệu lực
✅ Thống kê: Sức chứa, Số ghế, Đang bảo trì, Suất chiếu sắp tới

---

## Kiểm tra kết quả

### Test 1: Tạo phòng mới
```
✓ Tất cả ghế màu xám (Unassigned)
✓ Dropdown hiển thị "Chọn loại ghế"
✓ Có lối đi bên phải mỗi hàng
```

### Test 2: Đổi sang Standard
```
✓ Ghế chuyển sang màu xanh lá nhạt
✓ Dropdown hiển thị "Standard"
✓ Có thể đặt vé cho ghế này
```

### Test 3: Đổi sang VIP
```
✓ Ghế chuyển sang màu vàng/cam
✓ Dropdown hiển thị "VIP"
✓ Giá vé cao hơn Standard
```

### Test 4: Đổi sang Couple
```
✓ Hàng có số ghế chẵn
✓ 2 ghế gắn liền thành 1 cặp (margin âm)
✓ Màu hồng
✓ Dropdown hiển thị "Couple"
✓ Khách đặt vé phải đặt cả cặp
```

### Test 5: Responsive
```
✓ Màn hình > 1280px: Lối đi rộng 50px
✓ Màn hình < 1280px: Lối đi thu gọn 36px
✓ Ghế không bị lệch layout
```

---

## Troubleshooting

### Vấn đề: Không thấy loại "Unassigned" trong database
**Giải pháp:** Chạy lại script migration:
```bash
sqlcmd -S "tcp:localhost,1433" -U sa -P 123 -d CinemaWebDB -i database/add_unassigned_seat_type.sql
```

### Vấn đề: Ghế mới vẫn màu xanh thay vì xám
**Giải pháp:** 
1. Kiểm tra `SeatType` có `Unassigned` chưa
2. Xóa cache browser (Ctrl + F5)
3. Restart server Tomcat

### Vấn đề: Không đổi được sang Couple
**Giải pháp:** Kiểm tra:
- ✓ Số ghế phải chẵn (2, 4, 6, 8, 10...)
- ✓ Không có ghế đang bảo trì
- ✓ Đánh số liên tục từ 1

### Vấn đề: Lối đi đẩy nút "Đổi loại" ra ngoài màn hình
**Giải pháp:** 
- Responsive đã xử lý: lối đi tự động thu gọn trên màn hình nhỏ
- Kiểm tra CSS `.aisle-right` đã load đúng chưa

---

## Tác giả & Ngày cập nhật

**Ngày:** 2026-11-04  
**Version:** 1.0  
**Status:** ✅ Hoàn thành và đã test

**Liên hệ hỗ trợ:** Xem file README.md
