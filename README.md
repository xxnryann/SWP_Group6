# CinemaWeb — Hệ thống quản lý rạp chiếu phim

Ứng dụng web JSP theo mô hình 3 tầng: **Controller (Servlet) → Service → DAO → DBContext (JDBC)**.
Stack: Java 11/17 · Jakarta Servlet 6.0 · JSP + JSTL 3.0 · SQL Server 2019 (MSSQL JDBC) · Tomcat 10.1.

> **Không dùng Maven.** Project dùng layout NetBeans/Ant (`src/java`, `web/`, `lib/`), build bằng `javac` qua `scripts/build.ps1`.

---

## 1. Chạy project

### 1.1. Tạo database

```powershell
sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -f 65001 -i sql\new.sql
```

`sql/new.sql` **drop và tạo lại** toàn bộ `CinemaWebDB` (32 bảng, 22 stored procedure, 3 view, trigger, hàm + dữ liệu mẫu). Cần `sqlcmd` và SQL Server 2019+.

> `-f 65001` bắt buộc, nếu không chuỗi tiếng Việt trong seed data sẽ bị hỏng.

### 1.2. Cấu hình

Sửa `src/java/app.properties`:

| Khoá | Ý nghĩa |
|---|---|
| `db.url` / `db.user` / `db.password` | Kết nối SQL Server (mặc định `CinemaWebDB`) |
| `mail.*` | Gửi email OTP. Để trống `mail.host` ⇒ OTP in ra log Tomcat (chế độ dev) |
| `vnpay.partnerCode` / `vnpay.secretKey` | Thông tin cổng VNPAY thật |
| `vnpay.mockGateway` | `true` ⇒ tự dùng cổng giả lập nội bộ `/mock/payment` |
| `vnpay.paymentUrl` | URL trang thanh toán VNPAY (mặc định sandbox) |
| `vnpay.bankCode` | Mã ngân hàng/phương thức thanh toán, rỗng để khách tự chọn |
| `vnpay.mockPaymentUrl` | Đường dẫn cổng giả lập nội bộ (mặc định `/mock/payment`) |

### 1.3. Build & deploy

```powershell
# Build (javac → web/WEB-INF/classes)
powershell -ExecutionPolicy Bypass -File scripts\build.ps1
powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Clean     # xoá class cũ trước

# Build + copy sang Tomcat (tự tìm CATALINA_HOME, hoặc truyền -TomcatHome)
powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1
powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -TomcatHome "C:\path\to\Tomcat10.1" -Context CinemaWeb
```

Mở `http://localhost:8080/CinemaWeb/`.

> **Lưu ý deploy:** Tomcat không tự reload class. `deploy.ps1` đã xoá `work/Catalina/localhost/<context>` và `temp/work/...`; nếu vẫn chạy code cũ thì restart Tomcat.

### 1.4. Script hỗ trợ

| Script | Công dụng |
|---|---|
| `scripts/build.ps1` | Biên dịch toàn bộ `src/java` bằng `javac` (UTF-8, Java 17), copy `app.properties` |
| `scripts/deploy.ps1` | Build rồi deploy `web/` sang `webapps/<context>` của Tomcat |
| `scripts/ensure-utf8-bom.ps1` | Thêm BOM UTF-8 cho file `.ps1` (PowerShell 5.1 đọc file không BOM theo ANSI → hỏng tiếng Việt) |
| `scripts/fix_mojibake.py` | Sửa file bị "mojibake" (UTF-8 bị đọc như cp1252 rồi ghi lại) |
| `scripts/compare-procedures.ps1` | Đối chiếu stored procedure trong `sql/new.sql` với DB đã deploy (thêm `-Sync` để tạo lại procedure lệch) |
| `scripts/test-booking-flow.ps1` | Kiểm thử trọn luồng BF-02 (happy path) |
| `scripts/test-booking-errors.ps1` | Kiểm thử các nhánh lỗi (hủy, webhook sai chữ ký, idempotency) |
| `scripts/test-smoke.ps1` | Kiểm thử nhanh toàn bộ 5 vai trò: mọi trang chính trả 200, 4 dashboard theo vai trò, `/booking/*` chặn khách chưa đăng nhập |
| `scripts/test-rail.py` | Kiểm thử menu dọc (rail): đăng nhập từng vai trò rồi duyệt các trang con, xác nhận rail luôn hiện, đúng link active và không còn thanh nav ngang |

