/*
    ============================================================================
    seed.sql - dữ liệu mẫu của CinemaWebDB
    ============================================================================
    Chạy SAU schema.sql, trên DB chưa có dữ liệu:
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -b -f 65001 -i database/seed.sql

    Gồm: tài khoản, phim, rạp/phòng/ghế, giá vé, combo, voucher, đơn đặt vé mẫu, tin tức,
    tham số hệ thống; sau đó là poster/thumbnail và lịch chiếu demo tính theo ngày chạy.
    ============================================================================
*/

USE [CinemaWebDB]
GO

SET NOCOUNT ON;
GO
SET XACT_ABORT ON;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/* =====================================================================
   DỮ LIỆU MẪU (SEED)
   Xếp theo thứ tự các luồng ở trên.
   ===================================================================== */

-- ---------- Luồng 1. Tài khoản & phân quyền ----------
GO

INSERT dbo.AppRole(role_name) VALUES (N'Admin'), (N'CinemaManager'), (N'Staff'), (N'Customer');
GO

SET IDENTITY_INSERT dbo.Users ON;
INSERT dbo.Users (UserId, FullName, Email, Phone, PasswordHash, Role, Status) VALUES
    (1, N'Quản trị hệ thống', N'admin@cinema.vn', N'0900000001', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'ADMIN', N'ACTIVE'),
    (2, N'Quản lí', N'manager@cinema.vn', N'0900000002', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'MANAGER', N'ACTIVE'),
    (3, N'Nhân viên', N'staff@cinema.vn', N'0900000003', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'STAFF', N'ACTIVE'),
    (4, N'Lê Khách Một', N'khach1@gmail.com', N'0911111111', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'CUSTOMER', N'ACTIVE'),
    (5, N'Phạm Khách Hai', N'khach2@gmail.com', N'0922222222', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'CUSTOMER', N'ACTIVE');
SET IDENTITY_INSERT dbo.Users OFF;
GO

SET IDENTITY_INSERT dbo.Account ON;
INSERT dbo.Account (account_id, role_id, full_name, email, phone, password_hash, status) VALUES
    (1, 1, N'Quản trị hệ thống', N'admin@cinema.vn', '0900000001', '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active'),
    (2, 2, N'Quản lí', N'manager@cinema.vn', '0900000002', '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active'),
    (3, 3, N'Nhân viên', N'staff@cinema.vn', '0900000003', '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active'),
    (4, 4, N'Lê Khách Một', N'khach1@gmail.com', '0911111111', '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active'),
    (5, 4, N'Phạm Khách Hai', N'khach2@gmail.com', '0922222222', '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active');
SET IDENTITY_INSERT dbo.Account OFF;
GO

INSERT dbo.Customer(customer_id, my_point_balance, total_spent) VALUES (4, 20, 1714100), (5, 0, 0);
GO

INSERT dbo.Permission(permission_code, description) VALUES
    ('ACCOUNT_MANAGE', N'Quản lý tài khoản'),
    ('ROOM_SEAT_MANAGE', N'Quản lý phòng/ghế/lịch chiếu'),
    ('MOVIE_MANAGE', N'Quản lý phim/thể loại'),
    ('PRICE_PROMO_MANAGE', N'Giá vé, voucher, MyPoint'),
    ('COUNTER_SALE', N'Bán vé tại quầy, check-in, đổi ghế'),
    ('BOOK_TICKET', N'Đặt vé online');
GO

INSERT dbo.RolePermission(role_id, permission_id) VALUES (1,1),(1,2),(2,3),(2,4),(3,5),(4,6);
GO

-- ---------- Luồng 2. Phim ----------
GO

INSERT dbo.Genre(genre_name) VALUES
    (N'Action'), (N'Romance'), (N'Animation'), (N'Horror'), (N'Science Fiction'), (N'Family');
GO

SET IDENTITY_INSERT dbo.Movie ON;
INSERT dbo.Movie (movie_id, title, original_title, synopsis, director, main_cast, duration_minutes,
                  spoken_language, country, age_rating, trailer_url, poster_url, release_date, end_date, status) VALUES
