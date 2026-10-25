/*
    CinemaDB - focused schema for the current Movie and Showtime modules
    ================================================================
    This script intentionally creates only:
      Users, Account, AppRole, Customer
      Genre, Movie, MovieGenre, vw_MovieDetail
      Cinema, Room, TimeSlot, Showtime

    Intentionally not created yet (kept as documentation only):
      Booking, Ticket, Seat, SeatType, vw_SeatMap, Combo, BookingCombo,
      Payment, TicketPrice, Holiday, Voucher, VoucherUsage, Review,
      News, EmailNotification, MyPointConfig, MyPointTransaction,
      Permission, RolePermission, SystemConfig, SystemLog and related procedures.

    Run this file only against a new/empty CinemaDB. It does not drop an
    existing database and does not contain machine-specific MDF/LDF paths.
*/

USE master;
GO

IF DB_ID(N'CinemaDB') IS NULL
    CREATE DATABASE CinemaDB;
GO

USE CinemaDB;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Account module ---------- */
CREATE TABLE dbo.AppRole (
    role_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AppRole PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL CONSTRAINT UQ_AppRole_Name UNIQUE
);
GO

CREATE TABLE dbo.Account (
    account_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Account PRIMARY KEY,
    role_id INT NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) NOT NULL CONSTRAINT UQ_Account_Email UNIQUE,
    phone VARCHAR(15) NULL CONSTRAINT UQ_Account_Phone UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CONSTRAINT DF_Account_Status DEFAULT 'Active',
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Account_Created DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Account_Role FOREIGN KEY (role_id) REFERENCES dbo.AppRole(role_id)
);
GO

CREATE TABLE dbo.Users (
    UserId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL CONSTRAINT UQ_Users_Email UNIQUE,
    Phone VARCHAR(15) NOT NULL CONSTRAINT UQ_Users_Phone UNIQUE,
    PasswordHash VARCHAR(100) NOT NULL,
    DateOfBirth DATE NULL,
    Gender VARCHAR(10) NULL,
    Role VARCHAR(20) NOT NULL CONSTRAINT DF_Users_Role DEFAULT 'CUSTOMER',
    Status VARCHAR(20) NOT NULL CONSTRAINT DF_Users_Status DEFAULT 'PENDING',
    OtpHash VARCHAR(64) NULL,
    OtpExpiry DATETIME2(7) NULL,
    OtpAttempts INT NOT NULL CONSTRAINT DF_Users_OtpAttempts DEFAULT 0,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Users_Created DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Users_Role CHECK (Role IN ('CUSTOMER','STAFF','MANAGER','ADMIN')),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('PENDING','ACTIVE','BLOCKED'))
);
GO

CREATE TABLE dbo.Customer (
    customer_id INT NOT NULL CONSTRAINT PK_Customer PRIMARY KEY,
    my_point_balance INT NOT NULL CONSTRAINT DF_Customer_Points DEFAULT 0,
    total_spent DECIMAL(14,0) NOT NULL CONSTRAINT DF_Customer_Spent DEFAULT 0,
    CONSTRAINT FK_Customer_User FOREIGN KEY (customer_id) REFERENCES dbo.Users(UserId)
);
GO

/* ---------- Movie module ---------- */
CREATE TABLE dbo.Genre (
    genre_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Genre PRIMARY KEY,
    genre_name NVARCHAR(50) NOT NULL CONSTRAINT UQ_Genre_Name UNIQUE,
    description NVARCHAR(200) NULL
);
GO

CREATE TABLE dbo.Movie (
    movie_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Movie PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    original_title NVARCHAR(200) NULL,
    synopsis NVARCHAR(MAX) NULL,
    director NVARCHAR(100) NULL,
    main_cast NVARCHAR(500) NULL,
    duration_minutes INT NOT NULL,
    spoken_language NVARCHAR(50) NULL,
    country NVARCHAR(50) NULL,
    age_rating VARCHAR(5) NOT NULL,
    trailer_url VARCHAR(500) NULL,
    trailer_file VARCHAR(500) NULL,
    poster_url VARCHAR(500) NULL,
    release_date DATE NOT NULL,
    end_date DATE NULL,
    status VARCHAR(12) NOT NULL CONSTRAINT DF_Movie_Status DEFAULT 'Upcoming',
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Movie_Created DEFAULT SYSDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT CK_Movie_Duration CHECK (duration_minutes BETWEEN 1 AND 150),
    CONSTRAINT CK_Movie_Dates CHECK (end_date IS NULL OR end_date >= release_date),
    CONSTRAINT CK_Movie_Status CHECK (status IN ('Upcoming','NowShowing','Stopped')),
);
GO

CREATE TABLE dbo.MovieGenre (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    CONSTRAINT PK_MovieGenre PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT FK_MovieGenre_Movie FOREIGN KEY (movie_id) REFERENCES dbo.Movie(movie_id) ON DELETE CASCADE,
    CONSTRAINT FK_MovieGenre_Genre FOREIGN KEY (genre_id) REFERENCES dbo.Genre(genre_id) ON DELETE CASCADE
);
GO

CREATE VIEW dbo.vw_MovieDetail
AS
SELECT m.movie_id, m.title, m.original_title, m.synopsis, m.director, m.main_cast,
       m.duration_minutes, m.spoken_language, m.country, m.age_rating,
       m.trailer_url, m.trailer_file, m.poster_url, m.release_date, m.end_date,
       m.status, m.created_at, m.updated_at,
       genres.genres, genres.genre_ids
FROM dbo.Movie AS m
OUTER APPLY (
    SELECT STRING_AGG(g.genre_name, N', ') AS genres,
           STRING_AGG(CONVERT(VARCHAR(11), g.genre_id), ',') AS genre_ids
    FROM dbo.MovieGenre AS mg
    INNER JOIN dbo.Genre AS g ON g.genre_id = mg.genre_id
    WHERE mg.movie_id = m.movie_id
) AS genres;
GO

/* ---------- Showtime module ---------- */
CREATE TABLE dbo.Cinema (
    cinema_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cinema PRIMARY KEY,
    cinema_name NVARCHAR(150) NOT NULL,
    address NVARCHAR(300) NULL,
    phone VARCHAR(20) NULL
);
GO

CREATE TABLE dbo.Room (
    room_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Room PRIMARY KEY,
    cinema_id INT NOT NULL,
    room_name NVARCHAR(50) NOT NULL,
    room_type VARCHAR(20) NULL,
    capacity INT NOT NULL,
    status VARCHAR(12) NOT NULL CONSTRAINT DF_Room_Status DEFAULT 'Active',
    CONSTRAINT FK_Room_Cinema FOREIGN KEY (cinema_id) REFERENCES dbo.Cinema(cinema_id),
    CONSTRAINT UQ_Room_Cinema_Name UNIQUE (cinema_id, room_name)
);
GO

CREATE TABLE dbo.TimeSlot (
    slot_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TimeSlot PRIMARY KEY,
    slot_name NVARCHAR(30) NOT NULL,
    start_time TIME(7) NOT NULL,
    end_time TIME(7) NOT NULL,
    CONSTRAINT UQ_TimeSlot_Start UNIQUE (start_time)
);
GO

CREATE TABLE dbo.Showtime (
    showtime_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Showtime PRIMARY KEY,
    movie_id INT NOT NULL,
    room_id INT NOT NULL,
    slot_id INT NOT NULL,
    start_time DATETIME2(7) NOT NULL,
    end_time DATETIME2(7) NOT NULL,
    show_date AS CONVERT(DATE, start_time) PERSISTED,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_Showtime_Status DEFAULT 'Scheduled',
    created_by INT NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Showtime_Created DEFAULT SYSDATETIME(),
    room_name NVARCHAR(50) NULL,
    starts_at DATETIME2(7) NULL,
    ticket_price DECIMAL(10,2) NULL,
    CONSTRAINT FK_Showtime_Movie FOREIGN KEY (movie_id) REFERENCES dbo.Movie(movie_id),
    CONSTRAINT FK_Showtime_Room FOREIGN KEY (room_id) REFERENCES dbo.Room(room_id),
    CONSTRAINT FK_Showtime_Slot FOREIGN KEY (slot_id) REFERENCES dbo.TimeSlot(slot_id),
    CONSTRAINT FK_Showtime_Creator FOREIGN KEY (created_by) REFERENCES dbo.Users(UserId),
    CONSTRAINT UQ_Showtime_Room_Start UNIQUE (room_id, start_time)
);
GO

/* ---------- Indexes used by the current DAO queries ---------- */
CREATE INDEX IX_Movie_Status_Release ON dbo.Movie(status, release_date, end_date);
CREATE INDEX IX_Movie_Created ON dbo.Movie(created_at DESC, movie_id DESC);
CREATE INDEX IX_MovieGenre_Genre_Movie ON dbo.MovieGenre(genre_id, movie_id);
CREATE INDEX IX_Showtime_Date_Status ON dbo.Showtime(show_date, status, starts_at);
CREATE INDEX IX_Showtime_Movie ON dbo.Showtime(movie_id, starts_at);
CREATE INDEX IX_Showtime_Room_Date ON dbo.Showtime(room_id, show_date, starts_at);
GO

/* ---------- Procedures required by MovieDAO ---------- */
/* ---------- Procedures required by MovieDAO ---------- */
IF OBJECT_ID(N'dbo.sp_SaveMovie', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_SaveMovie;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.sp_SaveMovie
 @movie_id INT = NULL, @title NVARCHAR(200), @original_title NVARCHAR(200)=NULL,
 @synopsis NVARCHAR(MAX)=NULL, @director NVARCHAR(100)=NULL, @main_cast NVARCHAR(500)=NULL,
 @duration_minutes INT, @spoken_language NVARCHAR(50)=NULL, @country NVARCHAR(50)=NULL,
 @age_rating VARCHAR(5), @trailer_url VARCHAR(500)=NULL, @poster_url VARCHAR(500)=NULL,
 @release_date DATE, @end_date DATE=NULL, @status VARCHAR(12), @genre_ids VARCHAR(500)=NULL,
 @account_id INT=NULL, @movie_id_out INT OUTPUT, @trailer_file VARCHAR(500)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @release_date < CAST(GETDATE() AS DATE)
    AND (@movie_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM dbo.Movie WHERE movie_id=@movie_id AND release_date=@release_date
    ))
 BEGIN ;THROW 51001, 'Release date cannot be in the past.', 1; END;
 IF @end_date IS NOT NULL AND @end_date < @release_date BEGIN ;THROW 51002, 'End date cannot precede release date.', 1; END;
 IF @status NOT IN ('Upcoming','NowShowing','Stopped') BEGIN ;THROW 51003, 'Invalid movie status.', 1; END;
 BEGIN TRANSACTION;
 IF @movie_id IS NULL
 BEGIN
  INSERT dbo.Movie(title,original_title,synopsis,director,main_cast,duration_minutes,spoken_language,country,age_rating,trailer_url,trailer_file,poster_url,release_date,end_date,status)
  VALUES(@title,@original_title,@synopsis,@director,@main_cast,@duration_minutes,@spoken_language,@country,@age_rating,@trailer_url,@trailer_file,@poster_url,@release_date,@end_date,@status);
  SET @movie_id_out=CONVERT(INT,SCOPE_IDENTITY());
 END
 ELSE
 BEGIN
  UPDATE dbo.Movie SET title=@title,original_title=@original_title,synopsis=@synopsis,director=@director,main_cast=@main_cast,duration_minutes=@duration_minutes,spoken_language=@spoken_language,country=@country,age_rating=@age_rating,trailer_url=@trailer_url,trailer_file=@trailer_file,poster_url=@poster_url,release_date=@release_date,end_date=@end_date,status=@status,updated_at=SYSDATETIME() WHERE movie_id=@movie_id;
  IF @@ROWCOUNT=0 BEGIN ;THROW 51004, 'Movie not found.', 1; END; SET @movie_id_out=@movie_id;
 END;
  UPDATE dbo.Showtime
  SET status='Cancelled'
  WHERE movie_id=@movie_id_out
    AND status='Scheduled'
    AND starts_at IS NOT NULL
    AND CAST(starts_at AS DATE) < @release_date;
  DELETE FROM dbo.MovieGenre WHERE movie_id=@movie_id_out;
 IF NULLIF(LTRIM(RTRIM(@genre_ids)), '') IS NOT NULL INSERT dbo.MovieGenre(movie_id,genre_id) SELECT @movie_id_out,TRY_CONVERT(INT,LTRIM(RTRIM(value))) FROM STRING_SPLIT(@genre_ids,',') WHERE TRY_CONVERT(INT,LTRIM(RTRIM(value))) IS NOT NULL;
 COMMIT TRANSACTION;
END;
GO
IF OBJECT_ID(N'dbo.sp_DeleteMovie', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_DeleteMovie;
GO
CREATE PROCEDURE dbo.sp_DeleteMovie @movie_id INT AS
BEGIN
 SET NOCOUNT ON; IF EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id=@movie_id) BEGIN ;THROW 51005, 'Movie has showtimes.', 1; END;
 DELETE FROM dbo.Movie WHERE movie_id=@movie_id; IF @@ROWCOUNT=0 BEGIN ;THROW 51006, 'Movie not found.', 1; END;