---

## 2. Đặt vé online (BF-02 / UC12–UC18)

### 2.1. Luồng

```
/showtimes
   └─ chọn suất  →  /booking/seats?showtimeId=N
                       └─ chọn ghế (đôi phải đi cặp, ghế bảo trì không chọn được)
                           └─ giữ ghế (YELLOW, TTL 5 phút)  →  /booking/extras
                               └─ combo → voucher → MyPoint            →  /booking/payment
                                   └─ đếm ngược 15 phút, bấm "Thanh toán"
                                       └─ cổng VNPAY (hoặc /mock/payment)
                                           └─ /booking/payment/return  →  xác nhận → /account/tickets
```

### 2.2. Endpoint

| URL | Method | Ai | Mô tả |
|---|---|---|---|
| `/booking/seats` | GET | Customer | Sơ đồ ghế của suất chiếu |
| `/booking/seats` | POST | Customer | Giữ ghế → chuyển sang bước combo |
| `/booking/extras` | GET/POST | Customer | Combo, voucher, MyPoint |
| `/booking/payment` | GET/POST | Customer | Tóm tắt đơn + đếm ngược + bấm thanh toán / hủy |
| `/booking/payment/return` | GET | Cổng thanh toán | Xác nhận kết quả (có HMAC-SHA512) |
| `/booking/cancel-result` | GET | Customer | Trang kết quả hủy / thất bại |
| `/mock/payment` | GET/POST | Dev | Cổng thanh toán giả lập (chỉ khi `vnpay.mockGateway=true`) |
| `/api/v1/commerce/payment/webhook/vnpay` | POST | VNPAY (server-to-server) | IPN — trả JSON `RspCode` |

`/booking/*` được bảo vệ bởi `BookingAuthFilter`: chưa đăng nhập → redirect `/login`; sai vai trò → **403**. Chỉ role `CUSTOMER` được đặt vé online.

> **Ngoại lệ:** `/booking/payment/return` (nơi cổng thanh toán chuyển khách về) được filter **cố ý bỏ qua** — cổng gọi bằng GET và không mang cookie phiên. Endpoint này tra cứu đơn bằng `vnp_TxnRef` (= mã đơn) chứ không dựa vào session, nên vẫn an toàn.

### 2.3. Thanh toán

- **VNPAY 2.1.0** — HMAC-SHA512, so sánh hash constant-time, `vnp_Amount` ×100, `vnp_OrderInfo` không dấu.
- **Cổng giả lập nội bộ** — dùng khi thiếu `vnpay.secretKey`; trả về đúng tập tham số + chữ ký hợp lệ nên luồng test được y hệt cổng thật.
- **Idempotency** — Return URL và webhook cùng gọi `OnlineBookingService.confirmGatewayPayment`. Đơn đã `Paid` trả về thành công nhưng **không phát vé lần 2**.
- **Đối soát** — số tiền cổng báo lệch tổng tiền đơn ⇒ không cấp vé, ghi cảnh báo.
- **Webhook trả** `RspCode`: `00` đã cập nhật · `97` chữ ký sai (không retry) · `99` lỗi hệ thống (VNPAY retry tối đa 10 lần).

### 2.4. Quy tắc nghiệp vụ được enforce

| Mã | Nơi thực thi |
|---|---|
| `GBR-01` giữ ghế 5 phút | `sp_HoldSeats` + `sp_ReleaseExpiredHolds`, gọi trước mọi lần đọc |
| `GBR-02` phiên đặt vé 15 phút | `SystemConfig.BOOKING_SESSION_MINUTES` + `sp_CreateBooking` |
| `GBR-03` ghế đôi đi cặp | JSP tự chọn cặp + `sp_HoldSeats` từ chối ghế lẻ |
| `GBR-04` ngưỡng chi tiêu voucher | `sp_ApplyVoucher` |
| `GBR-05` voucher còn hiệu lực | `sp_ApplyVoucher` |
| `GBR-06` MyPoint chỉ tích từ đơn thành công | `sp_ConfirmPayment` (chỉ khi `is_success = 1`) |
| `GBR-07` trần % quy đổi MyPoint | `sp_ApplyMyPoint` / `MyPointConfig` |
| `GBR-08` ghế bảo trì | `vw_SeatMap` trả `GREY`, DAO chặn giữ ghế |
| `GBR-09` chỉ Cinema Manager quản lý phim | `MovieManagerMenuFilter` + `AdminFilter` |