(1, N'TRẠI BUÔN NGƯỜI', N'The Human Market', N'Một nhóm người xa lạ bị cuốn vào cuộc sinh tồn kinh hoàng trong khu chợ bí ẩn.', N'Đạo diễn A', N'Diễn viên 1, Diễn viên 2', 135, N'Tiếng Việt', N'Việt Nam', N'T18', 'https://www.youtube.com/watch?v=nlFar2vq4Yo', '/media/posters/ca6c44ce-a0c6-45f9-a855-8e8461b86415.jpg', '2026-09-25', '2026-10-12', N'Stopped'),
(2, N'VERITY: BÍ MẬT BỊ CHÔN VÙI', N'Verity', N'Những trang bản thảo hé lộ bí mật đen tối phía sau một gia đình tưởng như hoàn hảo.', N'Đạo diễn B', N'Diễn viên 3, Diễn viên 4', 117, N'Tiếng Anh, phụ đề Tiếng Việt', N'Mỹ', N'T18', 'https://www.youtube.com/watch?v=V-JKf_FgRjU', '/media/posters/b230b406-8e4d-415a-9e73-a053c3e3c15a.webp', '2026-09-16', '2026-10-10', N'Stopped'),
(3, N'MÙA XUÂN ĐẾN MUỘN', N'Late Spring', N'Câu chuyện gia đình về những cuộc gặp gỡ và lựa chọn làm thay đổi một mùa xuân.', N'Đạo diễn C', N'Diễn viên 5, Diễn viên 6', 120, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, '/media/posters/bbf5824d-978f-4f91-9d07-00ddeed0dbfe.jpg', '2026-09-05', '2026-10-01', N'Stopped'),
(4, N'QUỶ ĂN TẠNG 4: HỒI TỈNH', N'The Possessed 4', N'Một nghi lễ cổ xưa đánh thức thế lực đang ngủ yên trong ngôi làng hẻo lánh.', N'Đạo diễn D', N'Diễn viên 7, Diễn viên 8', 111, N'Tiếng Thái, phụ đề Tiếng Việt', N'Thái Lan', N'T18', 'https://www.youtube.com/watch?v=BP2_TUBOS6U', '/media/posters/b21ca0cc-a98e-4041-87b4-530649d8b1d9.jpg', '2026-10-16', NULL, N'NowShowing'),
(5, N'SHAUN THE SHEEP: “QUÁI LẠ” GHÉ NHÀ', N'Shaun the Sheep: The Strange Visitor', N'Shaun và cả đàn cừu gặp một vị khách bất ngờ trong chuyến phiêu lưu hài hướng.', N'Đạo diễn E', N'Lồng tiếng Việt', 81, N'Lồng tiếng Việt', N'Anh', N'P', 'https://www.youtube.com/watch?v=UZ46Smi6mOw', '/media/posters/3a72af13-0439-48a9-bd11-d57b8b82974e.jpg', '2026-10-16', NULL, N'NowShowing'),
(6, N'CÕI NGUYÊN', N'The Origin', N'Những dấu vết kỳ lạ dẫn một nhóm bạn đến bí mật bị chôn vùi dưới khu rừng già.', N'Đạo diễn F', N'Diễn viên 9, Diễn viên 10', 89, N'Tiếng Việt', N'Việt Nam', N'T18', 'https://www.youtube.com/watch?v=zsMuQUkduug', '/media/posters/ebf03e6b-51d6-42fd-b6ff-aacd4f75e6d9.png', '2026-10-23', NULL, N'NowShowing'),
(7, N'BAMBI: LÃNH ĐỊA SĂN MỒI', N'Bambi: The Reckoning', N'Cuộc đối đầu sinh tồn bắt đầu khi khu rừng yên bình trở thành lãnh địa săn mồi.', N'Đạo diễn G', N'Diễn viên 11, Diễn viên 12', 80, N'Tiếng Anh, phụ đề Tiếng Việt', N'Anh', N'T16', 'https://www.youtube.com/watch?v=U6vHNWqdO0s', '/media/posters/94455dd6-caee-41de-b18c-20c4d0fa8ed5.jpg', '2026-10-23', NULL, N'NowShowing'),
(8, N'ÁN MẠNG KARAOKE', N'Karaoke Murders', N'Một buổi tối karaoke biến thành vụ án bí ẩn mà không ai trong nhóm có thể rời đi.', N'Đạo diễn H', N'Diễn viên 13, Diễn viên 14', 96, N'Tiếng Việt', N'Việt Nam', N'T18', 'https://www.youtube.com/watch?v=UOjRGIatX38', '/media/posters/68257345-cc14-4c19-a8c6-d053ed8a80d6.jpg', '2026-10-30', NULL, N'Upcoming'),
(9, N'CẢM XÚC LẠ KỲ', N'Strange Feelings', N'Chuyến phiêu lưu hoạt hình khám phá thế giới cảm xúc và tình bạn.', N'Đạo diễn I', N'Lồng tiếng Việt', 96, N'Lồng tiếng Việt', N'Mỹ', N'P', 'https://www.youtube.com/watch?v=yRUAzGQ3nSY', '/media/posters/16116417-13e8-46d3-a29a-61e529048adc.jpg', '2026-11-07', NULL, N'Upcoming'),
(10, N'OÁN LINH ĐÒI MẠNG', N'Laudanum', N'Một căn phòng khóa kín lưu giữ câu chuyện khiến những người bước vào phải trả giá.', N'Đạo diễn J', N'Diễn viên 15, Diễn viên 16', 98, N'Tiếng Việt', N'Việt Nam', N'T18', 'https://www.youtube.com/watch?v=vM9t7-_Kenk', '/media/posters/3c6c718a-7c67-44b1-ba1e-af428ea43bb8.jpg', '2026-11-13', NULL, N'Upcoming'),
(11, N'TRÁI TIM MÙA ĐÔNG', N'Winter Hearts', N'Hai con người xa lạ học cách bắt đầu lại sau những biến cố của cuộc sống.', N'Đạo diễn K', N'Diễn viên 17, Diễn viên 18', 108, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, '/media/posters/4c574fa7-af54-4fc1-881b-c013224acdc8.webp', '2026-11-21', NULL, N'Upcoming'),
(12, N'CẢM XÚC LẠ KỲ: PHẦN 2', N'Strange Feelings 2', N'Phần tiếp theo mở ra chuyến phiêu lưu mới trong thế giới cảm xúc, với những thay đổi khi nhân vật bước sang giai đoạn trưởng thành.', N'Đạo diễn L', N'Lồng tiếng Việt', 102, N'Lồng tiếng Việt', N'Mỹ', N'P', 'https://www.youtube.com/watch?v=LEjhY15eCx0', '/media/posters/b698c1c6-ee1f-428f-9cdf-11687f437460.webp', '2026-11-14', NULL, N'Upcoming'),
(13, N'THÀNH PHỐ SAU MƯA', N'City After Rain', N'Một nhiếp ảnh trẻ lần theo những bức ảnh cũ để tìm lại người bạn đã mất liên lạc.', N'Đạo diễn M', N'Diễn viên 19, Diễn viên 20', 100, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, '/media/posters/6e22e5c3-a4ad-4d5b-bc88-7adee586ed0c.jpg', '2026-10-24', NULL, N'NowShowing'),
(14, N'HÀNH TRÌNH SAO BĂNG', N'Meteor Journey', N'Một nhóm bạn cùng thực hiện chuyến đi xuyên Việt để quan sát trận mưa sao băng hiếm gặp.', N'Đạo diễn N', N'Diễn viên 21, Diễn viên 22', 110, N'Tiếng Việt', N'Việt Nam', N'P', NULL, '/media/posters/895021ad-16aa-46d6-90de-5595c5b3ab67.jpg', '2026-10-24', NULL, N'NowShowing');
SET IDENTITY_INSERT dbo.Movie OFF;
GO

