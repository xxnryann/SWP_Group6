USE [CinemaWebDB];
GO

-- Combo image URL, stock-independent combo ordering, and full MyPoint redemption.
IF COL_LENGTH('dbo.Combo', 'image_url') IS NULL
BEGIN
    ALTER TABLE dbo.Combo ADD image_url NVARCHAR(500) NULL;
END
GO

DROP PROCEDURE IF EXISTS dbo.sp_AddCombo;
GO
CREATE PROCEDURE dbo.sp_AddCombo @booking_id INT, @combo_id INT, @quantity INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @status VARCHAR(15) = (SELECT status FROM dbo.Booking WHERE booking_id = @booking_id);
    IF @status IS NULL OR @status NOT IN ('Selecting','PendingPayment') THROW 50020, N'Booking không còn hiệu lực.', 1;
    IF @quantity <= 0
        DELETE FROM dbo.BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id;
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Combo WHERE combo_id = @combo_id AND status = 'Active')
            THROW 50021, N'Combo không tồn tại hoặc không còn bán.', 1;
        IF EXISTS (SELECT 1 FROM dbo.BookingCombo WHERE booking_id = @booking_id AND combo_id = @combo_id)
            UPDATE dbo.BookingCombo SET quantity = @quantity WHERE booking_id = @booking_id AND combo_id = @combo_id;
        ELSE
            INSERT INTO dbo.BookingCombo(booking_id, combo_id, quantity, unit_price)
            SELECT @booking_id, combo_id, @quantity, price FROM dbo.Combo WHERE combo_id = @combo_id;
    END
    EXEC dbo.sp_RecalcBooking @booking_id;
END
GO

DROP PROCEDURE IF EXISTS dbo.sp_ConfirmPayment;
GO
CREATE PROCEDURE dbo.sp_ConfirmPayment
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

DROP PROCEDURE IF EXISTS dbo.sp_CancelTicket;
GO
CREATE PROCEDURE dbo.sp_CancelTicket
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

DROP PROCEDURE IF EXISTS dbo.sp_CancelCombo;
GO
CREATE PROCEDURE dbo.sp_CancelCombo @booking_id INT, @account_id INT AS
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

DROP PROCEDURE IF EXISTS dbo.sp_CancelMovie;
GO
CREATE PROCEDURE dbo.sp_CancelMovie @movie_id INT, @manager_id INT, @confirm BIT = 0 AS
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

DROP PROCEDURE IF EXISTS dbo.sp_ApplyMyPoint;
GO
CREATE PROCEDURE dbo.sp_ApplyMyPoint @booking_id INT, @points INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @customer_id INT, @status VARCHAR(15), @base DECIMAL(12,0), @pt_value INT, @disc DECIMAL(12,0);
    SELECT @customer_id = customer_id, @status = status, @base = ticket_total + combo_total - voucher_discount
    FROM dbo.Booking WHERE booking_id = @booking_id;
    SELECT TOP 1 @pt_value = point_value_vnd
    FROM dbo.MyPointConfig WHERE is_active = 1 ORDER BY effective_from DESC, config_id DESC;

    IF @status IS NULL OR @status <> 'PendingPayment' THROW 50040, N'Chỉ dùng MyPoint ở bước thanh toán.', 1;
    IF @customer_id IS NULL THROW 50041, N'Khách mua tại quầy không có tài khoản MyPoint.', 1;
    IF @points < 0 THROW 50042, N'Số điểm không hợp lệ.', 1;
    IF @points > (SELECT my_point_balance FROM dbo.Customer WHERE customer_id = @customer_id)
        THROW 50043, N'Số dư MyPoint không đủ.', 1;

    IF @points > FLOOR(@base / @pt_value)
        SET @points = FLOOR(@base / @pt_value);
    SET @disc = @points * @pt_value;

    UPDATE dbo.Booking SET points_used = @points, points_discount = @disc WHERE booking_id = @booking_id;
    EXEC dbo.sp_RecalcBooking @booking_id;
END
GO

UPDATE dbo.MyPointConfig SET max_redeem_percent = 100 WHERE is_active = 1;
GO

PRINT N'[OK] CinemaWebDB combo image and MyPoint migration completed.';
GO
