/*
    update_ticket_pricing.sql — nâng cấp DB CinemaWebDB cũ cho phần quản lý giá vé (11/11/2026).
    Giữ nguyên dữ liệu, chạy lại nhiều lần vẫn an toàn. Nhớ dùng -I (QUOTED_IDENTIFIER ON):
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -C -I -b -f 65001 -i database/update_ticket_pricing.sql
    Nội dung:
      - TicketPrice: effective_from (lịch đổi giá), updated_by, updated_at; khóa duy nhất theo phiên bản
      - PriceChangeLog: nhật ký thay đổi giá
      - Holiday.is_recurring, RoomType.surcharge
      - fn_GetDayType, fn_GetPriceFor, fn_GetTicketPrice (có phụ thu phòng, ngày lễ lặp hằng năm)
      - sp_HoldSeats: báo lỗi 50018 dễ hiểu khi chưa có giá
      - fn_GetSlotId + trigger Showtime: khung giờ vòng qua nửa đêm (Khuya 22:00 - 06:00)
*/
USE CinemaWebDB;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.TicketPrice', 'effective_from') IS NULL
    ALTER TABLE dbo.TicketPrice ADD effective_from DATE NOT NULL CONSTRAINT DF_TicketPrice_From DEFAULT '20000101';
IF COL_LENGTH('dbo.TicketPrice', 'updated_by') IS NULL
    ALTER TABLE dbo.TicketPrice ADD updated_by INT NULL
        CONSTRAINT FK_TicketPrice_Updater FOREIGN KEY REFERENCES dbo.Account(account_id);
IF COL_LENGTH('dbo.TicketPrice', 'updated_at') IS NULL
    ALTER TABLE dbo.TicketPrice ADD updated_at DATETIME2(7) NULL;
GO
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_TicketPrice' AND parent_object_id = OBJECT_ID('dbo.TicketPrice'))
    ALTER TABLE dbo.TicketPrice DROP CONSTRAINT UQ_TicketPrice;
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_TicketPrice_Version')
    ALTER TABLE dbo.TicketPrice ADD CONSTRAINT UQ_TicketPrice_Version UNIQUE (seat_type_id, slot_id, day_type, effective_from);
GO

IF COL_LENGTH('dbo.Holiday', 'is_recurring') IS NULL
    ALTER TABLE dbo.Holiday ADD is_recurring BIT NOT NULL CONSTRAINT DF_Holiday_Recurring DEFAULT 0;
IF COL_LENGTH('dbo.RoomType', 'surcharge') IS NULL
    ALTER TABLE dbo.RoomType ADD surcharge DECIMAL(10,0) NOT NULL CONSTRAINT DF_RoomType_Surcharge DEFAULT 0
        CONSTRAINT CK_RoomType_Surcharge CHECK (surcharge >= 0);
GO

IF OBJECT_ID('dbo.PriceChangeLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PriceChangeLog (
        log_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PriceChangeLog PRIMARY KEY,
        category VARCHAR(20) NOT NULL,
        item NVARCHAR(200) NOT NULL,
        old_value NVARCHAR(100) NULL,
        new_value NVARCHAR(100) NULL,
        note NVARCHAR(200) NULL,
        changed_by INT NULL,
        changed_at DATETIME2(7) NOT NULL CONSTRAINT DF_PriceChangeLog_At DEFAULT SYSDATETIME(),
        CONSTRAINT FK_PriceChangeLog_Account FOREIGN KEY (changed_by) REFERENCES dbo.Account(account_id),
        CONSTRAINT CK_PriceChangeLog_Category CHECK (category IN ('Price','Schedule','Surcharge','TimeSlot','Holiday'))
    );
    CREATE INDEX IX_PriceChangeLog_At ON dbo.PriceChangeLog(changed_at DESC);
END
GO

DROP FUNCTION IF EXISTS dbo.fn_GetTicketPrice;
DROP FUNCTION IF EXISTS dbo.fn_GetPriceFor;
DROP FUNCTION IF EXISTS dbo.fn_GetDayType;
DROP FUNCTION IF EXISTS dbo.fn_GetSlotId;
GO
-- Khung gia cua mot gio bat dau. Khung keo dai toi gio bat dau cua khung ke tiep va vong qua
-- nua dem: gio som hon moi khung thuoc khung bat dau muon nhat (vd. 01:00 thuoc Khuya 22:00 - 06:00).
CREATE FUNCTION dbo.fn_GetSlotId(@t TIME(7)) RETURNS INT AS
BEGIN
    RETURN (SELECT TOP (1) slot_id FROM dbo.TimeSlot
            ORDER BY CASE WHEN start_time <= @t THEN 0 ELSE 1 END, start_time DESC);
