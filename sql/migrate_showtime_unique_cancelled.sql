-- Cho phép tạo lại suất chiếu ở giờ đã có một suất bị huỷ trong cùng phòng.
-- Trước đây UQ_Showtime_Room_Start (room_id, start_time) tính cả suất đã huỷ nên giờ đó không bao giờ dùng lại được
-- (ví dụ sau khi "Ngừng chiếu" / "Hủy phim"). Chạy file này một lần trên CSDL đã có sẵn; chạy lại nhiều lần vẫn an toàn.
USE CinemaWebDB;
GO
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Showtime_Room_Start' AND parent_object_id = OBJECT_ID('dbo.Showtime'))
    ALTER TABLE dbo.Showtime DROP CONSTRAINT UQ_Showtime_Room_Start;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Showtime_Room_Start' AND object_id = OBJECT_ID('dbo.Showtime'))
    CREATE UNIQUE INDEX UQ_Showtime_Room_Start ON dbo.Showtime(room_id, start_time) WHERE status <> 'Cancelled';
GO
