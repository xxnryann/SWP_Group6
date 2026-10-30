/* ----------------------------------------------------------------------------
   seed_demo.sql - DU LIEU DEMO TUY CHON (chay SAU cinemaweb.sql).

   1) Poster / trailer cua 14 phim va thumbnail cac tin tuc.
      File anh poster KHONG nam trong repo: copy vao thu muc media (media.upload.root trong app.properties,
      thu muc con posters/) hoac upload lai o trang quan ly phim, neu khong poster se bi trong.
      Thumbnail tin tuc la /assets/img/news/news-N.png (co trong repo).
   2) Lich chieu xoay vong theo ngay: sua @from / @to o dau muc 2 cho khoang ngay can xep.

   Chay:  sqlcmd -S <server> -d CinemaWebDB -I -f 65001 -i sql\seed_demo.sql
   -------------------------------------------------------------------------- */
GO

/* ============================================================================
   1. Poster / trailer phim va thumbnail tin tuc
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
   2. Lich chieu xoay vong theo ngay (xoa suat chua co ve tu @from roi xep lai)
   ============================================================================ */
SET NOCOUNT ON;
DECLARE @from DATE = '2026-10-29', @to DATE = '2026-11-27';

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