UPDATE dbo.Movie SET end_date = DATEADD(MONTH, 1, release_date) WHERE end_date IS NULL;
GO

INSERT dbo.MovieGenre(movie_id, genre_id)
SELECT v.movie_id, g.genre_id
FROM (VALUES
          (1, N'Action'), (1, N'Horror'),
          (2, N'Romance'), (2, N'Horror'),
          (3, N'Romance'), (3, N'Family'),
          (4, N'Action'), (4, N'Horror'),
          (5, N'Animation'), (5, N'Family'),
          (6, N'Horror'), (6, N'Science Fiction'),
          (7, N'Horror'), (7, N'Family'),
          (8, N'Horror'),
          (9, N'Animation'), (9, N'Family'),
          (10, N'Horror'),
          (11, N'Romance'), (11, N'Family'),
          (12, N'Animation'), (12, N'Family'),
          (13, N'Romance'), (13, N'Family'),
          (14, N'Animation'), (14, N'Family')
     ) AS v(movie_id, genre_name)
         JOIN dbo.Genre AS g ON g.genre_name = v.genre_name;
GO

-- ---------- Luồng 3. Rạp, phòng, ghế ----------
GO

INSERT dbo.Cinema(cinema_name, address, phone) VALUES (N'Cinema Hòa Lạc', N'Thạch Thất, Hà Nội', '0243000000');
GO

INSERT dbo.Room(cinema_id, room_name, room_type, capacity) VALUES
    (1, N'Phòng 1', '2D', 50),
    (1, N'Phòng 2', '3D', 50),
    (1, N'Phòng 3', '2D', 50),
    (1, N'Phòng 4', '3D', 50);
GO

INSERT dbo.SeatType(type_name, is_couple, description) VALUES
    (N'Standard', 0, N'Ghế thường'),
    (N'VIP', 0, N'Ghế VIP'),
    (N'Couple', 1, N'Ghế đôi (đặt theo cặp)');
GO

-- 4 phong x 5 hang x 10 ghe = 200 ghe. Hang A-C: Standard, D: VIP, E: Couple.
INSERT dbo.Seat(room_id, row_label, seat_number, seat_type_id)
SELECT r.room_id, rw.row_label, n.seat_number,
       CASE WHEN rw.row_label IN ('A','B','C') THEN 1 WHEN rw.row_label = 'D' THEN 2 ELSE 3 END
FROM dbo.Room r
         CROSS JOIN (VALUES ('A'),('B'),('C'),('D'),('E')) AS rw(row_label)
         CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS n(seat_number)
ORDER BY r.room_id, rw.row_label, n.seat_number;
GO

-- Gan ghế doi theo cap (E1-E2, E3-E4, ...)
UPDATE s
SET s.pair_seat_id = p.seat_id
    FROM dbo.Seat s
JOIN dbo.Seat p ON p.room_id = s.room_id AND p.row_label = s.row_label
    AND p.seat_number = CASE WHEN s.seat_number % 2 = 1 THEN s.seat_number + 1 ELSE s.seat_number - 1 END
WHERE s.seat_type_id = 3;
GO

-- ---------- Luồng 4. Giá vé & khuyến mãi ----------
GO

