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
    CreatedAt    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT UQ_Users_Phone UNIQUE (Phone),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('PENDING','ACTIVE','BLOCKED')),
    CONSTRAINT CK_Users_Role   CHECK (Role   IN ('CUSTOMER','STAFF','MANAGER','ADMIN'))
);
GO

-- Ticket history and MyPoint come from the shared booking schema (sql/new.sql: Booking, Ticket, MyPointTransaction).

-- First admin: register a normal account on the site, verify the OTP, then run:
--   UPDATE dbo.Users SET Role = 'ADMIN' WHERE Email = N'your-email@example.com';

-- =====================================================================
-- SEED DATA (demo accounts). Password of EVERY account below: Cinema@123
--   admin@cinema.local     ADMIN     ACTIVE
--   manager@cinema.local   MANAGER   ACTIVE
--   staff@cinema.local     STAFF     ACTIVE
--   an@cinema.local        CUSTOMER  ACTIVE   
--   binh@cinema.local      CUSTOMER  ACTIVE   
--   chi@cinema.local       CUSTOMER  ACTIVE
--   blocked@cinema.local   CUSTOMER  BLOCKED  (cannot log in)
--   pending@cinema.local   CUSTOMER  PENDING  (OTP not verified)
-- =====================================================================
INSERT INTO dbo.Users (FullName, Email, Phone, PasswordHash, DateOfBirth, Gender, Role, Status) VALUES
(N'Quản trị viên',   N'admin@cinema.local',   '0900000001', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1995-01-15', 'MALE',   'ADMIN',    'ACTIVE'),
(N'Quản lý rạp',     N'manager@cinema.local', '0900000002', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1992-03-20', 'FEMALE', 'MANAGER',  'ACTIVE'),
(N'Nhân viên bán vé',N'staff@cinema.local',   '0900000003', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '1999-07-08', 'MALE',   'STAFF',    'ACTIVE'),
(N'Nguyễn Văn An',   N'an@cinema.local',      '0911111111', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2002-02-27', 'MALE',   'CUSTOMER', 'ACTIVE'),
(N'Trần Thị Bình',   N'binh@cinema.local',    '0922222222', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2001-11-05', 'FEMALE', 'CUSTOMER', 'ACTIVE'),
(N'Lê Minh Chi',     N'chi@cinema.local',     '0933333333', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2003-06-30', 'OTHER',  'CUSTOMER', 'ACTIVE'),
(N'Tài khoản bị khoá',N'blocked@cinema.local','0944444444', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2000-09-09', 'MALE',   'CUSTOMER', 'BLOCKED'),
(N'Chưa xác thực OTP',N'pending@cinema.local','0955555555', '$2a$10$BZ/sxHUKkDd7RTWDEd7B..e40UKIqsOTBudmxYWmZ7QXFLnIXJC5K', '2000-12-12', 'FEMALE', 'CUSTOMER', 'PENDING');
GO