END
GO

-- Loai ngay: le (co dinh hoac lap lai hang nam) > cuoi tuan (T7, CN) > ngay thuong
CREATE FUNCTION dbo.fn_GetDayType(@d DATE) RETURNS VARCHAR(10) AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM dbo.Holiday h
                             WHERE h.holiday_date = @d
                                OR (h.is_recurring = 1 AND h.holiday_date <= @d
                                    AND MONTH(h.holiday_date) = MONTH(@d) AND DAY(h.holiday_date) = DAY(@d)))
                     THEN 'Holiday'
                WHEN DATEDIFF(DAY, '19000107', @d) % 7 IN (0, 6) THEN 'Weekend'   -- CN, T7
                ELSE 'Weekday' END;
END
GO

-- Gia 1 ghe = gia o (phien ban hieu luc tai ngay chieu) + phu thu loai phong. NULL = chua cau hinh gia.
CREATE FUNCTION dbo.fn_GetPriceFor(@seat_type_id INT, @d DATE, @slot_id INT, @room_type VARCHAR(20)) RETURNS DECIMAL(10,0) AS
BEGIN
    DECLARE @price DECIMAL(10,0), @day_type VARCHAR(10) = dbo.fn_GetDayType(@d);
    SELECT TOP (1) @price = price FROM dbo.TicketPrice
    WHERE seat_type_id = @seat_type_id AND slot_id = @slot_id AND day_type = @day_type AND effective_from <= @d
    ORDER BY effective_from DESC;
    IF @price IS NULL RETURN NULL;
    RETURN @price + ISNULL((SELECT surcharge FROM dbo.RoomType WHERE type_code = @room_type), 0);
END
GO

-- Gia ve theo suat chieu: loai ghe + khung gio + loai ngay + phu thu phong
CREATE FUNCTION dbo.fn_GetTicketPrice(@showtime_id INT, @seat_type_id INT) RETURNS DECIMAL(10,0) AS
BEGIN
    DECLARE @slot INT, @d DATE, @room_type VARCHAR(20);
    SELECT @slot = s.slot_id, @d = s.show_date, @room_type = r.room_type
    FROM dbo.Showtime s JOIN dbo.Room r ON r.room_id = s.room_id WHERE s.showtime_id = @showtime_id;
    RETURN dbo.fn_GetPriceFor(@seat_type_id, @d, @slot, @room_type);
END
GO