/* TimeSlot = KHUNG GIA (khong con la suat chien co dinh).
   Lich chien bay gio tu do trong ngay; slot_id cua mot suat duoc suy ra tu
   gio bat dau (Sáng / Chiều / Tối) de tra gia ve theo khung giờ. */
INSERT dbo.TimeSlot(slot_name, start_time, end_time) VALUES
    (N'Sáng', '00:00:00', '12:00:00'),
    (N'Chiều', '12:00:00', '18:00:00'),
    (N'Tối', '18:00:00', '23:59:59');
GO

INSERT dbo.Holiday(holiday_date, holiday_name) VALUES
    ('2027-01-01', N'Tết Dương lịch'),
    ('2027-02-06', N'Tết Nguyên đán');
GO

/* Gia ve theo loai ghe + khung gia (Sang / Chieu / Toi) + loai ngay. */
INSERT dbo.TicketPrice(seat_type_id, slot_id, day_type, price) VALUES
    (3,1,'Weekday',100000),(3,2,'Weekday',110000),(3,3,'Weekday',105000),
    (3,1,'Weekend',110000),(3,2,'Weekend',120000),(3,3,'Weekend',115000),
    (3,1,'Holiday',120000),(3,2,'Holiday',130000),(3,3,'Holiday',125000),
    (1,1,'Weekday',60000),(1,2,'Weekday',70000),(1,3,'Weekday',65000),
    (1,1,'Weekend',70000),(1,2,'Weekend',80000),(1,3,'Weekend',75000),
    (1,1,'Holiday',80000),(1,2,'Holiday',90000),(1,3,'Holiday',85000),
    (2,1,'Weekday',80000),(2,2,'Weekday',90000),(2,3,'Weekday',85000),
    (2,1,'Weekend',90000),(2,2,'Weekend',100000),(2,3,'Weekend',95000),
    (2,1,'Holiday',100000),(2,2,'Holiday',110000),(2,3,'Holiday',105000);
GO

INSERT dbo.Combo(combo_name, description, price, stock, status) VALUES
    (N'Combo 1 bắp + 1 nước', N'1 bắp ngọt vừa + 1 nước ngọt', 69000, 1, 'Active'),
    (N'Combo 2 bắp + 2 nước', N'2 bắp ngọt lớn + 2 nước ngọt', 119000, 100, 'Active');
GO

INSERT dbo.Voucher(code, description, discount_type, discount_value, max_discount, min_order_amount,
                   min_cumulative_spending, usage_limit, used_count, per_customer_limit, valid_from, valid_to, status, created_by) VALUES
    ('WELCOME10', N'Giảm 10% (tối đa 30k) cho khách chi tiêu từ 1 triệu', 'Percent', 10.00, 30000, 50000, 1000000, 100, 1, 1, '2026-10-17', '2026-12-17', 'Allowed', 2);
GO

INSERT dbo.MyPointConfig(earn_rate_percent, point_value_vnd, max_redeem_percent, effective_from, is_active, updated_by) VALUES
    (5.00, 1000, 20.00, '2026-10-18', 1, 2);
GO

-- ---------- Luồng 5. Lịch chiếu ----------
GO

/* Lich chien 15 ngay ke tu hom nay.
   Moi phong duoc xep suat lien tuc tu 09:00 den khi khong con phim vua gio dong cua:
     - gio ket thuc = gio bat dau + thoi luong phim
     - suat ke tiep bat dau sau khi suat truoc ket thuc 15 phut
     - phim xoay vong va lech nhau giua cac phong, nen cung mot phim co suat o
       nhieu phong voi gio khac nhau (khach co nhieu lua chon hon).
   slot_id (khung gia Sang/Chieu/Toi) duoc suy ra tu gio bat dau. */
DECLARE @day_offset INT = 1;
DECLARE @open_min INT = 9 * 60;    -- 09:00
DECLARE @close_min INT = 23 * 60;  -- 23:00
DECLARE @turnover INT = 15;

DECLARE @day DATE, @room_id INT, @room_name NVARCHAR(50), @room_index INT;
DECLARE @cursor DATETIME2(7), @close_dt DATETIME2(7);
DECLARE @movie_count INT, @movie_id INT, @duration INT, @slot_id INT, @step INT;
DECLARE @movies TABLE (rn INT PRIMARY KEY, movie_id INT NOT NULL, duration_minutes INT NOT NULL);

DECLARE roomCur CURSOR LOCAL FAST_FORWARD FOR
SELECT room_id, room_name FROM dbo.Room WHERE status = 'Active' ORDER BY room_id;

WHILE @day_offset <= 15
BEGIN
    SET @day = DATEADD(DAY, @day_offset, CAST(GETDATE() AS DATE));
    SET @close_dt = DATEADD(MINUTE, @close_min, CAST(@day AS DATETIME2(7)));
    SET @room_index = 0;