Logic nghiệp vụ nằm **một lần** ở tầng `service` và **stored procedure của DB** — dùng chung cho cả luồng online và bán tại quầy, không copy-paste giữa hai controller.

### 2.5. Giải phóng ghế hết hạn (GBR-01/02)

Cơ chế hết hạn chạy ở **cả hai tầng**, nên việc giải phóng ghế **không phụ thuộc lưu lượng truy cập**:

| Tầng | Cách chạy |
|---|---|
| Tầng DB | `sp_HoldSeats` tự gọi `sp_ReleaseExpiredHolds` trước khi giữ ghế; `vw_SeatMap` chỉ hiện YELLOW khi `payment_expires_at` còn hạn ⇒ ghế hết hạn hiện GREEN ngay |
| Tầng ứng dụng | `OnlineBookingService.releaseExpiredHolds()` gọi procedure khi đọc đơn (có **throttle 2 giây** để không dồn 3 lệnh UPDATE thừa ở mỗi lần bấm chuột) |

> Job nền định kỳ (`@Scheduled` / `@WebListener`) chưa đưa vào phạm vi lần này — cơ chế trên đã đảm bảo ghế được trả về dù khách đóng trình duyệt.

### 2.6. Quy tắc lịch chiếu (linh hoạt, không còn 5 khung cố định)

Lịch chiếu được xếp theo từng phòng, không còn 5 khung giờ cố định áp dụng chung:

| Quy tắc | Giá trị | Nơi enforce |
|---|---|---|
| Giờ mở cửa / đóng cửa | 09:00 – 23:00 | `ShowtimeRules.OPEN_TIME` / `CLOSE_TIME`, `save()` + `insertBatch()` |
| Giờ kết thúc suất chiếu | `giờ bắt đầu + thời lượng phim` | `ShowtimeDAO.save`, trigger `trg_Showtime_SyncDaoCompatibility` |
| Khoảng cách giữa 2 suất cùng phòng | 15 phút (dọn phòng) | `ShowtimeRules.TURNOVER_MINUTES`, `validateMovieAndRoomConflict` |
| Bước chọn giờ bắt đầu | mốc tròn 15 phút | `ShowtimeRules.isOnGrid`, `findAvailableStartTimes` |

Một phim có thể có nhiều suất ở **các phòng khác nhau với giờ khác nhau** — `ShowtimePlanner` xoay vòng phim và lệch chỉ số giữa các phòng (`index = (roomIndex + step) % movies.size()`) nên khách có nhiều lựa chọn hơn.

`dbo.TimeSlot` giờ là **khung giá** (Sáng 00:00–12:00, Chiều 12:00–18:00, Tối 18:00–23:59) chứ không phải suất chiếu; `slot_id` của một suất được suy ra từ giờ bắt đầu nên `fn_GetTicketPrice` và `dbo.TicketPrice` giữ nguyên cách tính.

Manager tạo lịch theo một trong hai cách:

| Cách | URL | Mô tả |
|---|---|---|
| Sinh lịch tự động | `/manage/showtimes?action=generate` | Chọn ngày + giờ mở cửa + phòng + phim; hệ thống xếp liên tục đến giờ đóng cửa |
| Thêm/sửa từng suất | `/manage/showtimes?action=new` | Nhập từng suất, giờ bắt đầu chọn từ danh sách mốc 15 phút còn trống |

### 2.7. Tối ưu truy vấn

