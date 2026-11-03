/*
    ============================================================================
    schema.sql - cấu trúc cơ sở dữ liệu CinemaWebDB của hệ thống CineStar
    ============================================================================
    Target      : SQL Server 2019+ (verified on SQL Server 2019 Express)
    Database    : CinemaWebDB  (matches src/java/app.properties -> db.url)
    Content     : 32 tables, 26 stored procedures, 3 views, 1 trigger,
                  1 scalar function. Dữ liệu mẫu nằm ở seed.sql.

    HOW TO RUN
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -b -f 65001 -i database/drop.sql     (tùy chọn)
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -b -f 65001 -i database/schema.sql
      sqlcmd -S "tcp:localhost,1433" -U sa -P <password> -b -f 65001 -i database/seed.sql

    NOTES
      - schema.sql chỉ chạy được trên DB chưa có bảng. Nếu CinemaWebDB đã tồn tại,
        chạy drop.sql trước (drop.sql xóa toàn bộ dữ liệu, nhớ sao lưu nếu cần giữ).
      - Showtimes are flexible: each screening starts at any 15-minute mark
        between 09:00 and 23:00, ends at start + movie duration, and the next
        screening in the same room starts 15 minutes after the previous one ends.
        dbo.TimeSlot now holds three PRICE BANDS (morning / afternoon / evening);
        the band of a showtime is derived from its start time so ticket prices
        keep working through fn_GetTicketPrice.

    MỤC LỤC THEO LUỒNG (mỗi luồng: bảng -> index -> view/function -> procedure)
      Luồng  1. Tài khoản & phân quyền : AppRole, Account, Users, Customer, Permission, RolePermission
                                         sp_RegisterAccount
      Luồng  2. Quản lý phim           : Genre, Movie, MovieGenre
                                         sp_SearchMovies, sp_SaveMovie, sp_StopMovie, sp_DeleteMovie
      Luồng  3. Rạp, phòng, ghế        : Cinema, Room, SeatType, Seat
      Luồng  4. Giá vé & khuyến mãi    : TimeSlot, Holiday, TicketPrice, Combo, Voucher, MyPointConfig
                                         fn_GetTicketPrice
      Luồng  5. Lịch chiếu             : Showtime, trg_Showtime_SyncDaoCompatibility
      Luồng  6. Đặt vé & thanh toán    : Booking, Ticket, BookingCombo, Payment, VoucherUsage, MyPointTransaction
                                         vw_SeatMap, sp_RecalcBooking, sp_ReleaseExpiredHolds, sp_CreateBooking,
                                         sp_HoldSeats, sp_AddCombo, sp_ApplyVoucher, sp_ApplyMyPoint, sp_ConfirmPayment
      Luồng  7. Soát vé & đổi ghế      : TicketChangeHistory, sp_CheckInTicket, sp_ChangeSeat
      Luồng  8. Vé của tôi, hủy & hoàn : sp_ExpirePastTickets, sp_GetCustomerTickets, sp_CancelTicket, sp_CancelCombo,
                                         sp_CancelMovie
      Luồng  9. Đánh giá phim          : Review, vw_MovieDetail, sp_AddReview
      Luồng 10. Thông báo & Hộp thư    : EmailNotification, sp_QueueNewMovieEmail, sp_QueueVoucherEmail,
                                         sp_SyncInboxPromotions, sp_QueueReviewReminders, sp_QueueShowtimeReminders
      Luồng 11. Tin tức                : News
      Luồng 12. Báo cáo doanh thu      : vw_RevenueByMovie
      Luồng 13. Quản trị hệ thống      : SystemConfig, SystemLog
    ============================================================================
*/

USE master;
GO

IF DB_ID(N'CinemaWebDB') IS NULL
    CREATE DATABASE [CinemaWebDB];
GO

ALTER DATABASE [CinemaWebDB] SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE [CinemaWebDB] SET ANSI_NULLS ON;
GO

ALTER DATABASE [CinemaWebDB] SET ANSI_NULL_DEFAULT ON;
GO

ALTER DATABASE [CinemaWebDB] SET ANSI_PADDING ON;
GO

ALTER DATABASE [CinemaWebDB] SET ANSI_WARNINGS ON;
GO

ALTER DATABASE [CinemaWebDB] SET ARITHABORT ON;
GO

ALTER DATABASE [CinemaWebDB] SET CONCAT_NULL_YIELDS_NULL ON;
GO

ALTER DATABASE [CinemaWebDB] SET QUOTED_IDENTIFIER ON;
GO

ALTER DATABASE [CinemaWebDB] SET NUMERIC_ROUNDABORT OFF;
GO

ALTER DATABASE [CinemaWebDB] SET RECURSIVE_TRIGGERS ON;
GO

ALTER DATABASE [CinemaWebDB] SET AUTO_UPDATE_STATISTICS ON;
GO

ALTER DATABASE [CinemaWebDB] SET READ_WRITE;
GO

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
   LUỒNG 1. TÀI KHOẢN & PHÂN QUYỀN
   Đăng ký, đăng nhập, hồ sơ cá nhân, vai trò và quyền.
   ===================================================================== */

-- ---------- Bảng ----------
GO

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
    CONSTRAINT FK_Account_Role FOREIGN KEY (role_id) REFERENCES dbo.AppRole(role_id),
    CONSTRAINT CK_Account_Status CHECK (status IN ('Active','Locked'))
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
    IdNumber VARCHAR(20) NULL,          -- CMND/CCCD/Ho chieu
    Province NVARCHAR(100) NULL,
    District NVARCHAR(100) NULL,
    Address NVARCHAR(255) NULL,
    AvatarUrl VARCHAR(100) NULL,        -- /media/avatars/<uuid>.<ext>
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
    -- Khach tu chon nhan email phim moi / uu dai voucher; email ve, huy ve, nhac lich van luon gui
    receive_promo_email BIT NOT NULL CONSTRAINT DF_Customer_PromoEmail DEFAULT 1,
    CONSTRAINT FK_Customer_User FOREIGN KEY (customer_id) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_Customer_Points CHECK (my_point_balance >= 0),
    CONSTRAINT CK_Customer_Spent CHECK (total_spent >= 0)
);
GO

CREATE TABLE dbo.Permission (
    permission_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Permission PRIMARY KEY,
    permission_code VARCHAR(50) NOT NULL CONSTRAINT UQ_Permission_Code UNIQUE,
    description NVARCHAR(200) NULL
);
GO

CREATE TABLE dbo.RolePermission (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    CONSTRAINT PK_RolePermission PRIMARY KEY (role_id, permission_id),
    CONSTRAINT FK_RolePermission_Role FOREIGN KEY (role_id) REFERENCES dbo.AppRole(role_id),
    CONSTRAINT FK_RolePermission_Permission FOREIGN KEY (permission_id) REFERENCES dbo.Permission(permission_id)
);
GO

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   UC: Register Account (Guest -> Customer)
   Ghi c Account + Customer trong cung mot transaction. account_id sinh ra
   duoc dung lam customer_id -> FK Customer.customer_id tro ve Account.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_RegisterAccount
    @full_name NVARCHAR(100), @email VARCHAR(100), @phone VARCHAR(15), @password_hash VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF EXISTS (SELECT 1 FROM dbo.Account WHERE email = @email) THROW 50001, N'Email đã được đăng ký.', 1;
    BEGIN TRAN;
    INSERT INTO dbo.Account(role_id, full_name, email, phone, password_hash)
    VALUES ((SELECT role_id FROM dbo.AppRole WHERE role_name = N'Customer'), @full_name, @email, @phone, @password_hash);
    INSERT INTO dbo.Customer(customer_id) VALUES (SCOPE_IDENTITY());
    COMMIT;
END
GO

/* =====================================================================
   LUỒNG 2. QUẢN LÝ PHIM
   Thêm/sửa/ngừng chiếu/xóa phim, thể loại, tìm kiếm phim.
   Trang chi tiết phim đọc từ vw_MovieDetail (xem Luồng 9, vì view cần bảng Review).
   ===================================================================== */