OPEN roomCur;
FETCH NEXT FROM roomCur INTO @room_id, @room_name;
WHILE @@FETCH_STATUS = 0
BEGIN
DELETE FROM @movies;
INSERT INTO @movies(rn, movie_id, duration_minutes)
SELECT ROW_NUMBER() OVER (ORDER BY m.movie_id), m.movie_id, m.duration_minutes
FROM dbo.Movie m
WHERE m.release_date <= @day
  AND (m.end_date IS NULL OR m.end_date >= @day)
  AND m.status <> 'Stopped';

SET @movie_count = (SELECT COUNT(*) FROM @movies);
        SET @cursor = DATEADD(MINUTE, @open_min, CAST(@day AS DATETIME2(7)));
        SET @step = 0;

        WHILE @movie_count > 0
BEGIN
            SET @movie_id = NULL;
            -- Uu tien phim theo vong tron lech nhau giua cac phong, nhung chi
            -- chon phim ket thuc truoc gio dong cua.
SELECT TOP (1) @movie_id = movie_id, @duration = duration_minutes
FROM @movies
WHERE DATEADD(MINUTE, duration_minutes, @cursor) <= @close_dt
ORDER BY ((rn - 1 - @room_index - @step) % @movie_count + @movie_count) % @movie_count, rn;

IF @movie_id IS NULL BREAK;

            SET @slot_id = (
                SELECT TOP (1) ts.slot_id FROM dbo.TimeSlot ts
                WHERE CAST(@cursor AS TIME(7)) >= ts.start_time
                  AND CAST(@cursor AS TIME(7)) < ts.end_time
                ORDER BY ts.start_time);

            INSERT dbo.Showtime
                (movie_id, room_id, slot_id, start_time, end_time, status, created_by, room_name, starts_at, ticket_price)
            VALUES (@movie_id, @room_id, @slot_id, @cursor, DATEADD(MINUTE, @duration, @cursor),
                    'Scheduled', NULL, @room_name, @cursor, 0);

            SET @cursor = DATEADD(MINUTE, @duration + @turnover, @cursor);
            SET @step = @step + 1;
END

        SET @room_index = @room_index + 1;
FETCH NEXT FROM roomCur INTO @room_id, @room_name;
END
CLOSE roomCur;

SET @day_offset = @day_offset + 1;
END
DEALLOCATE roomCur;
GO

-- Dien gia tri hien thi cho cac suat da sinh (gia tham chu = loai ghe re nhat).
UPDATE s
SET s.ticket_price = COALESCE(
        dbo.fn_GetTicketPrice(s.showtime_id, (SELECT MIN(st.seat_type_id) FROM dbo.SeatType st)), 0)
    FROM dbo.Showtime s
WHERE s.ticket_price IS NULL OR s.ticket_price = 0;
GO

-- ---------- Luồng 6. Đặt vé & thanh toán ----------
GO

SET IDENTITY_INSERT dbo.Booking ON;
INSERT dbo.Booking (booking_id, booking_code, customer_id, staff_id, showtime_id, channel, status, created_at,
                    session_expires_at, payment_expires_at, ticket_total, combo_total, voucher_id, voucher_discount,
                    points_used, points_discount, total_amount, paid_at) VALUES
    (1, 'BK70179E14A2', 4, NULL, 1, 'Online', 'Paid', '2026-10-18T12:15:22.3437011', '2026-10-18T12:30:22.3437011',
     '2026-10-18T12:20:22.3956680', 180000, 69000, 1, 24900, 10, 10000, 214100, '2026-10-18T12:15:22.5637018');
SET IDENTITY_INSERT dbo.Booking OFF;
GO

INSERT dbo.BookingCombo(booking_id, combo_id, quantity, unit_price) VALUES (1, 1, 1, 69000);
GO

INSERT dbo.Ticket(booking_id, showtime_id, seat_id, price, ticket_code, status, checked_in_at, checked_in_by) VALUES
    (1, 1, 35, 90000, 'TK4C537F9A2BD3', 'Booked', NULL, NULL),
    (1, 1, 36, 90000, 'TK26EDCB1E2C3D', 'Booked', NULL, NULL);
GO

INSERT dbo.Payment(booking_id, method, amount, refunded_amount, gateway_txn_id, status, created_at, paid_at) VALUES
    (1, 'BankTransfer', 214100, 0, 'TXN-DEMO-0001', 'Success', '2026-10-18T12:15:22.5637018', '2026-10-18T12:15:22.5637018');
GO

INSERT dbo.VoucherUsage(voucher_id, booking_id, customer_id, used_at) VALUES (1, 1, 4, '2026-10-18T12:15:22.5646650');
GO

INSERT dbo.MyPointTransaction(customer_id, booking_id, txn_type, points, created_at) VALUES
    (4, 1, 'Redeem', -10, '2026-10-18T12:15:22.5646650'),
    (4, 1, 'Earn', 10, '2026-10-18T12:15:22.5646650');
GO

-- ---------- Luồng 10. Thông báo ----------
GO

INSERT dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id, status, created_at, sent_at) VALUES
    (4, 'ETicket', N'Vé điện tử của bạn', N'Đính kèm mã QR các vé đã đặt.', NULL, NULL, 1, 'Pending', '2026-10-18T12:15:22.5657016', NULL);