END;
GO
IF OBJECT_ID(N'dbo.sp_StopMovie', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_StopMovie;
GO
CREATE PROCEDURE dbo.sp_StopMovie @movie_id INT AS
BEGIN
 SET NOCOUNT ON; UPDATE dbo.Movie SET status='Stopped',updated_at=SYSDATETIME() WHERE movie_id=@movie_id;
 IF @@ROWCOUNT=0 BEGIN ;THROW 51007, 'Movie not found.', 1; END;
 UPDATE dbo.Showtime SET status='Cancelled' WHERE movie_id=@movie_id AND start_time>SYSDATETIME() AND status='Scheduled';
END;
GO
/* ---------- Seed data ---------- */
INSERT dbo.AppRole(role_name)
VALUES
    (N'Admin'),
    (N'CinemaManager'),
    (N'Staff'),
    (N'Customer');
GO
SET IDENTITY_INSERT dbo.Users ON;
INSERT dbo.Users
    (UserId, FullName, Email, Phone, PasswordHash, Role, Status)
VALUES
    (1, N'Quản trị hệ thống', N'admin@cinema.vn', N'0900000001',
     N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'ADMIN', N'ACTIVE'),
    (2, N'Nguyễn Quản Lý', N'manager@cinema.vn', N'0900000002',
     N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'MANAGER', N'ACTIVE'),
    (3, N'Trần Nhân Viên', N'staff@cinema.vn', N'0900000003',
     N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'STAFF', N'ACTIVE'),
    (4, N'Lê Khách Một', N'khach1@gmail.com', N'0911111111',
     N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'CUSTOMER', N'ACTIVE'),
    (5, N'Phạm Khách Hai', N'khach2@gmail.com', N'0922222222',
     N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'CUSTOMER', N'ACTIVE');
SET IDENTITY_INSERT dbo.Users OFF;
GO
INSERT dbo.Customer(customer_id)
VALUES (4), (5);
GO
INSERT dbo.Genre(genre_name)
VALUES
    (N'Action'),
    (N'Romance'),
    (N'Animation'),
    (N'Horror'),
    (N'Science Fiction'),
    (N'Family');
GO
INSERT dbo.Cinema(cinema_name, address, phone)
VALUES (N'Cinema Hòa Lạc', N'Thạch Thất, Hà Nội', '0243000000');
INSERT dbo.Room(cinema_id, room_name, room_type, capacity)
VALUES
    (1, N'Phòng 1', '2D', 50),
    (1, N'Phòng 2', '3D', 50),
    (1, N'Phòng 3', '2D', 50),
    (1, N'Phòng 4', '3D', 50);
INSERT dbo.TimeSlot(slot_name, start_time, end_time)
VALUES
    (N'Suất 1', '09:00', '11:30'),
    (N'Suất 2', '11:45', '14:15'),
    (N'Suất 3', '14:30', '17:00'),
    (N'Suất 4', '17:15', '19:45'),
    (N'Suất 5', '20:00', '22:30');
GO
SET IDENTITY_INSERT dbo.Movie ON;
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (1, N'TRẠI BUÔN NGƯỜI', N'The Human Market', N'Một nhóm người xa lạ bị cuốn vào cuộc sinh tồn kinh hoàng trong khu chợ bí ẩn.', N'Đạo diễn A', N'Diễn viên 1, Diễn viên 2', 135, N'Tiếng Việt', N'Việt Nam', N'T18', NULL, NULL, CAST(N'2026-09-25' AS Date), CAST(N'2026-10-12' AS Date), N'Stopped', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (2, N'VERITY: BÍ MẬT BỊ CHÔN VÙI', N'Verity', N'Những trang bản thảo hé lộ bí mật đen tối phía sau một gia đình tưởng như hoàn hảo.', N'Đạo diễn B', N'Diễn viên 3, Diễn viên 4', 117, N'Tiếng Anh, phụ đề Tiếng Việt', N'Mỹ', N'T18', NULL, NULL, CAST(N'2026-09-16' AS Date), CAST(N'2026-10-10' AS Date), N'Stopped', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (3, N'MÙA XUÂN ĐẾN MUỘN', N'Late Spring', N'Câu chuyện gia đình về những cuộc gặp gỡ và lựa chọn làm thay đổi một mùa xuân.', N'Đạo diễn C', N'Diễn viên 5, Diễn viên 6', 120, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, NULL, CAST(N'2026-09-05' AS Date), CAST(N'2026-10-01' AS Date), N'Stopped', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (4, N'QUỶ ĂN TẠNG 4: HỒI TỈNH', N'The Possessed 4', N'Một nghi lễ cổ xưa đánh thức thế lực đang ngủ yên trong ngôi làng hẻo lánh.', N'Đạo diễn D', N'Diễn viên 7, Diễn viên 8', 111, N'Tiếng Thái, phụ đề Tiếng Việt', N'Thái Lan', N'T18', NULL, NULL, CAST(N'2026-10-16' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (5, N'SHAUN THE SHEEP: “QUÁI LẠ” GHÉ NHÀ', N'Shaun the Sheep: The Strange Visitor', N'Shaun và cả đàn cừu gặp một vị khách bất ngờ trong chuyến phiêu lưu hài hước.', N'Đạo diễn E', N'Lồng tiếng Việt', 81, N'Lồng tiếng Việt', N'Anh', N'P', NULL, NULL, CAST(N'2026-10-16' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (6, N'CÕI NGUYÊN', N'The Origin', N'Những dấu vết kỳ lạ dẫn một nhóm bạn đến bí mật bị chôn vùi dưới khu rừng già.', N'Đạo diễn F', N'Diễn viên 9, Diễn viên 10', 89, N'Tiếng Việt', N'Việt Nam', N'T18', NULL, NULL, CAST(N'2026-10-23' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (7, N'BAMBI: LÃNH ĐỊA SĂN MỒI', N'Bambi: The Reckoning', N'Cuộc đối đầu sinh tồn bắt đầu khi khu rừng yên bình trở thành lãnh địa săn mồi.', N'Đạo diễn G', N'Diễn viên 11, Diễn viên 12', 80, N'Tiếng Anh, phụ đề Tiếng Việt', N'Anh', N'T16', NULL, NULL, CAST(N'2026-10-23' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (8, N'ÁN MẠNG KARAOKE', N'Karaoke Murders', N'Một buổi tối karaoke biến thành vụ án bí ẩn mà không ai trong nhóm có thể rời đi.', N'Đạo diễn H', N'Diễn viên 13, Diễn viên 14', 96, N'Tiếng Việt', N'Việt Nam', N'T18', NULL, NULL, CAST(N'2026-10-30' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (9, N'CẢM XÚC LẠ KỲ', N'Strange Feelings', N'Chuyến phiêu lưu hoạt hình khám phá thế giới cảm xúc và tình bạn.', N'Đạo diễn I', N'Lồng tiếng Việt', 96, N'Lồng tiếng Việt', N'Mỹ', N'P', NULL, NULL, CAST(N'2026-11-07' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (10, N'OÁN LINH ĐÒI MẠNG', N'Laudanum', N'Một căn phòng khóa kín lưu giữ câu chuyện khiến những người bước vào phải trả giá.', N'Đạo diễn J', N'Diễn viên 15, Diễn viên 16', 98, N'Tiếng Việt', N'Việt Nam', N'T18', NULL, NULL, CAST(N'2026-11-13' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (11, N'TRÁI TIM MÙA ĐÔNG', N'Winter Hearts', N'Hai con người xa lạ học cách bắt đầu lại sau những biến cố của cuộc sống.', N'Đạo diễn K', N'Diễn viên 17, Diễn viên 18', 108, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, NULL, CAST(N'2026-11-21' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (12, N'CẢM XÚC LẠ KỲ: PHẦN 2', N'Strange Feelings 2', N'Phần tiếp theo mở ra chuyến phiêu lưu mới trong thế giới cảm xúc, với những thay đổi khi nhân vật bước sang giai đoạn trưởng thành.', N'Đạo diễn L', N'Lồng tiếng Việt', 102, N'Lồng tiếng Việt', N'Mỹ', N'P', NULL, NULL, CAST(N'2026-11-14' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (13, N'THÀNH PHỐ SAU MƯA', N'City After Rain', N'Một nhiếp ảnh gia trẻ lần theo những bức ảnh cũ để tìm lại người bạn đã mất liên lạc.', N'Đạo diễn M', N'Diễn viên 19, Diễn viên 20', 100, N'Tiếng Việt', N'Việt Nam', N'T13', NULL, NULL, CAST(N'2026-10-24' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at]) VALUES (14, N'HÀNH TRÌNH SAO BĂNG', N'Meteor Journey', N'Một nhóm bạn cùng thực hiện chuyến đi xuyên Việt để quan sát trận mưa sao băng hiếm gặp.', N'Đạo diễn N', N'Diễn viên 21, Diễn viên 22', 110, N'Tiếng Việt', N'Việt Nam', N'P', NULL, NULL, CAST(N'2026-10-24' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL)
SET IDENTITY_INSERT dbo.Movie OFF;
GO
UPDATE dbo.Movie
SET end_date = DATEADD(MONTH, 1, release_date)
WHERE end_date IS NULL;
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
/*
   Showtime seed:
   Each day has all five fixed slots in all four rooms.
   Every eligible movie is assigned at least one slot before the
   remaining slots are distributed in a stable round-robin order.
*/
WITH Dates AS (
    SELECT DATEADD(DAY, d.day_offset, CAST(GETDATE() AS DATE)) AS show_date,
           d.day_offset
    FROM (VALUES
        (1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
        (11), (12), (13), (14), (15)
    ) AS d(day_offset)
),
EligibleMovies AS (
    SELECT d.show_date, m.movie_id, m.duration_minutes,
           ROW_NUMBER() OVER (
               PARTITION BY d.show_date
               ORDER BY m.movie_id
           ) AS movie_number,
           COUNT(*) OVER (PARTITION BY d.show_date) AS movie_count
    FROM dbo.Movie AS m
    CROSS JOIN Dates AS d
    WHERE m.release_date <= d.show_date
      AND (m.end_date IS NULL OR m.end_date >= d.show_date)
      AND m.status <> 'Stopped'
),
ShowtimeGrid AS (
    SELECT d.show_date, d.day_offset, r.room_id, r.room_name,
           ts.slot_id, ts.start_time,
           ROW_NUMBER() OVER (
               PARTITION BY d.show_date
               ORDER BY r.room_id, ts.slot_id
           ) AS grid_number
    FROM Dates AS d
    CROSS JOIN dbo.Room AS r
    CROSS JOIN dbo.TimeSlot AS ts
)
INSERT dbo.Showtime
    (movie_id, room_id, slot_id, start_time, end_time, status,
     created_by, room_name, starts_at)
SELECT m.movie_id,
       g.room_id,
       g.slot_id,
       starts.starts_at,
       DATEADD(MINUTE, m.duration_minutes, starts.starts_at),
       'Scheduled',
       NULL,
       g.room_name,
       starts.starts_at
FROM ShowtimeGrid AS g
JOIN EligibleMovies AS m
  ON m.show_date = g.show_date
 AND m.movie_number =
     ((g.grid_number - 1) % m.movie_count) + 1
CROSS APPLY (
    SELECT CAST(DATEADD(
        MINUTE,
        DATEDIFF(MINUTE, CAST('00:00' AS TIME), g.start_time),
        CAST(g.show_date AS DATETIME2(7))
    ) AS DATETIME2(7)) AS starts_at
) AS starts;
GO
/* LEGACY SQL - preserved but disabled. Every line below is a SQL comment. */
-- /*
-- ===============================================================================
-- GHI CHU DOI CHIEU new.sql VOI CODE JAVA HIEN TAI (2026-10-22)
-- Day la ghi chu, khong phai lenh SQL. Cac lenh goc Movie/Showtime ben duoi duoc
-- giu nguyen; phan "COMPATIBILITY LAYER FOR MOVIE/SHOWTIME JAVA DAO" o cuoi file
-- bo sung cot/view/procedure/trigger de tuong thich voi DAO hien tai va giu lai
-- cac cot Showtime cu cho cac luong booking/seat map.
-- 
-- 1. TEN DATABASE / KHA NANG CHAY SCRIPT
--    - Script tao database CinemaDB, nhung src/java/app.properties dang ket noi
--      CinemaDB_TestSTT12. Hai ten nay phai trung nhau: doi connection string hoac
--      doi ten database trong script.
--    - Lenh CREATE DATABASE ben duoi gan duong dan file MDF/LDF cu the tren may
--      tao script. SQL Server khac co the khong co duong dan nay; can sua file path
--      theo may dich hoac tao database bang cong cu SQL Server truoc khi chay phan
--      schema.
--    - Script khong idempotent: chay lai tren database CinemaDB da ton tai se gap
--      loi CREATE DATABASE. Chi chay mot lan tren instance/database sach.
-- 
-- 2. MOVIE - LOP TUONG THICH O CUOI FILE
--    - MovieDAO truy van dbo.vw_MovieDetail va doc cac cot trailer_file,
--      updated_at, created_by, created_by_name, genres, genre_ids. View hien tai
--      khong xuat trailer_file, updated_at, created_by, created_by_name, genre_ids;
--      bang Movie cung chua co trailer_file. Lop tuong thich them cot trailer_file
--      va thay view de xuat day du cac cot DAO can.
--    - MovieDAO goi dbo.sp_SaveMovie (19 tham so), dbo.sp_DeleteMovie va
--      dbo.sp_StopMovie;      ca ba procedure khong co trong script goc. Lop tuong thich tao procedure
--      theo contract hien tai.
--    - ManageMovieServlet truyen Users.UserId vao Movie.created_by, trong khi FK
--      Movie.created_by tham chieu Account.account_id. ID mau Users/Account hien
--      dang trung nhau theo thu tu seed, nhung khong dam bao cho tai khoan moi.
--      Procedure moi map Users.UserId sang Account.account_id theo email.
-- 
-- 3. SHOWTIME - LOP TUONG THICH O CUOI FILE
--    - DAO hien tai doc/ghi Showtime.room_name, starts_at, ticket_price. Schema
--      dung room_id, slot_id, start_time, end_time. Lop tuong thich giu cac cot
--      nay, them room_name/starts_at/ticket_price cho DAO va trigger dong bo cac
--      gia tri quan he khi luu qua DAO.
--    - DAO chi gui ten phong, khong gui cinema_id; neu nhieu rap co cung ten phong,
--      trigger chon room_id nho nhat dang Active. Cac he thong can chon rap chinh
--      xac nen them cinema_id vao giao dien/DAO truoc khi dung nhieu rap.
--    - ticket_price moi la gia tham khao cho man hinh/quan ly; logic booking cu
--      van dung TicketPrice/fn_GetTicketPrice theo seat type va khung gio.
-- 
-- 4. NEWS - SCHEMA CO CAC COT CODE HIEN TAI CAN
--    - dbo.News co news_id, title, content, thumbnail_url, status, created_by,
--      created_at, updated_at; dbo.Account co account_id/full_name/email. Cac cot
--      nay phu hop voi NewsDAO (status Draft/Published/Hidden cung vua varchar(10)).
--    - NewsDAO tim Account bang email cua Users truoc khi insert. Cac email mau
--      trong Users va Account hien tai khop nhau; khi them user moi, can tao/dong
--      bo Account cung email, neu khong chuc nang ghi tin se khong tim duoc account.
--    - Code dang luu created_by vao Account, con xac thuc/role doc tu Users; hai
--      bang tai khoan rieng biet. Can tiep tuc dong bo tai khoan/role; khong nen
--      coi Users.UserId va Account.account_id la cung mot ID.
-- 
-- Ket luan: lop tuong thich o cuoi file bo sung phan schema/procedure Movie va
-- Showtime cho DAO hien tai, dong thoi giu cac lenh DDL goc. News van can dong bo
-- Users/Account cho tai khoan moi. Chua xac nhan script tren SQL Server thuc te.
-- ===============================================================================
-- */
-- USE [master]
-- GO
-- /****** Object:  Database [CinemaDB]    Script Date: 21/10/2026 4:16:22 CH ******/
-- CREATE DATABASE [CinemaDB]
--  CONTAINMENT = NONE
--  ON  PRIMARY 
-- ( NAME = N'CinemaDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CinemaDB.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
--  LOG ON 
-- ( NAME = N'CinemaDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\CinemaDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
--  WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
-- GO
-- ALTER DATABASE [CinemaDB] SET COMPATIBILITY_LEVEL = 160
-- GO
-- IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
-- begin
-- EXEC [CinemaDB].[dbo].[sp_fulltext_database] @action = 'enable'
-- end
-- GO
-- ALTER DATABASE [CinemaDB] SET ANSI_NULL_DEFAULT OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET ANSI_NULLS OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET ANSI_PADDING OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET ANSI_WARNINGS OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET ARITHABORT OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET AUTO_CLOSE OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET AUTO_SHRINK OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET AUTO_UPDATE_STATISTICS ON 
-- GO
-- ALTER DATABASE [CinemaDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET CURSOR_DEFAULT  GLOBAL 
-- GO
-- ALTER DATABASE [CinemaDB] SET CONCAT_NULL_YIELDS_NULL OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET NUMERIC_ROUNDABORT OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET QUOTED_IDENTIFIER OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET RECURSIVE_TRIGGERS OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET  ENABLE_BROKER 
-- GO
-- ALTER DATABASE [CinemaDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET TRUSTWORTHY OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET PARAMETERIZATION SIMPLE 
-- GO
-- ALTER DATABASE [CinemaDB] SET READ_COMMITTED_SNAPSHOT OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET HONOR_BROKER_PRIORITY OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET RECOVERY FULL 
-- GO
-- ALTER DATABASE [CinemaDB] SET  MULTI_USER 
-- GO
-- ALTER DATABASE [CinemaDB] SET PAGE_VERIFY CHECKSUM  
-- GO
-- ALTER DATABASE [CinemaDB] SET DB_CHAINING OFF 
-- GO
-- ALTER DATABASE [CinemaDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
-- GO
-- ALTER DATABASE [CinemaDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
-- GO
-- ALTER DATABASE [CinemaDB] SET DELAYED_DURABILITY = DISABLED 
-- GO
-- ALTER DATABASE [CinemaDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
-- GO
-- EXEC sys.sp_db_vardecimal_storage_format N'CinemaDB', N'ON'
-- GO
-- ALTER DATABASE [CinemaDB] SET QUERY_STORE = ON
-- GO
-- ALTER DATABASE [CinemaDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
-- GO
-- USE [CinemaDB]
-- GO
-- /****** Object:  UserDefinedFunction [dbo].[fn_GetTicketPrice]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- /* =====================================================================
--    4. HÀM & STORED PROCEDURE THEO USE CASE
--    ===================================================================== */
-- 
-- -- Giá vé theo loại ghế + khung giờ + loại ngày (thường / cuối tuần / lễ)
-- CREATE FUNCTION [dbo].[fn_GetTicketPrice](@showtime_id INT, @seat_type_id INT) RETURNS DECIMAL(10,0) AS
-- BEGIN
--     DECLARE @slot INT, @d DATE, @day_type VARCHAR(10), @price DECIMAL(10,0);
--     SELECT @slot = slot_id, @d = show_date FROM Showtime WHERE showtime_id = @showtime_id;
--     SET @day_type = CASE WHEN EXISTS (SELECT 1 FROM Holiday WHERE holiday_date = @d) THEN 'Holiday'
--                          WHEN DATEDIFF(DAY, '19000107', @d) % 7 IN (0, 6) THEN 'Weekend'   -- CN, T7
--                          ELSE 'Weekday' END;
--     SELECT @price = price FROM TicketPrice WHERE seat_type_id = @seat_type_id AND slot_id = @slot AND day_type = @day_type;
--     RETURN @price;
-- END
-- GO
-- /****** Object:  Table [dbo].[Genre]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Genre](
-- 	[genre_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[genre_name] [nvarchar](50) NOT NULL,
-- 	[description] [nvarchar](200) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[genre_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Movie]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Movie](
-- 	[movie_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[title] [nvarchar](200) NOT NULL,
-- 	[original_title] [nvarchar](200) NULL,
-- 	[synopsis] [nvarchar](max) NULL,
-- 	[director] [nvarchar](100) NULL,
-- 	[main_cast] [nvarchar](500) NULL,
-- 	[duration_minutes] [int] NOT NULL,
-- 	[spoken_language] [nvarchar](50) NULL,
-- 	[country] [nvarchar](50) NULL,
-- 	[age_rating] [varchar](5) NOT NULL,
-- 	[trailer_url] [varchar](500) NULL,
-- 	[poster_url] [varchar](500) NULL,
-- 	[release_date] [date] NOT NULL,
-- 	[end_date] [date] NULL,
-- 	[status] [varchar](12) NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- 	[updated_at] [datetime2](7) NULL,
-- 	[created_by] [int] NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[movie_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[MovieGenre]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[MovieGenre](
-- 	[movie_id] [int] NOT NULL,
-- 	[genre_id] [int] NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[movie_id] ASC,
-- 	[genre_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Review]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Review](
-- 	[review_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[movie_id] [int] NOT NULL,
-- 	[customer_id] [int] NOT NULL,
-- 	[rating] [tinyint] NOT NULL,
-- 	[comment] [nvarchar](1000) NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[review_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  View [dbo].[vw_MovieDetail]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- /* =====================================================================
--    3. VIEW
--    ===================================================================== */
-- CREATE VIEW [dbo].[vw_MovieDetail] AS
-- SELECT m.movie_id, m.title, m.original_title, m.synopsis, m.director, m.main_cast, m.duration_minutes,
--        m.spoken_language, m.country, m.age_rating, m.trailer_url, m.poster_url,
--        m.release_date, m.end_date, m.status, m.created_at,
--        (SELECT STRING_AGG(g.genre_name, N', ') FROM MovieGenre mg JOIN Genre g ON g.genre_id = mg.genre_id
--          WHERE mg.movie_id = m.movie_id) AS genres,
--        (SELECT AVG(CAST(r.rating AS DECIMAL(3,2))) FROM Review r WHERE r.movie_id = m.movie_id) AS avg_rating,
--        (SELECT COUNT(*) FROM Review r WHERE r.movie_id = m.movie_id) AS review_count
-- FROM Movie m;
-- GO
-- /****** Object:  Table [dbo].[Showtime]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Showtime](
-- 	[showtime_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[movie_id] [int] NOT NULL,
-- 	[room_id] [int] NOT NULL,
-- 	[slot_id] [int] NOT NULL,
-- 	[start_time] [datetime2](7) NOT NULL,
-- 	[end_time] [datetime2](7) NOT NULL,
-- 	[show_date]  AS (CONVERT([date],[start_time])) PERSISTED,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_by] [int] NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[showtime_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Booking]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Booking](
-- 	[booking_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[booking_code] [varchar](20) NOT NULL,
-- 	[customer_id] [int] NULL,
-- 	[staff_id] [int] NULL,
-- 	[showtime_id] [int] NOT NULL,
-- 	[channel] [varchar](10) NOT NULL,
-- 	[status] [varchar](15) NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- 	[session_expires_at] [datetime2](7) NOT NULL,
-- 	[payment_expires_at] [datetime2](7) NULL,
-- 	[ticket_total] [decimal](12, 0) NOT NULL,
-- 	[combo_total] [decimal](12, 0) NOT NULL,
-- 	[voucher_id] [int] NULL,
-- 	[voucher_discount] [decimal](12, 0) NOT NULL,
-- 	[points_used] [int] NOT NULL,
-- 	[points_discount] [decimal](12, 0) NOT NULL,
-- 	[total_amount] [decimal](12, 0) NOT NULL,
-- 	[paid_at] [datetime2](7) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[booking_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Ticket]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Ticket](
-- 	[ticket_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[booking_id] [int] NOT NULL,
-- 	[showtime_id] [int] NOT NULL,
-- 	[seat_id] [int] NOT NULL,
-- 	[price] [decimal](10, 0) NOT NULL,
-- 	[ticket_code] [varchar](30) NOT NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[checked_in_at] [datetime2](7) NULL,
-- 	[checked_in_by] [int] NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[ticket_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[SeatType]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[SeatType](
-- 	[seat_type_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[type_name] [nvarchar](30) NOT NULL,
-- 	[is_couple] [bit] NOT NULL,
-- 	[description] [nvarchar](200) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[seat_type_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Seat]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Seat](
-- 	[seat_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[room_id] [int] NOT NULL,
-- 	[row_label] [char](1) NOT NULL,
-- 	[seat_number] [int] NOT NULL,
-- 	[seat_type_id] [int] NOT NULL,
-- 	[pair_seat_id] [int] NULL,
-- 	[status] [varchar](12) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[seat_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  View [dbo].[vw_SeatMap]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- Sơ đồ ghế theo suất chiếu + màu trạng thái
-- CREATE VIEW [dbo].[vw_SeatMap] AS
-- SELECT st.showtime_id, s.seat_id, s.row_label, s.seat_number, sty.type_name AS seat_type, s.pair_seat_id,
--        CASE WHEN s.status = 'Maintenance'                                            THEN 'GREY'
--             WHEN x.status IN ('Booked','Used')                                       THEN 'RED'
--             WHEN x.status = 'Held' AND x.payment_expires_at > SYSDATETIME()          THEN 'YELLOW'
--             ELSE 'GREEN' END AS color
-- FROM Showtime st
-- JOIN Seat s      ON s.room_id = st.room_id
-- JOIN SeatType sty ON sty.seat_type_id = s.seat_type_id
-- OUTER APPLY (SELECT TOP 1 t.status, b.payment_expires_at
--              FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id
--              WHERE t.showtime_id = st.showtime_id AND t.seat_id = s.seat_id
--                AND t.status IN ('Held','Booked','Used')
--              ORDER BY t.ticket_id DESC) x;
-- GO
-- /****** Object:  Table [dbo].[Cinema]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Cinema](
-- 	[cinema_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[cinema_name] [nvarchar](100) NOT NULL,
-- 	[address] [nvarchar](200) NULL,
-- 	[phone] [varchar](15) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[cinema_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Room]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Room](
-- 	[room_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[cinema_id] [int] NOT NULL,
-- 	[room_name] [nvarchar](50) NOT NULL,
-- 	[room_type] [varchar](10) NOT NULL,
-- 	[capacity] [int] NOT NULL,
-- 	[status] [varchar](10) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[room_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  View [dbo].[vw_RevenueByMovie]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- CREATE VIEW [dbo].[vw_RevenueByMovie] AS
-- SELECT m.movie_id, m.title, c.cinema_id, c.cinema_name, CAST(b.paid_at AS DATE) AS revenue_date,
--        COUNT(t.ticket_id) AS tickets_sold, SUM(t.price) AS ticket_revenue
-- FROM Ticket t
-- JOIN Booking b  ON b.booking_id = t.booking_id AND b.status = 'Paid'
-- JOIN Showtime s ON s.showtime_id = t.showtime_id
-- JOIN Movie m    ON m.movie_id = s.movie_id
-- JOIN Room r     ON r.room_id = s.room_id
-- JOIN Cinema c   ON c.cinema_id = r.cinema_id
-- WHERE t.status IN ('Booked','Used')
-- GROUP BY m.movie_id, m.title, c.cinema_id, c.cinema_name, CAST(b.paid_at AS DATE);
-- GO
-- /****** Object:  Table [dbo].[Account]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Account](
-- 	[account_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[role_id] [int] NOT NULL,
-- 	[full_name] [nvarchar](100) NOT NULL,
-- 	[email] [varchar](100) NOT NULL,
-- 	[phone] [varchar](15) NOT NULL,
-- 	[password_hash] [varchar](255) NOT NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[account_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[AppRole]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[AppRole](
-- 	[role_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[role_name] [nvarchar](30) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[role_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[BookingCombo]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[BookingCombo](
-- 	[booking_id] [int] NOT NULL,
-- 	[combo_id] [int] NOT NULL,
-- 	[quantity] [int] NOT NULL,
-- 	[unit_price] [decimal](10, 0) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[booking_id] ASC,
-- 	[combo_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Combo]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Combo](
-- 	[combo_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[combo_name] [nvarchar](100) NOT NULL,
-- 	[description] [nvarchar](300) NULL,
-- 	[price] [decimal](10, 0) NOT NULL,
-- 	[stock] [int] NOT NULL,
-- 	[status] [varchar](10) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[combo_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Customer]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Customer](
-- 	[customer_id] [int] NOT NULL,
-- 	[my_point_balance] [int] NOT NULL,
-- 	[total_spent] [decimal](14, 0) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[customer_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[EmailNotification]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[EmailNotification](
-- 	[notif_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[customer_id] [int] NOT NULL,
-- 	[notif_type] [varchar](20) NOT NULL,
-- 	[subject] [nvarchar](200) NOT NULL,
-- 	[body] [nvarchar](max) NULL,
-- 	[showtime_id] [int] NULL,
-- 	[movie_id] [int] NULL,
-- 	[booking_id] [int] NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- 	[sent_at] [datetime2](7) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[notif_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Holiday]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Holiday](
-- 	[holiday_date] [date] NOT NULL,
-- 	[holiday_name] [nvarchar](100) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[holiday_date] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[MyPointConfig]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[MyPointConfig](
-- 	[config_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[earn_rate_percent] [decimal](5, 2) NOT NULL,
-- 	[point_value_vnd] [int] NOT NULL,
-- 	[max_redeem_percent] [decimal](5, 2) NOT NULL,
-- 	[effective_from] [date] NOT NULL,
-- 	[is_active] [bit] NOT NULL,
-- 	[updated_by] [int] NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[config_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[MyPointTransaction]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[MyPointTransaction](
-- 	[txn_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[customer_id] [int] NOT NULL,
-- 	[booking_id] [int] NULL,
-- 	[txn_type] [varchar](10) NOT NULL,
-- 	[points] [int] NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[txn_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[News]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[News](
-- 	[news_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[title] [nvarchar](200) NOT NULL,
-- 	[content] [nvarchar](max) NOT NULL,
-- 	[thumbnail_url] [varchar](500) NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_by] [int] NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- 	[updated_at] [datetime2](7) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[news_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Payment]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Payment](
-- 	[payment_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[booking_id] [int] NOT NULL,
-- 	[method] [varchar](15) NOT NULL,
-- 	[amount] [decimal](12, 0) NOT NULL,
-- 	[gateway_txn_id] [varchar](100) NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- 	[paid_at] [datetime2](7) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[payment_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Permission]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Permission](
-- 	[permission_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[permission_code] [varchar](50) NOT NULL,
-- 	[description] [nvarchar](200) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[permission_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[RolePermission]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[RolePermission](
-- 	[role_id] [int] NOT NULL,
-- 	[permission_id] [int] NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[role_id] ASC,
-- 	[permission_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[SystemConfig]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[SystemConfig](
-- 	[config_key] [varchar](50) NOT NULL,
-- 	[config_value] [nvarchar](100) NOT NULL,
-- 	[description] [nvarchar](200) NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[config_key] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[SystemLog]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[SystemLog](
-- 	[log_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[account_id] [int] NULL,
-- 	[action] [nvarchar](100) NOT NULL,
-- 	[detail] [nvarchar](500) NULL,
-- 	[created_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[log_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[TicketChangeHistory]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[TicketChangeHistory](
-- 	[change_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[ticket_id] [int] NOT NULL,
-- 	[change_type] [varchar](15) NOT NULL,
-- 	[old_seat_id] [int] NULL,
-- 	[new_seat_id] [int] NULL,
-- 	[old_showtime_id] [int] NULL,
-- 	[new_showtime_id] [int] NULL,
-- 	[changed_by] [int] NULL,
-- 	[reason] [nvarchar](200) NULL,
-- 	[changed_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[change_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[TicketPrice]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[TicketPrice](
-- 	[price_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[seat_type_id] [int] NOT NULL,
-- 	[slot_id] [int] NOT NULL,
-- 	[day_type] [varchar](10) NOT NULL,
-- 	[price] [decimal](10, 0) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[price_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[TimeSlot]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[TimeSlot](
-- 	[slot_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[slot_name] [nvarchar](30) NOT NULL,
-- 	[start_time] [time](7) NOT NULL,
-- 	[end_time] [time](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[slot_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Users]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Users](
-- 	[UserId] [int] IDENTITY(1,1) NOT NULL,
-- 	[FullName] [nvarchar](100) NOT NULL,
-- 	[Email] [nvarchar](150) NOT NULL,
-- 	[Phone] [varchar](15) NOT NULL,
-- 	[PasswordHash] [varchar](100) NOT NULL,
-- 	[DateOfBirth] [date] NULL,
-- 	[Gender] [varchar](10) NULL,
-- 	[Role] [varchar](20) NOT NULL,
-- 	[Status] [varchar](20) NOT NULL,
-- 	[OtpHash] [varchar](64) NULL,
-- 	[OtpExpiry] [datetime2](7) NULL,
-- 	[OtpAttempts] [int] NOT NULL,
-- 	[CreatedAt] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[UserId] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[Voucher]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[Voucher](
-- 	[voucher_id] [int] IDENTITY(1,1) NOT NULL,
-- 	[code] [varchar](30) NOT NULL,
-- 	[description] [nvarchar](200) NULL,
-- 	[discount_type] [varchar](10) NOT NULL,
-- 	[discount_value] [decimal](12, 2) NOT NULL,
-- 	[max_discount] [decimal](12, 0) NULL,
-- 	[min_order_amount] [decimal](12, 0) NOT NULL,
-- 	[min_cumulative_spending] [decimal](14, 0) NOT NULL,
-- 	[usage_limit] [int] NOT NULL,
-- 	[used_count] [int] NOT NULL,
-- 	[per_customer_limit] [int] NOT NULL,
-- 	[valid_from] [date] NOT NULL,
-- 	[valid_to] [date] NOT NULL,
-- 	[status] [varchar](10) NOT NULL,
-- 	[created_by] [int] NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[voucher_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- /****** Object:  Table [dbo].[VoucherUsage]    Script Date: 21/10/2026 4:16:22 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE TABLE [dbo].[VoucherUsage](
-- 	[voucher_id] [int] NOT NULL,
-- 	[booking_id] [int] NOT NULL,
-- 	[customer_id] [int] NOT NULL,
-- 	[used_at] [datetime2](7) NOT NULL,
-- PRIMARY KEY CLUSTERED 
-- (
-- 	[voucher_id] ASC,
-- 	[booking_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- ) ON [PRIMARY]
-- GO
-- SET IDENTITY_INSERT [dbo].[Account] ON 
-- 
-- INSERT [dbo].[Account] ([account_id], [role_id], [full_name], [email], [phone], [password_hash], [status], [created_at]) VALUES (1, 1, N'Quản trị hệ thống', N'admin@cinema.vn', N'0900000001', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'Active', CAST(N'2026-10-18T12:15:22.2031000' AS DateTime2))
-- INSERT [dbo].[Account] ([account_id], [role_id], [full_name], [email], [phone], [password_hash], [status], [created_at]) VALUES (2, 2, N'Nguyễn Quản Lý', N'manager@cinema.vn', N'0900000002', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'Active', CAST(N'2026-10-18T12:15:22.2031000' AS DateTime2))
-- INSERT [dbo].[Account] ([account_id], [role_id], [full_name], [email], [phone], [password_hash], [status], [created_at]) VALUES (3, 3, N'Trần Nhân Viên', N'staff@cinema.vn', N'0900000003', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'Active', CAST(N'2026-10-18T12:15:22.2031000' AS DateTime2))
-- INSERT [dbo].[Account] ([account_id], [role_id], [full_name], [email], [phone], [password_hash], [status], [created_at]) VALUES (4, 4, N'Lê Khách Một', N'khach1@gmail.com', N'0911111111', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'Active', CAST(N'2026-10-18T12:15:22.2031000' AS DateTime2))
-- INSERT [dbo].[Account] ([account_id], [role_id], [full_name], [email], [phone], [password_hash], [status], [created_at]) VALUES (5, 4, N'Phạm Khách Hai', N'khach2@gmail.com', N'0922222222', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', N'Active', CAST(N'2026-10-18T12:15:22.2031000' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[Account] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[AppRole] ON 
-- 
-- INSERT [dbo].[AppRole] ([role_id], [role_name]) VALUES (1, N'Admin')
-- INSERT [dbo].[AppRole] ([role_id], [role_name]) VALUES (2, N'CinemaManager')
-- INSERT [dbo].[AppRole] ([role_id], [role_name]) VALUES (4, N'Customer')
-- INSERT [dbo].[AppRole] ([role_id], [role_name]) VALUES (3, N'Staff')
-- SET IDENTITY_INSERT [dbo].[AppRole] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Booking] ON 
-- 
-- INSERT [dbo].[Booking] ([booking_id], [booking_code], [customer_id], [staff_id], [showtime_id], [channel], [status], [created_at], [session_expires_at], [payment_expires_at], [ticket_total], [combo_total], [voucher_id], [voucher_discount], [points_used], [points_discount], [total_amount], [paid_at]) VALUES (1, N'BK70179E14A2', 4, NULL, 1, N'Online', N'Paid', CAST(N'2026-10-18T12:15:22.3437011' AS DateTime2), CAST(N'2026-10-18T12:30:22.3437011' AS DateTime2), CAST(N'2026-10-18T12:20:22.3956680' AS DateTime2), CAST(180000 AS Decimal(12, 0)), CAST(69000 AS Decimal(12, 0)), 1, CAST(24900 AS Decimal(12, 0)), 10, CAST(10000 AS Decimal(12, 0)), CAST(214100 AS Decimal(12, 0)), CAST(N'2026-10-18T12:15:22.5637018' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[Booking] OFF
-- GO
-- INSERT [dbo].[BookingCombo] ([booking_id], [combo_id], [quantity], [unit_price]) VALUES (1, 1, 1, CAST(69000 AS Decimal(10, 0)))
-- GO
-- SET IDENTITY_INSERT [dbo].[Cinema] ON 
-- 
-- INSERT [dbo].[Cinema] ([cinema_id], [cinema_name], [address], [phone]) VALUES (1, N'Cinema Hòa Lạc', N'Thạch Thất, Hà Nội', N'0243000000')
-- SET IDENTITY_INSERT [dbo].[Cinema] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Combo] ON 
-- 
-- INSERT [dbo].[Combo] ([combo_id], [combo_name], [description], [price], [stock], [status]) VALUES (1, N'Combo 1 bắp + 1 nước', N'1 bắp ngọt vừa + 1 nước ngọt', CAST(69000 AS Decimal(10, 0)), 1, N'Active')
-- INSERT [dbo].[Combo] ([combo_id], [combo_name], [description], [price], [stock], [status]) VALUES (2, N'Combo 2 bắp + 2 nước', N'2 bắp ngọt lớn + 2 nước ngọt', CAST(119000 AS Decimal(10, 0)), 100, N'Active')
-- SET IDENTITY_INSERT [dbo].[Combo] OFF
-- GO
-- INSERT [dbo].[Customer] ([customer_id], [my_point_balance], [total_spent]) VALUES (4, 20, CAST(1714100 AS Decimal(14, 0)))
-- INSERT [dbo].[Customer] ([customer_id], [my_point_balance], [total_spent]) VALUES (5, 0, CAST(0 AS Decimal(14, 0)))
-- GO
-- SET IDENTITY_INSERT [dbo].[EmailNotification] ON 
-- 
-- INSERT [dbo].[EmailNotification] ([notif_id], [customer_id], [notif_type], [subject], [body], [showtime_id], [movie_id], [booking_id], [status], [created_at], [sent_at]) VALUES (1, 4, N'ETicket', N'Vé điện tử của bạn', N'Đính kèm mã QR các vé đã đặt.', NULL, NULL, 1, N'Pending', CAST(N'2026-10-18T12:15:22.5657016' AS DateTime2), NULL)
-- SET IDENTITY_INSERT [dbo].[EmailNotification] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Genre] ON 
-- 
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (1, N'Hành động', NULL)
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (2, N'Tình cảm', NULL)
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (3, N'Hoạt hình', NULL)
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (4, N'Kinh dị', NULL)
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (5, N'Khoa học viễn tưởng', NULL)
-- INSERT [dbo].[Genre] ([genre_id], [genre_name], [description]) VALUES (6, N'Gia đình', NULL)
-- SET IDENTITY_INSERT [dbo].[Genre] OFF
-- GO
-- INSERT [dbo].[Holiday] ([holiday_date], [holiday_name]) VALUES (CAST(N'2027-01-01' AS Date), N'Tết Dương lịch')
-- INSERT [dbo].[Holiday] ([holiday_date], [holiday_name]) VALUES (CAST(N'2027-02-06' AS Date), N'Tết Nguyên đán')
-- GO
-- SET IDENTITY_INSERT [dbo].[Movie] ON 
-- 
-- INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at], [created_by]) VALUES (1, N'Hành Tinh Cát', N'Desert Planet', N'Cuộc chiến giành quyền kiểm soát hành tinh sa mạc.', N'Đạo diễn A', N'Diễn viên 1, Diễn viên 2', 165, N'Tiếng Anh', N'Mỹ', N'T13', N'https://youtube.com/watch?v=trailer_1', N'https://img.cinema.vn/p1.jpg', CAST(N'2026-10-08' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL, 2)
-- INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at], [created_by]) VALUES (2, N'Mùa Xuân Đến Muộn', N'Late Spring', N'Câu chuyện tình cảm gia đình ngày Tết.', N'Đạo diễn B', N'Diễn viên 3, Diễn viên 4', 120, N'Tiếng Việt', N'Việt Nam', N'T16', N'https://youtube.com/watch?v=trailer_2', N'https://img.cinema.vn/p2.jpg', CAST(N'2026-10-15' AS Date), NULL, N'NowShowing', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL, 2)
-- INSERT [dbo].[Movie] ([movie_id], [title], [original_title], [synopsis], [director], [main_cast], [duration_minutes], [spoken_language], [country], [age_rating], [trailer_url], [poster_url], [release_date], [end_date], [status], [created_at], [updated_at], [created_by]) VALUES (3, N'Cảm Xúc Lạ Kỳ', N'Strange Feelings', N'Hoạt hình về thế giới cảm xúc trong đầu một cô bé.', N'Đạo diễn C', N'Lồng tiếng 1, Lồng tiếng 2', 96, N'Lồng tiếng Việt', N'Mỹ', N'P', N'https://youtube.com/watch?v=trailer_3', N'https://img.cinema.vn/p3.jpg', CAST(N'2026-11-07' AS Date), NULL, N'Upcoming', CAST(N'2026-10-18T12:15:22.2041065' AS DateTime2), NULL, 2)
-- SET IDENTITY_INSERT [dbo].[Movie] OFF
-- GO
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (1, 1)
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (1, 5)
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (2, 2)
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (2, 6)
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (3, 3)
-- INSERT [dbo].[MovieGenre] ([movie_id], [genre_id]) VALUES (3, 6)
-- GO
-- SET IDENTITY_INSERT [dbo].[MyPointConfig] ON 
-- 
-- INSERT [dbo].[MyPointConfig] ([config_id], [earn_rate_percent], [point_value_vnd], [max_redeem_percent], [effective_from], [is_active], [updated_by]) VALUES (1, CAST(5.00 AS Decimal(5, 2)), 1000, CAST(20.00 AS Decimal(5, 2)), CAST(N'2026-10-18' AS Date), 1, 2)
-- SET IDENTITY_INSERT [dbo].[MyPointConfig] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[MyPointTransaction] ON 
-- 
-- INSERT [dbo].[MyPointTransaction] ([txn_id], [customer_id], [booking_id], [txn_type], [points], [created_at]) VALUES (1, 4, 1, N'Redeem', -10, CAST(N'2026-10-18T12:15:22.5646650' AS DateTime2))
-- INSERT [dbo].[MyPointTransaction] ([txn_id], [customer_id], [booking_id], [txn_type], [points], [created_at]) VALUES (2, 4, 1, N'Earn', 10, CAST(N'2026-10-18T12:15:22.5646650' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[MyPointTransaction] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[News] ON 
-- 
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (1, N'Khai trương Cinema Hòa Lạc', N'Ưu đãi vé 50k trong tuần đầu tiên.', NULL, N'Published', 2, CAST(N'2026-10-18T12:15:22.2421313' AS DateTime2), NULL)
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (2, N'Khai trương cụm rạp CineStar Quận 7', N'Cụm rạp mới với 8 phòng chiếu hiện đại, công nghệ âm thanh Dolby Atmos và ghế đôi couple chính thức đi vào hoạt động từ ngày 25/10. Nhân dịp khai trương, rạp tặng 500 vé miễn phí cho khách hàng đến sớm nhất trong ngày khai trương.', NULL, N'Published', 2, CAST(N'2026-10-19T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-19T11:50:21.8015869' AS DateTime2))
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (3, N'Ưu đãi vé cuối tuần: đồng giá 45K suất chiếu sáng', N'Từ nay đến hết tháng 11, mọi suất chiếu trước 10h sáng thứ Bảy và Chủ Nhật áp dụng giá vé đồng hạng chỉ 45.000đ cho ghế thường. Không áp dụng cùng voucher giảm giá khác. Chi tiết xem tại quầy vé hoặc mục khuyến mãi.', NULL, N'Published', 2, CAST(N'2026-10-20T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-20T11:50:21.8015869' AS DateTime2))
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (4, N'Thông báo: lịch nghỉ lễ và giờ chiếu đặc biệt', N'Rạp mở cửa xuyên suốt dịp lễ, suất chiếu muộn nhất bắt đầu lúc 23h30. Khách hàng nên đặt vé trước trên website để tránh hết chỗ ở các suất prime-time từ 19h đến 21h.', NULL, N'Published', 2, CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2))
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (5, N'Bản nháp: chương trình tri ân khách hàng thân thiết', N'Nội dung đang soạn: tặng điểm MyPoint gấp đôi cho mọi giao dịch trong tháng 12...', NULL, N'Draft', 2, CAST(N'2026-10-20T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-20T11:50:21.8015869' AS DateTime2))
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (6, N'Bản nháp: lịch chiếu phim Tết 2027', N'Đang chờ xác nhận từ nhà phát hành. Chưa công bố.', NULL, N'Draft', 2, CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2))
-- INSERT [dbo].[News] ([news_id], [title], [content], [thumbnail_url], [status], [created_by], [created_at], [updated_at]) VALUES (7, N'Bài test nội bộ - không hiển thị', N'Tin này dùng để kiểm tra tab trạng thái Đã ẩn, khách hàng không bao giờ thấy.', NULL, N'Hidden', 2, CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2), CAST(N'2026-10-21T11:50:21.8015869' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[News] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Payment] ON 
-- 
-- INSERT [dbo].[Payment] ([payment_id], [booking_id], [method], [amount], [gateway_txn_id], [status], [created_at], [paid_at]) VALUES (1, 1, N'BankTransfer', CAST(214100 AS Decimal(12, 0)), N'TXN-DEMO-0001', N'Success', CAST(N'2026-10-18T12:15:22.5637018' AS DateTime2), CAST(N'2026-10-18T12:15:22.5637018' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[Payment] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Permission] ON 
-- 
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (1, N'ACCOUNT_MANAGE', N'Quản lý tài khoản')
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (2, N'ROOM_SEAT_MANAGE', N'Quản lý phòng/ghế/lịch chiếu')
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (3, N'MOVIE_MANAGE', N'Quản lý phim/thể loại')
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (4, N'PRICE_PROMO_MANAGE', N'Giá vé, voucher, MyPoint')
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (5, N'COUNTER_SALE', N'Bán vé tại quầy, check-in')
-- INSERT [dbo].[Permission] ([permission_id], [permission_code], [description]) VALUES (6, N'BOOK_TICKET', N'Đặt vé online')
-- SET IDENTITY_INSERT [dbo].[Permission] OFF
-- GO
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (1, 1)
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (1, 2)
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (2, 3)
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (2, 4)
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (3, 5)
-- INSERT [dbo].[RolePermission] ([role_id], [permission_id]) VALUES (4, 6)
-- GO
-- SET IDENTITY_INSERT [dbo].[Room] ON 
-- 
-- INSERT [dbo].[Room] ([room_id], [cinema_id], [room_name], [room_type], [capacity], [status]) VALUES (1, 1, N'Phòng 1', N'2D', 50, N'Active')
-- INSERT [dbo].[Room] ([room_id], [cinema_id], [room_name], [room_type], [capacity], [status]) VALUES (2, 1, N'Phòng 2', N'3D', 50, N'Active')
-- SET IDENTITY_INSERT [dbo].[Room] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Seat] ON 
-- 
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (1, 1, N'A', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (2, 1, N'A', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (3, 1, N'A', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (4, 1, N'A', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (5, 1, N'A', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (6, 1, N'A', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (7, 1, N'A', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (8, 1, N'A', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (9, 1, N'A', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (10, 1, N'A', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (11, 1, N'B', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (12, 1, N'B', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (13, 1, N'B', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (14, 1, N'B', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (15, 1, N'B', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (16, 1, N'B', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (17, 1, N'B', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (18, 1, N'B', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (19, 1, N'B', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (20, 1, N'B', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (21, 1, N'C', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (22, 1, N'C', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (23, 1, N'C', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (24, 1, N'C', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (25, 1, N'C', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (26, 1, N'C', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (27, 1, N'C', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (28, 1, N'C', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (29, 1, N'C', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (30, 1, N'C', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (31, 1, N'D', 1, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (32, 1, N'D', 2, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (33, 1, N'D', 3, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (34, 1, N'D', 4, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (35, 1, N'D', 5, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (36, 1, N'D', 6, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (37, 1, N'D', 7, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (38, 1, N'D', 8, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (39, 1, N'D', 9, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (40, 1, N'D', 10, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (41, 1, N'E', 1, 3, 42, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (42, 1, N'E', 2, 3, 41, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (43, 1, N'E', 3, 3, 44, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (44, 1, N'E', 4, 3, 43, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (45, 1, N'E', 5, 3, 46, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (46, 1, N'E', 6, 3, 45, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (47, 1, N'E', 7, 3, 48, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (48, 1, N'E', 8, 3, 47, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (49, 1, N'E', 9, 3, 50, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (50, 1, N'E', 10, 3, 49, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (51, 2, N'A', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (52, 2, N'A', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (53, 2, N'A', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (54, 2, N'A', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (55, 2, N'A', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (56, 2, N'A', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (57, 2, N'A', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (58, 2, N'A', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (59, 2, N'A', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (60, 2, N'A', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (61, 2, N'B', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (62, 2, N'B', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (63, 2, N'B', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (64, 2, N'B', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (65, 2, N'B', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (66, 2, N'B', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (67, 2, N'B', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (68, 2, N'B', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (69, 2, N'B', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (70, 2, N'B', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (71, 2, N'C', 1, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (72, 2, N'C', 2, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (73, 2, N'C', 3, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (74, 2, N'C', 4, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (75, 2, N'C', 5, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (76, 2, N'C', 6, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (77, 2, N'C', 7, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (78, 2, N'C', 8, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (79, 2, N'C', 9, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (80, 2, N'C', 10, 1, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (81, 2, N'D', 1, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (82, 2, N'D', 2, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (83, 2, N'D', 3, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (84, 2, N'D', 4, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (85, 2, N'D', 5, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (86, 2, N'D', 6, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (87, 2, N'D', 7, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (88, 2, N'D', 8, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (89, 2, N'D', 9, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (90, 2, N'D', 10, 2, NULL, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (91, 2, N'E', 1, 3, 92, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (92, 2, N'E', 2, 3, 91, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (93, 2, N'E', 3, 3, 94, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (94, 2, N'E', 4, 3, 93, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (95, 2, N'E', 5, 3, 96, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (96, 2, N'E', 6, 3, 95, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (97, 2, N'E', 7, 3, 98, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (98, 2, N'E', 8, 3, 97, N'Active')
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (99, 2, N'E', 9, 3, 100, N'Active')
-- GO
-- INSERT [dbo].[Seat] ([seat_id], [room_id], [row_label], [seat_number], [seat_type_id], [pair_seat_id], [status]) VALUES (100, 2, N'E', 10, 3, 99, N'Active')
-- SET IDENTITY_INSERT [dbo].[Seat] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[SeatType] ON 
-- 
-- INSERT [dbo].[SeatType] ([seat_type_id], [type_name], [is_couple], [description]) VALUES (1, N'Standard', 0, N'Ghế thường')
-- INSERT [dbo].[SeatType] ([seat_type_id], [type_name], [is_couple], [description]) VALUES (2, N'VIP', 0, N'Ghế VIP')
-- INSERT [dbo].[SeatType] ([seat_type_id], [type_name], [is_couple], [description]) VALUES (3, N'Couple', 1, N'Ghế đôi (đặt theo cặp)')
-- SET IDENTITY_INSERT [dbo].[SeatType] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Showtime] ON 
-- 
-- INSERT [dbo].[Showtime] ([showtime_id], [movie_id], [room_id], [slot_id], [start_time], [end_time], [status], [created_by], [created_at]) VALUES (1, 1, 1, 3, CAST(N'2026-10-19T19:00:00.0000000' AS DateTime2), CAST(N'2026-10-19T22:00:00.0000000' AS DateTime2), N'Scheduled', 1, CAST(N'2026-10-18T12:15:22.2328181' AS DateTime2))
-- INSERT [dbo].[Showtime] ([showtime_id], [movie_id], [room_id], [slot_id], [start_time], [end_time], [status], [created_by], [created_at]) VALUES (2, 1, 1, 2, CAST(N'2026-10-20T14:00:00.0000000' AS DateTime2), CAST(N'2026-10-20T17:00:00.0000000' AS DateTime2), N'Scheduled', 1, CAST(N'2026-10-18T12:15:22.2328181' AS DateTime2))
-- INSERT [dbo].[Showtime] ([showtime_id], [movie_id], [room_id], [slot_id], [start_time], [end_time], [status], [created_by], [created_at]) VALUES (3, 2, 2, 3, CAST(N'2026-10-19T19:00:00.0000000' AS DateTime2), CAST(N'2026-10-19T21:15:00.0000000' AS DateTime2), N'Scheduled', 1, CAST(N'2026-10-18T12:15:22.2328181' AS DateTime2))
-- INSERT [dbo].[Showtime] ([showtime_id], [movie_id], [room_id], [slot_id], [start_time], [end_time], [status], [created_by], [created_at]) VALUES (4, 2, 2, 3, CAST(N'2026-10-20T19:00:00.0000000' AS DateTime2), CAST(N'2026-10-20T21:15:00.0000000' AS DateTime2), N'Scheduled', 1, CAST(N'2026-10-18T12:15:22.2328181' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[Showtime] OFF
-- GO
-- INSERT [dbo].[SystemConfig] ([config_key], [config_value], [description]) VALUES (N'BOOKING_SESSION_MINUTES', N'15', N'Thời gian tối đa của một phiên đặt vé')
-- INSERT [dbo].[SystemConfig] ([config_key], [config_value], [description]) VALUES (N'CANCEL_BEFORE_HOURS', N'2', N'Chỉ được hủy vé trước giờ chiếu tối thiểu (giờ)')
-- INSERT [dbo].[SystemConfig] ([config_key], [config_value], [description]) VALUES (N'CHECKIN_EARLY_MINUTES', N'30', N'Cho phép check-in sớm trước giờ chiếu (phút)')
-- INSERT [dbo].[SystemConfig] ([config_key], [config_value], [description]) VALUES (N'PAYMENT_WINDOW_MINUTES', N'5', N'Thời gian giữ ghế chờ chuyển khoản')
-- GO
-- SET IDENTITY_INSERT [dbo].[Ticket] ON 
-- 
-- INSERT [dbo].[Ticket] ([ticket_id], [booking_id], [showtime_id], [seat_id], [price], [ticket_code], [status], [checked_in_at], [checked_in_by]) VALUES (1, 1, 1, 35, CAST(90000 AS Decimal(10, 0)), N'TK4C537F9A2BD3', N'Booked', NULL, NULL)
-- INSERT [dbo].[Ticket] ([ticket_id], [booking_id], [showtime_id], [seat_id], [price], [ticket_code], [status], [checked_in_at], [checked_in_by]) VALUES (2, 1, 1, 36, CAST(90000 AS Decimal(10, 0)), N'TK26EDCB1E2C3D', N'Booked', NULL, NULL)
-- SET IDENTITY_INSERT [dbo].[Ticket] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[TicketPrice] ON 
-- 
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (1, 3, 1, N'Weekday', CAST(100000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (2, 3, 2, N'Weekday', CAST(110000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (3, 3, 3, N'Weekday', CAST(110000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (4, 3, 4, N'Weekday', CAST(105000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (5, 3, 1, N'Weekend', CAST(110000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (6, 3, 2, N'Weekend', CAST(120000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (7, 3, 3, N'Weekend', CAST(120000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (8, 3, 4, N'Weekend', CAST(115000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (9, 3, 1, N'Holiday', CAST(120000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (10, 3, 2, N'Holiday', CAST(130000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (11, 3, 3, N'Holiday', CAST(130000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (12, 3, 4, N'Holiday', CAST(125000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (13, 1, 1, N'Weekday', CAST(60000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (14, 1, 2, N'Weekday', CAST(70000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (15, 1, 3, N'Weekday', CAST(70000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (16, 1, 4, N'Weekday', CAST(65000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (17, 1, 1, N'Weekend', CAST(70000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (18, 1, 2, N'Weekend', CAST(80000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (19, 1, 3, N'Weekend', CAST(80000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (20, 1, 4, N'Weekend', CAST(75000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (21, 1, 1, N'Holiday', CAST(80000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (22, 1, 2, N'Holiday', CAST(90000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (23, 1, 3, N'Holiday', CAST(90000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (24, 1, 4, N'Holiday', CAST(85000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (25, 2, 1, N'Weekday', CAST(80000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (26, 2, 2, N'Weekday', CAST(90000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (27, 2, 3, N'Weekday', CAST(90000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (28, 2, 4, N'Weekday', CAST(85000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (29, 2, 1, N'Weekend', CAST(90000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (30, 2, 2, N'Weekend', CAST(100000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (31, 2, 3, N'Weekend', CAST(100000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (32, 2, 4, N'Weekend', CAST(95000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (33, 2, 1, N'Holiday', CAST(100000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (34, 2, 2, N'Holiday', CAST(110000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (35, 2, 3, N'Holiday', CAST(110000 AS Decimal(10, 0)))
-- INSERT [dbo].[TicketPrice] ([price_id], [seat_type_id], [slot_id], [day_type], [price]) VALUES (36, 2, 4, N'Holiday', CAST(105000 AS Decimal(10, 0)))
-- SET IDENTITY_INSERT [dbo].[TicketPrice] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[TimeSlot] ON 
-- 
-- INSERT [dbo].[TimeSlot] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (1, N'Sáng', CAST(N'08:00:00' AS Time), CAST(N'12:00:00' AS Time))
-- INSERT [dbo].[TimeSlot] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (2, N'Chiều', CAST(N'12:00:00' AS Time), CAST(N'17:00:00' AS Time))
-- INSERT [dbo].[TimeSlot] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (3, N'Tối', CAST(N'17:00:00' AS Time), CAST(N'22:00:00' AS Time))
-- INSERT [dbo].[TimeSlot] ([slot_id], [slot_name], [start_time], [end_time]) VALUES (4, N'Khuya', CAST(N'22:00:00' AS Time), CAST(N'23:59:00' AS Time))
-- SET IDENTITY_INSERT [dbo].[TimeSlot] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Users] ON 
-- 
-- INSERT [dbo].[Users] ([UserId], [FullName], [Email], [Phone], [PasswordHash], [DateOfBirth], [Gender], [Role], [Status], [OtpHash], [OtpExpiry], [OtpAttempts], [CreatedAt]) VALUES (1, N'Quản trị hệ thống', N'admin@cinema.vn', N'0900000001', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', NULL, NULL, N'ADMIN', N'ACTIVE', NULL, NULL, 0, CAST(N'2026-10-21T11:50:21.7821422' AS DateTime2))
-- INSERT [dbo].[Users] ([UserId], [FullName], [Email], [Phone], [PasswordHash], [DateOfBirth], [Gender], [Role], [Status], [OtpHash], [OtpExpiry], [OtpAttempts], [CreatedAt]) VALUES (2, N'Nguyễn Quản Lý', N'manager@cinema.vn', N'0900000002', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', NULL, NULL, N'MANAGER', N'ACTIVE', NULL, NULL, 0, CAST(N'2026-10-21T11:50:21.7821422' AS DateTime2))
-- INSERT [dbo].[Users] ([UserId], [FullName], [Email], [Phone], [PasswordHash], [DateOfBirth], [Gender], [Role], [Status], [OtpHash], [OtpExpiry], [OtpAttempts], [CreatedAt]) VALUES (3, N'Trần Nhân Viên', N'staff@cinema.vn', N'0900000003', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', NULL, NULL, N'STAFF', N'ACTIVE', NULL, NULL, 0, CAST(N'2026-10-21T11:50:21.7821422' AS DateTime2))
-- INSERT [dbo].[Users] ([UserId], [FullName], [Email], [Phone], [PasswordHash], [DateOfBirth], [Gender], [Role], [Status], [OtpHash], [OtpExpiry], [OtpAttempts], [CreatedAt]) VALUES (4, N'Lê Khách Một', N'khach1@gmail.com', N'0911111111', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', NULL, NULL, N'CUSTOMER', N'ACTIVE', NULL, NULL, 0, CAST(N'2026-10-21T11:50:21.7821422' AS DateTime2))
-- INSERT [dbo].[Users] ([UserId], [FullName], [Email], [Phone], [PasswordHash], [DateOfBirth], [Gender], [Role], [Status], [OtpHash], [OtpExpiry], [OtpAttempts], [CreatedAt]) VALUES (5, N'Phạm Khách Hai', N'khach2@gmail.com', N'0922222222', N'$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', NULL, NULL, N'CUSTOMER', N'ACTIVE', NULL, NULL, 0, CAST(N'2026-10-21T11:50:21.7821422' AS DateTime2))
-- SET IDENTITY_INSERT [dbo].[Users] OFF
-- GO
-- SET IDENTITY_INSERT [dbo].[Voucher] ON 
-- 
-- INSERT [dbo].[Voucher] ([voucher_id], [code], [description], [discount_type], [discount_value], [max_discount], [min_order_amount], [min_cumulative_spending], [usage_limit], [used_count], [per_customer_limit], [valid_from], [valid_to], [status], [created_by]) VALUES (1, N'WELCOME10', N'Giảm 10% (tối đa 30k) cho khách chi tiêu từ 1 triệu', N'Percent', CAST(10.00 AS Decimal(12, 2)), CAST(30000 AS Decimal(12, 0)), CAST(50000 AS Decimal(12, 0)), CAST(1000000 AS Decimal(14, 0)), 100, 1, 1, CAST(N'2026-10-17' AS Date), CAST(N'2026-12-17' AS Date), N'Allowed', 2)
-- SET IDENTITY_INSERT [dbo].[Voucher] OFF
-- GO
-- INSERT [dbo].[VoucherUsage] ([voucher_id], [booking_id], [customer_id], [used_at]) VALUES (1, 1, 4, CAST(N'2026-10-18T12:15:22.5646650' AS DateTime2))
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Account__AB6E61646B6B3858]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Account] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[email] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__AppRole__783254B124380BC1]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[AppRole] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[role_name] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Booking__FF29040F78D48682]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Booking] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[booking_code] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Genre__1E98D15111481949]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Genre] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[genre_name] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Permissi__A98A808EB924BC44]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Permission] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[permission_code] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- /****** Object:  Index [UQ__Review__CF1BABF0A020CC1B]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Review] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[movie_id] ASC,
-- 	[customer_id] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Room__87D55EE5A7E4793F]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Room] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[cinema_id] ASC,
-- 	[room_name] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Seat__768E1F1C4ED5EA79]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Seat] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[room_id] ASC,
-- 	[row_label] ASC,
-- 	[seat_number] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__SeatType__543C4FD92402E135]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[SeatType] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[type_name] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- /****** Object:  Index [UQ__Showtime__AB060B3B87C9A232]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Showtime] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[room_id] ASC,
-- 	[start_time] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Ticket__628DB75F763D6F86]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Ticket] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[ticket_code] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- /****** Object:  Index [ux_Ticket_ActiveSeat]    Script Date: 21/10/2026 4:16:23 CH ******/
-- CREATE UNIQUE NONCLUSTERED INDEX [ux_Ticket_ActiveSeat] ON [dbo].[Ticket]
-- (
-- 	[showtime_id] ASC,
-- 	[seat_id] ASC
-- )
-- WHERE ([status] IN ('Held', 'Booked', 'Used'))
-- WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__TicketPr__340A44A3B6291A75]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[TicketPrice] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[seat_type_id] ASC,
-- 	[slot_id] ASC,
-- 	[day_type] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__TimeSlot__83415C6FC87BF2CA]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[TimeSlot] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[slot_name] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ_Users_Email]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [UQ_Users_Email] UNIQUE NONCLUSTERED 
-- (
-- 	[Email] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ_Users_Phone]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [UQ_Users_Phone] UNIQUE NONCLUSTERED 
-- (
-- 	[Phone] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- SET ANSI_PADDING ON
-- GO
-- /****** Object:  Index [UQ__Voucher__357D4CF946205F80]    Script Date: 21/10/2026 4:16:23 CH ******/
-- ALTER TABLE [dbo].[Voucher] ADD UNIQUE NONCLUSTERED 
-- (
-- 	[code] ASC
-- )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- GO
-- ALTER TABLE [dbo].[Account] ADD  DEFAULT ('Active') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Account] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ('Online') FOR [channel]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ('Selecting') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [ticket_total]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [combo_total]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [voucher_discount]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [points_used]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [points_discount]
-- GO
-- ALTER TABLE [dbo].[Booking] ADD  DEFAULT ((0)) FOR [total_amount]
-- GO
-- ALTER TABLE [dbo].[Combo] ADD  DEFAULT ((0)) FOR [stock]
-- GO
-- ALTER TABLE [dbo].[Combo] ADD  DEFAULT ('Active') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Customer] ADD  DEFAULT ((0)) FOR [my_point_balance]
-- GO
-- ALTER TABLE [dbo].[Customer] ADD  DEFAULT ((0)) FOR [total_spent]
-- GO
-- ALTER TABLE [dbo].[EmailNotification] ADD  DEFAULT ('Pending') FOR [status]
-- GO
-- ALTER TABLE [dbo].[EmailNotification] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Movie] ADD  DEFAULT ('Upcoming') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Movie] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[MyPointConfig] ADD  DEFAULT ((1)) FOR [is_active]
-- GO
-- ALTER TABLE [dbo].[MyPointTransaction] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[News] ADD  DEFAULT ('Published') FOR [status]
-- GO
-- ALTER TABLE [dbo].[News] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Payment] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Review] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Room] ADD  DEFAULT ('2D') FOR [room_type]
-- GO
-- ALTER TABLE [dbo].[Room] ADD  DEFAULT ('Active') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Seat] ADD  DEFAULT ('Active') FOR [status]
-- GO
-- ALTER TABLE [dbo].[SeatType] ADD  DEFAULT ((0)) FOR [is_couple]
-- GO
-- ALTER TABLE [dbo].[Showtime] ADD  DEFAULT ('Scheduled') FOR [status]
-- GO
-- ALTER TABLE [dbo].[Showtime] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[SystemLog] ADD  DEFAULT (sysdatetime()) FOR [created_at]
-- GO
-- ALTER TABLE [dbo].[Ticket] ADD  DEFAULT ('Held') FOR [status]
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory] ADD  DEFAULT (sysdatetime()) FOR [changed_at]
-- GO
-- ALTER TABLE [dbo].[Users] ADD  DEFAULT ('CUSTOMER') FOR [Role]
-- GO
-- ALTER TABLE [dbo].[Users] ADD  DEFAULT ('PENDING') FOR [Status]
-- GO
-- ALTER TABLE [dbo].[Users] ADD  DEFAULT ((0)) FOR [OtpAttempts]
-- GO
-- ALTER TABLE [dbo].[Users] ADD  DEFAULT (sysdatetime()) FOR [CreatedAt]
-- GO
-- ALTER TABLE [dbo].[Voucher] ADD  DEFAULT ((0)) FOR [min_order_amount]
-- GO
-- ALTER TABLE [dbo].[Voucher] ADD  DEFAULT ((0)) FOR [min_cumulative_spending]
-- GO
-- ALTER TABLE [dbo].[Voucher] ADD  DEFAULT ((0)) FOR [used_count]
-- GO
-- ALTER TABLE [dbo].[Voucher] ADD  DEFAULT ((1)) FOR [per_customer_limit]
-- GO
-- ALTER TABLE [dbo].[Voucher] ADD  DEFAULT ('Allowed') FOR [status]
-- GO
-- ALTER TABLE [dbo].[VoucherUsage] ADD  DEFAULT (sysdatetime()) FOR [used_at]
-- GO
-- ALTER TABLE [dbo].[Account]  WITH CHECK ADD FOREIGN KEY([role_id])
-- REFERENCES [dbo].[AppRole] ([role_id])
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Customer] ([customer_id])
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([showtime_id])
-- REFERENCES [dbo].[Showtime] ([showtime_id])
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([staff_id])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD FOREIGN KEY([voucher_id])
-- REFERENCES [dbo].[Voucher] ([voucher_id])
-- GO
-- ALTER TABLE [dbo].[BookingCombo]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[BookingCombo]  WITH CHECK ADD FOREIGN KEY([combo_id])
-- REFERENCES [dbo].[Combo] ([combo_id])
-- GO
-- ALTER TABLE [dbo].[Customer]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Customer] ([customer_id])
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD FOREIGN KEY([movie_id])
-- REFERENCES [dbo].[Movie] ([movie_id])
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD FOREIGN KEY([showtime_id])
-- REFERENCES [dbo].[Showtime] ([showtime_id])
-- GO
-- ALTER TABLE [dbo].[Movie]  WITH CHECK ADD FOREIGN KEY([created_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[MovieGenre]  WITH CHECK ADD FOREIGN KEY([genre_id])
-- REFERENCES [dbo].[Genre] ([genre_id])
-- GO
-- ALTER TABLE [dbo].[MovieGenre]  WITH CHECK ADD FOREIGN KEY([movie_id])
-- REFERENCES [dbo].[Movie] ([movie_id])
-- ON DELETE CASCADE
-- GO
-- ALTER TABLE [dbo].[MyPointConfig]  WITH CHECK ADD FOREIGN KEY([updated_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[MyPointTransaction]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[MyPointTransaction]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Customer] ([customer_id])
-- GO
-- ALTER TABLE [dbo].[News]  WITH CHECK ADD FOREIGN KEY([created_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[Payment]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[Review]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Customer] ([customer_id])
-- GO
-- ALTER TABLE [dbo].[Review]  WITH CHECK ADD FOREIGN KEY([movie_id])
-- REFERENCES [dbo].[Movie] ([movie_id])
-- GO
-- ALTER TABLE [dbo].[RolePermission]  WITH CHECK ADD FOREIGN KEY([permission_id])
-- REFERENCES [dbo].[Permission] ([permission_id])
-- GO
-- ALTER TABLE [dbo].[RolePermission]  WITH CHECK ADD FOREIGN KEY([role_id])
-- REFERENCES [dbo].[AppRole] ([role_id])
-- GO
-- ALTER TABLE [dbo].[Room]  WITH CHECK ADD FOREIGN KEY([cinema_id])
-- REFERENCES [dbo].[Cinema] ([cinema_id])
-- GO
-- ALTER TABLE [dbo].[Seat]  WITH CHECK ADD FOREIGN KEY([pair_seat_id])
-- REFERENCES [dbo].[Seat] ([seat_id])
-- GO
-- ALTER TABLE [dbo].[Seat]  WITH CHECK ADD FOREIGN KEY([room_id])
-- REFERENCES [dbo].[Room] ([room_id])
-- GO
-- ALTER TABLE [dbo].[Seat]  WITH CHECK ADD FOREIGN KEY([seat_type_id])
-- REFERENCES [dbo].[SeatType] ([seat_type_id])
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD FOREIGN KEY([created_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD FOREIGN KEY([movie_id])
-- REFERENCES [dbo].[Movie] ([movie_id])
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD FOREIGN KEY([room_id])
-- REFERENCES [dbo].[Room] ([room_id])
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD FOREIGN KEY([slot_id])
-- REFERENCES [dbo].[TimeSlot] ([slot_id])
-- GO
-- ALTER TABLE [dbo].[SystemLog]  WITH CHECK ADD FOREIGN KEY([account_id])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[Ticket]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[Ticket]  WITH CHECK ADD FOREIGN KEY([checked_in_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[Ticket]  WITH CHECK ADD FOREIGN KEY([seat_id])
-- REFERENCES [dbo].[Seat] ([seat_id])
-- GO
-- ALTER TABLE [dbo].[Ticket]  WITH CHECK ADD FOREIGN KEY([showtime_id])
-- REFERENCES [dbo].[Showtime] ([showtime_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([changed_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([new_seat_id])
-- REFERENCES [dbo].[Seat] ([seat_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([new_showtime_id])
-- REFERENCES [dbo].[Showtime] ([showtime_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([old_seat_id])
-- REFERENCES [dbo].[Seat] ([seat_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([old_showtime_id])
-- REFERENCES [dbo].[Showtime] ([showtime_id])
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD FOREIGN KEY([ticket_id])
-- REFERENCES [dbo].[Ticket] ([ticket_id])
-- GO
-- ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD FOREIGN KEY([seat_type_id])
-- REFERENCES [dbo].[SeatType] ([seat_type_id])
-- GO
-- ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD FOREIGN KEY([slot_id])
-- REFERENCES [dbo].[TimeSlot] ([slot_id])
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD FOREIGN KEY([created_by])
-- REFERENCES [dbo].[Account] ([account_id])
-- GO
-- ALTER TABLE [dbo].[VoucherUsage]  WITH CHECK ADD FOREIGN KEY([booking_id])
-- REFERENCES [dbo].[Booking] ([booking_id])
-- GO
-- ALTER TABLE [dbo].[VoucherUsage]  WITH CHECK ADD FOREIGN KEY([customer_id])
-- REFERENCES [dbo].[Customer] ([customer_id])
-- GO
-- ALTER TABLE [dbo].[VoucherUsage]  WITH CHECK ADD FOREIGN KEY([voucher_id])
-- REFERENCES [dbo].[Voucher] ([voucher_id])
-- GO
-- ALTER TABLE [dbo].[Account]  WITH CHECK ADD CHECK  (([status]='Locked' OR [status]='Active'))
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD CHECK  (([channel]='Counter' OR [channel]='Online'))
-- GO
-- ALTER TABLE [dbo].[Booking]  WITH CHECK ADD CHECK  (([status]='Expired' OR [status]='Cancelled' OR [status]='Paid' OR [status]='PendingPayment' OR [status]='Selecting'))
-- GO
-- ALTER TABLE [dbo].[BookingCombo]  WITH CHECK ADD CHECK  (([quantity]>(0)))
-- GO
-- ALTER TABLE [dbo].[Combo]  WITH CHECK ADD CHECK  (([price]>=(0)))
-- GO
-- ALTER TABLE [dbo].[Combo]  WITH CHECK ADD CHECK  (([status]='Hidden' OR [status]='Active'))
-- GO
-- ALTER TABLE [dbo].[Combo]  WITH CHECK ADD CHECK  (([stock]>=(0)))
-- GO
-- ALTER TABLE [dbo].[Customer]  WITH CHECK ADD CHECK  (([my_point_balance]>=(0)))
-- GO
-- ALTER TABLE [dbo].[Customer]  WITH CHECK ADD CHECK  (([total_spent]>=(0)))
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD CHECK  (([notif_type]='MovieCancelled' OR [notif_type]='ETicket' OR [notif_type]='Voucher' OR [notif_type]='NewMovie' OR [notif_type]='ShowtimeReminder'))
-- GO
-- ALTER TABLE [dbo].[EmailNotification]  WITH CHECK ADD CHECK  (([status]='Failed' OR [status]='Sent' OR [status]='Pending'))
-- GO
-- ALTER TABLE [dbo].[Movie]  WITH CHECK ADD CHECK  (([age_rating]='T18' OR [age_rating]='T16' OR [age_rating]='T13' OR [age_rating]='K' OR [age_rating]='P'))
-- GO
-- ALTER TABLE [dbo].[Movie]  WITH CHECK ADD CHECK  (([duration_minutes]>(0)))
-- GO
-- ALTER TABLE [dbo].[Movie]  WITH CHECK ADD CHECK  (([status]='Stopped' OR [status]='NowShowing' OR [status]='Upcoming'))
-- GO
-- ALTER TABLE [dbo].[MyPointTransaction]  WITH CHECK ADD CHECK  (([txn_type]='Adjust' OR [txn_type]='Redeem' OR [txn_type]='Earn'))
-- GO
-- ALTER TABLE [dbo].[News]  WITH CHECK ADD CHECK  (([status]='Hidden' OR [status]='Published' OR [status]='Draft'))
-- GO
-- ALTER TABLE [dbo].[Payment]  WITH CHECK ADD CHECK  (([method]='Cash' OR [method]='BankTransfer'))
-- GO
-- ALTER TABLE [dbo].[Payment]  WITH CHECK ADD CHECK  (([status]='Refunded' OR [status]='Failed' OR [status]='Success' OR [status]='Pending'))
-- GO
-- ALTER TABLE [dbo].[Review]  WITH CHECK ADD CHECK  (([rating]>=(1) AND [rating]<=(5)))
-- GO
-- ALTER TABLE [dbo].[Room]  WITH CHECK ADD CHECK  (([capacity]>(0)))
-- GO
-- ALTER TABLE [dbo].[Room]  WITH CHECK ADD CHECK  (([room_type]='4DX' OR [room_type]='IMAX' OR [room_type]='3D' OR [room_type]='2D'))
-- GO
-- ALTER TABLE [dbo].[Room]  WITH CHECK ADD CHECK  (([status]='Closed' OR [status]='Active'))
-- GO
-- ALTER TABLE [dbo].[Seat]  WITH CHECK ADD CHECK  (([status]='Maintenance' OR [status]='Active'))
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD CHECK  (([end_time]>[start_time]))
-- GO
-- ALTER TABLE [dbo].[Showtime]  WITH CHECK ADD CHECK  (([status]='Finished' OR [status]='Cancelled' OR [status]='Scheduled'))
-- GO
-- ALTER TABLE [dbo].[Ticket]  WITH CHECK ADD CHECK  (([status]='Expired' OR [status]='Cancelled' OR [status]='Used' OR [status]='Booked' OR [status]='Held'))
-- GO
-- ALTER TABLE [dbo].[TicketChangeHistory]  WITH CHECK ADD CHECK  (([change_type]='SeatChange' OR [change_type]='ExchangeShowtime' OR [change_type]='Cancel'))
-- GO
-- ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD CHECK  (([day_type]='Holiday' OR [day_type]='Weekend' OR [day_type]='Weekday'))
-- GO
-- ALTER TABLE [dbo].[TicketPrice]  WITH CHECK ADD CHECK  (([price]>=(0)))
-- GO
-- ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK_Users_Role] CHECK  (([Role]='ADMIN' OR [Role]='MANAGER' OR [Role]='STAFF' OR [Role]='CUSTOMER'))
-- GO
-- ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK_Users_Role]
-- GO
-- ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [CK_Users_Status] CHECK  (([Status]='BLOCKED' OR [Status]='ACTIVE' OR [Status]='PENDING'))
-- GO
-- ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [CK_Users_Status]
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD CHECK  (([valid_to]>=[valid_from]))
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD CHECK  (([discount_type]='Amount' OR [discount_type]='Percent'))
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD CHECK  (([discount_value]>(0)))
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD CHECK  (([status]='Disabled' OR [status]='Used' OR [status]='Expired' OR [status]='Allowed'))
-- GO
-- ALTER TABLE [dbo].[Voucher]  WITH CHECK ADD CHECK  (([usage_limit]>(0)))
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_AddCombo]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Order Popcorn & Drink Combos (@quantity = 0 để bỏ combo)
-- CREATE PROCEDURE [dbo].[sp_AddCombo] @booking_id INT, @combo_id INT, @quantity INT AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @status VARCHAR(15) = (SELECT status FROM Booking WHERE booking_id = @booking_id);
--     IF @status IS NULL OR @status NOT IN ('Selecting','PendingPayment') THROW 50020, N'Booking không còn hiệu lực.', 1;
--     IF @quantity <= 0
--         DELETE FROM BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id;
--     ELSE
--     BEGIN
--         IF NOT EXISTS (SELECT 1 FROM Combo WHERE combo_id = @combo_id AND status = 'Active' AND stock >= @quantity)
--             THROW 50021, N'Combo không tồn tại hoặc không đủ số lượng.', 1;
--         IF EXISTS (SELECT 1 FROM BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id)
--             UPDATE BookingCombo SET quantity = @quantity WHERE booking_id = @booking_id AND combo_id = @combo_id;
--         ELSE
--             INSERT INTO BookingCombo(booking_id, combo_id, quantity, unit_price)
--             SELECT @booking_id, combo_id, @quantity, price FROM Combo WHERE combo_id = @combo_id;
--     END
--     EXEC sp_RecalcBooking @booking_id;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_AddReview]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Movie Review & Comment (chỉ phim đã xem = có vé đã check-in)
-- CREATE PROCEDURE [dbo].[sp_AddReview] @customer_id INT, @movie_id INT, @rating TINYINT, @comment NVARCHAR(1000) = NULL AS
-- BEGIN
--     SET NOCOUNT ON;
--     IF NOT EXISTS (SELECT 1 FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id
--                    JOIN Showtime s ON s.showtime_id = t.showtime_id
--                    WHERE b.customer_id = @customer_id AND s.movie_id = @movie_id AND t.status = 'Used')
--         THROW 50090, N'Chỉ được đánh giá phim bạn đã xem.', 1;
--     INSERT INTO Review(movie_id, customer_id, rating, comment) VALUES (@movie_id, @customer_id, @rating, @comment);
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_ApplyMyPoint]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Apply MyPoint (tối đa % giá trị đơn hiện tại)
-- CREATE PROCEDURE [dbo].[sp_ApplyMyPoint] @booking_id INT, @points INT AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @customer_id INT, @status VARCHAR(15), @base DECIMAL(12,0), @pt_value INT, @max_pct DECIMAL(5,2), @disc DECIMAL(12,0);
--     SELECT @customer_id = customer_id, @status = status, @base = ticket_total + combo_total - voucher_discount
--     FROM Booking WHERE booking_id = @booking_id;
--     SELECT TOP 1 @pt_value = point_value_vnd, @max_pct = max_redeem_percent
--     FROM MyPointConfig WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC;
-- 
--     IF @status IS NULL OR @status <> 'PendingPayment' THROW 50040, N'Chỉ dùng MyPoint ở bước thanh toán.', 1;
--     IF @customer_id IS NULL THROW 50041, N'Khách mua tại quầy không có tài khoản MyPoint.', 1;
--     IF @points < 0 THROW 50042, N'Số điểm không hợp lệ.', 1;
--     IF @points > (SELECT my_point_balance FROM Customer WHERE customer_id = @customer_id)
--         THROW 50043, N'Số dư MyPoint không đủ.', 1;
-- 
--     SET @disc = @points * @pt_value;
--     IF @disc > @base * @max_pct / 100 THROW 50044, N'Vượt quá tỷ lệ tối đa được dùng MyPoint trên giá trị đơn.', 1;
-- 
--     UPDATE Booking SET points_used = @points, points_discount = @disc WHERE booking_id = @booking_id;
--     EXEC sp_RecalcBooking @booking_id;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_ApplyVoucher]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Apply Cinema Voucher (áp voucher trước, sau đó mới áp MyPoint)
-- CREATE PROCEDURE [dbo].[sp_ApplyVoucher] @booking_id INT, @code VARCHAR(30) AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @customer_id INT, @status VARCHAR(15), @subtotal DECIMAL(12,0);
--     DECLARE @vid INT, @type VARCHAR(10), @val DECIMAL(12,2), @maxd DECIMAL(12,0), @min_order DECIMAL(12,0),
--             @min_spent DECIMAL(14,0), @limit INT, @used INT, @per INT, @vstatus VARCHAR(10), @from DATE, @to DATE,
--             @disc DECIMAL(12,0);
-- 
--     SELECT @customer_id = customer_id, @status = status, @subtotal = ticket_total + combo_total
--     FROM Booking WHERE booking_id = @booking_id;
--     IF @status IS NULL OR @status <> 'PendingPayment' THROW 50030, N'Chỉ áp voucher ở bước thanh toán (sau khi giữ ghế).', 1;
--     IF @customer_id IS NULL THROW 50031, N'Khách mua tại quầy không dùng voucher online.', 1;
-- 
--     SELECT @vid = voucher_id, @type = discount_type, @val = discount_value, @maxd = max_discount,
--            @min_order = min_order_amount, @min_spent = min_cumulative_spending, @limit = usage_limit,
--            @used = used_count, @per = per_customer_limit, @vstatus = status, @from = valid_from, @to = valid_to
--     FROM Voucher WHERE code = @code;
-- 
--     IF @vid IS NULL THROW 50032, N'Mã voucher không tồn tại.', 1;
--     IF @vstatus <> 'Allowed' THROW 50033, N'Voucher không còn ở trạng thái cho phép sử dụng.', 1;
--     IF CAST(SYSDATETIME() AS DATE) NOT BETWEEN @from AND @to THROW 50034, N'Voucher chưa đến hoặc đã quá hạn.', 1;
--     IF @used >= @limit THROW 50035, N'Voucher đã hết lượt sử dụng.', 1;
--     IF (SELECT total_spent FROM Customer WHERE customer_id = @customer_id) < @min_spent
--         THROW 50036, N'Chi tiêu tích lũy chưa đạt mức tối thiểu để dùng voucher.', 1;
--     IF @subtotal < @min_order THROW 50037, N'Giá trị đơn hàng chưa đạt mức tối thiểu của voucher.', 1;
--     IF (SELECT COUNT(*) FROM VoucherUsage WHERE voucher_id = @vid AND customer_id = @customer_id) >= @per
--         THROW 50038, N'Bạn đã dùng hết số lần cho phép của voucher này.', 1;
-- 
--     SET @disc = CASE @type WHEN 'Percent' THEN @subtotal * @val / 100 ELSE @val END;
--     IF @maxd IS NOT NULL AND @disc > @maxd SET @disc = @maxd;
--     IF @disc > @subtotal SET @disc = @subtotal;
-- 
--     UPDATE Booking SET voucher_id = @vid, voucher_discount = @disc, points_used = 0, points_discount = 0
--     WHERE booking_id = @booking_id;
--     EXEC sp_RecalcBooking @booking_id;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_CancelBooking]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Cancel / Exchange Tickets (hủy cả booking trước giờ chiếu tối thiểu theo SystemConfig)
-- -- Việc hoàn lại MyPoint / voucher khi hủy: tùy quy định nhóm, chưa xử lý ở đây.
-- CREATE PROCEDURE [dbo].[sp_CancelBooking] @booking_id INT, @account_id INT, @reason NVARCHAR(200) = NULL AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     DECLARE @status VARCHAR(15), @start DATETIME2;
--     DECLARE @hours INT = (SELECT CAST(config_value AS INT) FROM SystemConfig WHERE config_key = 'CANCEL_BEFORE_HOURS');
--     SELECT @status = b.status, @start = s.start_time FROM Booking b JOIN Showtime s ON s.showtime_id = b.showtime_id
--     WHERE b.booking_id = @booking_id;
-- 
--     IF @status IS NULL OR @status <> 'Paid' THROW 50070, N'Chỉ hủy được booking đã thanh toán.', 1;
--     IF DATEADD(HOUR, -@hours, @start) < SYSDATETIME() THROW 50071, N'Đã quá thời hạn cho phép hủy vé.', 1;
-- 
--     BEGIN TRAN;
--     INSERT INTO TicketChangeHistory(ticket_id, change_type, old_seat_id, old_showtime_id, changed_by, reason)
--     SELECT ticket_id, 'Cancel', seat_id, showtime_id, @account_id, @reason FROM Ticket
--     WHERE booking_id = @booking_id AND status = 'Booked';
--     UPDATE Ticket SET status = 'Cancelled' WHERE booking_id = @booking_id AND status = 'Booked';
--     UPDATE Booking SET status = 'Cancelled' WHERE booking_id = @booking_id;
--     UPDATE Payment SET status = 'Refunded' WHERE booking_id = @booking_id AND status = 'Success';
--     COMMIT;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_CancelMovie]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Now-Showing Movie Cancellation Alert
-- -- @confirm = 0: chỉ cảnh báo (liệt kê suất/vé bị ảnh hưởng). @confirm = 1: xác nhận hủy, hoàn tiền, gửi email.
-- CREATE PROCEDURE [dbo].[sp_CancelMovie] @movie_id INT, @manager_id INT, @confirm BIT = 0 AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     SELECT s.showtime_id, s.start_time, r.room_name, COUNT(t.ticket_id) AS booked_tickets
--     FROM Showtime s JOIN Room r ON r.room_id = s.room_id
--     LEFT JOIN Ticket t ON t.showtime_id = s.showtime_id AND t.status = 'Booked'
--     WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
--     GROUP BY s.showtime_id, s.start_time, r.room_name;
--     IF @confirm = 0 RETURN;
-- 
--     BEGIN TRAN;
--     INSERT INTO EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id)
--     SELECT DISTINCT b.customer_id, 'MovieCancelled', N'Thông báo hủy suất chiếu',
--            N'Suất chiếu bạn đã đặt bị hủy, vé sẽ được hoàn tiền.', s.showtime_id, @movie_id, b.booking_id
--     FROM Booking b JOIN Showtime s ON s.showtime_id = b.showtime_id
--     WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
--       AND b.status = 'Paid' AND b.customer_id IS NOT NULL;
-- 
--     UPDATE p SET p.status = 'Refunded'
--     FROM Payment p JOIN Booking b ON b.booking_id = p.booking_id JOIN Showtime s ON s.showtime_id = b.showtime_id
--     WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() AND p.status = 'Success';
-- 
--     UPDATE t SET t.status = 'Cancelled'
--     FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id
--     WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() AND t.status IN ('Held','Booked');
-- 
--     UPDATE b SET b.status = 'Cancelled'
--     FROM Booking b JOIN Showtime s ON s.showtime_id = b.showtime_id
--     WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
--       AND b.status IN ('Paid','PendingPayment');
-- 
--     UPDATE Showtime SET status = 'Cancelled'
--     WHERE movie_id = @movie_id AND status = 'Scheduled' AND start_time > SYSDATETIME();
-- 
--     UPDATE Movie SET status = 'Stopped', end_date = CAST(SYSDATETIME() AS DATE), updated_at = SYSDATETIME()
--     WHERE movie_id = @movie_id;
-- 
--     INSERT INTO SystemLog(account_id, action, detail) VALUES (@manager_id, N'CANCEL_MOVIE', CONCAT(N'movie_id=', @movie_id));
--     COMMIT;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_ChangeSeat]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Seat Change (Admin) - đổi ghế trong cùng suất. Ghế đôi cần đổi cả cặp -> xử lý riêng ở tầng ứng dụng.
-- CREATE PROCEDURE [dbo].[sp_ChangeSeat] @ticket_id INT, @new_seat_id INT, @admin_id INT, @reason NVARCHAR(200) = NULL AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     EXEC sp_ReleaseExpiredHolds;
--     DECLARE @showtime_id INT, @old_seat INT, @tstatus VARCHAR(10), @room INT,
--             @new_room INT, @new_pair INT, @new_status VARCHAR(12);
-- 
--     SELECT @showtime_id = t.showtime_id, @old_seat = t.seat_id, @tstatus = t.status, @room = s.room_id
--     FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id WHERE t.ticket_id = @ticket_id;
--     SELECT @new_room = room_id, @new_pair = pair_seat_id, @new_status = status FROM Seat WHERE seat_id = @new_seat_id;
-- 
--     IF @tstatus IS NULL OR @tstatus <> 'Booked' THROW 50080, N'Chỉ đổi ghế cho vé đã thanh toán và chưa sử dụng.', 1;
--     IF @new_room IS NULL OR @new_room <> @room THROW 50081, N'Ghế mới phải thuộc cùng phòng của suất chiếu.', 1;
--     IF @new_status = 'Maintenance' THROW 50082, N'Ghế mới đang bảo trì.', 1;
--     IF @new_pair IS NOT NULL OR EXISTS (SELECT 1 FROM Seat WHERE seat_id = @old_seat AND pair_seat_id IS NOT NULL)
--         THROW 50083, N'Ghế đôi phải đổi theo cặp, không hỗ trợ đổi từng ghế.', 1;
--     IF NOT EXISTS (SELECT 1 FROM vw_SeatMap WHERE showtime_id = @showtime_id AND seat_id = @new_seat_id AND color = 'GREEN')
--         THROW 50084, N'Ghế mới không còn trống.', 1;
-- 
--     BEGIN TRAN;
--     UPDATE Ticket SET seat_id = @new_seat_id WHERE ticket_id = @ticket_id;      -- giữ nguyên giá vé đã thanh toán
--     INSERT INTO TicketChangeHistory(ticket_id, change_type, old_seat_id, new_seat_id, old_showtime_id, new_showtime_id, changed_by, reason)
--     VALUES (@ticket_id, 'SeatChange', @old_seat, @new_seat_id, @showtime_id, @showtime_id, @admin_id, @reason);
--     COMMIT;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_CheckInTicket]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Ticket Check-in (QR Scan)
-- CREATE PROCEDURE [dbo].[sp_CheckInTicket] @ticket_code VARCHAR(30), @staff_id INT AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @tid INT, @tstatus VARCHAR(10), @start DATETIME2, @end DATETIME2, @sstatus VARCHAR(10);
--     DECLARE @early INT = (SELECT CAST(config_value AS INT) FROM SystemConfig WHERE config_key = 'CHECKIN_EARLY_MINUTES');
--     SELECT @tid = t.ticket_id, @tstatus = t.status, @start = s.start_time, @end = s.end_time, @sstatus = s.status
--     FROM Ticket t JOIN Showtime s ON s.showtime_id = t.showtime_id WHERE t.ticket_code = @ticket_code;
-- 
--     IF @tid IS NULL THROW 50060, N'Mã vé không tồn tại.', 1;
--     IF @tstatus = 'Used' THROW 50061, N'Vé đã được sử dụng.', 1;
--     IF @tstatus <> 'Booked' OR @sstatus = 'Cancelled' THROW 50062, N'Vé không hợp lệ.', 1;
--     IF SYSDATETIME() < DATEADD(MINUTE, -@early, @start) OR SYSDATETIME() > @end
--         THROW 50063, N'Ngoài thời gian cho phép vào phòng chiếu.', 1;
-- 
--     UPDATE Ticket SET status = 'Used', checked_in_at = SYSDATETIME(), checked_in_by = @staff_id WHERE ticket_id = @tid;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_ConfirmPayment]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Payment + Confirm / Return Payment Result (Payment Gateway gọi về)
-- CREATE PROCEDURE [dbo].[sp_ConfirmPayment]
--     @booking_id INT, @gateway_txn_id VARCHAR(100) = NULL, @is_success BIT, @method VARCHAR(15) = 'BankTransfer'
-- AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     DECLARE @status VARCHAR(15), @pay_exp DATETIME2, @customer_id INT, @total DECIMAL(12,0), @voucher_id INT, @points INT;
--     DECLARE @earn_rate DECIMAL(5,2), @pt_value INT, @earned INT;
-- 
--     SELECT @status = status, @pay_exp = payment_expires_at, @customer_id = customer_id,
--            @total = total_amount, @voucher_id = voucher_id, @points = points_used
--     FROM Booking WHERE booking_id = @booking_id;
--     IF @status IS NULL OR @status <> 'PendingPayment'
--         THROW 50050, N'Booking không ở trạng thái chờ thanh toán (có thể đã hết hạn).', 1;
-- 
--     BEGIN TRAN;
--     IF @is_success = 1 AND @pay_exp >= SYSDATETIME()
--     BEGIN
--         UPDATE Booking SET status = 'Paid', paid_at = SYSDATETIME() WHERE booking_id = @booking_id;
--         UPDATE Ticket SET status = 'Booked' WHERE booking_id = @booking_id AND status = 'Held';   -- YELLOW -> RED
--         INSERT INTO Payment(booking_id, method, amount, gateway_txn_id, status, paid_at)
--         VALUES (@booking_id, @method, @total, @gateway_txn_id, 'Success', SYSDATETIME());
-- 
--         UPDATE c SET c.stock = c.stock - bc.quantity
--         FROM Combo c JOIN BookingCombo bc ON bc.combo_id = c.combo_id WHERE bc.booking_id = @booking_id;
-- 
--         IF @voucher_id IS NOT NULL
--         BEGIN
--             INSERT INTO VoucherUsage(voucher_id, booking_id, customer_id) VALUES (@voucher_id, @booking_id, @customer_id);
--             UPDATE Voucher SET used_count = used_count + 1,
--                    status = CASE WHEN used_count + 1 >= usage_limit THEN 'Used' ELSE status END
--             WHERE voucher_id = @voucher_id;
--         END
-- 
--         IF @customer_id IS NOT NULL
--         BEGIN
--             SELECT TOP 1 @earn_rate = earn_rate_percent, @pt_value = point_value_vnd
--             FROM MyPointConfig WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC;
--             SET @earned = FLOOR(@total * @earn_rate / 100.0 / @pt_value);
-- 
--             IF @points > 0
--                 INSERT INTO MyPointTransaction(customer_id, booking_id, txn_type, points) VALUES (@customer_id, @booking_id, 'Redeem', -@points);
--             IF @earned > 0
--                 INSERT INTO MyPointTransaction(customer_id, booking_id, txn_type, points) VALUES (@customer_id, @booking_id, 'Earn', @earned);
-- 
--             UPDATE Customer SET my_point_balance = my_point_balance - @points + ISNULL(@earned, 0),
--                                 total_spent = total_spent + @total
--             WHERE customer_id = @customer_id;
-- 
--             INSERT INTO EmailNotification(customer_id, notif_type, subject, body, booking_id)
--             VALUES (@customer_id, 'ETicket', N'Vé điện tử của bạn', N'Đính kèm mã QR các vé đã đặt.', @booking_id);
--         END
--     END
--     ELSE
--     BEGIN
--         UPDATE Ticket SET status = 'Cancelled' WHERE booking_id = @booking_id AND status = 'Held';   -- YELLOW -> GREEN
--         UPDATE Booking SET status = CASE WHEN @is_success = 1 THEN 'Expired' ELSE 'Cancelled' END WHERE booking_id = @booking_id;
--         INSERT INTO Payment(booking_id, method, amount, gateway_txn_id, status)
--         VALUES (@booking_id, @method, @total, @gateway_txn_id, 'Failed');
--     END
--     COMMIT;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_CreateBooking]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Book Movie Tickets (bước 1 - mở phiên đặt vé) / Counter Ticket Sales (@channel = 'Counter')
-- CREATE PROCEDURE [dbo].[sp_CreateBooking]
--     @customer_id INT = NULL, @staff_id INT = NULL, @showtime_id INT, @channel VARCHAR(10) = 'Online',
--     @booking_id INT OUTPUT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @session_min INT = (SELECT CAST(config_value AS INT) FROM SystemConfig WHERE config_key = 'BOOKING_SESSION_MINUTES');
--     IF NOT EXISTS (SELECT 1 FROM Showtime s JOIN Movie m ON m.movie_id = s.movie_id
--                    WHERE s.showtime_id = @showtime_id AND s.status = 'Scheduled'
--                      AND s.start_time > SYSDATETIME() AND m.status <> 'Stopped')
--         THROW 50002, N'Suất chiếu không tồn tại, đã bắt đầu hoặc đã bị hủy.', 1;
--     IF @customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Account WHERE account_id = @customer_id AND status = 'Active')
--         THROW 50003, N'Tài khoản không hợp lệ hoặc đã bị khóa.', 1;
-- 
--     INSERT INTO Booking(booking_code, customer_id, staff_id, showtime_id, channel, session_expires_at)
--     VALUES ('BK' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 10)),
--             @customer_id, @staff_id, @showtime_id, @channel, DATEADD(MINUTE, @session_min, SYSDATETIME()));
--     SET @booking_id = SCOPE_IDENTITY();
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_HoldSeats]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Select Seats (giữ ghế) - @seat_ids dạng '41,42'. Ghế đôi phải chọn cả cặp, ghế bảo trì không được chọn.
-- CREATE PROCEDURE [dbo].[sp_HoldSeats] @booking_id INT, @seat_ids NVARCHAR(MAX) AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     EXEC sp_ReleaseExpiredHolds;
-- 
--     DECLARE @showtime_id INT, @status VARCHAR(15), @session_exp DATETIME2, @room_id INT;
--     DECLARE @pay_min INT = (SELECT CAST(config_value AS INT) FROM SystemConfig WHERE config_key = 'PAYMENT_WINDOW_MINUTES');
--     SELECT @showtime_id = b.showtime_id, @status = b.status, @session_exp = b.session_expires_at, @room_id = s.room_id
--     FROM Booking b JOIN Showtime s ON s.showtime_id = b.showtime_id WHERE b.booking_id = @booking_id;
-- 
--     IF @status IS NULL THROW 50010, N'Không tìm thấy booking.', 1;
--     IF @status <> 'Selecting' OR @session_exp < SYSDATETIME()
--         THROW 50011, N'Phiên đặt vé đã hết hạn (tối đa 15 phút) hoặc không ở bước chọn ghế.', 1;
-- 
--     DECLARE @sel TABLE (seat_id INT PRIMARY KEY);
--     INSERT INTO @sel SELECT DISTINCT CAST(value AS INT) FROM STRING_SPLIT(@seat_ids, ',') WHERE LTRIM(RTRIM(value)) <> '';
-- 
--     IF NOT EXISTS (SELECT 1 FROM @sel) THROW 50013, N'Chưa chọn ghế nào.', 1;
--     IF EXISTS (SELECT 1 FROM @sel x LEFT JOIN Seat s ON s.seat_id = x.seat_id AND s.room_id = @room_id WHERE s.seat_id IS NULL)
--         THROW 50014, N'Có ghế không thuộc phòng chiếu của suất này.', 1;
--     IF EXISTS (SELECT 1 FROM Seat s JOIN @sel x ON x.seat_id = s.seat_id WHERE s.status = 'Maintenance')
--         THROW 50015, N'Có ghế đang bảo trì, không thể chọn.', 1;
--     IF EXISTS (SELECT 1 FROM Seat s JOIN @sel x ON x.seat_id = s.seat_id
--                WHERE s.pair_seat_id IS NOT NULL AND s.pair_seat_id NOT IN (SELECT seat_id FROM @sel))
--         THROW 50016, N'Ghế đôi phải được chọn cả cặp, không được tách.', 1;
-- 
--     BEGIN TRY
--         BEGIN TRAN;
--         INSERT INTO Ticket(booking_id, showtime_id, seat_id, price, ticket_code, status)
--         SELECT @booking_id, @showtime_id, s.seat_id, dbo.fn_GetTicketPrice(@showtime_id, s.seat_type_id),
--                'TK' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 12)), 'Held'
--         FROM Seat s JOIN @sel x ON x.seat_id = s.seat_id;
-- 
--         UPDATE Booking SET status = 'PendingPayment',
--                payment_expires_at = CASE WHEN DATEADD(MINUTE, @pay_min, SYSDATETIME()) < session_expires_at
--                                          THEN DATEADD(MINUTE, @pay_min, SYSDATETIME()) ELSE session_expires_at END
--         WHERE booking_id = @booking_id;
--         EXEC sp_RecalcBooking @booking_id;
--         COMMIT;
--     END TRY
--     BEGIN CATCH
--         IF @@TRANCOUNT > 0 ROLLBACK;
--         IF ERROR_NUMBER() IN (2601, 2627) THROW 50017, N'Có ghế vừa được người khác giữ hoặc đặt.', 1;
--         THROW;
--     END CATCH
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_QueueShowtimeReminders]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- Job: Showtime Reminder Email (chạy định kỳ, vd mỗi 15 phút)
-- CREATE PROCEDURE [dbo].[sp_QueueShowtimeReminders] @hours_before INT = 3 AS
-- BEGIN
--     SET NOCOUNT ON;
--     INSERT INTO EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id)
--     SELECT b.customer_id, 'ShowtimeReminder', N'Nhắc lịch xem phim', N'Suất chiếu của bạn sắp bắt đầu.',
--            s.showtime_id, s.movie_id, b.booking_id
--     FROM Booking b JOIN Showtime s ON s.showtime_id = b.showtime_id
--     WHERE b.status = 'Paid' AND b.customer_id IS NOT NULL AND s.status = 'Scheduled'
--       AND s.start_time BETWEEN SYSDATETIME() AND DATEADD(HOUR, @hours_before, SYSDATETIME())
--       AND NOT EXISTS (SELECT 1 FROM EmailNotification e WHERE e.booking_id = b.booking_id AND e.notif_type = 'ShowtimeReminder');
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_RecalcBooking]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- Tính lại tổng tiền booking
-- CREATE PROCEDURE [dbo].[sp_RecalcBooking] @booking_id INT AS
-- BEGIN
--     SET NOCOUNT ON;
--     UPDATE b SET
--         ticket_total = ISNULL((SELECT SUM(t.price) FROM Ticket t
--                                WHERE t.booking_id = b.booking_id AND t.status IN ('Held','Booked','Used')), 0),
--         combo_total  = ISNULL((SELECT SUM(bc.quantity * bc.unit_price) FROM BookingCombo bc
--                                WHERE bc.booking_id = b.booking_id), 0)
--     FROM Booking b WHERE b.booking_id = @booking_id;
-- 
--     UPDATE Booking SET total_amount =
--         CASE WHEN ticket_total + combo_total - voucher_discount - points_discount < 0 THEN 0
--              ELSE ticket_total + combo_total - voucher_discount - points_discount END
--     WHERE booking_id = @booking_id;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_RegisterAccount]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Register Account (Guest -> Customer)
-- CREATE PROCEDURE [dbo].[sp_RegisterAccount]
--     @full_name NVARCHAR(100), @email VARCHAR(100), @phone VARCHAR(15), @password_hash VARCHAR(255)
-- AS
-- BEGIN
--     SET NOCOUNT ON; SET XACT_ABORT ON;
--     IF EXISTS (SELECT 1 FROM Account WHERE email = @email) THROW 50001, N'Email đã được đăng ký.', 1;
--     BEGIN TRAN;
--     INSERT INTO Account(role_id, full_name, email, phone, password_hash)
--     VALUES ((SELECT role_id FROM AppRole WHERE role_name = N'Customer'), @full_name, @email, @phone, @password_hash);
--     INSERT INTO Customer(customer_id) VALUES (SCOPE_IDENTITY());
--     COMMIT;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_ReleaseExpiredHolds]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- Job: nhả ghế / hủy booking hết hạn (15 phút phiên đặt, 5 phút thanh toán)
-- CREATE PROCEDURE [dbo].[sp_ReleaseExpiredHolds] AS
-- BEGIN
--     SET NOCOUNT ON;
--     DECLARE @now DATETIME2 = SYSDATETIME();
--     UPDATE t SET t.status = 'Expired'
--     FROM Ticket t JOIN Booking b ON b.booking_id = t.booking_id
--     WHERE t.status = 'Held' AND b.status = 'PendingPayment' AND b.payment_expires_at < @now;
--     UPDATE Booking SET status = 'Expired' WHERE status = 'PendingPayment' AND payment_expires_at < @now;
--     UPDATE Booking SET status = 'Expired' WHERE status = 'Selecting' AND session_expires_at < @now;
-- END
-- GO
-- /****** Object:  StoredProcedure [dbo].[sp_SearchMovies]    Script Date: 21/10/2026 4:16:23 CH ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- 
-- -- UC: Search Movies (không cần đăng nhập)
-- CREATE PROCEDURE [dbo].[sp_SearchMovies]
--     @keyword NVARCHAR(200) = NULL, @genre_id INT = NULL, @cinema_id INT = NULL, @show_date DATE = NULL
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     SELECT DISTINCT d.*
--     FROM vw_MovieDetail d
--     WHERE d.status <> 'Stopped'
--       AND (@keyword IS NULL OR d.title LIKE N'%' + @keyword + N'%' OR d.original_title LIKE N'%' + @keyword + N'%')
--       AND (@genre_id IS NULL OR EXISTS (SELECT 1 FROM MovieGenre mg WHERE mg.movie_id = d.movie_id AND mg.genre_id = @genre_id))
--       AND ((@cinema_id IS NULL AND @show_date IS NULL) OR EXISTS (
--             SELECT 1 FROM Showtime s JOIN Room r ON r.room_id = s.room_id
--             WHERE s.movie_id = d.movie_id AND s.status = 'Scheduled'
--               AND (@cinema_id IS NULL OR r.cinema_id = @cinema_id)
--               AND (@show_date IS NULL OR s.show_date = @show_date)));
-- END
-- GO
-- 
-- /*
-- ===============================================================================
-- COMPATIBILITY LAYER FOR MOVIE/SHOWTIME JAVA DAO
-- Giu nguyen cac CREATE TABLE / VIEW / INDEX goc o phia tren. Cac lenh ALTER,
-- CREATE OR ALTER ben duoi la lop tuong thich, khong thay the/xoa lich su schema.
-- Chi chay sau khi toan bo schema goc va du lieu seed da tao thanh cong.
-- ===============================================================================
-- */
-- 
-- /* MovieDAO requires a trailer-file column in addition to the original schema. */
-- IF COL_LENGTH(N'dbo.Movie', N'trailer_file') IS NULL
-- BEGIN
--     ALTER TABLE dbo.Movie ADD trailer_file VARCHAR(500) NULL;
-- END
-- GO
-- 
-- /* ShowtimeDAO works with the legacy room-name/start/price contract. Keep the
--    normalized columns because bookings, seat maps and pricing procedures use them. */
-- IF COL_LENGTH(N'dbo.Showtime', N'room_name') IS NULL
--     ALTER TABLE dbo.Showtime ADD room_name NVARCHAR(50) NULL;
-- IF COL_LENGTH(N'dbo.Showtime', N'starts_at') IS NULL
--     ALTER TABLE dbo.Showtime ADD starts_at DATETIME2(7) NULL;
-- IF COL_LENGTH(N'dbo.Showtime', N'ticket_price') IS NULL
--     ALTER TABLE dbo.Showtime ADD ticket_price DECIMAL(10,2) NULL;
-- GO
-- 
-- /* The legacy table has a persisted show_date computed from start_time, so its
--    normalized columns remain NOT NULL. Safe placeholders satisfy old constraints
--    until the synchronization trigger maps the DAO-facing values. */
-- IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'dbo.Seq_ShowtimeCompatibilityPlaceholder'))
--     EXEC(N'CREATE SEQUENCE dbo.Seq_ShowtimeCompatibilityPlaceholder AS BIGINT START WITH 1 INCREMENT BY 1;');
-- IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
--                WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_RoomId_Compatibility')
--     ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_RoomId_Compatibility DEFAULT (1) FOR room_id;
-- IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
--                WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_SlotId_Compatibility')
--     ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_SlotId_Compatibility DEFAULT (1) FOR slot_id;
-- IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
--                WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_StartTime_Compatibility')
--     ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_StartTime_Compatibility
--         DEFAULT (DATEADD(MICROSECOND, CONVERT(INT, NEXT VALUE FOR dbo.Seq_ShowtimeCompatibilityPlaceholder),
--                          CONVERT(DATETIME2(7), '20000101'))) FOR start_time;
-- IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
--                WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_EndTime_Compatibility')
--     ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_EndTime_Compatibility
--         DEFAULT (CONVERT(DATETIME2(7), '20000101')) FOR end_time;
-- GO
-- 
-- /* Preserve the original unique-index command above; replace its runtime
--    constraint with a named equivalent used by the compatibility columns. */
-- DECLARE @showtimeUniqueIndex SYSNAME;
-- SELECT TOP (1) @showtimeUniqueIndex = i.name
-- FROM sys.indexes i
-- WHERE i.object_id = OBJECT_ID(N'dbo.Showtime')
--   AND i.is_unique = 1
--   AND i.is_primary_key = 0
--   AND (SELECT COUNT(*) FROM sys.index_columns ic
--        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
--          AND ic.key_ordinal > 0) = 2
--   AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
--               ON c.object_id = ic.object_id AND c.column_id = ic.column_id
--               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
--                 AND ic.key_ordinal = 1 AND c.name = N'room_id')
--   AND EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.columns c
--               ON c.object_id = ic.object_id AND c.column_id = ic.column_id
--               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
--                 AND ic.key_ordinal = 2 AND c.name = N'start_time');
-- IF @showtimeUniqueIndex IS NOT NULL
-- BEGIN
--     DECLARE @dropShowtimeIndexSql NVARCHAR(4000);
--     IF EXISTS (SELECT 1 FROM sys.key_constraints
--                WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime')
--                  AND name = @showtimeUniqueIndex)
--         SET @dropShowtimeIndexSql = N'ALTER TABLE dbo.Showtime DROP CONSTRAINT '
--             + QUOTENAME(@showtimeUniqueIndex) + N';';
--     ELSE
--         SET @dropShowtimeIndexSql = N'DROP INDEX ' + QUOTENAME(@showtimeUniqueIndex)
--             + N' ON dbo.Showtime;';
--     EXEC sys.sp_executesql @dropShowtimeIndexSql;
-- END
-- GO
-- 
-- IF NOT EXISTS (SELECT 1 FROM sys.indexes
--                WHERE object_id = OBJECT_ID(N'dbo.Showtime')
--                  AND name = N'UX_Showtime_Room_StartTime')
-- BEGIN
--     CREATE UNIQUE INDEX UX_Showtime_Room_StartTime
--         ON dbo.Showtime(room_id, start_time);
-- END
-- GO
-- 
-- /* Backfill DAO-facing values for existing normalized showtimes. Display price
--    uses the lowest seat type as a reference; booking still prices each seat using
--    fn_GetTicketPrice and the existing TicketPrice matrix. */
-- UPDATE s
-- SET s.room_name = r.room_name,
--     s.starts_at = s.start_time,
--     s.ticket_price = COALESCE(
--         dbo.fn_GetTicketPrice(s.showtime_id, (SELECT MIN(st.seat_type_id) FROM dbo.SeatType st)), 0)
-- FROM dbo.Showtime s
-- JOIN dbo.Room r ON r.room_id = s.room_id
-- WHERE s.room_name IS NULL OR s.starts_at IS NULL OR s.ticket_price IS NULL;
-- GO
-- 
-- /* Convert MovieDAO's Users.UserId into the Account.account_id required by the
--    existing Movie.created_by foreign key. */
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE OR ALTER VIEW dbo.vw_MovieDetail
-- AS
-- SELECT m.movie_id, m.title, m.original_title, m.synopsis, m.director, m.main_cast,
--        m.duration_minutes, m.spoken_language, m.country, m.age_rating, m.trailer_url,
--        m.trailer_file, m.poster_url, m.release_date, m.end_date, m.status,
--        m.created_at, m.updated_at, m.created_by, a.full_name AS created_by_name,
--        (SELECT STRING_AGG(g.genre_name, N', ')
--         FROM dbo.MovieGenre mg JOIN dbo.Genre g ON g.genre_id = mg.genre_id
--         WHERE mg.movie_id = m.movie_id) AS genres,
--        (SELECT STRING_AGG(CONVERT(VARCHAR(11), mg.genre_id), ',')
--                 WITHIN GROUP (ORDER BY mg.genre_id)
--         FROM dbo.MovieGenre mg WHERE mg.movie_id = m.movie_id) AS genre_ids,
--        (SELECT AVG(CAST(r.rating AS DECIMAL(3,2)))
--         FROM dbo.Review r WHERE r.movie_id = m.movie_id) AS avg_rating,
--        (SELECT COUNT(*) FROM dbo.Review r WHERE r.movie_id = m.movie_id) AS review_count
-- FROM dbo.Movie m
-- LEFT JOIN dbo.Account a ON a.account_id = m.created_by;
-- GO
-- 
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE OR ALTER PROCEDURE dbo.sp_SaveMovie
--     @movie_id INT,
--     @title NVARCHAR(200),
--     @original_title NVARCHAR(200),
--     @synopsis NVARCHAR(MAX),
--     @director NVARCHAR(100),
--     @main_cast NVARCHAR(500),
--     @duration_minutes INT,
--     @spoken_language NVARCHAR(50),
--     @country NVARCHAR(50),
--     @age_rating VARCHAR(5),
--     @trailer_url VARCHAR(500),
--     @poster_url VARCHAR(500),
--     @release_date DATE,
--     @end_date DATE,
--     @status VARCHAR(12),
--     @genre_ids VARCHAR(MAX),
--     @actor_user_id INT,
--     @movie_id_out INT OUTPUT,
--     @trailer_file VARCHAR(500) = NULL
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     SET XACT_ABORT ON;
-- 
--     DECLARE @account_id INT;
--     SELECT @account_id = a.account_id
--     FROM dbo.Users u
--     JOIN dbo.Account a ON a.email = u.Email
--     WHERE u.UserId = @actor_user_id;
-- 
--     IF @account_id IS NULL
--         THROW 51010, N'Không tìm thấy tài khoản Account tương ứng với người dùng đăng nhập.', 1;
--     IF @title IS NULL OR LTRIM(RTRIM(@title)) = N''
--         THROW 51011, N'Tên phim không được để trống.', 1;
--     IF @duration_minutes <= 0 OR @release_date IS NULL
--         THROW 51012, N'Thời lượng hoặc ngày khởi chiếu không hợp lệ.', 1;
--     IF @end_date IS NOT NULL AND @end_date < @release_date
--         THROW 51013, N'Ngày kết thúc không được trước ngày khởi chiếu.', 1;
--     IF @status NOT IN ('Upcoming', 'NowShowing', 'Stopped')
--         THROW 51014, N'Trạng thái phim không hợp lệ.', 1;
-- 
--     DECLARE @Genres TABLE (genre_id INT PRIMARY KEY);
--     IF NULLIF(LTRIM(RTRIM(@genre_ids)), '') IS NOT NULL
--     BEGIN
--         IF EXISTS (SELECT 1 FROM STRING_SPLIT(@genre_ids, ',')
--                    WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NULL)
--             THROW 51015, N'Danh sách thể loại không hợp lệ.', 1;
-- 
--         INSERT INTO @Genres(genre_id)
--         SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value)))
--         FROM STRING_SPLIT(@genre_ids, ',')
--         WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL;
-- 
--         IF EXISTS (SELECT 1 FROM @Genres g
--                    LEFT JOIN dbo.Genre dbGenre ON dbGenre.genre_id = g.genre_id
--                    WHERE dbGenre.genre_id IS NULL)
--             THROW 51016, N'Thể loại được chọn không tồn tại.', 1;
--     END
-- 
--     BEGIN TRANSACTION;
--     IF @movie_id IS NULL
--     BEGIN
--         INSERT INTO dbo.Movie
--             (title, original_title, synopsis, director, main_cast, duration_minutes,
--              spoken_language, country, age_rating, trailer_url, trailer_file, poster_url,
--              release_date, end_date, status, created_by)
--         VALUES
--             (@title, @original_title, @synopsis, @director, @main_cast, @duration_minutes,
--              @spoken_language, @country, @age_rating, @trailer_url, @trailer_file, @poster_url,
--              @release_date, @end_date, @status, @account_id);
--         SET @movie_id_out = CONVERT(INT, SCOPE_IDENTITY());
--     END
--     ELSE
--     BEGIN
--         UPDATE dbo.Movie
--         SET title = @title, original_title = @original_title, synopsis = @synopsis,
--             director = @director, main_cast = @main_cast, duration_minutes = @duration_minutes,
--             spoken_language = @spoken_language, country = @country, age_rating = @age_rating,
--             trailer_url = @trailer_url, trailer_file = @trailer_file, poster_url = @poster_url,
--             release_date = @release_date, end_date = @end_date, status = @status,
--             updated_at = SYSDATETIME()
--         WHERE movie_id = @movie_id;
-- 
--         IF @@ROWCOUNT = 0
--             THROW 51017, N'Không tìm thấy phim cần cập nhật.', 1;
--         SET @movie_id_out = @movie_id;
--     END
-- 
--     DELETE FROM dbo.MovieGenre WHERE movie_id = @movie_id_out;
--     INSERT INTO dbo.MovieGenre(movie_id, genre_id)
--     SELECT @movie_id_out, genre_id FROM @Genres;
--     COMMIT TRANSACTION;
-- END
-- GO
-- 
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE OR ALTER PROCEDURE dbo.sp_DeleteMovie
--     @movie_id INT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     SET XACT_ABORT ON;
-- 
--     IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id)
--         THROW 51020, N'Không tìm thấy phim cần xóa.', 1;
--     IF EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id = @movie_id)
--        OR EXISTS (SELECT 1 FROM dbo.Review WHERE movie_id = @movie_id)
--        OR EXISTS (SELECT 1 FROM dbo.EmailNotification WHERE movie_id = @movie_id)
--         THROW 51021, N'Phim đã có lịch chiếu, đánh giá hoặc thông báo nên không thể xóa.', 1;
-- 
--     DELETE FROM dbo.Movie WHERE movie_id = @movie_id;
-- END
-- GO
-- 
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE OR ALTER PROCEDURE dbo.sp_StopMovie
--     @movie_id INT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     SET XACT_ABORT ON;
-- 
--     IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id)
--         THROW 51022, N'Không tìm thấy phim cần ngừng chiếu.', 1;
-- 
--     BEGIN TRANSACTION;
--     UPDATE dbo.Movie SET status = 'Stopped', updated_at = SYSDATETIME()
--     WHERE movie_id = @movie_id;
-- 
--     UPDATE s
--     SET status = 'Cancelled'
--     FROM dbo.Showtime s
--     WHERE s.movie_id = @movie_id
--       AND s.start_time > SYSDATETIME()
--       AND s.status = 'Scheduled'
--       AND NOT EXISTS (SELECT 1 FROM dbo.Ticket t
--                       WHERE t.showtime_id = s.showtime_id
--                         AND t.status IN ('Booked', 'Used'));
--     COMMIT TRANSACTION;
-- END
-- GO
-- 
-- /* Keep the normalized Showtime columns in sync for legacy booking workflows.
--    DAO rows require an active room-name match and a configured TimeSlot. */
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- CREATE OR ALTER TRIGGER dbo.trg_Showtime_SyncDaoCompatibility
-- ON dbo.Showtime
-- AFTER INSERT, UPDATE
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--     IF NOT UPDATE(room_name) AND NOT UPDATE(starts_at)
--         RETURN;
-- 
--     IF EXISTS (
--         SELECT 1
--         FROM inserted i
--         WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL
--           AND NOT EXISTS (SELECT 1 FROM dbo.Room r
--                           WHERE r.room_name = i.room_name AND r.status = 'Active')
--     )
--         THROW 51030, N'Không tìm thấy phòng đang hoạt động với tên đã chọn.', 1;
-- 
--     IF EXISTS (
--         SELECT 1
--         FROM inserted i
--         WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL
--           AND NOT EXISTS (
--               SELECT 1 FROM dbo.TimeSlot ts
--               WHERE CONVERT(TIME(7), i.starts_at) >= ts.start_time
--                 AND (CONVERT(TIME(7), i.starts_at) < ts.end_time
--                      OR (ts.end_time < ts.start_time AND CONVERT(TIME(7), i.starts_at) >= ts.start_time))
--           )
--     )
--         THROW 51031, N'Giờ bắt đầu không nằm trong khung giờ chiếu đã cấu hình.', 1;
-- 
--     UPDATE s
--     SET s.room_id = roomChoice.room_id,
--         s.slot_id = slotChoice.slot_id,
--         s.start_time = i.starts_at,
--         s.end_time = DATEADD(MINUTE, m.duration_minutes, i.starts_at)
--     FROM dbo.Showtime s
--     JOIN inserted i ON i.showtime_id = s.showtime_id
--     JOIN dbo.Movie m ON m.movie_id = i.movie_id
--     CROSS APPLY (
--         SELECT TOP (1) r.room_id
--         FROM dbo.Room r
--         WHERE r.room_name = i.room_name AND r.status = 'Active'
--         ORDER BY r.room_id
--     ) roomChoice
--     CROSS APPLY (
--         SELECT TOP (1) ts.slot_id
--         FROM dbo.TimeSlot ts
--         WHERE CONVERT(TIME(7), i.starts_at) >= ts.start_time
--           AND (CONVERT(TIME(7), i.starts_at) < ts.end_time
--                OR (ts.end_time < ts.start_time AND CONVERT(TIME(7), i.starts_at) >= ts.start_time))
--         ORDER BY ts.start_time
--     ) slotChoice
--     WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL;
-- END
-- GO
-- 
-- USE [master]
-- GO
-- ALTER DATABASE [CinemaDB] SET  READ_WRITE 
-- GO