-- ---------- Bảng ----------
GO

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
    created_by INT NULL,
    is_deleted BIT NOT NULL CONSTRAINT DF_Movie_IsDeleted DEFAULT 0,   -- xoa mem: phim da co lich su ve/doanh thu
    CONSTRAINT FK_Movie_Creator FOREIGN KEY (created_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_Movie_Duration CHECK (duration_minutes BETWEEN 1 AND 150),
    CONSTRAINT CK_Movie_Dates CHECK (end_date IS NULL OR end_date >= release_date),
    CONSTRAINT CK_Movie_Status CHECK (status IN ('Upcoming','NowShowing','Stopped')),
    CONSTRAINT CK_Movie_AgeRating CHECK (age_rating IN ('T18','T16','T13','K','P'))
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

-- ---------- Index ----------
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_Movie_Title ON dbo.Movie(title) WHERE is_deleted = 0;
GO

CREATE INDEX IX_Movie_Status_Release ON dbo.Movie(status, release_date, end_date);
GO

CREATE INDEX IX_Movie_Created ON dbo.Movie(created_at DESC, movie_id DESC);
GO

CREATE INDEX IX_MovieGenre_Genre_Movie ON dbo.MovieGenre(genre_id, movie_id);
GO

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   UC: Tim kiem phim (khong can dang nhap)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_SearchMovies
    @keyword NVARCHAR(200) = NULL, @genre_id INT = NULL, @cinema_id INT = NULL, @show_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT d.*
    FROM dbo.vw_MovieDetail d
    WHERE d.status <> 'Stopped'
      AND (@keyword IS NULL OR d.title LIKE N'%' + @keyword + N'%' OR d.original_title LIKE N'%' + @keyword + N'%')
      AND (@genre_id IS NULL OR EXISTS (SELECT 1 FROM dbo.MovieGenre mg WHERE mg.movie_id = d.movie_id AND mg.genre_id = @genre_id))
      AND ((@cinema_id IS NULL AND @show_date IS NULL) OR EXISTS (
            SELECT 1 FROM dbo.Showtime s JOIN dbo.Room r ON r.room_id = s.room_id
            WHERE s.movie_id = d.movie_id AND s.status = 'Scheduled'
              AND (@cinema_id IS NULL OR r.cinema_id = @cinema_id)
              AND (@show_date IS NULL OR s.show_date = @show_date)));
END
GO

/* ----------------------------------------------------------------------------
   QUAN LY PHIM (Manager) - dung cho MovieDAO.
   @actor_user_id la Users.UserId cua nguoi dang nhap -> resolve sang
   Account.account_id (bang nghiep vu) vi Movie.created_by tro ve Account.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_SaveMovie
    @movie_id INT = NULL,
    @title NVARCHAR(200),
    @original_title NVARCHAR(200) = NULL,
    @synopsis NVARCHAR(MAX) = NULL,
    @director NVARCHAR(100) = NULL,
    @main_cast NVARCHAR(500) = NULL,
    @duration_minutes INT,
    @spoken_language NVARCHAR(50) = NULL,
    @country NVARCHAR(50) = NULL,
    @age_rating VARCHAR(5),
    @trailer_url VARCHAR(500) = NULL,
    @poster_url VARCHAR(500) = NULL,
    @release_date DATE,
    @end_date DATE = NULL,
    @status VARCHAR(12),
    @genre_ids VARCHAR(500) = NULL,
    @actor_user_id INT = NULL,
    @movie_id_out INT OUTPUT,
    @trailer_file VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @account_id INT;
    SELECT @account_id = a.account_id
    FROM dbo.Users u
    JOIN dbo.Account a ON a.email = u.Email
    WHERE u.UserId = @actor_user_id;

    IF @account_id IS NULL
        THROW 51010, N'Không tìm thấy tài khoản Account tương ứng với người dùng đăng nhập.', 1;
    IF @title IS NULL OR LTRIM(RTRIM(@title)) = N''
        THROW 51011, N'Tên phim không được để trống.', 1;
    IF @duration_minutes <= 0 OR @release_date IS NULL
        THROW 51012, N'Thời lượng hoặc ngày khởi chiếu không hợp lệ.', 1;
    IF @end_date IS NOT NULL AND @end_date < @release_date
        THROW 51013, N'Ngày kết thúc không được trước ngày khởi chiếu.', 1;
    IF @status NOT IN ('Upcoming', 'NowShowing', 'Stopped')
        THROW 51014, N'Trạng thái phim không hợp lệ.', 1;

    DECLARE @Genres TABLE (genre_id INT PRIMARY KEY);
    IF NULLIF(LTRIM(RTRIM(@genre_ids)), '') IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM STRING_SPLIT(@genre_ids, ',')
                   WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NULL)
            THROW 51015, N'Danh sách thể loại không hợp lệ.', 1;

        INSERT INTO @Genres(genre_id)
        SELECT DISTINCT TRY_CONVERT(INT, LTRIM(RTRIM(value)))
        FROM STRING_SPLIT(@genre_ids, ',')
        WHERE TRY_CONVERT(INT, LTRIM(RTRIM(value))) IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @Genres g
                   LEFT JOIN dbo.Genre dbGenre ON dbGenre.genre_id = g.genre_id
                   WHERE dbGenre.genre_id IS NULL)
            THROW 51016, N'Thể loại được chọn không tồn tại.', 1;
    END

    BEGIN TRANSACTION;
    IF @movie_id IS NULL
    BEGIN
        INSERT INTO dbo.Movie
            (title, original_title, synopsis, director, main_cast, duration_minutes,
             spoken_language, country, age_rating, trailer_url, trailer_file, poster_url,
             release_date, end_date, status, created_by)
        VALUES
            (@title, @original_title, @synopsis, @director, @main_cast, @duration_minutes,
             @spoken_language, @country, @age_rating, @trailer_url, @trailer_file, @poster_url,
             @release_date, @end_date, @status, @account_id);
        SET @movie_id_out = CONVERT(INT, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.Movie
        SET title = @title, original_title = @original_title, synopsis = @synopsis,
            director = @director, main_cast = @main_cast, duration_minutes = @duration_minutes,
            spoken_language = @spoken_language, country = @country, age_rating = @age_rating,
            trailer_url = @trailer_url, trailer_file = @trailer_file, poster_url = @poster_url,
            release_date = @release_date, end_date = @end_date, status = @status,
            updated_at = SYSDATETIME()
        WHERE movie_id = @movie_id;

        IF @@ROWCOUNT = 0
            THROW 51017, N'Không tìm thấy phim cần cập nhật.', 1;
        SET @movie_id_out = @movie_id;
    END

    DELETE FROM dbo.MovieGenre WHERE movie_id = @movie_id_out;
    INSERT INTO dbo.MovieGenre(movie_id, genre_id)
    SELECT @movie_id_out, genre_id FROM @Genres;
    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_StopMovie @movie_id INT AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id)
        THROW 51022, N'Không tìm thấy phim cần ngừng chiếu.', 1;
    DECLARE @booked_showtimes INT = (
        SELECT COUNT(DISTINCT s.showtime_id)
        FROM dbo.Showtime s
        JOIN dbo.Ticket t ON t.showtime_id = s.showtime_id
        WHERE s.movie_id = @movie_id
          AND s.start_time > SYSDATETIME()
          AND s.status = 'Scheduled'
          AND t.status = 'Booked'
    );
    IF @booked_showtimes > 0
        THROW 50200, N'Phim còn suất chiếu đã bán vé, hãy dùng Hủy & hoàn tiền.', 1;

    BEGIN TRANSACTION;
    UPDATE dbo.Movie SET status = 'Stopped', updated_at = SYSDATETIME()
    WHERE movie_id = @movie_id;

    UPDATE s
    SET status = 'Cancelled'
    FROM dbo.Showtime s
    WHERE s.movie_id = @movie_id
      AND s.start_time > SYSDATETIME()
      AND s.status = 'Scheduled'
      AND NOT EXISTS (SELECT 1 FROM dbo.Ticket t
                      WHERE t.showtime_id = s.showtime_id
                        AND t.status IN ('Booked', 'Used'));
    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DeleteMovie @movie_id INT, @hard_deleted BIT = 0 OUTPUT AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @hard_deleted = 0;

    IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id AND is_deleted = 0)
        THROW 51020, N'Không tìm thấy phim cần xóa.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id AND status <> 'Stopped')
        THROW 51023, N'Chỉ có thể xóa phim đã ngừng chiếu.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id = @movie_id)
        THROW 51024, N'Không thể xóa phim vì vẫn còn suất chiếu hoặc vé liên quan.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id = @movie_id AND status = 'Scheduled' AND end_time > SYSDATETIME())
        THROW 51021, N'Phim còn suất chưa chiếu xong nên chưa thể xóa. Hãy dùng "Hủy & hoàn tiền" rồi xóa lại; suất đang chiếu cần đợi kết thúc.', 1;

    -- Phim vua them nham: thu hoi email bao phim moi chua gui va thong bao chi nam trong hop thu.
    DELETE FROM dbo.EmailNotification WHERE movie_id = @movie_id AND notif_type = 'NewMovie' AND status IN ('Pending','InApp');

    -- Phim da co lich su (suat chieu, ve, doanh thu, danh gia, thong bao): chi an di, khong xoa du lieu.
    IF EXISTS (SELECT 1 FROM dbo.Showtime WHERE movie_id = @movie_id)
       OR EXISTS (SELECT 1 FROM dbo.Review WHERE movie_id = @movie_id)
       OR EXISTS (SELECT 1 FROM dbo.EmailNotification WHERE movie_id = @movie_id)
        UPDATE dbo.Movie SET is_deleted = 1, status = 'Stopped', updated_at = SYSDATETIME() WHERE movie_id = @movie_id;
    ELSE
    BEGIN
        DELETE FROM dbo.Movie WHERE movie_id = @movie_id;
        SET @hard_deleted = 1;
    END
END
GO

/* =====================================================================
   LUỒNG 3. RẠP, PHÒNG, GHẾ
   Rạp, phòng chiếu, loại ghế và sơ đồ ghế (ghế đôi liên kết qua pair_seat_id).
   ===================================================================== */

-- ---------- Bảng ----------
GO

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
    room_type VARCHAR(20) NULL CONSTRAINT DF_Room_Type DEFAULT '2D',
    capacity INT NOT NULL,
    status VARCHAR(12) NOT NULL CONSTRAINT DF_Room_Status DEFAULT 'Active',
    CONSTRAINT FK_Room_Cinema FOREIGN KEY (cinema_id) REFERENCES dbo.Cinema(cinema_id),
    CONSTRAINT UQ_Room_Cinema_Name UNIQUE (cinema_id, room_name),
    CONSTRAINT CK_Room_Type CHECK (room_type IN ('2D','3D','IMAX','4DX')),
    CONSTRAINT CK_Room_Status CHECK (status IN ('Active','Closed')),
    CONSTRAINT CK_Room_Capacity CHECK (capacity > 0)
);
GO

CREATE TABLE dbo.SeatType (
    seat_type_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SeatType PRIMARY KEY,
    type_name NVARCHAR(30) NOT NULL CONSTRAINT UQ_SeatType_Name UNIQUE,
    is_couple BIT NOT NULL CONSTRAINT DF_SeatType_Couple DEFAULT 0,
    description NVARCHAR(200) NULL
);
GO

CREATE TABLE dbo.Seat (
    seat_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Seat PRIMARY KEY,
    room_id INT NOT NULL,
    row_label CHAR(1) NOT NULL,
    seat_number INT NOT NULL,
    seat_type_id INT NOT NULL,
    pair_seat_id INT NULL,
    status VARCHAR(12) NOT NULL CONSTRAINT DF_Seat_Status DEFAULT 'Active',
    CONSTRAINT FK_Seat_Room FOREIGN KEY (room_id) REFERENCES dbo.Room(room_id),
    CONSTRAINT FK_Seat_Type FOREIGN KEY (seat_type_id) REFERENCES dbo.SeatType(seat_type_id),
    CONSTRAINT FK_Seat_Pair FOREIGN KEY (pair_seat_id) REFERENCES dbo.Seat(seat_id),
    CONSTRAINT UQ_Seat_Room_Row_Number UNIQUE (room_id, row_label, seat_number),
    CONSTRAINT CK_Seat_Status CHECK (status IN ('Active','Maintenance'))
);
GO

/* =====================================================================
   LUỒNG 4. GIÁ VÉ & KHUYẾN MÃI
   Khung giá, ngày lễ, bảng giá vé, combo, voucher, cấu hình MyPoint.
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.TimeSlot (
    slot_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TimeSlot PRIMARY KEY,
    slot_name NVARCHAR(30) NOT NULL CONSTRAINT UQ_TimeSlot_Name UNIQUE,
    start_time TIME(7) NOT NULL,
    end_time TIME(7) NOT NULL,
    CONSTRAINT UQ_TimeSlot_Start UNIQUE (start_time)
);
GO

CREATE TABLE dbo.Holiday (
    holiday_date DATE NOT NULL CONSTRAINT PK_Holiday PRIMARY KEY,
    holiday_name NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.TicketPrice (
    price_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TicketPrice PRIMARY KEY,
    seat_type_id INT NOT NULL,
    slot_id INT NOT NULL,
    day_type VARCHAR(10) NOT NULL,
    price DECIMAL(10,0) NOT NULL,
    CONSTRAINT FK_TicketPrice_SeatType FOREIGN KEY (seat_type_id) REFERENCES dbo.SeatType(seat_type_id),
    CONSTRAINT FK_TicketPrice_Slot FOREIGN KEY (slot_id) REFERENCES dbo.TimeSlot(slot_id),
    CONSTRAINT UQ_TicketPrice UNIQUE (seat_type_id, slot_id, day_type),
    CONSTRAINT CK_TicketPrice_DayType CHECK (day_type IN ('Weekday','Weekend','Holiday')),
    CONSTRAINT CK_TicketPrice_Price CHECK (price >= 0)
);
GO

CREATE TABLE dbo.Combo (
    combo_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Combo PRIMARY KEY,
    combo_name NVARCHAR(100) NOT NULL,
    description NVARCHAR(300) NULL,
    price DECIMAL(10,0) NOT NULL,
    stock INT NOT NULL CONSTRAINT DF_Combo_Stock DEFAULT 0,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_Combo_Status DEFAULT 'Active',
    CONSTRAINT CK_Combo_Price CHECK (price >= 0),
    CONSTRAINT CK_Combo_Stock CHECK (stock >= 0),
    CONSTRAINT CK_Combo_Status CHECK (status IN ('Active','Hidden'))
);
GO

CREATE TABLE dbo.Voucher (
    voucher_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Voucher PRIMARY KEY,
    code VARCHAR(30) NOT NULL CONSTRAINT UQ_Voucher_Code UNIQUE,
    description NVARCHAR(200) NULL,
    discount_type VARCHAR(10) NOT NULL,
    discount_value DECIMAL(12,2) NOT NULL,
    max_discount DECIMAL(12,0) NULL,
    min_order_amount DECIMAL(12,0) NOT NULL CONSTRAINT DF_Voucher_MinOrder DEFAULT 0,
    min_cumulative_spending DECIMAL(14,0) NOT NULL CONSTRAINT DF_Voucher_MinSpent DEFAULT 0,
    usage_limit INT NOT NULL,
    used_count INT NOT NULL CONSTRAINT DF_Voucher_Used DEFAULT 0,
    per_customer_limit INT NOT NULL CONSTRAINT DF_Voucher_PerCustomer DEFAULT 1,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_Voucher_Status DEFAULT 'Allowed',
    created_by INT NULL,
    CONSTRAINT FK_Voucher_Creator FOREIGN KEY (created_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_Voucher_Dates CHECK (valid_to >= valid_from),
    CONSTRAINT CK_Voucher_Type CHECK (discount_type IN ('Percent','Amount')),
    CONSTRAINT CK_Voucher_Value CHECK (discount_value > 0),
    CONSTRAINT CK_Voucher_Status CHECK (status IN ('Allowed','Used','Expired','Disabled')),
    CONSTRAINT CK_Voucher_Limit CHECK (usage_limit > 0)
);
GO

CREATE TABLE dbo.MyPointConfig (
    config_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MyPointConfig PRIMARY KEY,
    earn_rate_percent DECIMAL(5,2) NOT NULL,
    point_value_vnd INT NOT NULL,
    max_redeem_percent DECIMAL(5,2) NOT NULL,
    effective_from DATE NOT NULL,
    is_active BIT NOT NULL CONSTRAINT DF_MyPointConfig_Active DEFAULT 1,
    updated_by INT NULL,
    CONSTRAINT FK_MyPointConfig_Updater FOREIGN KEY (updated_by) REFERENCES dbo.Account(account_id)
);
GO

-- ---------- Function ----------
GO

-- Gia ve theo loai ghe + khung gio + loai ngay (thuong / cuoi tuan / le)
CREATE FUNCTION dbo.fn_GetTicketPrice(@showtime_id INT, @seat_type_id INT) RETURNS DECIMAL(10,0) AS
BEGIN
    DECLARE @slot INT, @d DATE, @day_type VARCHAR(10), @price DECIMAL(10,0);
    SELECT @slot = slot_id, @d = show_date FROM dbo.Showtime WHERE showtime_id = @showtime_id;
    SET @day_type = CASE WHEN EXISTS (SELECT 1 FROM dbo.Holiday WHERE holiday_date = @d) THEN 'Holiday'
                         WHEN DATEDIFF(DAY, '19000107', @d) % 7 IN (0, 6) THEN 'Weekend'   -- CN, T7
                         ELSE 'Weekday' END;
    SELECT @price = price FROM dbo.TicketPrice WHERE seat_type_id = @seat_type_id AND slot_id = @slot AND day_type = @day_type;
    RETURN @price;
END
GO

/* =====================================================================
   LUỒNG 5. LỊCH CHIẾU
   ShowtimeDAO ghi bằng room_name + starts_at; trigger quy chuyển về room_id / slot_id /
   start_time / end_time chuẩn hóa. Giờ bắt đầu tự do trong ngày; slot_id chỉ là khung giá
   suy ra từ giờ bắt đầu.
   ===================================================================== */

