/* ----------------------------------------------------------------------------
   upgrade.sql - NANG CAP CSDL DA TON TAI (khong mat du lieu).

   Dung khi da co CinemaWebDB tao tu ban cu cua cinemaweb.sql. CSDL tao moi tu cinemaweb.sql
   da co san moi thay doi duoi day, KHONG can chay file nay.
   Moi muc deu idempotent: chay lai nhieu lan van an toan. Thu tu cac muc = thu tu thoi gian.

   Chay:  sqlcmd -S <server> -d CinemaWebDB -I -f 65001 -i sql\upgrade.sql      (xac thuc: SQLCMDPASSWORD hoac -E)
   Sau do cap nhat stored procedure:  scripts\compare-procedures.ps1 -Sync

   Khi doi cinemaweb.sql, them mot muc moi vao CUOI file nay (dat so thu tu + ngay).
   -------------------------------------------------------------------------- */
SET XACT_ABORT ON;
GO

/* ============================================================================
   1. Thong tin ca nhan mo rong cho Users (28/10/2026)
   ============================================================================ */
/*
  Thong tin ca nhan mo rong cho Users (CMND/CCCD, tinh/thanh, quan/huyen, dia chi, anh dai dien).
  Chay tren DB DA TON TAI (DB tao moi tu sql/cinemaweb.sql da co san cac cot nay). An toan khi chay lai.
*/
IF COL_LENGTH('dbo.Users', 'IdNumber')  IS NULL ALTER TABLE dbo.Users ADD IdNumber  VARCHAR(20)   NULL;
IF COL_LENGTH('dbo.Users', 'Province')  IS NULL ALTER TABLE dbo.Users ADD Province  NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'District')  IS NULL ALTER TABLE dbo.Users ADD District  NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'Address')   IS NULL ALTER TABLE dbo.Users ADD Address   NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Users', 'AvatarUrl') IS NULL ALTER TABLE dbo.Users ADD AvatarUrl VARCHAR(100)  NULL;
GO

/* ============================================================================
   2. Suat chieu da huy khong chiem gio cua phong (29/10/2026)
   ============================================================================ */
-- Cho phép tạo lại suất chiếu ở giờ đã có một suất bị huỷ trong cùng phòng.
-- Trước đây UQ_Showtime_Room_Start (room_id, start_time) tính cả suất đã huỷ nên giờ đó không bao giờ dùng lại được
-- (ví dụ sau khi "Ngừng chiếu" / "Hủy phim"). Chạy file này một lần trên CSDL đã có sẵn; chạy lại nhiều lần vẫn an toàn.
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Showtime_Room_Start' AND parent_object_id = OBJECT_ID('dbo.Showtime'))
    ALTER TABLE dbo.Showtime DROP CONSTRAINT UQ_Showtime_Room_Start;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Showtime_Room_Start' AND object_id = OBJECT_ID('dbo.Showtime'))
    CREATE UNIQUE INDEX UQ_Showtime_Room_Start ON dbo.Showtime(room_id, start_time) WHERE status <> 'Cancelled';
GO

/* ============================================================================
   3. Hoan tien chi ghi o dong Payment goc, bo sp_CancelBooking (30/10/2026)
   ============================================================================ */
/* ----------------------------------------------------------------------------
   Migration: hoan tien chi ghi o MOT cho (dong thanh toan goc)

   Van de cu: sp_CancelTicket / sp_CancelMovie vua THEM dong Payment 'Refunded' cho lan hoan,
   vua cong don refunded_amount len dong goc -> tong refunded_amount / amount cua don bi tinh doi.

   Quy uoc moi: Payment.refunded_amount cua dong thanh toan goc la so tien da hoan (cong don);
   hoan du so tien -> status = 'Refunded'. Khong con dong Payment rieng cho tung lan hoan.

   File nay: (1) gop cac dong hoan cu vao dong goc, (2) xoa procedure khong dung sp_CancelBooking.
   Chay idempotent (chay lai khong doi gi). Sau khi chay, cap nhat procedure moi:
       scripts\compare-procedures.ps1 -Sync

   -------------------------------------------------------------------------- */