GO

-- ---------- Luồng 11. Tin tức ----------
GO

INSERT dbo.News(title, content, thumbnail_url, status, created_by, created_at, updated_at) VALUES
 (N'Khai trương Cinema Hòa Lạc', N'Ưu đãi vé 50k trong tuần đầu tiên.', NULL, 'Published', 2, '2026-10-18T12:15:22.2421313', NULL),
 (N'Khai trương cụm rạp CineStar Quận 7', N'Cụm rạp mới với 8 phòng chiếu hiện đại, công nghệ âm thanh Dolby Atmos và ghế đôi couple chính thức đi vào hoạt động từ ngày 25/10. Nhân dịp khai trương, rạp tặng 500 vé miễn phí cho khách hàng đến sớm nhất trong ngày khai trương.', NULL, 'Published', 2, '2026-10-19T11:50:21.8015869', '2026-10-19T11:50:21.8015869'),
 (N'Ưu đãi vé cuối tuần: đồng giá 45K suất chiếu sáng', N'Từ nay đến hết tháng 11, mọi suất chiếu trước 10h sáng thứ Bảy và Chủ Nhật áp dụng giá vé đồng hạng chỉ 45.000đ cho ghế thường. Không áp dụng cùng voucher giảm giá khác. Chi tiết xem tại quầy vé hoặc mục khuyến mãi.', NULL, 'Published', 2, '2026-10-20T11:50:21.8015869', '2026-10-20T11:50:21.8015869'),
 (N'Thông báo: lịch nghỉ lễ và giờ chiếu đặc biệt', N'Rạp mở cửa xuyên suốt dịp lễ, suất chiếu muộn nhất bắt đầu lúc 23h30. Khách hàng nên đặt vé trước trên website để tránh hết chỗ ở các suất prime-time từ 19h đến 21h.', NULL, 'Published', 2, '2026-10-21T11:50:21.8015869', '2026-10-21T11:50:21.8015869'),
 (N'Bản nháp: chương trình tri âu khách hàng thân thiết', N'Nội dung đang soạn: tặng điểm MyPoint gấp đôi cho mọi giao dịch trong tháng 12...', NULL, 'Draft', 2, '2026-10-20T11:50:21.8015869', '2026-10-20T11:50:21.8015869'),
 (N'Bản nháp: lịch chiếu phim Tết 2027', N'Đang chờ xác nhận từ nhà phát hành. Chưa công bố.', NULL, 'Draft', 2, '2026-10-21T11:50:21.8015869', '2026-10-21T11:50:21.8015869'),
 (N'Bài test nội bộ - không hiển thị', N'Tin này dùng để kiểm tra tab trạng thái Đã ẩn, khách hàng không bao giờ thấy.', NULL, 'Hidden', 2, '2026-10-21T11:50:21.8015869', '2026-10-21T11:50:21.8015869');
GO

-- ---------- Luồng 13. Quản trị hệ thống ----------
GO

INSERT dbo.SystemConfig(config_key, config_value, description) VALUES
    ('BOOKING_SESSION_MINUTES', N'15', N'Thời gian tối đa của một phiên đặt vé'),
    ('CANCEL_BEFORE_HOURS', N'2', N'Chỉ được hủy vé trước giờ chiếu tối thiểu (giờ)'),
    ('CHECKIN_EARLY_MINUTES', N'30', N'Cho phép check-in sớm trước giờ chiếu (phút)'),
    ('PAYMENT_WINDOW_MINUTES', N'5', N'Thời gian giữ ghế chờ chuyển khoản'),
    ('REMINDER_HOURS_BEFORE', N'3', N'Gửi email nhắc lịch trước giờ chiếu (giờ)');
GO

/* ============================================================================
   Demo 1. Poster / trailer phim va thumbnail tin tuc
   File anh poster KHONG nam trong repo: copy vao thu muc media (media.upload.root trong
   app.properties, thu muc con posters/) hoac upload lai o trang quan ly phim.
   ============================================================================ */
SET NOCOUNT ON;