-- ---------- Bảng ----------
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
    -- Cot tuong thich cho ShowtimeDAO (ten phong / gio bat dau / gia ve)
    room_name NVARCHAR(50) NULL,
    starts_at DATETIME2(7) NULL,
    ticket_price DECIMAL(10,2) NULL,
    CONSTRAINT FK_Showtime_Movie FOREIGN KEY (movie_id) REFERENCES dbo.Movie(movie_id),
    CONSTRAINT FK_Showtime_Room FOREIGN KEY (room_id) REFERENCES dbo.Room(room_id),
    CONSTRAINT FK_Showtime_Slot FOREIGN KEY (slot_id) REFERENCES dbo.TimeSlot(slot_id),
    CONSTRAINT FK_Showtime_Creator FOREIGN KEY (created_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_Showtime_Times CHECK (end_time > start_time),
    CONSTRAINT CK_Showtime_Status CHECK (status IN ('Scheduled','Cancelled','Finished'))
);
-- Mỗi phòng chỉ có một suất bắt đầu tại một thời điểm, KHÔNG tính suất đã huỷ (để dùng lại giờ trống sau khi huỷ / ngừng chiếu).
CREATE UNIQUE INDEX UQ_Showtime_Room_Start ON dbo.Showtime(room_id, start_time) WHERE status <> 'Cancelled';
GO

-- ---------- Index ----------
GO

CREATE INDEX IX_Showtime_Date_Status ON dbo.Showtime(show_date, status, starts_at);
GO

CREATE INDEX IX_Showtime_Movie ON dbo.Showtime(movie_id, starts_at);
GO

CREATE INDEX IX_Showtime_Room_Date ON dbo.Showtime(room_id, show_date, starts_at);
GO

-- ---------- Giá trị mặc định tương thích & trigger ----------
GO

/* Mac dinh tuong thich: cho phep chen Showtime chi can movie_id + room_name +
   starts_at (bo trong room_id / slot_id / start_time / end_time). */
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE object_id = OBJECT_ID(N'dbo.Seq_ShowtimeCompatibilityPlaceholder'))
    EXEC(N'CREATE SEQUENCE dbo.Seq_ShowtimeCompatibilityPlaceholder AS BIGINT START WITH 1 INCREMENT BY 1;');
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
               WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_RoomId_Compatibility')
    ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_RoomId_Compatibility DEFAULT (1) FOR room_id;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
               WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_SlotId_Compatibility')
    ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_SlotId_Compatibility DEFAULT (1) FOR slot_id;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
               WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_StartTime_Compatibility')
    ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_StartTime_Compatibility
        DEFAULT (DATEADD(MICROSECOND, CONVERT(INT, NEXT VALUE FOR dbo.Seq_ShowtimeCompatibilityPlaceholder),
                         CONVERT(DATETIME2(7), '20000101'))) FOR start_time;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints
               WHERE parent_object_id = OBJECT_ID(N'dbo.Showtime') AND name = N'DF_Showtime_EndTime_Compatibility')
    ALTER TABLE dbo.Showtime ADD CONSTRAINT DF_Showtime_EndTime_Compatibility
        DEFAULT (CONVERT(DATETIME2(7), '20000102')) FOR end_time;
GO

CREATE OR ALTER TRIGGER dbo.trg_Showtime_SyncDaoCompatibility
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

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM dbo.TimeSlot ts
              WHERE CONVERT(TIME(7), i.starts_at) >= ts.start_time
                AND (CONVERT(TIME(7), i.starts_at) < ts.end_time
                     OR (ts.end_time < ts.start_time AND CONVERT(TIME(7), i.starts_at) >= ts.start_time))
          )
    )
        THROW 51031, N'Giờ bắt đầu không thuộc khung giá nào đã cấu hình.', 1;

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
    CROSS APPLY (
        SELECT TOP (1) ts.slot_id
        FROM dbo.TimeSlot ts
        WHERE CONVERT(TIME(7), i.starts_at) >= ts.start_time
          AND (CONVERT(TIME(7), i.starts_at) < ts.end_time
               OR (ts.end_time < ts.start_time AND CONVERT(TIME(7), i.starts_at) >= ts.start_time))
        ORDER BY ts.start_time
    ) slotChoice
    WHERE i.room_name IS NOT NULL AND i.starts_at IS NOT NULL;
END
GO

