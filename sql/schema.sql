-- SQL Server schema for the Account module
IF DB_ID('CinemaDB') IS NULL CREATE DATABASE CinemaDB;
GO
USE CinemaDB;
GO

IF OBJECT_ID('dbo.PointTransactions') IS NOT NULL DROP TABLE dbo.PointTransactions;
IF OBJECT_ID('dbo.Tickets') IS NOT NULL DROP TABLE dbo.Tickets;
IF OBJECT_ID('dbo.Users') IS NOT NULL DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    UserId       INT IDENTITY(1,1) PRIMARY KEY,
    FullName     NVARCHAR(100)  NOT NULL,
    Email        NVARCHAR(150)  NOT NULL,
    Phone        VARCHAR(15)    NOT NULL,
    PasswordHash VARCHAR(100)   NOT NULL,            -- BCrypt
    DateOfBirth  DATE           NULL,
    Gender       VARCHAR(10)    NULL,                -- MALE / FEMALE / OTHER
    Role         VARCHAR(20)    NOT NULL DEFAULT 'CUSTOMER',   -- CUSTOMER / STAFF / MANAGER / ADMIN
    Status       VARCHAR(20)    NOT NULL DEFAULT 'PENDING',    -- PENDING / ACTIVE / BLOCKED
    OtpHash      VARCHAR(64)    NULL,                -- SHA-256 of the OTP
    OtpExpiry    DATETIME2      NULL,
    OtpAttempts  INT            NOT NULL DEFAULT 0,
    MyPoint      INT            NOT NULL DEFAULT 0,
    CreatedAt    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT UQ_Users_Phone UNIQUE (Phone),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('PENDING','ACTIVE','BLOCKED')),
    CONSTRAINT CK_Users_Role   CHECK (Role   IN ('CUSTOMER','STAFF','MANAGER','ADMIN'))
);
GO

-- Ticket history (filled by the booking module; Status: PAID / CANCELLED / USED)
CREATE TABLE dbo.Tickets (
    TicketId    INT IDENTITY(1,1) PRIMARY KEY,
    UserId      INT            NOT NULL REFERENCES dbo.Users(UserId),
    MovieTitle  NVARCHAR(200)  NOT NULL,
    CinemaName  NVARCHAR(150)  NOT NULL,
    RoomName    NVARCHAR(50)   NOT NULL,
    Seats       NVARCHAR(100)  NOT NULL,
    ShowTime    DATETIME2      NOT NULL,
    TotalPrice  DECIMAL(12,0)  NOT NULL,
    Status      VARCHAR(20)    NOT NULL DEFAULT 'PAID',
    CreatedAt   DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Tickets_Status CHECK (Status IN ('PAID','CANCELLED','USED'))
);
CREATE INDEX IX_Tickets_User ON dbo.Tickets(UserId, CreatedAt DESC);
GO

-- MyPoint ledger: Points > 0 earned, < 0 redeemed
CREATE TABLE dbo.PointTransactions (
    TxId       INT IDENTITY(1,1) PRIMARY KEY,
    UserId     INT            NOT NULL REFERENCES dbo.Users(UserId),
    Points     INT            NOT NULL,
    Reason     NVARCHAR(200)  NOT NULL,
    TicketId   INT            NULL REFERENCES dbo.Tickets(TicketId),
    CreatedAt  DATETIME2      NOT NULL DEFAULT SYSDATETIME()
);
CREATE INDEX IX_PointTx_User ON dbo.PointTransactions(UserId, CreatedAt DESC);
GO

-- First admin: register a normal account on the site, verify the OTP, then run:
--   UPDATE dbo.Users SET Role = 'ADMIN' WHERE Email = N'your-email@example.com';

