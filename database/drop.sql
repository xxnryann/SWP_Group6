/*
    drop.sql - (tùy chọn) xóa sạch CinemaWebDB để chạy lại từ đầu.
    CẢNH BÁO: xóa toàn bộ dữ liệu. Sao lưu trước nếu cần giữ.
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -b -f 65001 -i database/drop.sql
*/

USE master;
GO

IF DB_ID(N'CinemaWebDB') IS NOT NULL
BEGIN
    DECLARE @dropSql NVARCHAR(MAX) =
        N'ALTER DATABASE [CinemaWebDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [CinemaWebDB];';
    EXEC sys.sp_executesql @dropSql;
END
GO

PRINT N'[OK] Da xoa CinemaWebDB (neu co).';
GO