SET XACT_ABORT ON;
BEGIN TRAN;

-- Dong goc = dong thanh toan co payment_id nho nhat (Success / Refunded) cua moi don.
-- Dong hoan cu = dong 'Refunded' co payment_id lon hon dong goc cung don.
SELECT p.payment_id, p.booking_id, p.amount
INTO #refund_rows
FROM dbo.Payment p
JOIN (SELECT booking_id, MIN(payment_id) AS first_id
      FROM dbo.Payment WHERE status IN ('Success', 'Refunded') GROUP BY booking_id) o
     ON o.booking_id = p.booking_id AND p.payment_id > o.first_id
WHERE p.status = 'Refunded';

-- Gop: so tien hoan cua dong goc = max(gia tri dang co, tong cac dong hoan cu), khong vuot amount.
UPDATE o SET
    o.refunded_amount = CASE WHEN x.total > o.refunded_amount THEN
                                  CASE WHEN x.total > o.amount THEN o.amount ELSE x.total END
                             ELSE o.refunded_amount END,
    o.status = CASE WHEN (CASE WHEN x.total > o.refunded_amount THEN
                                    CASE WHEN x.total > o.amount THEN o.amount ELSE x.total END
                               ELSE o.refunded_amount END) >= o.amount THEN 'Refunded' ELSE o.status END
FROM dbo.Payment o
JOIN (SELECT r.booking_id, SUM(r.amount) AS total FROM #refund_rows r GROUP BY r.booking_id) x
     ON x.booking_id = o.booking_id
JOIN (SELECT booking_id, MIN(payment_id) AS first_id
      FROM dbo.Payment WHERE status IN ('Success', 'Refunded') GROUP BY booking_id) f
     ON f.booking_id = o.booking_id AND f.first_id = o.payment_id;

DELETE p FROM dbo.Payment p JOIN #refund_rows r ON r.payment_id = p.payment_id;
PRINT CONCAT('Da gop ', @@ROWCOUNT, ' dong hoan tien cu vao dong thanh toan goc.');

DROP TABLE #refund_rows;
COMMIT;
GO

-- Procedure khong co noi nao goi (huy ca don duoc xu ly boi sp_CancelTicket / sp_CancelMovie).
DROP PROCEDURE IF EXISTS dbo.sp_CancelBooking;
GO

/* ============================================================================
   4. Doi ten hien thi tai khoan seed manager / staff (30/10/2026)
   ============================================================================ */
-- Doi ten hien thi cua 2 tai khoan seed: manager -> "Quan li", staff -> "Nhan vien".
UPDATE dbo.Account SET full_name = N'Quản lí'   WHERE email = N'manager@cinema.vn';
UPDATE dbo.Users   SET FullName  = N'Quản lí'   WHERE Email = N'manager@cinema.vn';
UPDATE dbo.Account SET full_name = N'Nhân viên' WHERE email = N'staff@cinema.vn';
UPDATE dbo.Users   SET FullName  = N'Nhân viên' WHERE Email = N'staff@cinema.vn';
GO

/* ============================================================================
   5. Anh tin tuc 1-4 doi tu PNG (2 MB) sang JPEG nhe (30/10/2026)
   ============================================================================ */
UPDATE dbo.News SET thumbnail_url = REPLACE(thumbnail_url, '.png', '.jpg')
WHERE thumbnail_url LIKE '/assets/img/news/news-[1-4].png';
GO

/* ============================================================================
   6. Thong bao huy ve cho hop thu khach hang: them loai 'TicketCancelled' (31/10/2026)
   ============================================================================ */
-- Sau khi chay, cap nhat sp_CancelTicket:  scripts\compare-procedures.ps1 -Sync
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EmailNotification_Type'
               AND parent_object_id = OBJECT_ID('dbo.EmailNotification') AND definition LIKE '%TicketCancelled%')
