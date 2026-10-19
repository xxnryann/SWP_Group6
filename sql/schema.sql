-- SQL Server schema for the Account module
IF DB_ID('CinemaDB') IS NULL CREATE DATABASE CinemaDB;
GO
USE CinemaDB;
GO

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