| Kỹ thuật | Ở đâu | Tác dụng |
|---|---|---|
| Gộp 3 truy vấn chi tiết đơn (booking + vé + combo) vào **1 connection** | `BookingDAO.findOnlineBooking(Connection, int)` | Tiết kiệm 2 round-trip mỗi lần mở màn hình combo/thanh toán |
| Tra mã đơn → đọc chi tiết trong cùng connection | `BookingDAO.findOnlineBookingByCode` | Return URL / IPN chỉ cần 1 connection thay vì 2 |
| Gộp 4 truy vấn kiểm tra lịch chiếu (phim + phòng + lịch cùng ngày) vào **1 connection** | `ShowtimeDAO.findAvailableStartTimes` | Giảm 4 round-trip xuống 1 khi mở form lập lịch |
| Xếp lịch tự động dùng hàm thuần (không JDBC) + ghi cả ngày trong **1 transaction** | `ShowtimePlanner.plan`, `ShowtimeDAO.insertBatch` | Sinh lịch cho nhiều phòng chỉ tốn 1 connection; hoặc ghi hết, hoặc không ghi gì |
| Cache cấu hình MyPoint **có TTL 5 phút** | `OnlineBookingService.getPointConfig()` | Bỏ 1 vòng truy vấn DB mỗi lần mở màn hình combo, vẫn tự nhận cấu hình mới khi Manager sửa |
| Cache cấu hình VNPAY trong bộ nhớ | `VNPayProperties.load()` | Không dựng lại map cấu hình ở mỗi request |
| Throttle 2 giây cho `sp_ReleaseExpiredHolds` | `OnlineBookingService.releaseExpiredHolds()` | Không dồn 3 lệnh `UPDATE` thừa mỗi lần bấm chuột |
| Cấu hình MyPoint đọc `TOP 1 ... ORDER BY effective_from DESC` | `BookingDAO.getPointConfig()` | Luôn lấy cấu hình đang hiệu lực, không cần index phụ |
| Bỏ `LOWER()` khi so sánh email (`Account.email` đã collation `CI_AS`) | `TicketDAO`, `UserDAO` | So sánh trực tiếp còn **SARGable** → seek index thay vì scan |
| Index hỗ trợ luồng đặt vé | `sql/new.sql` → `IX_Booking_Customer_Status`, `IX_Booking_Showtime_Status`, `IX_Booking_Expiry`, `IX_Ticket_Booking_Status`, `IX_Payment_GatewayTxn`, `IX_MyPointTxn_Customer` | Tránh scan bảng khi `Ticket`/`Booking` đã lớn; `IX_Payment_GatewayTxn` là khoá idempotency của webhook |

---

## 3. Cấu trúc thư mục

```
src/java/com/cinema/
├── controller/            # Servlet + Filter (@WebServlet / @WebFilter)
│   ├── booking/           # Luồng đặt vé online (BF-02)
│   ├── dashboard/         # 4 servlet dashboard + DashboardAuthFilter
│   ├── MovieController/   # Quản lý phim
│   ├── RoomController/    # Quản lý phòng + sơ đồ ghế
│   └── ShowtimeController/# Lịch chiếu
├── service/               # Business logic (không import jakarta.servlet)
├── dao/                   # SQL thuần, PreparedStatement
├── model/                 # POJO (field + getter/setter)
├── integration/vnpay/     # Adapter VNPAY + MockPaymentGateway
└── util/                  # DBContext, EmailService, Validator, RequestParams…
    └── ShowtimeUtil/      # ShowtimeRules (15 phút) + ShowtimePlanner (sinh lịch)

web/
├── WEB-INF/views/         # JSP + JSTL (không scriptlet)
│   ├── booking/           # 5 màn hình của luồng đặt vé
│   └── dashboard/         # 4 trang dashboard + menu dọc dùng chung (_dash_rail.jspf)
├── WEB-INF/web.xml
└── assets/                # CSS / JS

sql/new.sql                # Full schema + stored procedure + seed
scripts/                   # Build, deploy, test (PowerShell)
```

---

## 4. Các URL khác

| URL | Ai | Mô tả |
|---|---|---|
| `/` | Guest | Trang chủ |
| `/register`, `/verify-otp` | Guest | Tạo tài khoản + OTP email |
| `/login`, `/logout` | all | Đăng nhập / đăng xuất |
| `/movies`, `/movies/detail?id=` | Guest | Danh sách phim, chi tiết phim |
| `/showtimes` | all | Lịch chiếu (link đặt vé cho Customer) |
| `/pricing` | all | Bảng giá vé 2D (đọc động từ bảng `TicketPrice`) |
| `/news` | Guest | Tin tức công khai |
| `/account/profile`, `/account/password` | Customer | Hồ sơ, đổi mật khẩu |
| `/account/tickets` | Customer | Lịch sử vé |
| `/account/points` | Customer | Biến động MyPoint |
| `/dashboard/admin` | Admin | Dashboard quản trị (tổng quan hệ thống) |
| `/dashboard/manager` | Manager, Admin | Dashboard quản lý rạp (vận hành, doanh thu) |
| `/dashboard/staff` | Staff, Manager, Admin | Dashboard nhân viên quầy (lịch chiếu, ghế) |
| `/dashboard/customer` | Customer | Dashboard khách hàng (MyPoint, vé, phim) |
| `/admin/users`, `/admin/rooms`, `/admin/seats` | Admin | Quản lý người dùng, phòng, sơ đồ ghế |
| `/staff/counter`, `/staff/combo` | Staff | Bán vé / combo tại quầy |
| `/manage/movies`, `/manage/showtimes` | Manager | Quản lý phim, lịch chiếu |
| `/manage/showtimes?action=generate` | Manager | Sinh lịch chiếu tự động cho một ngày |
| `/manager/news` | Manager | Quản lý tin tức |

