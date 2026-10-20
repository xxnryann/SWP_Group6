/* =====================================================================
   CinemaDB — SCRIPT TEST: LUỒNG LOGIN + STT 12 (Quản lý tin tức)
   ---------------------------------------------------------------------
   Chạy 1 lần duy nhất trên SQL Server (mở SSMS > New Query > Execute).
   Script tạo mới hoàn toàn database CinemaDB, gồm:
     1) Bảng Users            — luồng đăng nhập/đăng ký của khung code
     2) Bảng AppRole, Account  — theo script database của nhóm
     3) Bảng News              — phần STT 12, đúng cột/status của script nhóm

   Tài khoản test — MẬT KHẨU CHUNG: 123456
     manager@cinema.vn  / MANAGER   → vào được /manager/news
     admin@cinema.vn    / ADMIN     → vào được /manager/news
     staff@cinema.vn    / STAFF     → bị chặn 403 ở /manager/news (test phân quyền)
     khach1@gmail.com   / CUSTOMER  → bị chặn 403, nhưng xem được /news
   ===================================================================== */

IF DB_ID(N'CinemaDB') IS NOT NULL
BEGIN
    ALTER DATABASE CinemaDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CinemaDB;
END
GO
CREATE DATABASE CinemaDB;
GO
USE CinemaDB;
GO

/* =====================================================================
   1. BẢNG Users — luồng login/register của khung code (nguyên văn schema.sql)
   ===================================================================== */
CREATE TABLE dbo.Users (
                           UserId       INT IDENTITY(1,1) PRIMARY KEY,
                           FullName     NVARCHAR(100)  NOT NULL,
                           Email        NVARCHAR(150)  NOT NULL,
                           Phone        VARCHAR(15)    NOT NULL,
                           PasswordHash VARCHAR(100)  NOT NULL,            -- BCrypt
                           DateOfBirth  DATE           NULL,
                           Gender       VARCHAR(10)    NULL,                -- MALE / FEMALE / OTHER
                           Role         VARCHAR(20)    NOT NULL DEFAULT 'CUSTOMER',   -- CUSTOMER / STAFF / MANAGER / ADMIN
                           Status       VARCHAR(20)    NOT NULL DEFAULT 'PENDING',    -- PENDING / ACTIVE / BLOCKED
                           OtpHash      VARCHAR(64)    NULL,                -- SHA-256 of the OTP
                           OtpExpiry    DATETIME2      NULL,
                           OtpAttempts  INT            NOT NULL DEFAULT 0,
                           CreatedAt    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
                           CONSTRAINT UQ_Users_Email UNIQUE (Email),
                           CONSTRAINT UQ_Users_Phone UNIQUE (Phone),
                           CONSTRAINT CK_Users_Status CHECK (Status IN ('PENDING','ACTIVE','BLOCKED')),
                           CONSTRAINT CK_Users_Role   CHECK (Role   IN ('CUSTOMER','STAFF','MANAGER','ADMIN'))
);
GO

/* =====================================================================
   2. BẢNG AppRole, Account, News — đúng script database của nhóm
   ===================================================================== */
CREATE TABLE AppRole (
                         role_id     INT IDENTITY PRIMARY KEY,
                         role_name   NVARCHAR(30) NOT NULL UNIQUE          -- Admin, CinemaManager, Staff, Customer
);
GO