-- ===== Poster / trailer cua phim =====
UPDATE dbo.Movie SET poster_url = N'/media/posters/aab06cfe-6593-4244-8479-a206e2cba49e.jpg', trailer_url = N'https://www.youtube.com/watch?v=nlFar2vq4Yo', trailer_file = NULL WHERE movie_id = 1;
UPDATE dbo.Movie SET poster_url = N'/media/posters/5c666d59-c09e-404a-b684-61aa56b775f4.webp', trailer_url = N'https://www.youtube.com/watch?v=V-JKf_FgRjU', trailer_file = NULL WHERE movie_id = 2;
UPDATE dbo.Movie SET poster_url = N'/media/posters/de99a528-3d1f-416f-8ae5-bd92c08e6849.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 3;
UPDATE dbo.Movie SET poster_url = N'/media/posters/b21bba96-cae1-48e6-b321-5b01a4b4c374.jpg', trailer_url = N'https://www.youtube.com/watch?v=BP2_TUBOS6U', trailer_file = NULL WHERE movie_id = 4;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ad326dc5-8aa0-40f6-9288-5e85db708898.jpg', trailer_url = N'https://www.youtube.com/watch?v=UZ46Smi6mOw', trailer_file = NULL WHERE movie_id = 5;
UPDATE dbo.Movie SET poster_url = N'/media/posters/747550a1-45aa-4ecf-a0ae-df001fba3287.png', trailer_url = N'https://www.youtube.com/watch?v=zsMuQUkduug', trailer_file = NULL WHERE movie_id = 6;
UPDATE dbo.Movie SET poster_url = N'/media/posters/9950b720-692f-4774-9e6f-f51d10b89a28.jpg', trailer_url = N'https://www.youtube.com/watch?v=U6vHNWqdO0s', trailer_file = NULL WHERE movie_id = 7;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ceb78fa6-727c-45e6-8dcf-67cd7ecde2c1.jpg', trailer_url = N'https://www.youtube.com/watch?v=UOjRGIatX38', trailer_file = NULL WHERE movie_id = 8;
UPDATE dbo.Movie SET poster_url = N'/media/posters/12e088e5-6238-4d4c-b867-b16160e803b9.jpg', trailer_url = N'https://www.youtube.com/watch?v=yRUAzGQ3nSY', trailer_file = NULL WHERE movie_id = 9;
UPDATE dbo.Movie SET poster_url = N'/media/posters/833996da-8272-4cfd-a303-0a6afa6f481c.jpg', trailer_url = N'https://www.youtube.com/watch?v=vM9t7-_Kenk', trailer_file = NULL WHERE movie_id = 10;
UPDATE dbo.Movie SET poster_url = N'/media/posters/517daa27-402b-4b83-acff-5faa34730c2c.webp', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 11;
UPDATE dbo.Movie SET poster_url = N'/media/posters/ca966a45-a8be-44d4-8ea2-eb62c8a271e9.webp', trailer_url = N'https://www.youtube.com/watch?v=LEjhY15eCx0', trailer_file = NULL WHERE movie_id = 12;
UPDATE dbo.Movie SET poster_url = N'/media/posters/6f7333de-f212-4dee-84ad-bbd1da0c1599.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 13;
UPDATE dbo.Movie SET poster_url = N'/media/posters/62aa9b9b-cda5-4e1b-be48-cac65b4c4df0.jpg', trailer_url = NULL, trailer_file = NULL WHERE movie_id = 14;

-- ===== Thumbnail tin tuc =====
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-1.jpg' WHERE news_id = 1;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-2.jpg' WHERE news_id = 2;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-3.jpg' WHERE news_id = 3;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-4.jpg' WHERE news_id = 4;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-5.png' WHERE news_id = 5;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-6.png' WHERE news_id = 6;
UPDATE dbo.News SET thumbnail_url = N'/assets/img/news/news-7.png' WHERE news_id = 7;
GO

/* ============================================================================
   Demo 2. Lich chieu xoay vong 30 ngay ke tu hom nay (xoa suat chua co ve tu @from roi xep lai)
   ============================================================================ */
SET NOCOUNT ON;
DECLARE @from DATE = CAST(GETDATE() AS DATE), @to DATE = DATEADD(DAY, 29, CAST(GETDATE() AS DATE));

-- 1. Xoa cac suat chua co ve/giu cho tu ngay @from tro di (suat co du lieu lien quan duoc giu lai)
DECLARE @sql NVARCHAR(MAX) = N'DELETE s FROM dbo.Showtime s WHERE s.show_date >= @f AND s.status = ''Scheduled''';
SELECT @sql += N' AND NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
             + N' x WHERE x.' + QUOTENAME(COL_NAME(fkc.parent_object_id, fkc.parent_column_id)) + N' = s.showtime_id)'
FROM sys.foreign_keys fk
    JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
WHERE fk.referenced_object_id = OBJECT_ID('dbo.Showtime');
EXEC sp_executesql @sql, N'@f DATE', @f = @from;
DECLARE @kept INT = (SELECT COUNT(*) FROM dbo.Showtime WHERE show_date >= @from);

-- 2. Xep lich xoay vong: moi ngay mot nhom phim, thu tu va gio chieu khac nhau
DECLARE @day DATE = @from, @added INT = 0;
DECLARE @open_min INT = 9*60, @close_min INT = 23*60;
DECLARE @room_idx INT, @room_id INT, @room_name NVARCHAR(50), @cursor DATETIME2(7), @close_dt DATETIME2(7);
DECLARE @base INT, @n INT, @p INT, @try INT, @movie_id INT, @duration INT, @slot_id INT, @mins INT, @end DATETIME2(7);

CREATE TABLE #avail (rk INT PRIMARY KEY, movie_id INT, dur INT);