BEGIN
    ALTER TABLE dbo.EmailNotification DROP CONSTRAINT CK_EmailNotification_Type;
    ALTER TABLE dbo.EmailNotification ADD CONSTRAINT CK_EmailNotification_Type
        CHECK (notif_type IN ('ETicket','ShowtimeReminder','NewMovie','Voucher','MovieCancelled','TicketCancelled'));
END
GO

/* ============================================================================
   7. Xoa mem phim da co lich su: Movie.is_deleted (31/10/2026)
   ============================================================================ */
-- Sau khi chay, cap nhat sp_DeleteMovie:  scripts\compare-procedures.ps1 -Sync
IF COL_LENGTH('dbo.Movie', 'is_deleted') IS NULL
    ALTER TABLE dbo.Movie ADD is_deleted BIT NOT NULL CONSTRAINT DF_Movie_IsDeleted DEFAULT 0;
GO
-- Phim da xoa mem khong giu ten: co the them lai phim cung ten.
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Movie_Title' AND object_id = OBJECT_ID('dbo.Movie') AND has_filter = 0)
    DROP INDEX UX_Movie_Title ON dbo.Movie;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Movie_Title' AND object_id = OBJECT_ID('dbo.Movie'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_Movie_Title ON dbo.Movie(title) WHERE is_deleted = 0;
GO
CREATE OR ALTER VIEW dbo.vw_MovieDetail
AS
SELECT m.movie_id, m.title, m.original_title, m.synopsis, m.director, m.main_cast,
       m.duration_minutes, m.spoken_language, m.country, m.age_rating, m.trailer_url,
       m.trailer_file, m.poster_url, m.release_date, m.end_date, m.status,
       m.created_at, m.updated_at, m.created_by, a.full_name AS created_by_name,
       (SELECT STRING_AGG(g.genre_name, N', ')
        FROM dbo.MovieGenre mg JOIN dbo.Genre g ON g.genre_id = mg.genre_id
        WHERE mg.movie_id = m.movie_id) AS genres,
       (SELECT STRING_AGG(CONVERT(VARCHAR(11), mg.genre_id), ',')
                WITHIN GROUP (ORDER BY mg.genre_id)
        FROM dbo.MovieGenre mg WHERE mg.movie_id = m.movie_id) AS genre_ids,
       (SELECT AVG(CAST(r.rating AS DECIMAL(3,2)))
        FROM dbo.Review r WHERE r.movie_id = m.movie_id) AS avg_rating,
       (SELECT COUNT(*) FROM dbo.Review r WHERE r.movie_id = m.movie_id) AS review_count
FROM dbo.Movie m
LEFT JOIN dbo.Account a ON a.account_id = m.created_by
WHERE m.is_deleted = 0;
GO

/* ============================================================================
   8. Danh gia phim chi sau khi suat chieu ket thuc (01/11/2026)
   ============================================================================ */
-- Chi doi sp_AddReview, sp_GetCustomerTickets:  scripts\compare-procedures.ps1 -Sync

/* ============================================================================
   9. Nhac danh gia sau khi xem phim, thuong 5 diem MyPoint (01/11/2026)
   ============================================================================ */
-- Sau khi chay, tao sp_QueueReviewReminders va cap nhat sp_AddReview:  scripts\compare-procedures.ps1 -Sync
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_EmailNotification_Type'
               AND parent_object_id = OBJECT_ID('dbo.EmailNotification') AND definition LIKE '%ReviewReminder%')
BEGIN
    ALTER TABLE dbo.EmailNotification DROP CONSTRAINT CK_EmailNotification_Type;
    ALTER TABLE dbo.EmailNotification ADD CONSTRAINT CK_EmailNotification_Type
        CHECK (notif_type IN ('ETicket','ShowtimeReminder','NewMovie','Voucher','MovieCancelled','TicketCancelled','ReviewReminder'));
END
GO

/* ============================================================================
   10. Email phim moi / voucher, chan soat ve trung (01/11/2026)
   ============================================================================ */
-- Chi doi procedure (sp_QueueNewMovieEmail, sp_QueueVoucherEmail, sp_CheckInTicket, sp_DeleteMovie):
--     scripts\compare-procedures.ps1 -Sync