CREATE TABLE Account (
                         account_id    INT IDENTITY PRIMARY KEY,
                         role_id       INT NOT NULL REFERENCES AppRole(role_id),
                         full_name     NVARCHAR(100) NOT NULL,
                         email         VARCHAR(100)  NOT NULL UNIQUE,
                         phone         VARCHAR(15)   NOT NULL,
                         password_hash VARCHAR(255)  NOT NULL,
                         status        VARCHAR(10)   NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Locked')),
                         created_at    DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE News (
                      news_id    INT IDENTITY PRIMARY KEY,
                      title      NVARCHAR(200) NOT NULL,
                      content    NVARCHAR(MAX) NOT NULL,
                      thumbnail_url VARCHAR(500),
                      status     VARCHAR(10) NOT NULL DEFAULT 'Published' CHECK (status IN ('Draft','Published','Hidden')),
                      created_by INT NOT NULL REFERENCES Account(account_id),
                      created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
                      updated_at DATETIME2 NULL
);
GO

/* =====================================================================
   3. DỮ LIỆU TEST
   ===================================================================== */
-- 3.1 Role trong bảng Account
INSERT INTO AppRole(role_name) VALUES (N'Admin'),(N'CinemaManager'),(N'Staff'),(N'Customer');
GO

-- 3.2 Tài khoản trong bảng Account (email TRÙNG với bảng Users để tra created_by)
--     Mật khẩu: 123456 (BCrypt)
DECLARE @h VARCHAR(100) = '$2b$12$mXnfK0FGY4fwy4hGyw4ctuItps3qXEhVvmFrGiBBqCuKEIAUnAFy.';
INSERT INTO Account(role_id, full_name, email, phone, password_hash) VALUES
                                                                         ((SELECT role_id FROM AppRole WHERE role_name = N'Admin'),         N'Quản trị hệ thống', 'admin@cinema.vn',   '0900000001', @h),
                                                                         ((SELECT role_id FROM AppRole WHERE role_name = N'CinemaManager'), N'Nguyễn Quản Lý',    'manager@cinema.vn', '0900000002', @h),
                                                                         ((SELECT role_id FROM AppRole WHERE role_name = N'Staff'),         N'Trần Nhân Viên',    'staff@cinema.vn',   '0900000003', @h),
                                                                         ((SELECT role_id FROM AppRole WHERE role_name = N'Customer'),       N'Lê Khách Một',      'khach1@gmail.com',  '0911111111', @h);
GO

-- 3.3 Tài khoản trong bảng Users (khung code login dùng bảng này)
--     Status = 'ACTIVE' để đăng nhập được ngay, không cần qua OTP
DECLARE @h2 VARCHAR(100) = '$2b$12$mXnfK0FGY4fwy4hGyw4ctuItps3qXEhVvmFrGiBBqCuKEIAUnAFy.';
INSERT INTO Users(FullName, Email, Phone, PasswordHash, Role, Status) VALUES
                                                                          (N'Quản trị hệ thống', 'admin@cinema.vn',   '0900000001', @h2, 'ADMIN',    'ACTIVE'),
                                                                          (N'Nguyễn Quản Lý',    'manager@cinema.vn', '0900000002', @h2, 'MANAGER',  'ACTIVE'),
                                                                          (N'Trần Nhân Viên',    'staff@cinema.vn',   '0900000003', @h2, 'STAFF',    'ACTIVE'),
                                                                          (N'Lê Khách Một',      'khach1@gmail.com',  '0911111111', @h2, 'CUSTOMER', 'ACTIVE');
GO

-- 3.4 Tin tức test: 3 Published / 2 Draft / 1 Hidden
DECLARE @acc INT = (SELECT account_id FROM Account WHERE email = 'manager@cinema.vn');
INSERT INTO News (title, content, thumbnail_url, status, created_by, created_at, updated_at)
VALUES
    (N'Khai trương cụm rạp CineStar Quận 7',
     N'Cụm rạp mới với 8 phòng chiếu hiện đại, công nghệ âm thanh Dolby Atmos chính thức đi vào hoạt động từ ngày 25/10. Nhân dịp khai trương, rạp tặng 500 vé miễn phí cho khách hàng đến sớm nhất trong ngày khai trương.',
     NULL, 'Published', @acc, DATEADD(day, -2, SYSDATETIME()), DATEADD(day, -2, SYSDATETIME())),
    (N'Ưu đãi vé cuối tuần: đồng giá 45K suất chiếu sáng',
     N'Từ nay đến hết tháng 11, mọi suất chiếu trước 10h sáng thứ Bảy và Chủ Nhật áp dụng giá vé đồng hạng chỉ 45.000đ cho ghế thường. Không áp dụng cùng voucher giảm giá khác.',
     NULL, 'Published', @acc, DATEADD(day, -1, SYSDATETIME()), DATEADD(day, -1, SYSDATETIME())),
    (N'Thông báo: lịch nghỉ lễ và giờ chiếu đặc biệt',
     N'Rạp mở cửa xuyên suốt dịp lễ, suất chiếu muộn nhất bắt đầu lúc 23h30. Khách hàng nên đặt vé trước trên website để tránh hết chỗ ở các suất prime-time từ 19h đến 21h.',
     NULL, 'Published', @acc, SYSDATETIME(), SYSDATETIME()),
    (N'Bản nháp: chương trình tri ân khách hàng thân thiết',
     N'Nội dung đang soạn: tặng điểm MyPoint gấp đôi cho mọi giao dịch trong tháng 12...',
     NULL, 'Draft', @acc, DATEADD(day, -1, SYSDATETIME()), DATEADD(day, -1, SYSDATETIME())),
    (N'Bản nháp: lịch chiếu phim Tết 2027',
     N'Đang chờ xác nhận từ nhà phát hành. Chưa công bố.',
     NULL, 'Draft', @acc, SYSDATETIME(), SYSDATETIME()),
    (N'Bài test nội bộ - không hiển thị',
     N'Tin này dùng để kiểm tra tab trạng thái Đã ẩn, khách hàng không bao giờ thấy.',
     NULL, 'Hidden', @acc, SYSDATETIME(), SYSDATETIME());
GO

PRINT N'Xong! Test login với 4 tài khoản (mật khẩu 123456), rồi mở /manager/news và /news.';