/* =====================================================================
   LUỒNG 6. ĐẶT VÉ & THANH TOÁN
   Chọn suất -> giữ ghế -> combo -> voucher/MyPoint -> thanh toán -> xuất vé.
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.Booking (
    booking_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Booking PRIMARY KEY,
    booking_code VARCHAR(20) NOT NULL CONSTRAINT UQ_Booking_Code UNIQUE,
    customer_id INT NULL,
    staff_id INT NULL,
    showtime_id INT NOT NULL,
    channel VARCHAR(10) NOT NULL CONSTRAINT DF_Booking_Channel DEFAULT 'Online',
    status VARCHAR(15) NOT NULL CONSTRAINT DF_Booking_Status DEFAULT 'Selecting',
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Booking_Created DEFAULT SYSDATETIME(),
    session_expires_at DATETIME2(7) NOT NULL,
    payment_expires_at DATETIME2(7) NULL,
    ticket_total DECIMAL(12,0) NOT NULL CONSTRAINT DF_Booking_TicketTotal DEFAULT 0,
    combo_total DECIMAL(12,0) NOT NULL CONSTRAINT DF_Booking_ComboTotal DEFAULT 0,
    voucher_id INT NULL,
    voucher_discount DECIMAL(12,0) NOT NULL CONSTRAINT DF_Booking_VoucherDiscount DEFAULT 0,
    points_used INT NOT NULL CONSTRAINT DF_Booking_PointsUsed DEFAULT 0,
    points_discount DECIMAL(12,0) NOT NULL CONSTRAINT DF_Booking_PointsDiscount DEFAULT 0,
    total_amount DECIMAL(12,0) NOT NULL CONSTRAINT DF_Booking_Total DEFAULT 0,
    paid_at DATETIME2(7) NULL,
    CONSTRAINT FK_Booking_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_Booking_Staff FOREIGN KEY (staff_id) REFERENCES dbo.Account(account_id),
    CONSTRAINT FK_Booking_Showtime FOREIGN KEY (showtime_id) REFERENCES dbo.Showtime(showtime_id),
    CONSTRAINT FK_Booking_Voucher FOREIGN KEY (voucher_id) REFERENCES dbo.Voucher(voucher_id),
    CONSTRAINT CK_Booking_Channel CHECK (channel IN ('Online','Counter')),
    CONSTRAINT CK_Booking_Status CHECK (status IN ('Selecting','PendingPayment','Paid','Cancelled','Expired'))
);
GO

CREATE TABLE dbo.Ticket (
    ticket_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Ticket PRIMARY KEY,
    booking_id INT NOT NULL,
    showtime_id INT NOT NULL,
    seat_id INT NOT NULL,
    price DECIMAL(10,0) NOT NULL,
    ticket_code VARCHAR(30) NOT NULL CONSTRAINT UQ_Ticket_Code UNIQUE,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_Ticket_Status DEFAULT 'Held',
    checked_in_at DATETIME2(7) NULL,
    checked_in_by INT NULL,
    CONSTRAINT FK_Ticket_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT FK_Ticket_Showtime FOREIGN KEY (showtime_id) REFERENCES dbo.Showtime(showtime_id),
    CONSTRAINT FK_Ticket_Seat FOREIGN KEY (seat_id) REFERENCES dbo.Seat(seat_id),
    CONSTRAINT FK_Ticket_CheckedInBy FOREIGN KEY (checked_in_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_Ticket_Status CHECK (status IN ('Held','Booked','Used','Cancelled','Expired'))
);
GO

CREATE TABLE dbo.BookingCombo (
    booking_id INT NOT NULL,
    combo_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,0) NOT NULL,
    cancelled_at DATETIME2(7) NULL,   -- da huy thi tra lai ton kho; combo_total cua don giu nguyen de ty le hoan tien khong doi
    CONSTRAINT PK_BookingCombo PRIMARY KEY (booking_id, combo_id),
    CONSTRAINT FK_BookingCombo_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT FK_BookingCombo_Combo FOREIGN KEY (combo_id) REFERENCES dbo.Combo(combo_id),
    CONSTRAINT CK_BookingCombo_Qty CHECK (quantity > 0)
);
GO

CREATE TABLE dbo.Payment (
    payment_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Payment PRIMARY KEY,
    booking_id INT NOT NULL,
    method VARCHAR(15) NOT NULL,
    amount DECIMAL(12,0) NOT NULL,
    refunded_amount DECIMAL(12,0) NOT NULL CONSTRAINT DF_Payment_Refunded DEFAULT 0,
    gateway_txn_id VARCHAR(100) NULL,
    status VARCHAR(10) NOT NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Payment_Created DEFAULT SYSDATETIME(),
    paid_at DATETIME2(7) NULL,
    CONSTRAINT FK_Payment_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT CK_Payment_Method CHECK (method IN ('Cash','BankTransfer')),
    CONSTRAINT CK_Payment_Status CHECK (status IN ('Pending','Success','Failed','Refunded'))
);
GO

CREATE TABLE dbo.VoucherUsage (
    voucher_id INT NOT NULL,
    booking_id INT NOT NULL,
    customer_id INT NOT NULL,
    used_at DATETIME2(7) NOT NULL CONSTRAINT DF_VoucherUsage_Used DEFAULT SYSDATETIME(),
    CONSTRAINT PK_VoucherUsage PRIMARY KEY (voucher_id, booking_id),
    CONSTRAINT FK_VoucherUsage_Voucher FOREIGN KEY (voucher_id) REFERENCES dbo.Voucher(voucher_id),
    CONSTRAINT FK_VoucherUsage_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT FK_VoucherUsage_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id)
);
GO

CREATE TABLE dbo.MyPointTransaction (
    txn_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MyPointTransaction PRIMARY KEY,
    customer_id INT NOT NULL,
    booking_id INT NULL,
    txn_type VARCHAR(10) NOT NULL,
    points INT NOT NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_MyPointTransaction_Created DEFAULT SYSDATETIME(),
    CONSTRAINT FK_MyPointTransaction_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_MyPointTransaction_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT CK_MyPointTransaction_Type CHECK (txn_type IN ('Earn','Redeem','Adjust'))
);
GO

-- ---------- Index ----------
GO

CREATE UNIQUE NONCLUSTERED INDEX ux_Ticket_ActiveSeat ON dbo.Ticket(showtime_id, seat_id)
    WHERE status IN ('Held', 'Booked', 'Used');
GO

CREATE NONCLUSTERED INDEX IX_Booking_Customer_Status ON dbo.Booking(customer_id, status)
    INCLUDE (booking_id, booking_code, showtime_id, total_amount, created_at);
GO

CREATE NONCLUSTERED INDEX IX_Booking_Showtime_Status ON dbo.Booking(showtime_id, status);
GO

CREATE NONCLUSTERED INDEX IX_Booking_Expiry ON dbo.Booking(payment_expires_at)
    WHERE status = 'PendingPayment';
GO

CREATE NONCLUSTERED INDEX IX_Ticket_Booking_Status ON dbo.Ticket(booking_id, status)
    INCLUDE (seat_id, ticket_code, price);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Payment_GatewayTxn ON dbo.Payment(gateway_txn_id)
    WHERE gateway_txn_id IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_MyPointTxn_Customer ON dbo.MyPointTransaction(customer_id, created_at DESC);
GO

-- ---------- View ----------
GO

CREATE VIEW dbo.vw_SeatMap AS
SELECT st.showtime_id, s.seat_id, s.row_label, s.seat_number, sty.type_name AS seat_type, s.pair_seat_id,
       CASE WHEN s.status = 'Maintenance'                                            THEN 'GREY'
            WHEN x.status IN ('Booked','Used')                                       THEN 'RED'
            WHEN x.status = 'Held' AND x.payment_expires_at > SYSDATETIME()          THEN 'YELLOW'
            ELSE 'GREEN' END AS color
FROM dbo.Showtime st
JOIN dbo.Seat s       ON s.room_id = st.room_id
JOIN dbo.SeatType sty ON sty.seat_type_id = s.seat_type_id
OUTER APPLY (SELECT TOP 1 t.status, b.payment_expires_at
             FROM dbo.Ticket t JOIN dbo.Booking b ON b.booking_id = t.booking_id
             WHERE t.showtime_id = st.showtime_id AND t.seat_id = s.seat_id
               AND t.status IN ('Held','Booked','Used')
             ORDER BY t.ticket_id DESC) x;
GO

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   Job: tinh lai tong tien booking
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_RecalcBooking @booking_id INT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b SET
        ticket_total = ISNULL((SELECT SUM(t.price) FROM dbo.Ticket t
                               WHERE t.booking_id = b.booking_id AND t.status IN ('Held','Booked','Used')), 0),
        combo_total  = ISNULL((SELECT SUM(bc.quantity * bc.unit_price) FROM dbo.BookingCombo bc
                               WHERE bc.booking_id = b.booking_id), 0)
    FROM dbo.Booking b WHERE b.booking_id = @booking_id;

    UPDATE dbo.Booking SET total_amount =
        CASE WHEN ticket_total + combo_total - voucher_discount - points_discount < 0 THEN 0
             ELSE ticket_total + combo_total - voucher_discount - points_discount END
    WHERE booking_id = @booking_id;
END
GO

/* ----------------------------------------------------------------------------
   Job: nha ghe / huy booking het han (15 phut phien dat, 5 phut thanh toan)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ReleaseExpiredHolds AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @now DATETIME2 = SYSDATETIME();
    UPDATE t SET t.status = 'Expired'
    FROM dbo.Ticket t JOIN dbo.Booking b ON b.booking_id = t.booking_id
    WHERE t.status = 'Held' AND b.status = 'PendingPayment' AND b.payment_expires_at < @now;
    UPDATE dbo.Booking SET status = 'Expired' WHERE status = 'PendingPayment' AND payment_expires_at < @now;
    UPDATE dbo.Booking SET status = 'Expired' WHERE status = 'Selecting' AND session_expires_at < @now;
END
GO

/* ----------------------------------------------------------------------------
   UC: Book Movie Tickets (buoc 1 - mo phien dat ve) / Counter Ticket Sales
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CreateBooking
    @customer_id INT = NULL, @staff_id INT = NULL, @showtime_id INT, @channel VARCHAR(10) = 'Online',
    @booking_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @session_min INT = (SELECT CAST(config_value AS INT) FROM dbo.SystemConfig WHERE config_key = 'BOOKING_SESSION_MINUTES');
    IF NOT EXISTS (SELECT 1 FROM dbo.Showtime s JOIN dbo.Movie m ON m.movie_id = s.movie_id
                   WHERE s.showtime_id = @showtime_id AND s.status = 'Scheduled'
                     AND s.start_time > SYSDATETIME() AND m.status <> 'Stopped')
        THROW 50002, N'Suất chiếu không tồn tại, đã bắt đầu hoặc đã bị hủy.', 1;
    IF @customer_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Account WHERE account_id = @customer_id AND status = 'Active')
        THROW 50003, N'Tài khoản không hợp lệ hoặc đã bị khóa.', 1;

    INSERT INTO dbo.Booking(booking_code, customer_id, staff_id, showtime_id, channel, session_expires_at)
    VALUES ('BK' + UPPER(LEFT(REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', ''), 10)),
            @customer_id, @staff_id, @showtime_id, @channel, DATEADD(MINUTE, @session_min, SYSDATETIME()));
    SET @booking_id = SCOPE_IDENTITY();
END
GO

/* ----------------------------------------------------------------------------
   UC: Select Seats (giu ghe)
   @seat_ids dang '41,42'. Ghe doi phai chon ca cap, ghe bao tri khong duoc chon.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_HoldSeats @booking_id INT, @seat_ids NVARCHAR(MAX) AS
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

/* ----------------------------------------------------------------------------
   UC: Order Popcorn & Drink Combos (@quantity = 0 de bo combo)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_AddCombo @booking_id INT, @combo_id INT, @quantity INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @status VARCHAR(15) = (SELECT status FROM dbo.Booking WHERE booking_id = @booking_id);
    IF @status IS NULL OR @status NOT IN ('Selecting','PendingPayment') THROW 50020, N'Booking không còn hiệu lực.', 1;
    IF @quantity <= 0
        DELETE FROM dbo.BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id;
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE combo_id = @combo_id AND status = 'Active' AND stock >= @quantity)
            THROW 50021, N'Combo không tồn tại hoặc không đủ số lượng.', 1;
        IF EXISTS (SELECT 1 FROM dbo.BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id)
            UPDATE dbo.BookingCombo SET quantity = @quantity WHERE booking_id = @booking_id AND combo_id = @combo_id;
        ELSE
            INSERT INTO dbo.BookingCombo(booking_id, combo_id, quantity, unit_price)
            SELECT @booking_id, combo_id, @quantity, price FROM dbo.Combo WHERE combo_id = @combo_id;
    END
    EXEC dbo.sp_RecalcBooking @booking_id;
END
GO

/* ----------------------------------------------------------------------------
   UC: Apply Cinema Voucher (ap voucher truoc, sau do moi ap MyPoint)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ApplyVoucher @booking_id INT, @code VARCHAR(30) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @customer_id INT, @status VARCHAR(15), @subtotal DECIMAL(12,0);
    DECLARE @vid INT, @type VARCHAR(10), @val DECIMAL(12,2), @maxd DECIMAL(12,0), @min_order DECIMAL(12,0),
            @min_spent DECIMAL(14,0), @limit INT, @used INT, @per INT, @vstatus VARCHAR(10), @from DATE, @to DATE,
            @disc DECIMAL(12,0);

    SELECT @customer_id = customer_id, @status = status, @subtotal = ticket_total + combo_total
    FROM dbo.Booking WHERE booking_id = @booking_id;
    IF @status IS NULL OR @status <> 'PendingPayment' THROW 50030, N'Chỉ áp voucher ở bước thanh toán (sau khi giữ ghế).', 1;
    IF @customer_id IS NULL THROW 50031, N'Khách mua tại quầy không dùng voucher online.', 1;

    SELECT @vid = voucher_id, @type = discount_type, @val = discount_value, @maxd = max_discount,
           @min_order = min_order_amount, @min_spent = min_cumulative_spending, @limit = usage_limit,
           @used = used_count, @per = per_customer_limit, @vstatus = status, @from = valid_from, @to = valid_to
    FROM dbo.Voucher WHERE code = @code;

    IF @vid IS NULL THROW 50032, N'Mã voucher không tồn tại.', 1;
    IF @vstatus <> 'Allowed' THROW 50033, N'Voucher không còn ở trạng thái cho phép sử dụng.', 1;
    IF CAST(SYSDATETIME() AS DATE) NOT BETWEEN @from AND @to THROW 50034, N'Voucher chưa đến hoặc đã quá hạn.', 1;
    IF @used >= @limit THROW 50035, N'Voucher đã hết lượt sử dụng.', 1;
    IF (SELECT total_spent FROM dbo.Customer WHERE customer_id = @customer_id) < @min_spent
        THROW 50036, N'Chi tiêu tích lũy chưa đạt mức tối thiểu để dùng voucher.', 1;
    IF @subtotal < @min_order THROW 50037, N'Giá trị đơn hàng chưa đạt mức tối thiểu của voucher.', 1;
    IF (SELECT COUNT(*) FROM dbo.VoucherUsage WHERE voucher_id = @vid AND customer_id = @customer_id) >= @per
        THROW 50038, N'Bạn đã dùng hết số lần cho phép của voucher này.', 1;

    SET @disc = CASE @type WHEN 'Percent' THEN @subtotal * @val / 100 ELSE @val END;
    IF @maxd IS NOT NULL AND @disc > @maxd SET @disc = @maxd;
    IF @disc > @subtotal SET @disc = @subtotal;

    UPDATE dbo.Booking SET voucher_id = @vid, voucher_discount = @disc, points_used = 0, points_discount = 0
    WHERE booking_id = @booking_id;
    EXEC dbo.sp_RecalcBooking @booking_id;
END
GO

/* ----------------------------------------------------------------------------
   UC: Apply MyPoint (toi da % gia tri don hien tai)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ApplyMyPoint @booking_id INT, @points INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @customer_id INT, @status VARCHAR(15), @base DECIMAL(12,0), @pt_value INT, @max_pct DECIMAL(5,2), @disc DECIMAL(12,0);
    SELECT @customer_id = customer_id, @status = status, @base = ticket_total + combo_total - voucher_discount
    FROM dbo.Booking WHERE booking_id = @booking_id;
    SELECT TOP 1 @pt_value = point_value_vnd, @max_pct = max_redeem_percent
    FROM dbo.MyPointConfig WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC;

    IF @status IS NULL OR @status <> 'PendingPayment' THROW 50040, N'Chỉ dùng MyPoint ở bước thanh toán.', 1;
    IF @customer_id IS NULL THROW 50041, N'Khách mua tại quầy không có tài khoản MyPoint.', 1;
    IF @points < 0 THROW 50042, N'Số điểm không hợp lệ.', 1;
    IF @points > (SELECT my_point_balance FROM dbo.Customer WHERE customer_id = @customer_id)
        THROW 50043, N'Số dư MyPoint không đủ.', 1;

    SET @disc = @points * @pt_value;
    IF @disc > @base * @max_pct / 100 THROW 50044, N'Vượt quá tỷ lệ tối đa được dùng MyPoint trên giá trị đơn.', 1;

    UPDATE dbo.Booking SET points_used = @points, points_discount = @disc WHERE booking_id = @booking_id;
    EXEC dbo.sp_RecalcBooking @booking_id;
END
GO

/* ----------------------------------------------------------------------------
   UC: Payment + Confirm / Return Payment Result (Payment Gateway goi ve)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ConfirmPayment
    @booking_id INT, @gateway_txn_id VARCHAR(100) = NULL, @is_success BIT, @method VARCHAR(15) = 'BankTransfer'
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @status VARCHAR(15), @pay_exp DATETIME2, @customer_id INT, @total DECIMAL(12,0), @voucher_id INT, @points INT;
    DECLARE @earn_rate DECIMAL(5,2), @pt_value INT, @earned INT;

    SELECT @status = status, @pay_exp = payment_expires_at, @customer_id = customer_id,
           @total = total_amount, @voucher_id = voucher_id, @points = points_used
    FROM dbo.Booking WHERE booking_id = @booking_id;
    IF @status IS NULL OR @status <> 'PendingPayment'
        THROW 50050, N'Booking không ở trạng thái chờ thanh toán (có thể đã hết hạn).', 1;

    BEGIN TRAN;
    IF @is_success = 1 AND @pay_exp >= SYSDATETIME()
    BEGIN
        UPDATE dbo.Booking SET status = 'Paid', paid_at = SYSDATETIME() WHERE booking_id = @booking_id;
        UPDATE dbo.Ticket SET status = 'Booked' WHERE booking_id = @booking_id AND status = 'Held';   -- YELLOW -> RED
        INSERT INTO dbo.Payment(booking_id, method, amount, gateway_txn_id, status, paid_at)
        VALUES (@booking_id, @method, @total, @gateway_txn_id, 'Success', SYSDATETIME());

        UPDATE c SET c.stock = c.stock - bc.quantity
        FROM dbo.Combo c JOIN dbo.BookingCombo bc ON bc.combo_id = c.combo_id WHERE bc.booking_id = @booking_id;

        IF @voucher_id IS NOT NULL
        BEGIN
            INSERT INTO dbo.VoucherUsage(voucher_id, booking_id, customer_id) VALUES (@voucher_id, @booking_id, @customer_id);
            UPDATE dbo.Voucher SET used_count = used_count + 1,
                   status = CASE WHEN used_count + 1 >= usage_limit THEN 'Used' ELSE status END
            WHERE voucher_id = @voucher_id;
        END

        IF @customer_id IS NOT NULL
        BEGIN
            SELECT TOP 1 @earn_rate = earn_rate_percent, @pt_value = point_value_vnd
            FROM dbo.MyPointConfig WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC;
            SET @earned = FLOOR(@total * @earn_rate / 100.0 / @pt_value);

            IF @points > 0
                INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points) VALUES (@customer_id, @booking_id, 'Redeem', -@points);
            IF @earned > 0
                INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points) VALUES (@customer_id, @booking_id, 'Earn', @earned);

            UPDATE dbo.Customer SET my_point_balance = my_point_balance - @points + ISNULL(@earned, 0),
                                    total_spent = total_spent + @total
            WHERE customer_id = @customer_id;

            INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, booking_id)
            VALUES (@customer_id, 'ETicket', N'Vé điện tử của bạn', N'Đính kèm mã QR các vé đã đặt.', @booking_id);
        END
    END
    ELSE
    BEGIN
        UPDATE dbo.Ticket SET status = 'Cancelled' WHERE booking_id = @booking_id AND status = 'Held';   -- YELLOW -> GREEN
        UPDATE dbo.Booking SET status = CASE WHEN @is_success = 1 THEN 'Expired' ELSE 'Cancelled' END WHERE booking_id = @booking_id;
        INSERT INTO dbo.Payment(booking_id, method, amount, gateway_txn_id, status)
        VALUES (@booking_id, @method, @total, @gateway_txn_id, 'Failed');
    END
    COMMIT;
END
GO

/* =====================================================================
   LUỒNG 7. SOÁT VÉ & ĐỔI GHẾ
   Nhân viên soát vé tại rạp và đổi ghế cho khách.
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.TicketChangeHistory (
    change_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TicketChangeHistory PRIMARY KEY,
    ticket_id INT NOT NULL,
    change_type VARCHAR(15) NOT NULL,
    old_seat_id INT NULL,
    new_seat_id INT NULL,
    old_showtime_id INT NULL,
    new_showtime_id INT NULL,
    changed_by INT NULL,
    reason NVARCHAR(200) NULL,
    changed_at DATETIME2(7) NOT NULL CONSTRAINT DF_TicketChangeHistory_Changed DEFAULT SYSDATETIME(),
    CONSTRAINT FK_TCH_Ticket FOREIGN KEY (ticket_id) REFERENCES dbo.Ticket(ticket_id),
    CONSTRAINT FK_TCH_OldSeat FOREIGN KEY (old_seat_id) REFERENCES dbo.Seat(seat_id),
    CONSTRAINT FK_TCH_NewSeat FOREIGN KEY (new_seat_id) REFERENCES dbo.Seat(seat_id),
    CONSTRAINT FK_TCH_OldShowtime FOREIGN KEY (old_showtime_id) REFERENCES dbo.Showtime(showtime_id),
    CONSTRAINT FK_TCH_NewShowtime FOREIGN KEY (new_showtime_id) REFERENCES dbo.Showtime(showtime_id),
    CONSTRAINT FK_TCH_ChangedBy FOREIGN KEY (changed_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_TCH_Type CHECK (change_type IN ('Cancel','SeatChange','ExchangeShowtime'))
);
GO

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   UC: Ticket Check-in (QR Scan)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CheckInTicket @ticket_code VARCHAR(30), @staff_id INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @tid INT, @tstatus VARCHAR(10), @start DATETIME2, @end DATETIME2, @sstatus VARCHAR(10);
    DECLARE @early INT = (SELECT CAST(config_value AS INT) FROM dbo.SystemConfig WHERE config_key = 'CHECKIN_EARLY_MINUTES');
    SELECT @tid = t.ticket_id, @tstatus = t.status, @start = s.start_time, @end = s.end_time, @sstatus = s.status
    FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id WHERE t.ticket_code = @ticket_code;

    IF @tid IS NULL THROW 50060, N'Mã vé không tồn tại.', 1;
    IF @tstatus = 'Used' THROW 50061, N'Vé đã được sử dụng.', 1;
    IF @tstatus <> 'Booked' OR @sstatus = 'Cancelled' THROW 50062, N'Vé không hợp lệ.', 1;
    IF SYSDATETIME() < DATEADD(MINUTE, -@early, @start) OR SYSDATETIME() > @end
        THROW 50063, N'Ngoài thời gian cho phép vào phòng chiếu.', 1;

    -- Dieu kien status: hai may quet cung luc thi chi mot may soat duoc ve.
    UPDATE dbo.Ticket SET status = 'Used', checked_in_at = SYSDATETIME(), checked_in_by = @staff_id WHERE ticket_id = @tid AND status = 'Booked';
    IF @@ROWCOUNT = 0 THROW 50061, N'Vé đã được sử dụng.', 1;
END
GO

/* ----------------------------------------------------------------------------
   UC: Seat Change (Staff) - doi ghe trong cung suat, truoc gio chieu.
   Chi doi sang ghe cung loai nen gia ve khong doi. Ghe doi doi ca cap (ve cung don).
   Khoa theo suat de hai nhan vien thao tac cung luc khong lam sai lich su.
   Khach co tai khoan duoc bao qua hop thu va email vi ve dien tu da gui ghi ghe cu.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ChangeSeat @ticket_id INT, @new_seat_id INT, @staff_id INT, @reason NVARCHAR(200) = NULL AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    EXEC dbo.sp_ReleaseExpiredHolds;
    DECLARE @showtime_id INT = (SELECT showtime_id FROM dbo.Ticket WHERE ticket_id = @ticket_id);
    IF @showtime_id IS NULL THROW 50080, N'Chỉ đổi ghế cho vé đã thanh toán và chưa sử dụng.', 1;
    DECLARE @lock NVARCHAR(60) = CONCAT(N'seat-change-', @showtime_id);

    DECLARE @old_seat INT, @tstatus VARCHAR(10), @room INT, @booking_id INT, @customer_id INT,
            @start DATETIME2, @sstatus VARCHAR(10), @old_pair INT, @old_type INT,
            @new_room INT, @new_pair INT, @new_status VARCHAR(12), @new_type INT,
            @partner INT, @partner_status VARCHAR(10), @partner_booking INT;

    BEGIN TRY
        BEGIN TRAN;
        EXEC sp_getapplock @Resource = @lock, @LockMode = 'Exclusive', @LockOwner = 'Transaction';

        SELECT @old_seat = t.seat_id, @tstatus = t.status, @room = s.room_id, @booking_id = t.booking_id,
               @customer_id = b.customer_id, @start = s.start_time, @sstatus = s.status,
               @old_pair = sc.pair_seat_id, @old_type = sc.seat_type_id
        FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
        JOIN dbo.Booking b ON b.booking_id = t.booking_id JOIN dbo.Seat sc ON sc.seat_id = t.seat_id
        WHERE t.ticket_id = @ticket_id;
        SELECT @new_room = room_id, @new_pair = pair_seat_id, @new_status = status, @new_type = seat_type_id
        FROM dbo.Seat WHERE seat_id = @new_seat_id;

        IF @tstatus <> 'Booked' THROW 50080, N'Chỉ đổi ghế cho vé đã thanh toán và chưa sử dụng.', 1;
        IF @sstatus <> 'Scheduled' THROW 50085, N'Suất chiếu đã bị hủy nên không thể đổi ghế.', 1;
        IF @start <= SYSDATETIME() THROW 50086, N'Suất chiếu đã bắt đầu nên không thể đổi ghế.', 1;
        IF @new_room IS NULL OR @new_room <> @room THROW 50081, N'Ghế mới phải thuộc cùng phòng của suất chiếu.', 1;
        IF @new_status = 'Maintenance' THROW 50082, N'Ghế mới đang bảo trì.', 1;
        IF @new_type <> @old_type THROW 50087, N'Chỉ đổi sang ghế cùng loại để giữ nguyên giá vé.', 1;
        IF (@old_pair IS NULL AND @new_pair IS NOT NULL) OR (@old_pair IS NOT NULL AND @new_pair IS NULL)
            THROW 50083, N'Ghế đơn chỉ đổi sang ghế đơn, ghế đôi chỉ đổi sang ghế đôi.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.vw_SeatMap WHERE showtime_id = @showtime_id AND seat_id = @new_seat_id AND color = 'GREEN')
           OR (@new_pair IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.vw_SeatMap WHERE showtime_id = @showtime_id AND seat_id = @new_pair AND color = 'GREEN'))
            THROW 50084, N'Ghế mới không còn trống.', 1;

        -- Ve con lai cua cap ghe (co the khong con neu khach da huy mot ghe).
        IF @old_pair IS NOT NULL
            SELECT @partner = ticket_id, @partner_status = status, @partner_booking = booking_id
            FROM dbo.Ticket WHERE showtime_id = @showtime_id AND seat_id = @old_pair AND status IN ('Held','Booked','Used');
        IF @partner IS NOT NULL AND (@partner_status <> 'Booked' OR @partner_booking <> @booking_id)
            THROW 50088, N'Không thể đổi vì ghế còn lại của cặp đã sử dụng hoặc thuộc đơn khác.', 1;

        UPDATE dbo.Ticket SET seat_id = @new_seat_id WHERE ticket_id = @ticket_id;      -- giu nguyen gia ve da thanh toan
        INSERT INTO dbo.TicketChangeHistory(ticket_id, change_type, old_seat_id, new_seat_id, old_showtime_id, new_showtime_id, changed_by, reason)
        VALUES (@ticket_id, 'SeatChange', @old_seat, @new_seat_id, @showtime_id, @showtime_id, @staff_id, @reason);
        IF @partner IS NOT NULL
        BEGIN
            UPDATE dbo.Ticket SET seat_id = @new_pair WHERE ticket_id = @partner;
            INSERT INTO dbo.TicketChangeHistory(ticket_id, change_type, old_seat_id, new_seat_id, old_showtime_id, new_showtime_id, changed_by, reason)
            VALUES (@partner, 'SeatChange', @old_pair, @new_pair, @showtime_id, @showtime_id, @staff_id, @reason);
        END

        IF @customer_id IS NOT NULL
        BEGIN
            DECLARE @old_label NVARCHAR(40) = (SELECT CONCAT(row_label, seat_number) FROM dbo.Seat WHERE seat_id = @old_seat),
                    @new_label NVARCHAR(40) = (SELECT CONCAT(row_label, seat_number) FROM dbo.Seat WHERE seat_id = @new_seat_id);
            IF @partner IS NOT NULL
                SELECT @old_label += N', ' + (SELECT CONCAT(row_label, seat_number) FROM dbo.Seat WHERE seat_id = @old_pair),
                       @new_label += N', ' + (SELECT CONCAT(row_label, seat_number) FROM dbo.Seat WHERE seat_id = @new_pair);
            INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, booking_id)
            VALUES (@customer_id, 'SeatChanged', N'Vé của bạn đã được đổi ghế',
                    N'Ghế của bạn được đổi từ ' + @old_label + N' sang ' + @new_label + N'. Mã vé của bạn không thay đổi.',
                    @showtime_id, @booking_id);
        END
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        IF ERROR_NUMBER() IN (2601, 2627) THROW 50084, N'Ghế mới không còn trống.', 1;
        THROW;
    END CATCH
END
GO

/* =====================================================================
   LUỒNG 8. VÉ CỦA TÔI, HỦY VÉ & HOÀN TIỀN
   Lịch sử vé của khách, khách hủy vé, quản lý hủy phim kèm hoàn tiền.
   Số tiền hoàn cộng dồn vào Payment.refunded_amount của dòng thanh toán gốc.
   ===================================================================== */

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   Job: ve da qua gio chien -> trang thai 'Expired' (khong con hieu luc).
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_ExpirePastTickets AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.status = 'Expired'
    FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
    WHERE t.status = 'Booked' AND s.end_time < SYSDATETIME();