### 4.1. Dashboard theo vai trò

Sau khi đăng nhập thành công, hệ thống **tự động chuyển tới dashboard của đúng vai trò**:

| Vai trò | Đích sau đăng nhập | Nội dung dashboard |
|---|---|---|
| `ADMIN` | `/dashboard/admin` | Tổng người dùng, người dùng bị khoá, phòng chiếu, ghế, vé bán & doanh thu hôm nay; lịch chiếu; tài khoản mới nhất |
| `MANAGER` | `/dashboard/manager` | Phim đang chiếu / sắp chiếu, phòng chiếu, suất chiếu hôm nay, doanh thu hôm nay; lịch chiếu; top phim doanh thu 7 ngày |
| `STAFF` | `/dashboard/staff` | Suất chiếu hôm nay, ghế trống / đang giữ / đã bán, combo đang bán; lịch chiếu kèm nút "Chọn ghế" → bán vé tại quầy |
| `CUSTOMER` | `/dashboard/customer` | Điểm MyPoint, tổng chi tiêu, số vé đã mua, số đơn đã thanh toán; vé sắp tới; lưới phim đang chiếu |

Cơ chế hoạt động:

| Thành phần | Vai trò |
|---|---|
| `com.cinema.util.RoleDashboard` | Ánh xạ vai trò → URL dashboard; whitelist tiền tố URL theo vai trò (chống open redirect khi tôn trọng `afterLogin`) |
| `LoginServlet` | Đọc `RoleDashboard.pathFor(role)` để chuyển hướng; deep-link hợp lệ (vd `/account/tickets`) vẫn được giữ |
| `DashboardAuthFilter` | Bảo vệ 4 URL dashboard: chưa đăng nhập → 302 `/login`; tài khoản không `ACTIVE` → đăng xuất; sai vai trò → **403** |
| `DashboardDAO` | Số liệu tổng hợp chỉ đọc (PreparedStatement): người dùng, hạ tầng, phim, lịch chiếu + thống kê ghế (qua `vw_SeatMap`), doanh thu (qua `vw_RevenueByMovie`) |
| `web/WEB-INF/views/dashboard/_dash_rail.jspf` | Menu dọc cố định (rail) dùng chung cho mọi trang đã đăng nhập, đổi menu theo vai trò, highlight mục đang xem |

> **Quy ước phân quyền:** `/dashboard/admin` → ADMIN · `/dashboard/manager` → MANAGER, ADMIN · `/dashboard/staff` → STAFF, MANAGER, ADMIN · `/dashboard/customer` → CUSTOMER.
>
> **Fallback ngày:** nếu hôm nay rạp chưa có suất chiếu (dữ liệu seed được tạo từ một ngày khác), dashboard tự lùi về ngày gần nhất có lịch (`findNextShowtimeDate()`) và hiển thị đúng ngày đó trên tiêu đề.

### 4.2. Menu dọc (rail) cố định

Sau khi đăng nhập, **menu dọc bên trái luôn hiện ở mọi trang** — kể cả khi điều hướng sang trang khác (quản lý phim, lịch chiếu, hồ sơ, đặt vé…), nên không bao giờ bị mất menu.

Cơ chế:

