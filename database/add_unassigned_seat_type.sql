/*
    Thêm loại ghế "Unassigned" (chưa được chọn loại) vào hệ thống
    Loại ghế này sẽ được dùng mặc định khi tạo phòng mới
    Màu xám, không thể đặt vé cho đến khi admin đổi sang loại khác
*/

USE [CinemaWebDB];
GO

-- Thêm loại ghế Unassigned nếu chưa có
IF NOT EXISTS (SELECT 1 FROM dbo.SeatType WHERE type_name = N'Unassigned')
BEGIN
    INSERT INTO dbo.SeatType(type_name, is_couple, description)
    VALUES (N'Unassigned', 0, N'Chưa chọn loại ghế (cần admin thiết lập)');

    PRINT 'Đã thêm loại ghế Unassigned thành công.';
END
ELSE
BEGIN
    PRINT 'Loại ghế Unassigned đã tồn tại.';
END
GO

-- Kiểm tra kết quả
SELECT seat_type_id, type_name, is_couple, description
FROM dbo.SeatType
ORDER BY seat_type_id;
GO