END
GO

/* ----------------------------------------------------------------------------
   Lich su ve cua khach, tra ve TUNG VE (moi ve 1 the 1 ma QR).
   Tra ve 'can_cancel' = 1 khi ve con hieu luc VA con trong thoi han huy.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_GetCustomerTickets @email VARCHAR(100), @cancel_hours INT = 2
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_ExpirePastTickets;

    SELECT t.ticket_id, t.ticket_code, t.status AS ticket_status, t.price,
           b.booking_id, b.booking_code, b.status AS booking_status, b.customer_id,
           m.title AS movie_title, ci.cinema_name, r.room_name,
           CONCAT(sc.row_label, sc.seat_number) AS seat_label,
           s.start_time, s.end_time,
           CASE WHEN t.status = 'Booked'
                 AND DATEADD(HOUR, -@cancel_hours, s.start_time) >= SYSDATETIME()
                THEN 1 ELSE 0 END AS can_cancel,
           -- Ghe con lai cua cap ghe doi trong cung don: huy mot ve se huy ca cap.
           (SELECT CONCAT(ps.row_label, ps.seat_number) FROM dbo.Seat ps
            JOIN dbo.Ticket pt ON pt.seat_id = ps.seat_id
            WHERE ps.seat_id = sc.pair_seat_id AND pt.booking_id = t.booking_id
              AND pt.showtime_id = t.showtime_id AND pt.status = 'Booked') AS pair_label,
           m.movie_id,
           CASE WHEN t.status = 'Used' AND s.end_time < SYSDATETIME() AND m.is_deleted = 0
                 AND NOT EXISTS (SELECT 1 FROM dbo.Review rv WHERE rv.movie_id = m.movie_id AND rv.customer_id = b.customer_id)
                THEN 1 ELSE 0 END AS can_review
    FROM dbo.Ticket t
    JOIN dbo.Booking b   ON b.booking_id = t.booking_id
    JOIN dbo.Account a   ON a.account_id = b.customer_id
    JOIN dbo.Showtime s  ON s.showtime_id = t.showtime_id
    JOIN dbo.Movie m     ON m.movie_id = s.movie_id
    JOIN dbo.Room r      ON r.room_id = s.room_id
    JOIN dbo.Cinema ci   ON ci.cinema_id = r.cinema_id
    JOIN dbo.Seat sc     ON sc.seat_id = t.seat_id
    WHERE a.email = @email
      AND t.status IN ('Booked', 'Used', 'Expired', 'Cancelled')
      AND b.status IN ('Paid', 'Cancelled')
    ORDER BY s.start_time DESC, t.ticket_id DESC;
END
GO

/* ----------------------------------------------------------------------------
   UC: Huy 1 VE da thanh toan (UC19 / BF-09)
   Quay ve TUNG VE (moi the 1 ma QR). Huy ca don khi het ve hieu luc di qua cung procedure nay.
   Ghe doi ban theo cap nen huy mot ve se huy ca cap trong cung don.
   Ve tra tien mat van huy duoc tren web: thong bao huong dan khach ra quay nhan lai tien.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CancelTicket
    @ticket_id INT, @account_id INT, @reason NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;

    DECLARE @bstatus VARCHAR(15), @customer_id INT;
    DECLARE @tstatus VARCHAR(10), @tcode VARCHAR(30), @tprice DECIMAL(10,0);
    DECLARE @seat_id INT, @showtime_id INT, @start DATETIME2, @end DATETIME2;
    DECLARE @hours INT = (SELECT CAST(config_value AS INT) FROM dbo.SystemConfig WHERE config_key = 'CANCEL_BEFORE_HOURS');
    DECLARE @points_used INT, @points_discount DECIMAL(12,0), @voucher_id INT, @voucher_discount DECIMAL(12,0);
    DECLARE @order_total DECIMAL(12,0), @gross DECIMAL(12,0);
    DECLARE @active_count INT, @refund_points INT, @booking_id INT;
    DECLARE @refund DECIMAL(12,0), @already_refunded DECIMAL(12,0), @earned INT, @new_balance INT;
    DECLARE @codes NVARCHAR(100);
    DECLARE @pair_ticket INT, @pair_status VARCHAR(10), @pair_code VARCHAR(30), @pair_price DECIMAL(10,0), @pair_seat INT;

    SELECT @booking_id = booking_id FROM dbo.Ticket WHERE ticket_id = @ticket_id;

    SELECT @customer_id = b.customer_id, @bstatus = b.status,
           @points_used = b.points_used, @points_discount = b.points_discount,
           @voucher_id = b.voucher_id, @voucher_discount = b.voucher_discount,
           @order_total = b.total_amount, @gross = b.ticket_total + b.combo_total
    FROM dbo.Booking b WHERE b.booking_id = @booking_id;

    SELECT @tstatus = t.status, @tcode = t.ticket_code, @tprice = t.price,
           @seat_id = t.seat_id, @showtime_id = t.showtime_id,
           @start = s.start_time, @end = s.end_time
    FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
    WHERE t.ticket_id = @ticket_id;

    IF @tstatus IS NULL THROW 50080, N'Không tìm thấy vé.', 1;

    -- Ownership: ve phai thuoc don cua khach dang dang nhap.
    IF @customer_id IS NULL OR @customer_id <> @account_id
        THROW 50081, N'Bạn không có quyền huỷ vé này.', 1;

    -- Ve da soat ve -> khong huy duoc.
    IF @tstatus = 'Used' THROW 50082, N'Vé đã được soát vé, không thể huỷ.', 1;
    IF @tstatus = 'Cancelled' THROW 50083, N'Vé đã được huỷ.', 1;
    IF @tstatus = 'Expired' THROW 50084, N'Vé đã quá thời gian chiếu, không thể huỷ.', 1;
    IF @tstatus <> 'Booked' THROW 50085, N'Vé chưa thanh toán, không thể huỷ.', 1;

    -- Qua thoi han huy ve -> khong huy duoc.
    IF DATEADD(HOUR, -@hours, @start) < SYSDATETIME()
    BEGIN
        DECLARE @late_msg NVARCHAR(200) = CONCAT(N'Đã quá thời hạn huỷ vé: phải huỷ trước giờ chiếu ít nhất ', @hours, N' giờ.');
        THROW 50086, @late_msg, 1;
    END

    SELECT @pair_ticket = pt.ticket_id, @pair_status = pt.status, @pair_code = pt.ticket_code,
           @pair_price = pt.price, @pair_seat = pt.seat_id
    FROM dbo.Seat sc JOIN dbo.Ticket pt ON pt.seat_id = sc.pair_seat_id
    WHERE sc.seat_id = @seat_id AND pt.booking_id = @booking_id AND pt.showtime_id = @showtime_id
      AND pt.status IN ('Booked', 'Used');
    IF @pair_status = 'Used'
        THROW 50088, N'Cặp ghế đôi này đã có một ghế được soát vé, không thể huỷ.', 1;

    SET @codes = @tcode;
    BEGIN TRAN;
    INSERT INTO dbo.TicketChangeHistory(ticket_id, change_type, old_seat_id, old_showtime_id, changed_by, reason)
    VALUES (@ticket_id, 'Cancel', @seat_id, @showtime_id, @account_id, @reason);
    UPDATE dbo.Ticket SET status = 'Cancelled' WHERE ticket_id = @ticket_id AND status = 'Booked';

    IF @pair_ticket IS NOT NULL
    BEGIN
        INSERT INTO dbo.TicketChangeHistory(ticket_id, change_type, old_seat_id, old_showtime_id, changed_by, reason)
        VALUES (@pair_ticket, 'Cancel', @pair_seat, @showtime_id, @account_id, @reason);
        UPDATE dbo.Ticket SET status = 'Cancelled' WHERE ticket_id = @pair_ticket AND status = 'Booked';
        SET @tprice = @tprice + @pair_price;
        SET @codes = @tcode + N', ' + @pair_code;
    END

    -- Dem so ve con hieu luc cua don sau khi huy ve nay.
    SELECT @active_count = COUNT(*) FROM dbo.Ticket
    WHERE booking_id = @booking_id AND status IN ('Booked', 'Used');

    -- So tien da hoan truoc do cua don nay (cong don tren dong thanh toan goc).
    SELECT @already_refunded = ISNULL(SUM(refunded_amount), 0) FROM dbo.Payment
    WHERE booking_id = @booking_id;

    -- Tien hoan = phan chia theo ty le gia ve tren gia tri don (da tru voucher/MyPoint),
    -- nen tong hoan KHONG bao gio vuot so tien khach thuc tra.
    -- Huy ve cuoi cung -> hoan not phan con lai (gom ca combo) vi ca don bi huy.
    IF @active_count = 0
        SET @refund = @order_total - @already_refunded;
    ELSE
        SET @refund = ROUND(@tprice * @order_total / NULLIF(@gross, 0), 0);
    IF @refund > @order_total - @already_refunded SET @refund = @order_total - @already_refunded;
    IF @refund < 0 SET @refund = 0;

    -- Hoan tien chi ghi o MOT cho: dong thanh toan goc (refunded_amount cong don; hoan het -> 'Refunded').
    -- KHONG them dong Payment moi cho lan hoan, neu khong tong refunded_amount / amount cua don bi tinh doi.
    UPDATE dbo.Payment
    SET refunded_amount = @already_refunded + @refund,
        status = CASE WHEN @active_count = 0 THEN 'Refunded' ELSE status END
    WHERE booking_id = @booking_id AND status = 'Success';

    -- Chi tieu tich luy giam theo so tien da hoan.
    IF @refund > 0
        UPDATE dbo.Customer
        SET total_spent = CASE WHEN total_spent > @refund THEN total_spent - @refund ELSE 0 END
        WHERE customer_id = @customer_id;

    -- Don khong con ve hieu luc nao -> huy ca don.
    IF @active_count = 0
        UPDATE dbo.Booking SET status = 'Cancelled'
        WHERE booking_id = @booking_id AND status = 'Paid';

    -- Tra lai MyPoint da dung + thu hoi diem da tich + tra luot voucher
    -- CHI khi don khong con ve hieu luc (voucher/diem la chiet khau cap DON).
    IF @active_count = 0
    BEGIN
        SELECT @earned = ISNULL(SUM(points), 0) FROM dbo.MyPointTransaction
        WHERE booking_id = @booking_id AND txn_type = 'Earn';

        SET @refund_points = ISNULL(@points_used, 0);
        SELECT @new_balance = my_point_balance + @refund_points - @earned
        FROM dbo.Customer WHERE customer_id = @customer_id;
        IF @new_balance < 0
        BEGIN
            SET @earned = @earned + @new_balance;   -- chi thu hoi toi da so diem dang co
            SET @new_balance = 0;
        END

        IF @refund_points > 0
            INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points)
            VALUES (@customer_id, @booking_id, 'Adjust', @refund_points);
        IF @earned > 0
            INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points)
            VALUES (@customer_id, @booking_id, 'Adjust', -@earned);
        UPDATE dbo.Customer SET my_point_balance = @new_balance WHERE customer_id = @customer_id;
    END

    IF @active_count = 0 AND @voucher_id IS NOT NULL
    BEGIN
        DELETE FROM dbo.VoucherUsage WHERE booking_id = @booking_id;
        UPDATE dbo.Voucher SET used_count = CASE WHEN used_count > 0 THEN used_count - 1 ELSE 0 END,
               status = CASE WHEN status = 'Used' THEN 'Allowed' ELSE status END
        WHERE voucher_id = @voucher_id;
    END

    -- Ca don bi huy: combo con lai cung huy theo va tra ton kho.
    IF @active_count = 0
    BEGIN
        UPDATE c SET c.stock = c.stock + bc.quantity
        FROM dbo.Combo c JOIN dbo.BookingCombo bc ON bc.combo_id = c.combo_id
        WHERE bc.booking_id = @booking_id AND bc.cancelled_at IS NULL;
        UPDATE dbo.BookingCombo SET cancelled_at = SYSDATETIME()
        WHERE booking_id = @booking_id AND cancelled_at IS NULL;
    END

    -- Thong bao cho khach: chi hua hoan tien khi so tien hoan > 0 (don tra het bang MyPoint/voucher thi khong co).
    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, booking_id)
    VALUES (@customer_id, 'TicketCancelled',
            N'Hủy vé thành công',
            CASE WHEN @refund > 0
                 THEN N'Vé ' + @codes + N' đã được hủy. Số tiền hoàn lại: ' + FORMAT(@refund, 'N0', 'vi-VN') + N' đ.'
                      + CASE WHEN EXISTS (SELECT 1 FROM dbo.Payment WHERE booking_id = @booking_id AND method = 'Cash')
                             THEN N' Vui lòng đến quầy vé để nhận lại tiền mặt.' ELSE N'' END
                 ELSE N'Vé ' + @codes + N' đã được hủy. Vé này không có khoản tiền cần hoàn.' END,
            @showtime_id, @booking_id);
    COMMIT;
END
GO

/* ----------------------------------------------------------------------------
   UC: Huy toan bo combo cua mot don da thanh toan; ve cua don van giu nguyen.
   Cung thoi han huy voi ve. Tien hoan chia theo ty le nhu sp_CancelTicket (da tru voucher/MyPoint).
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CancelCombo @booking_id INT, @account_id INT AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @customer_id INT, @bstatus VARCHAR(15), @bcode VARCHAR(20), @showtime_id INT;
    DECLARE @order_total DECIMAL(12,0), @gross DECIMAL(12,0), @start DATETIME2;
    DECLARE @hours INT = (SELECT CAST(config_value AS INT) FROM dbo.SystemConfig WHERE config_key = 'CANCEL_BEFORE_HOURS');
    DECLARE @combo DECIMAL(12,0), @already DECIMAL(12,0), @refund DECIMAL(12,0);

    SELECT @customer_id = b.customer_id, @bstatus = b.status, @bcode = b.booking_code,
           @showtime_id = b.showtime_id, @order_total = b.total_amount, @gross = b.ticket_total + b.combo_total,
           @start = s.start_time
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id WHERE b.booking_id = @booking_id;

    IF @customer_id IS NULL OR @customer_id <> @account_id
        THROW 50091, N'Bạn không có quyền huỷ combo này.', 1;
    IF @bstatus <> 'Paid' THROW 50092, N'Đơn này không còn hiệu lực nên không thể huỷ combo.', 1;
    IF DATEADD(HOUR, -@hours, @start) < SYSDATETIME()
    BEGIN
        DECLARE @late_msg NVARCHAR(200) = CONCAT(N'Đã quá thời hạn huỷ combo: phải huỷ trước giờ chiếu ít nhất ', @hours, N' giờ.');
        THROW 50094, @late_msg, 1;
    END

    BEGIN TRAN;
    -- Khoa dong combo truoc khi tinh tien: hai yeu cau cung luc chi mot yeu cau duoc hoan.
    DECLARE @lines TABLE (combo_id INT, quantity INT, unit_price DECIMAL(10,0));
    UPDATE dbo.BookingCombo SET cancelled_at = SYSDATETIME()
    OUTPUT inserted.combo_id, inserted.quantity, inserted.unit_price INTO @lines
    WHERE booking_id = @booking_id AND cancelled_at IS NULL;
    IF NOT EXISTS (SELECT 1 FROM @lines)
    BEGIN
        ROLLBACK;
        THROW 50095, N'Đơn này không còn combo để huỷ.', 1;
    END

    UPDATE c SET c.stock = c.stock + l.quantity FROM dbo.Combo c JOIN @lines l ON l.combo_id = c.combo_id;

    SET @combo = (SELECT SUM(quantity * unit_price) FROM @lines);
    SELECT @already = ISNULL(SUM(refunded_amount), 0) FROM dbo.Payment WHERE booking_id = @booking_id;
    SET @refund = ROUND(@combo * @order_total / NULLIF(@gross, 0), 0);
    IF @refund > @order_total - @already SET @refund = @order_total - @already;
    IF @refund IS NULL OR @refund < 0 SET @refund = 0;

    UPDATE dbo.Payment SET refunded_amount = @already + @refund WHERE booking_id = @booking_id AND status = 'Success';
    IF @refund > 0
        UPDATE dbo.Customer SET total_spent = CASE WHEN total_spent > @refund THEN total_spent - @refund ELSE 0 END
        WHERE customer_id = @customer_id;

    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, booking_id)
    VALUES (@customer_id, 'ComboCancelled', N'Hủy combo thành công',
            CASE WHEN @refund > 0
                 THEN N'Combo của đơn ' + @bcode + N' đã được hủy. Số tiền hoàn lại: ' + FORMAT(@refund, 'N0', 'vi-VN') + N' đ.'
                      + CASE WHEN EXISTS (SELECT 1 FROM dbo.Payment WHERE booking_id = @booking_id AND method = 'Cash')
                             THEN N' Vui lòng đến quầy vé để nhận lại tiền mặt.' ELSE N'' END
                 ELSE N'Combo của đơn ' + @bcode + N' đã được hủy. Đơn này không có khoản tiền cần hoàn cho combo.' END,
            @showtime_id, @booking_id);
    COMMIT;
END
GO

/* ----------------------------------------------------------------------------
   UC: Now-Showing Movie Cancellation Alert
   @confirm = 0: chi canh bao. @confirm = 1: xac nhan huy, hoan tien, gui email.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CancelMovie @movie_id INT, @manager_id INT, @confirm BIT = 0 AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Movie WHERE movie_id = @movie_id)
        THROW 51022, N'Không tìm thấy phim cần hủy.', 1;

    -- Ket qua 1: cac suat se bi huy + so ve da ban (dung de canh bao truoc khi xac nhan).
    SELECT s.showtime_id, s.start_time, r.room_name, COUNT(t.ticket_id) AS booked_tickets
    FROM dbo.Showtime s JOIN dbo.Room r ON r.room_id = s.room_id
    LEFT JOIN dbo.Ticket t ON t.showtime_id = s.showtime_id AND t.status = 'Booked'
    WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
    GROUP BY s.showtime_id, s.start_time, r.room_name
    ORDER BY s.start_time;
    IF @confirm = 0 RETURN;

    BEGIN TRAN;

    -- Cac don da thanh toan thuoc cac suat se bi huy: tinh so tien con phai hoan, diem va voucher can tra.
    SELECT b.booking_id, b.customer_id, b.voucher_id, b.points_used,
           CAST(b.total_amount - ISNULL((SELECT SUM(p.refunded_amount) FROM dbo.Payment p
                                         WHERE p.booking_id = b.booking_id), 0) AS DECIMAL(12,0)) AS remaining,
           ISNULL((SELECT SUM(m.points) FROM dbo.MyPointTransaction m
                   WHERE m.booking_id = b.booking_id AND m.txn_type = 'Earn'), 0) AS earned
    INTO #bk
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id
    WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() AND b.status = 'Paid';

    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id)
    SELECT DISTINCT b.customer_id, 'MovieCancelled', N'Thông báo hủy suất chiếu',
           N'Suất chiếu bạn đã đặt bị hủy, vé sẽ được hoàn tiền.', s.showtime_id, @movie_id, b.booking_id
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id
    WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
      AND b.status = 'Paid' AND b.customer_id IS NOT NULL;

    -- Hoan tien chi ghi o MOT cho: dong thanh toan goc ghi nhan da hoan het (khong them dong Payment moi).
    UPDATE p SET p.refunded_amount = p.amount, p.status = 'Refunded'
    FROM dbo.Payment p JOIN #bk k ON k.booking_id = p.booking_id WHERE p.status = 'Success';

    -- Tra lai MyPoint da dung, thu hoi diem da tich, giam chi tieu tich luy (khong de am).
    INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points)
    SELECT customer_id, booking_id, 'Adjust', points_used FROM #bk WHERE customer_id IS NOT NULL AND points_used > 0;
    INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points)
    SELECT customer_id, booking_id, 'Adjust', -earned FROM #bk WHERE customer_id IS NOT NULL AND earned > 0;
    UPDATE c SET
        c.my_point_balance = CASE WHEN c.my_point_balance + x.points_used - x.earned < 0 THEN 0
                                  ELSE c.my_point_balance + x.points_used - x.earned END,
        c.total_spent = CASE WHEN c.total_spent > x.remaining THEN c.total_spent - x.remaining ELSE 0 END
    FROM dbo.Customer c
    JOIN (SELECT customer_id, SUM(points_used) AS points_used, SUM(earned) AS earned, SUM(remaining) AS remaining
          FROM #bk WHERE customer_id IS NOT NULL GROUP BY customer_id) x ON x.customer_id = c.customer_id;

    -- Tra luot voucher.
    UPDATE v SET v.used_count = CASE WHEN v.used_count >= x.n THEN v.used_count - x.n ELSE 0 END,
                 v.status = CASE WHEN v.status = 'Used' THEN 'Allowed' ELSE v.status END
    FROM dbo.Voucher v
    JOIN (SELECT voucher_id, COUNT(*) AS n FROM #bk WHERE voucher_id IS NOT NULL GROUP BY voucher_id) x
         ON x.voucher_id = v.voucher_id;
    DELETE u FROM dbo.VoucherUsage u JOIN #bk k ON k.booking_id = u.booking_id;

    -- Combo cua cac don da thanh toan: huy theo va tra ton kho (don chua thanh toan chua tru ton).
    UPDATE c SET c.stock = c.stock + x.qty
    FROM dbo.Combo c
    JOIN (SELECT bc.combo_id, SUM(bc.quantity) AS qty FROM dbo.BookingCombo bc JOIN #bk k ON k.booking_id = bc.booking_id
          WHERE bc.cancelled_at IS NULL GROUP BY bc.combo_id) x ON x.combo_id = c.combo_id;
    UPDATE bc SET bc.cancelled_at = SYSDATETIME()
    FROM dbo.BookingCombo bc JOIN #bk k ON k.booking_id = bc.booking_id WHERE bc.cancelled_at IS NULL;

    UPDATE t SET t.status = 'Cancelled'
    FROM dbo.Ticket t JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
    WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME() AND t.status IN ('Held','Booked');

    UPDATE b SET b.status = 'Cancelled'
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id
    WHERE s.movie_id = @movie_id AND s.status = 'Scheduled' AND s.start_time > SYSDATETIME()
      AND b.status IN ('Paid','PendingPayment','Selecting');

    UPDATE dbo.Showtime SET status = 'Cancelled'
    WHERE movie_id = @movie_id AND status = 'Scheduled' AND start_time > SYSDATETIME();

    UPDATE dbo.Movie SET status = 'Stopped', updated_at = SYSDATETIME(),
        end_date = CASE WHEN release_date > CAST(SYSDATETIME() AS DATE) THEN release_date ELSE CAST(SYSDATETIME() AS DATE) END
    WHERE movie_id = @movie_id;

    INSERT INTO dbo.SystemLog(account_id, action, detail) VALUES (@manager_id, N'CANCEL_MOVIE', CONCAT(N'movie_id=', @movie_id));
    DROP TABLE #bk;
    COMMIT;
END
GO

/* =====================================================================
   LUỒNG 9. ĐÁNH GIÁ PHIM
   Khách đã xem phim đánh giá sau khi suất chiếu kết thúc, được thưởng MyPoint.
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.Review (
    review_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Review PRIMARY KEY,
    movie_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating TINYINT NOT NULL,
    comment NVARCHAR(1000) NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_Review_Created DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Review_Movie FOREIGN KEY (movie_id) REFERENCES dbo.Movie(movie_id),
    CONSTRAINT FK_Review_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT UQ_Review_Movie_Customer UNIQUE (movie_id, customer_id),
    CONSTRAINT CK_Review_Rating CHECK (rating BETWEEN 1 AND 5)
);
GO

-- ---------- View ----------
GO

CREATE VIEW dbo.vw_MovieDetail
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

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   UC: Movie Review & Comment (chi phim da xem = co ve da check-in)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_AddReview @customer_id INT, @movie_id INT, @rating TINYINT, @comment NVARCHAR(1000) = NULL AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @bonus INT = 5;   -- khop voi noi dung thong bao ReviewReminder
    IF NOT EXISTS (SELECT 1 FROM dbo.Ticket t JOIN dbo.Booking b ON b.booking_id = t.booking_id
                   JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
                   JOIN dbo.Movie m ON m.movie_id = s.movie_id
                   WHERE b.customer_id = @customer_id AND s.movie_id = @movie_id AND t.status = 'Used'
                     AND s.end_time < SYSDATETIME() AND m.is_deleted = 0)
        THROW 50090, N'Chỉ được đánh giá phim bạn đã xem xong.', 1;

    -- UQ_Review_Movie_Customer dam bao moi phim chi thuong diem mot lan.
    BEGIN TRAN;
    INSERT INTO dbo.Review(movie_id, customer_id, rating, comment) VALUES (@movie_id, @customer_id, @rating, @comment);
    INSERT INTO dbo.MyPointTransaction(customer_id, booking_id, txn_type, points) VALUES (@customer_id, NULL, 'Earn', @bonus);
    UPDATE dbo.Customer SET my_point_balance = my_point_balance + @bonus WHERE customer_id = @customer_id;
    COMMIT;
END
GO

/* =====================================================================
   LUỒNG 10. THÔNG BÁO & HỘP THƯ
   Email gửi đi (Pending/Sent/Failed) và thông báo chỉ hiện trong app (InApp).
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.EmailNotification (
    notif_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EmailNotification PRIMARY KEY,
    customer_id INT NOT NULL,
    notif_type VARCHAR(20) NOT NULL,
    subject NVARCHAR(200) NOT NULL,
    body NVARCHAR(MAX) NULL,
    showtime_id INT NULL,
    movie_id INT NULL,
    booking_id INT NULL,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_EmailNotification_Status DEFAULT 'Pending',
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_EmailNotification_Created DEFAULT SYSDATETIME(),
    sent_at DATETIME2(7) NULL,
    CONSTRAINT FK_EmailNotification_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_EmailNotification_Showtime FOREIGN KEY (showtime_id) REFERENCES dbo.Showtime(showtime_id),
    CONSTRAINT FK_EmailNotification_Movie FOREIGN KEY (movie_id) REFERENCES dbo.Movie(movie_id),
    CONSTRAINT FK_EmailNotification_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
    CONSTRAINT CK_EmailNotification_Type CHECK (notif_type IN ('ETicket','ShowtimeReminder','NewMovie','Voucher','MovieCancelled','TicketCancelled','ComboCancelled','ReviewReminder','SeatChanged')),
    CONSTRAINT CK_EmailNotification_Status CHECK (status IN ('Pending','Sent','Failed','InApp'))
);
GO

-- ---------- Procedure ----------
GO

/* ----------------------------------------------------------------------------
   UC: Receive Email Notifications - bao phim moi cho moi khach dang hoat dong.
   Goi lai nhieu lan khong gui trung.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_QueueNewMovieEmail @movie_id INT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, movie_id)
    SELECT c.customer_id, 'NewMovie', LEFT(N'Phim mới: ' + m.title, 200),
           N'Phim "' + m.title + N'"'
               + CASE WHEN m.release_date > CAST(SYSDATETIME() AS DATE)
                      THEN N' sắp có mặt tại CineStar Cinemas, khởi chiếu ngày '
                      ELSE N' đang chiếu tại CineStar Cinemas từ ngày ' END
               + CONVERT(NVARCHAR(10), m.release_date, 103) + N'.',
           m.movie_id
    FROM dbo.Movie m
    CROSS JOIN dbo.Customer c
    JOIN dbo.Account a ON a.account_id = c.customer_id
    WHERE m.movie_id = @movie_id AND m.is_deleted = 0 AND m.status <> 'Stopped' AND a.status = 'Active'
      AND c.receive_promo_email = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.notif_type = 'NewMovie'
                      AND e.movie_id = m.movie_id AND e.customer_id = c.customer_id);
END
GO

/* ----------------------------------------------------------------------------
   UC: Receive Email Notifications - bao uu dai voucher cho khach du dieu kien chi tieu.
   Chi voucher dang bat va con han; goi lai nhieu lan khong gui trung.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_QueueVoucherEmail @code VARCHAR(30) AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body)
    SELECT c.customer_id, 'Voucher', N'Ưu đãi voucher ' + v.code,
           N'Dùng mã ' + v.code + N' khi đặt vé: '
               + COALESCE(NULLIF(v.description, N''),
                          CASE WHEN v.discount_type = 'Percent'
                               THEN N'giảm ' + FORMAT(v.discount_value, '0.##') + N'%'
                               ELSE N'giảm ' + FORMAT(v.discount_value, 'N0', 'vi-VN') + N' đ' END)
               + N'. Áp dụng từ ' + CONVERT(NVARCHAR(10), v.valid_from, 103)
               + N' đến ' + CONVERT(NVARCHAR(10), v.valid_to, 103) + N'.'
    FROM dbo.Voucher v
    CROSS JOIN dbo.Customer c
    JOIN dbo.Account a ON a.account_id = c.customer_id
    WHERE v.code = @code AND v.status = 'Allowed' AND v.valid_to >= CAST(SYSDATETIME() AS DATE)
      AND v.used_count < v.usage_limit
      AND a.status = 'Active' AND c.total_spent >= v.min_cumulative_spending AND c.receive_promo_email = 1
      AND (SELECT COUNT(*) FROM dbo.VoucherUsage u WHERE u.voucher_id = v.voucher_id AND u.customer_id = c.customer_id) < v.per_customer_limit
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.notif_type = 'Voucher'
                      AND e.customer_id = c.customer_id AND e.subject = N'Ưu đãi voucher ' + v.code);
END
GO

/* ----------------------------------------------------------------------------
   Hop thu: khi khach mo hop thu, bo sung thong bao phim moi (khoi chieu trong 14 ngay
   qua hoac sap chieu) va voucher khach dang dung duoc ma chua tung nhan.
   Status InApp: chi hien trong hop thu, job gui email khong lay cac dong nay.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_SyncInboxPromotions @customer_id INT AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @today DATE = CAST(SYSDATETIME() AS DATE);
    DECLARE @lock NVARCHAR(60) = CONCAT(N'inbox-promotions-', @customer_id);
    BEGIN TRANSACTION;
    -- Hai tab mo cung luc khong duoc tao trung thong bao.
    EXEC sp_getapplock @Resource = @lock, @LockMode = 'Exclusive', @LockOwner = 'Transaction';

    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, movie_id, status)
    SELECT @customer_id, 'NewMovie', LEFT(N'Phim mới: ' + m.title, 200), N'Phim "' + m.title + N'" tại CineStar Cinemas.', m.movie_id, 'InApp'
    FROM dbo.Movie m
    WHERE m.is_deleted = 0 AND m.status IN ('Upcoming','NowShowing') AND m.release_date >= DATEADD(DAY, -14, @today)
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.notif_type = 'NewMovie'
                      AND e.movie_id = m.movie_id AND e.customer_id = @customer_id)
    ORDER BY m.release_date, m.movie_id;

    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, status)
    SELECT @customer_id, 'Voucher', N'Ưu đãi voucher ' + v.code,
           N'Dùng mã ' + v.code + N' khi đặt vé: '
               + COALESCE(NULLIF(v.description, N''),
                          CASE WHEN v.discount_type = 'Percent'
                               THEN N'giảm ' + FORMAT(v.discount_value, '0.##') + N'%'
                               ELSE N'giảm ' + FORMAT(v.discount_value, 'N0', 'vi-VN') + N' đ' END)
               + N'. Hạn dùng đến ' + CONVERT(NVARCHAR(10), v.valid_to, 103) + N'.', 'InApp'
    FROM dbo.Voucher v
    JOIN dbo.Customer c ON c.customer_id = @customer_id
    WHERE v.status = 'Allowed' AND @today BETWEEN v.valid_from AND v.valid_to AND v.used_count < v.usage_limit
      AND c.total_spent >= v.min_cumulative_spending
      AND (SELECT COUNT(*) FROM dbo.VoucherUsage u WHERE u.voucher_id = v.voucher_id AND u.customer_id = @customer_id) < v.per_customer_limit
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.notif_type = 'Voucher'
                      AND e.customer_id = @customer_id AND e.subject = N'Ưu đãi voucher ' + v.code);
    COMMIT;
END
GO

/* ----------------------------------------------------------------------------
   Job: moi khach xem xong phim (ve da soat, suat vua ket thuc) -> nhac danh gia.
   Chi xet suat ket thuc trong 24 gio qua; moi khach mot thong bao cho moi phim.
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_QueueReviewReminders AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id)
    SELECT b.customer_id, 'ReviewReminder', N'Hãy đánh giá phim để nhận 5 điểm MyPoint',
           N'Hãy đánh giá phim để nhận 5 điểm MyPoint', MAX(s.showtime_id), s.movie_id, MAX(b.booking_id)
    FROM dbo.Ticket t JOIN dbo.Booking b ON b.booking_id = t.booking_id
    JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
    JOIN dbo.Movie m ON m.movie_id = s.movie_id
    WHERE t.status = 'Used' AND b.customer_id IS NOT NULL AND m.is_deleted = 0
      AND s.end_time < SYSDATETIME() AND s.end_time >= DATEADD(HOUR, -24, SYSDATETIME())
      AND NOT EXISTS (SELECT 1 FROM dbo.Review r WHERE r.movie_id = s.movie_id AND r.customer_id = b.customer_id)
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.notif_type = 'ReviewReminder'
                      AND e.movie_id = s.movie_id AND e.customer_id = b.customer_id)
    GROUP BY b.customer_id, s.movie_id;
END
GO

/* ----------------------------------------------------------------------------
   Job: Showtime Reminder Email (chay dinh ky, vd moi 15 phut)
   -------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_QueueShowtimeReminders @hours_before INT = 3 AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.EmailNotification(customer_id, notif_type, subject, body, showtime_id, movie_id, booking_id)
    SELECT b.customer_id, 'ShowtimeReminder', N'Nhắc lịch xem phim', N'Suất chiếu của bạn sắp bắt đầu.',
           s.showtime_id, s.movie_id, b.booking_id
    FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id = b.showtime_id
    WHERE b.status = 'Paid' AND b.customer_id IS NOT NULL AND s.status = 'Scheduled'
      AND s.start_time BETWEEN SYSDATETIME() AND DATEADD(HOUR, @hours_before, SYSDATETIME())
      AND NOT EXISTS (SELECT 1 FROM dbo.EmailNotification e WHERE e.booking_id = b.booking_id AND e.notif_type = 'ShowtimeReminder');
END
GO

/* =====================================================================
   LUỒNG 11. TIN TỨC
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.News (
    news_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_News PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    thumbnail_url VARCHAR(500) NULL,
    status VARCHAR(10) NOT NULL CONSTRAINT DF_News_Status DEFAULT 'Published',
    created_by INT NOT NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_News_Created DEFAULT SYSDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_News_Creator FOREIGN KEY (created_by) REFERENCES dbo.Account(account_id),
    CONSTRAINT CK_News_Status CHECK (status IN ('Draft','Published','Hidden'))
);
GO

/* =====================================================================
   LUỒNG 12. BÁO CÁO DOANH THU
   ===================================================================== */

