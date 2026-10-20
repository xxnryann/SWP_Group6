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
