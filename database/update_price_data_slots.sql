/*
    update_price_data_slots.sql — đặt lại khung giờ giá, bảng giá và phụ thu phòng (11/11/2026).
    Chạy SAU database/update_ticket_pricing.sql. Dùng được cho DB cũ (Sáng/Chiều/Tối) lẫn DB đã có 4 khung.
    Nếu DB đã đúng 2 khung "Trong ngày" + "Khuya" thì bỏ qua (không ghi đè giá Manager đã sửa).
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -C -I -b -f 65001 -i database/update_price_data_slots.sql

    Khung giờ (theo giờ bắt đầu suất chiếu, phủ kín 24 giờ):
      Trong ngày 06:00 – 22:00 | Khuya 22:00 – 06:00 (qua nửa đêm)
    Giá mỗi ghế (Khuya cao hơn 20.000đ):
                               Ngày thường  Cuối tuần  Ngày lễ
      Standard  Trong ngày         70.000      80.000    90.000
                Khuya              90.000     100.000   110.000
      VIP       Trong ngày         90.000     100.000   110.000
                Khuya             110.000     120.000   130.000
      Couple    Trong ngày        110.000     120.000   130.000
                Khuya             130.000     140.000   150.000
    Phụ thu mỗi ghế: 2D 0 | 3D 20.000 | IMAX 40.000 | 4DX 50.000
    Vé đã bán giữ nguyên giá đã lưu trong vé.
*/
USE CinemaWebDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET NOCOUNT ON;
GO

IF (SELECT COUNT(*) FROM dbo.TimeSlot) = 2
   AND EXISTS (SELECT 1 FROM dbo.TimeSlot WHERE slot_name = N'Trong ngày')
   AND EXISTS (SELECT 1 FROM dbo.TimeSlot WHERE slot_name = N'Khuya')
BEGIN
    PRINT N'[SKIP] Da co 2 khung Trong ngay + Khuya - khong chay lai.';
    RETURN;
END

IF OBJECT_ID('dbo.fn_GetSlotId', 'FN') IS NULL
    THROW 50900, N'Chưa có dbo.fn_GetSlotId — hãy chạy database/update_ticket_pricing.sql trước.', 1;

BEGIN TRAN;

DECLARE @old_slots NVARCHAR(200) = (SELECT STRING_AGG(CONCAT(slot_name, N' ', CONVERT(varchar(5), start_time, 108)), N', ')
                                      WITHIN GROUP (ORDER BY start_time) FROM dbo.TimeSlot);

-- 1. Giữ khung có slot_id nhỏ nhất (không phải Khuya) làm "Trong ngày"; giữ / tạo Khuya; gộp các khung còn lại.
DECLARE @day INT = (SELECT MIN(slot_id) FROM dbo.TimeSlot WHERE slot_name <> N'Khuya');
DECLARE @night INT = (SELECT slot_id FROM dbo.TimeSlot WHERE slot_name = N'Khuya');

UPDATE dbo.Showtime SET slot_id = @day
WHERE slot_id NOT IN (@day, ISNULL(@night, -1));
DELETE FROM dbo.TicketPrice;
DELETE FROM dbo.TimeSlot WHERE slot_id NOT IN (@day, ISNULL(@night, -1));

-- Đặt giờ trong một câu UPDATE để UNIQUE(start_time) chỉ kiểm tra sau khi đổi xong
UPDATE dbo.TimeSlot
SET slot_name = CASE WHEN slot_id = @day THEN N'Trong ngày' ELSE N'Khuya' END,
    start_time = CASE WHEN slot_id = @day THEN CAST('06:00' AS TIME(7)) ELSE CAST('22:00' AS TIME(7)) END,
    end_time = CASE WHEN slot_id = @day THEN CAST('22:00' AS TIME(7)) ELSE CAST('06:00' AS TIME(7)) END;
IF @night IS NULL
    INSERT dbo.TimeSlot(slot_name, start_time, end_time) VALUES (N'Khuya', '22:00', '06:00');

-- 2. Xếp lại khung cho mọi suất chiếu theo giờ bắt đầu
UPDATE s SET slot_id = dbo.fn_GetSlotId(CONVERT(TIME(7), s.start_time))
FROM dbo.Showtime s
WHERE s.slot_id <> dbo.fn_GetSlotId(CONVERT(TIME(7), s.start_time));
DECLARE @moved INT = @@ROWCOUNT;

-- 3. Bảng giá mới
INSERT dbo.TicketPrice(seat_type_id, slot_id, day_type, price, effective_from, updated_at)
SELECT st.seat_type_id, s.slot_id, d.day_type,
       d.base + t.extra + CASE WHEN s.slot_name = N'Khuya' THEN 20000 ELSE 0 END,
       '20000101', SYSDATETIME()
FROM (VALUES (N'Standard', 0), (N'VIP', 20000), (N'Couple', 40000)) AS t(type_name, extra)
JOIN dbo.SeatType st ON st.type_name = t.type_name
CROSS JOIN (VALUES ('Weekday', 70000), ('Weekend', 80000), ('Holiday', 90000)) AS d(day_type, base)
CROSS JOIN dbo.TimeSlot s;

-- 4. Phụ thu theo loại phòng
UPDATE rt SET surcharge = v.sc
FROM dbo.RoomType rt
JOIN (VALUES ('2D', 0), ('3D', 20000), ('IMAX', 40000), ('4DX', 50000)) v(code, sc) ON v.code = rt.type_code;

-- 5. Nhật ký
INSERT dbo.PriceChangeLog(category, item, old_value, new_value, note) VALUES
    ('TimeSlot', N'Khung giờ giá', LEFT(@old_slots, 100), N'Trong ngày 06:00, Khuya 22:00',
        CONCAT(N'Thiết lập lại bằng script; xếp lại ', @moved, N' suất chiếu')),
    ('Price', N'Toàn bộ bảng giá', NULL, N'Standard 70.000 – Couple 150.000đ',
        N'Thiết lập lại: Khuya cao hơn Trong ngày 20.000đ'),
    ('Surcharge', N'Phụ thu loại phòng', NULL, N'3D 20k, IMAX 40k, 4DX 50k', N'Thiết lập lại bằng script');

COMMIT;
DECLARE @cells INT = (SELECT COUNT(*) FROM dbo.TicketPrice);
PRINT CONCAT(N'[OK] 2 khung gio, ', @cells, N' o gia, xep lai ', @moved, N' suat chieu.');
GO