-- ---------- View ----------
GO

CREATE VIEW dbo.vw_RevenueByMovie AS
SELECT m.movie_id, m.title, c.cinema_id, c.cinema_name, CAST(b.paid_at AS DATE) AS revenue_date,
       COUNT(t.ticket_id) AS tickets_sold, SUM(t.price) AS ticket_revenue
FROM dbo.Ticket t
JOIN dbo.Booking b  ON b.booking_id = t.booking_id AND b.status = 'Paid'
JOIN dbo.Showtime s ON s.showtime_id = t.showtime_id
JOIN dbo.Movie m    ON m.movie_id = s.movie_id
JOIN dbo.Room r     ON r.room_id = s.room_id
JOIN dbo.Cinema c   ON c.cinema_id = r.cinema_id
WHERE t.status IN ('Booked','Used')
GROUP BY m.movie_id, m.title, c.cinema_id, c.cinema_name, CAST(b.paid_at AS DATE);
GO

/* =====================================================================
   LUỒNG 13. QUẢN TRỊ HỆ THỐNG
   Tham số hệ thống và nhật ký thao tác.
   ===================================================================== */

-- ---------- Bảng ----------
GO

CREATE TABLE dbo.SystemConfig (
    config_key VARCHAR(50) NOT NULL CONSTRAINT PK_SystemConfig PRIMARY KEY,
    config_value NVARCHAR(100) NOT NULL,
    description NVARCHAR(200) NULL
);
GO

