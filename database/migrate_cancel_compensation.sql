/*
    Hoan diem + voucher bu tru khi huy suat chieu (DB tao moi tu schema.sql da co san, khong can chay file nay).
      - Voucher.owner_customer_id: NULL = voucher cong khai, co gia tri = voucher ca nhan (chi chu so huu ap duoc)
    Chay lai nhieu lan van an toan. Sau do dong bo procedure tu schema.sql
    (sp_CancelMovie, sp_ApplyVoucher, sp_QueueVoucherEmail):

    sqlcmd -S "tcp:localhost,1433" -U sa -C -I -b -f 65001 -d CinemaWebDB -i database/migrate_cancel_compensation.sql
    powershell -ExecutionPolicy Bypass -File scripts/compare-procedures.ps1 -Sync
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH('dbo.Voucher', 'owner_customer_id') IS NULL
    ALTER TABLE dbo.Voucher ADD owner_customer_id INT NULL;
GO

IF OBJECT_ID('dbo.FK_Voucher_Owner', 'F') IS NULL
    ALTER TABLE dbo.Voucher ADD CONSTRAINT FK_Voucher_Owner
        FOREIGN KEY (owner_customer_id) REFERENCES dbo.Customer(customer_id);
GO

PRINT N'[OK] Voucher.owner_customer_id. Chay tiep compare-procedures.ps1 -Sync de cap nhat procedure.';
