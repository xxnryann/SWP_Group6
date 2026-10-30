/* ----------------------------------------------------------------------------
   Migration: hoan tien chi ghi o MOT cho (dong thanh toan goc)

   Van de cu: sp_CancelTicket / sp_CancelMovie vua THEM dong Payment 'Refunded' cho lan hoan,
   vua cong don refunded_amount len dong goc -> tong refunded_amount / amount cua don bi tinh doi.

   Quy uoc moi: Payment.refunded_amount cua dong thanh toan goc la so tien da hoan (cong don);
   hoan du so tien -> status = 'Refunded'. Khong con dong Payment rieng cho tung lan hoan.

   File nay: (1) gop cac dong hoan cu vao dong goc, (2) xoa procedure khong dung sp_CancelBooking.
   Chay idempotent (chay lai khong doi gi). Sau khi chay, cap nhat procedure moi:
       scripts\compare-procedures.ps1 -Sync

   Chay bang sqlcmd voi -I (QUOTED_IDENTIFIER) :  sqlcmd -S <server> -d CinemaWebDB -I -i sql\migrate_refund_single_write.sql
   -------------------------------------------------------------------------- */
SET XACT_ABORT ON;
GO

BEGIN TRAN;

-- Dong goc = dong thanh toan co payment_id nho nhat (Success / Refunded) cua moi don.
-- Dong hoan cu = dong 'Refunded' co payment_id lon hon dong goc cung don.
SELECT p.payment_id, p.booking_id, p.amount
INTO #refund_rows
FROM dbo.Payment p
JOIN (SELECT booking_id, MIN(payment_id) AS first_id
      FROM dbo.Payment WHERE status IN ('Success', 'Refunded') GROUP BY booking_id) o
     ON o.booking_id = p.booking_id AND p.payment_id > o.first_id
WHERE p.status = 'Refunded';

-- Gop: so tien hoan cua dong goc = max(gia tri dang co, tong cac dong hoan cu), khong vuot amount.
UPDATE o SET
    o.refunded_amount = CASE WHEN x.total > o.refunded_amount THEN
                                  CASE WHEN x.total > o.amount THEN o.amount ELSE x.total END
                             ELSE o.refunded_amount END,
    o.status = CASE WHEN (CASE WHEN x.total > o.refunded_amount THEN
                                    CASE WHEN x.total > o.amount THEN o.amount ELSE x.total END
                               ELSE o.refunded_amount END) >= o.amount THEN 'Refunded' ELSE o.status END
FROM dbo.Payment o
JOIN (SELECT r.booking_id, SUM(r.amount) AS total FROM #refund_rows r GROUP BY r.booking_id) x
     ON x.booking_id = o.booking_id
JOIN (SELECT booking_id, MIN(payment_id) AS first_id
      FROM dbo.Payment WHERE status IN ('Success', 'Refunded') GROUP BY booking_id) f
     ON f.booking_id = o.booking_id AND f.first_id = o.payment_id;

DELETE p FROM dbo.Payment p JOIN #refund_rows r ON r.payment_id = p.payment_id;
PRINT CONCAT('Da gop ', @@ROWCOUNT, ' dong hoan tien cu vao dong thanh toan goc.');

DROP TABLE #refund_rows;
COMMIT;
GO

-- Procedure khong co noi nao goi (huy ca don duoc xu ly boi sp_CancelTicket / sp_CancelMovie).
DROP PROCEDURE IF EXISTS dbo.sp_CancelBooking;
GO