WHILE @day <= @to
BEGIN
TRUNCATE TABLE #avail;
-- xep hang phim theo thu tu bam rieng cua tung ngay; moi ngay bo phim xep hang 1 (khi co tu 6 phim tro len)
-- de tap phim thay doi theo ngay. rk lien tuc 1..n de con tro xoay vong khong roi vao so khong ton tai.
DECLARE @total INT = (SELECT COUNT(*) FROM dbo.Movie m
        WHERE m.release_date <= @day AND (m.end_date IS NULL OR m.end_date >= @day) AND m.status <> 'Stopped');
    INSERT #avail (rk, movie_id, dur)
SELECT ROW_NUMBER() OVER (ORDER BY h), movie_id, duration_minutes
FROM (SELECT m.movie_id, m.duration_minutes, ROW_NUMBER() OVER (ORDER BY ABS(CAST(HASHBYTES('MD5', CONCAT(m.movie_id, '#', CONVERT(varchar(10), @day, 120))) AS INT) % 1000003)) h0,
          ABS(CAST(HASHBYTES('MD5', CONCAT(m.movie_id, '#', CONVERT(varchar(10), @day, 120))) AS INT) % 1000003) h
      FROM dbo.Movie m
      WHERE m.release_date <= @day AND (m.end_date IS NULL OR m.end_date >= @day) AND m.status <> 'Stopped') q
WHERE NOT (@total >= 6 AND h0 = 1);
SET @n = (SELECT COUNT(*) FROM #avail);

    IF @n > 0
BEGIN
        SET @close_dt = DATEADD(MINUTE, @close_min, CAST(@day AS DATETIME2(7)));
        SET @base = ABS(CHECKSUM(CONCAT('p', CONVERT(varchar(10), @day, 120)))) % @n;

        DECLARE roomCur CURSOR LOCAL FAST_FORWARD FOR
SELECT room_id, room_name, ROW_NUMBER() OVER (ORDER BY room_id) FROM dbo.Room WHERE status = 'Active' ORDER BY room_id;
OPEN roomCur;
FETCH NEXT FROM roomCur INTO @room_id, @room_name, @room_idx;
WHILE @@FETCH_STATUS = 0
BEGIN
            SET @p = @base + ((@room_idx - 1) * @n) / 4;   -- moi phong bat dau o mot phim khac nhau
            SET @cursor = DATEADD(MINUTE, @open_min + 15 * (ABS(CHECKSUM(@day, @room_id, 5)) % 9), CAST(@day AS DATETIME2(7)));
            WHILE 1 = 1
BEGIN
                SET @movie_id = NULL; SET @try = 0;
                WHILE @try < @n AND @movie_id IS NULL
BEGIN
SELECT @movie_id = a.movie_id, @duration = a.dur FROM #avail a WHERE a.rk = (@p % @n) + 1;
SET @p += 1; SET @try += 1;
                    SET @end = DATEADD(MINUTE, @duration, @cursor);
                    -- phai ket thuc truoc gio dong cua, khong trung gio bat dau cung phim, khong dung suat khac cung phong
                    IF @end > @close_dt
                       OR EXISTS (SELECT 1 FROM dbo.Showtime s WHERE s.movie_id = @movie_id AND ABS(DATEDIFF(MINUTE, s.start_time, @cursor)) < 120)
                       OR EXISTS (SELECT 1 FROM dbo.Showtime s WHERE s.room_id = @room_id AND s.status <> 'Cancelled'
                                  AND s.start_time < DATEADD(MINUTE, 15, @end) AND DATEADD(MINUTE, 15, s.end_time) > @cursor)
                        SET @movie_id = NULL;
END
                IF @movie_id IS NULL BREAK;

                SET @slot_id = (SELECT TOP (1) ts.slot_id FROM dbo.TimeSlot ts
                                WHERE CAST(@cursor AS TIME(7)) >= ts.start_time AND CAST(@cursor AS TIME(7)) < ts.end_time
                                ORDER BY ts.start_time);
                INSERT dbo.Showtime (movie_id, room_id, slot_id, start_time, end_time, status, created_by, room_name, starts_at, ticket_price)
                VALUES (@movie_id, @room_id, @slot_id, @cursor, @end, 'Scheduled', NULL, @room_name, @cursor, 0);
                SET @added += 1;

                SET @mins = DATEDIFF(MINUTE, CAST(@day AS DATETIME2(7)), @cursor) + @duration + 15 + 15 * (ABS(CHECKSUM(NEWID())) % 3);
                SET @cursor = DATEADD(MINUTE, ((@mins + 14) / 15) * 15, CAST(@day AS DATETIME2(7)));
END
FETCH NEXT FROM roomCur INTO @room_id, @room_name, @room_idx;
END
CLOSE roomCur; DEALLOCATE roomCur;
END
    SET @day = DATEADD(DAY, 1, @day);
END
DROP TABLE #avail;

UPDATE s SET s.ticket_price = COALESCE(dbo.fn_GetTicketPrice(s.showtime_id, (SELECT MIN(seat_type_id) FROM dbo.SeatType)), 0)
    FROM dbo.Showtime s WHERE s.ticket_price IS NULL OR s.ticket_price = 0;

SELECT @kept AS kept_with_data, @added AS added;
GO

PRINT N'[OK] Da nap du lieu mau vao CinemaWebDB.';
GO