DROP PROCEDURE IF EXISTS dbo.sp_HoldSeats;
GO
CREATE PROCEDURE dbo.sp_HoldSeats @booking_id INT, @seat_ids NVARCHAR(MAX) AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    EXEC dbo.sp_ReleaseExpiredHolds;

    DECLARE @showtime_id INT, @status VARCHAR(15), @session_exp DATETIME2, @room_id INT;
    DECLARE @pay_min INT = (SELECT CAST(config_value AS INT) FROM dbo.SystemConfig WHERE config_key = 'PAYMENT_WINDOW_MINUTES');
    SELECT @showtime_id = b.showtime_id, @status = b.status, @session_exp = b.session_expires_at, @room_id = s.room_id
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id WHERE b.booking_id = @booking_id;

    IF @status IS NULL THROW 50010, N'Không tìm thấy booking.', 1;
    IF @status <> 'Selecting' OR @session_exp < SYSDATETIME()
        THROW 50011, N'Phiên đặt vé đã hết hạn (tối đa 15 phút) hoặc không ở bước chọn ghế.', 1;

    DECLARE @sel TABLE (seat_id INT PRIMARY KEY);
    INSERT INTO @sel SELECT DISTINCT CAST(value AS INT) FROM STRING_SPLIT(@seat_ids, ',') WHERE LTRIM(RTRIM(value)) <> '';

    IF NOT EXISTS (SELECT 1 FROM @sel) THROW 50013, N'Chưa chọn ghế nào.', 1;
    IF EXISTS (SELECT 1 FROM @sel x LEFT JOIN dbo.Seat s ON s.seat_id = x.seat_id AND s.room_id = @room_id WHERE s.seat_id IS NULL)
        THROW 50014, N'Có ghế không thuộc phòng chiếu của suất này.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Seat s JOIN @sel x ON x.seat_id = s.seat_id WHERE s.status = 'Maintenance')
        THROW 50015, N'Có ghế đang bảo trì, không thể chọn.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Seat s JOIN @sel x ON x.seat_id = s.seat_id
               WHERE s.pair_seat_id IS NOT NULL AND s.pair_seat_id NOT IN (SELECT seat_id FROM @sel))
        THROW 50016, N'Ghế đôi phải được chọn cả cặp, không được tách.', 1;

    DECLARE @no_price NVARCHAR(400) = (
        SELECT STRING_AGG(t.type_name, N', ') FROM (
            SELECT DISTINCT st.type_name FROM dbo.Seat s JOIN @sel x ON x.seat_id = s.seat_id
            JOIN dbo.SeatType st ON st.seat_type_id = s.seat_type_id
            WHERE dbo.fn_GetTicketPrice(@showtime_id, s.seat_type_id) IS NULL) t);
    IF @no_price IS NOT NULL
    BEGIN
        DECLARE @no_price_msg NVARCHAR(600) = N'Suất chiếu này chưa có giá vé cho loại ghế: ' + @no_price
            + N'. Vui lòng chọn ghế khác hoặc liên hệ rạp.';
        THROW 50018, @no_price_msg, 1;
    END

    BEGIN TRY
        BEGIN TRAN;
        INSERT INTO dbo.Ticket(booking_id, showtime_id, seat_id, price, ticket_code, status)
        SELECT @booking_id, @showtime_id, s.seat_id, dbo.fn_GetTicketPrice(@showtime_id, s.seat_type_id),
               'TK' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 12)), 'Held'
        FROM dbo.Seat s JOIN @sel x ON x.seat_id = s.seat_id;

        UPDATE dbo.Booking SET status = 'PendingPayment',
               payment_expires_at = CASE WHEN DATEADD(MINUTE, @pay_min, SYSDATETIME()) < session_expires_at
                                         THEN DATEADD(MINUTE, @pay_min, SYSDATETIME()) ELSE session_expires_at END
        WHERE booking_id = @booking_id;
        EXEC dbo.sp_RecalcBooking @booking_id;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        IF ERROR_NUMBER() IN (2601, 2627) THROW 50017, N'Có ghế vừa được người khác giữ hoặc đặt.', 1;
        THROW;
    END CATCH
END
GO

DROP TRIGGER IF EXISTS dbo.trg_Showtime_SyncDaoCompatibility;
GO
CREATE TRIGGER dbo.trg_Showtime_SyncDaoCompatibility
ON dbo.Showtime
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(room_name) AND NOT UPDATE(starts_at)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.Room r
                          WHERE r.room_name = i.room_name AND r.status = 'Active')
    )
        THROW 51030, N'Không tìm thấy phòng đang hoạt động với tên đã chọn.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.TimeSlot)
        THROW 51031, N'Chưa cấu hình khung giờ giá nào.', 1;

    UPDATE s
    SET s.room_id = roomChoice.room_id,
        s.slot_id = slotChoice.slot_id,
        s.start_time = i.starts_at,
        s.end_time = DATEADD(MINUTE, m.duration_minutes, i.starts_at)
    FROM dbo.Showtime s
    JOIN inserted i ON i.showtime_id = s.showtime_id
    JOIN dbo.Movie m ON m.movie_id = i.movie_id
    CROSS APPLY (
        SELECT TOP (1) r.room_id
        FROM dbo.Room r
        WHERE r.room_name = i.room_name AND r.status = 'Active'
        ORDER BY r.room_id
    ) roomChoice
    CROSS APPLY (SELECT dbo.fn_GetSlotId(CONVERT(TIME(7), i.starts_at)) AS slot_id) slotChoice
    WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL;
END
GO

PRINT N'[OK] Da nang cap phan gia ve (TicketPrice phien ban, PriceChangeLog, phu thu phong, ngay le lap lai).';
GO