| Thành phần | Vai trò |
|---|---|
| `web/WEB-INF/views/dashboard/_dash_rail.jspf` | Rail cố định (`position: fixed`), sinh **một lần** trong `_header.jspf` — mọi trang đều include file này nên menu luôn tồn tại |
| `MovieManagerMenuFilter` | Gắn cờ `railModule` = đã đăng nhập **và** không phải trang chủ; `roleModule` cho các khu vực nội bộ |
| `_header.jspf` | Bỏ thanh nav ngang + breadcrumb khi rail hiện; nút "Đăng xuất" chỉ nằm ở chân rail |
| `cinema.css` | `body.has-rail { padding-left: 260px }` — nội dung trang lệch sang phải, không chồng lên rail |

Menu theo vai trò (mỗi role **chỉ** thấy chức năng của role đó):

| Vai trò | Menu dọc |
|---|---|
| `ADMIN` | Tổng quan · Người dùng · Phòng chiếu · Sơ đồ ghế · Báo cáo vận hành |
| `MANAGER` | Tổng quan · Quản lý phim · Lịch chiếu · Sinh lịch tự động · Quản lý tin tức |
| `STAFF` | Tổng quan · Bán vé tại quầy · Quản lý combo |
| `CUSTOMER` | Tổng quan · Lịch chiếu · Phim đang chiếu · Lịch sử vé · Điểm MyPoint · Thông tin cá nhân · Đổi mật khẩu · **Bảng giá vé** · **Tin tức** |

> Trang chủ `/` và `/home` giữ nguyên layout công khai (thanh nav ngang, không có rail) theo yêu cầu.

### Tài khoản seed

| Email | Vai trò (`Users.Role`) | Mật khẩu |
|---|---|---|
| `admin@cinema.vn` | `ADMIN` | `123456` |
| `manager@cinema.vn` | `MANAGER` | `123456` |
| `staff@cinema.vn` | `STAFF` | `123456` |
| `khach1@gmail.com` | `CUSTOMER` | `123456` |
| `khach2@gmail.com` | `CUSTOMER` | `123456` |

---

## 5. Kiểm thử

Yêu cầu: ứng dụng đã deploy lên Tomcat và CSDL đã seed.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-booking-flow.ps1
powershell -ExecutionPolicy Bypass -File scripts\test-booking-errors.ps1
powershell -ExecutionPolicy Bypass -File scripts\test-smoke.ps1
```

| Script | Phủ | Kết quả mong đợi |
|---|---|---|
| `test-booking-flow.ps1` | Đăng nhập → chọn suất → giữ ghế → combo/voucher → cổng giả lập → lịch sử vé | `TAT CA BUOC PASS` |
| `test-booking-errors.ps1` | A. Hủy ở cổng ⇒ ghế về GREEN<br>B. Webhook sai chữ ký ⇒ `RspCode 97`, không phát vé<br>C. Gọi lại callback ⇒ vé **không** phát 2 lần<br>D. Thanh toán OK ⇒ ghế chuyển RED | `TAT CA BUOC PASS` |
| `test-smoke.ps1` | Mọi trang chính của 5 vai trò (guest/customer/staff/manager/admin) trả HTTP 200; 4 URL dashboard trả 200 đúng vai trò; sai vai trò ⇒ 403; đăng nhập ⇒ chuyển đúng dashboard; `/booking/*` chưa đăng nhập ⇒ 302 về `/login` | `SMOKE TEST PASS` |
| `test-rail.py` | Duyệt 27 trang con của 4 vai trò: rail luôn hiện, số link cố định theo role, đúng mục `active`, không còn thanh nav ngang | `TONG: 27/27 trang OK` |

Tài khoản seed: `khach1@gmail.com` / `123456`.

---

## 6. Xử lý sự cố

| Triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|
| Tiếng Việt trong JSP/JS hiển thị sai | File bị "mojibake" (UTF-8 đọc như cp1252) | `python scripts\fix_mojibake.py` |
| Tiếng Việt trong `.ps1` sai | PowerShell 5.1 đọc file không BOM theo ANSI | `powershell -File scripts\ensure-utf8-bom.ps1 scripts` |
| Chạy code cũ sau khi deploy | Tomcat không reload class | Restart Tomcat hoặc xoá `work/Catalina/localhost/<ctx>` |
| `javac` báo `illegal character: '\ufeff'` | BOM ở đầu argfile | Script đã ghi file sources bằng encoding ASCII |
| Lỗi stored procedure khi chạy `new.sql` | Chạy trên SQL Server 2016 | Cần SQL Server 2019+ (script dùng `STRING_AGG`, `DROP IF EXISTS`) |