CREATE TABLE dbo.SystemLog (
    log_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SystemLog PRIMARY KEY,
    account_id INT NULL,
    action NVARCHAR(100) NOT NULL,
    detail NVARCHAR(500) NULL,
    created_at DATETIME2(7) NOT NULL CONSTRAINT DF_SystemLog_Created DEFAULT SYSDATETIME(),
    CONSTRAINT FK_SystemLog_Account FOREIGN KEY (account_id) REFERENCES dbo.Account(account_id)
);
GO

/* =====================================================================
   LỊCH SỬ THAY ĐỔI (tất cả đã nằm trong các luồng ở trên)
   28/10/2026  Users: thêm IdNumber, Province, District, Address, AvatarUrl
   29/10/2026  Showtime: suất đã hủy không chiếm giờ của phòng (UQ_Showtime_Room_Start có điều kiện)
   30/10/2026  Payment: hoàn tiền chỉ ghi ở dòng thanh toán gốc; bỏ sp_CancelBooking
   30/10/2026  Seed: đổi tên hiển thị tài khoản manager, staff
   30/10/2026  News: ảnh tin tức 1-4 chuyển từ PNG sang JPEG
   31/10/2026  EmailNotification: thêm loại TicketCancelled
   31/10/2026  Movie: xóa mềm bằng is_deleted; UX_Movie_Title chỉ tính phim chưa xóa
   01/11/2026  Review: chỉ đánh giá sau khi suất chiếu kết thúc; nhắc đánh giá (ReviewReminder), thưởng 5 điểm
   01/11/2026  Email phim mới / voucher; chặn soát vé trùng
   01/11/2026  EmailNotification: thêm trạng thái InApp cho Hộp thư
   02/11/2026  Đổi ghế: cùng loại ghế, đổi cả cặp ghế đôi, báo cho khách (SeatChanged)
02/11/2026  Hủy combo: BookingCombo.cancelled_at, sp_CancelCombo, thông báo ComboCancelled
03/11/2026  Email: Customer.receive_promo_email (khách tắt/bật email phim mới, ưu đãi); REMINDER_HOURS_BEFORE
   
   Script nâng cấp DB cũ giữ nguyên dữ liệu nằm trong lịch sử git: git show 6fe0e9e:sql/upgrade.sql
   ===================================================================== */

PRINT N'[OK] Da tao cau truc CinemaWebDB (32 bang, 26 procedure, 3 view, 1 trigger, 1 function). Chay tiep database/seed.sql.';
GO
