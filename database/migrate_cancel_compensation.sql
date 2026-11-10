/*
    Hoan diem + voucher den bu khi huy suat chieu (DB tao moi tu schema.sql + seed.sql da co san, khong can chay file nay).
      - Voucher.is_compensation, Voucher.grant_valid_days (voucher den bu, khong cong khai)
      - Bang VoucherGrant: luot voucher den bu cap cho khach (moi don bi huy = 1 luot, co han rieng)
      - Voucher DENBU25 (giam 25.000d, moi luot han 30 ngay)
    Chay lai nhieu lan van an toan. Sau do dong bo procedure tu schema.sql
    (sp_CancelMovie, sp_ApplyVoucher, sp_ConfirmPayment, sp_QueueVoucherEmail):

    sqlcmd -S "tcp:localhost,1433" -U sa -C -I -b -f 65001 -d CinemaWebDB -i database/migrate_cancel_compensation.sql
    powershell -ExecutionPolicy Bypass -File scripts/compare-procedures.ps1 -Sync
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Ban thu truoc (voucher ca nhan theo chu so huu) da bo.
IF OBJECT_ID('dbo.FK_Voucher_Owner', 'F') IS NOT NULL
    ALTER TABLE dbo.Voucher DROP CONSTRAINT FK_Voucher_Owner;
IF COL_LENGTH('dbo.Voucher', 'owner_customer_id') IS NOT NULL
    ALTER TABLE dbo.Voucher DROP COLUMN owner_customer_id;
GO

IF COL_LENGTH('dbo.Voucher', 'is_compensation') IS NULL
    ALTER TABLE dbo.Voucher ADD is_compensation BIT NOT NULL CONSTRAINT DF_Voucher_Compensation DEFAULT 0;
IF COL_LENGTH('dbo.Voucher', 'grant_valid_days') IS NULL
    ALTER TABLE dbo.Voucher ADD grant_valid_days INT NULL;
GO

IF OBJECT_ID('dbo.CK_Voucher_GrantDays', 'C') IS NULL
    ALTER TABLE dbo.Voucher ADD CONSTRAINT CK_Voucher_GrantDays CHECK (grant_valid_days IS NULL OR grant_valid_days > 0);
GO

IF OBJECT_ID('dbo.VoucherGrant', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.VoucherGrant (
        grant_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VoucherGrant PRIMARY KEY,
        voucher_id INT NOT NULL,
        customer_id INT NOT NULL,
        booking_id INT NULL,
        granted_at DATETIME2(7) NOT NULL CONSTRAINT DF_VoucherGrant_Granted DEFAULT SYSDATETIME(),
        expires_at DATE NOT NULL,
        used_booking_id INT NULL,
        used_at DATETIME2(7) NULL,
        CONSTRAINT FK_VoucherGrant_Voucher FOREIGN KEY (voucher_id) REFERENCES dbo.Voucher(voucher_id),
        CONSTRAINT FK_VoucherGrant_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
        CONSTRAINT FK_VoucherGrant_Booking FOREIGN KEY (booking_id) REFERENCES dbo.Booking(booking_id),
        CONSTRAINT FK_VoucherGrant_UsedBooking FOREIGN KEY (used_booking_id) REFERENCES dbo.Booking(booking_id)
    );
    CREATE INDEX IX_VoucherGrant_Customer ON dbo.VoucherGrant(customer_id, voucher_id, expires_at);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Voucher WHERE code = 'DENBU25')
    INSERT dbo.Voucher(code, description, discount_type, discount_value, max_discount, min_order_amount,
                       min_cumulative_spending, usage_limit, used_count, per_customer_limit, valid_from, valid_to, status,
                       created_by, is_compensation, grant_valid_days)
    VALUES ('DENBU25', N'Voucher đền bù 25.000đ khi rạp hủy suất chiếu', 'Amount', 25000, NULL, 0, 0, 1000000, 0, 1,
            '2026-01-01', '2099-12-31', 'Allowed', 2, 1, 30);
GO

PRINT N'[OK] Voucher den bu DENBU25 + VoucherGrant. Chay tiep compare-procedures.ps1 -Sync de cap nhat procedure.';