-- =====================================================================
-- SEED DATA (demo accounts). Password of EVERY account below: Cinema@123
--   admin@cinema.local     ADMIN     ACTIVE
--   manager@cinema.local   MANAGER   ACTIVE
--   staff@cinema.local     STAFF     ACTIVE
--   an@cinema.local        CUSTOMER  ACTIVE   (has tickets + points)
--   binh@cinema.local      CUSTOMER  ACTIVE   (has tickets + points)
--   chi@cinema.local       CUSTOMER  ACTIVE   (new, no history)
--   blocked@cinema.local   CUSTOMER  BLOCKED  (cannot log in)
--   pending@cinema.local   CUSTOMER  PENDING  (OTP not verified)
-- =====================================================================
INSERT INTO dbo.Users (FullName, Email, Phone, PasswordHash, DateOfBirth, Gender, Role, Status, MyPoint) VALUES
(N'Quản trị viên',   N'admin@cinema.local',   '0900000001', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1995-01-15', 'MALE',   'ADMIN',    'ACTIVE',  0),
(N'Quản lý rạp',     N'manager@cinema.local', '0900000002', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1992-03-20', 'FEMALE', 'MANAGER',  'ACTIVE',  0),
(N'Nhân viên bán vé',N'staff@cinema.local',   '0900000003', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1999-07-08', 'MALE',   'STAFF',    'ACTIVE',  0),
(N'Nguyễn Văn An',   N'an@cinema.local',      '0911111111', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2002-02-27', 'MALE',   'CUSTOMER', 'ACTIVE',  250),
(N'Trần Thị Bình',   N'binh@cinema.local',    '0922222222', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2001-11-05', 'FEMALE', 'CUSTOMER', 'ACTIVE',  120),
(N'Lê Minh Chi',     N'chi@cinema.local',     '0933333333', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2003-06-30', 'OTHER',  'CUSTOMER', 'ACTIVE',  0),
(N'Tài khoản bị khoá',N'blocked@cinema.local','0944444444', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2000-09-09', 'MALE',   'CUSTOMER', 'BLOCKED', 0),
(N'Chưa xác thực OTP',N'pending@cinema.local','0955555555', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2000-12-12', 'FEMALE', 'CUSTOMER', 'PENDING', 0);
GO

DECLARE @an INT   = (SELECT UserId FROM dbo.Users WHERE Email = N'an@cinema.local');
DECLARE @binh INT = (SELECT UserId FROM dbo.Users WHERE Email = N'binh@cinema.local');

INSERT INTO dbo.Tickets (UserId, MovieTitle, CinemaName, RoomName, Seats, ShowTime, TotalPrice, Status, CreatedAt) VALUES
(@an,   N'Mai',                   N'CinemaWeb Hà Nội',  N'Phòng 1', N'E5, E6',   '2026-10-05 19:30', 180000, 'USED',      '2026-10-03 10:15'),
(@an,   N'Đào, Phở và Piano',     N'CinemaWeb Hà Nội',  N'Phòng 2', N'C10',      '2026-10-12 20:00',  90000, 'USED',      '2026-10-10 14:00'),
(@an,   N'Avengers: Secret Wars', N'CinemaWeb Đà Nẵng', N'Phòng 3', N'G7, G8',   '2026-11-01 21:00', 240000, 'PAID',      '2026-10-18 09:30'),
(@an,   N'Kung Fu Panda 5',       N'CinemaWeb Hà Nội',  N'Phòng 1', N'A1',       '2026-10-15 15:00',  80000, 'CANCELLED', '2026-10-13 16:45'),
(@binh, N'Mai',                   N'CinemaWeb Hồ Chí Minh', N'Phòng 4', N'D3, D4', '2026-10-08 18:00', 200000, 'USED',    '2026-10-06 11:20'),
(@binh, N'Avengers: Secret Wars', N'CinemaWeb Hồ Chí Minh', N'Phòng 2', N'F9',     '2026-11-02 19:00', 120000, 'PAID',    '2026-10-19 08:10');

INSERT INTO dbo.PointTransactions (UserId, Points, Reason, TicketId, CreatedAt)
SELECT @an,   180, N'Tích điểm từ vé Mai',                 TicketId, '2026-10-05 22:00' FROM dbo.Tickets WHERE UserId=@an   AND MovieTitle=N'Mai'
UNION ALL
SELECT @an,    90, N'Tích điểm từ vé Đào, Phở và Piano',   TicketId, '2026-10-12 22:30' FROM dbo.Tickets WHERE UserId=@an   AND MovieTitle=N'Đào, Phở và Piano'
UNION ALL
SELECT @an,   -20, N'Đổi điểm giảm giá bắp nước',          NULL,     '2026-10-12 19:50'
UNION ALL
SELECT @binh, 120, N'Tích điểm từ vé Mai',                 TicketId, '2026-10-08 21:00' FROM dbo.Tickets WHERE UserId=@binh AND MovieTitle=N'Mai';
GO
