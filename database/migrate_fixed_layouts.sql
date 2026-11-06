/*
    Dua moi phong 2D, 3D, IMAX va 4DX ve layout co dinh:
      2D   (124 ghe): A-D Standard, E-H VIP moi hang 14 ghe; J Couple 6 cap.
      3D   (107 ghe): A/B/C Standard 12/13/14 ghe; D-G VIP moi hang 14 ghe; H Couple 6 cap.
      IMAX ( 40 ghe): A-B Standard, C-D VIP moi hang 8 ghe; E Couple 4 cap.
      4DX  ( 66 ghe): A 8 Standard; B 12 ghe (B5-B8 VIP, con lai Standard); C-E VIP moi hang 12 ghe; F Couple 5 cap.
    Giu seat_id cua ghe con dung nen lich su ve khong mat; chay lai nhieu lan van an toan.
    Dung lai va khong doi gi neu ghe can doi loai/xoa dang co ve con hieu luc, hoac ghe can xoa da co lich su ve.

    sqlcmd -S localhost -E -C -I -b -f i:65001 -d CinemaWebDB -i database/migrate_fixed_layouts.sql
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

DECLARE @standard INT = (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'Standard');
DECLARE @vip INT = (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'VIP');
DECLARE @couple INT = (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'Couple');
IF @standard IS NULL OR @vip IS NULL OR @couple IS NULL
    THROW 50100, N'Thieu loai ghe Standard, VIP hoac Couple.', 1;

DECLARE @want TABLE (room_id INT, row_label CHAR(1), seat_number INT, seat_type_id INT, PRIMARY KEY (room_id, row_label, seat_number));
INSERT INTO @want
SELECT r.room_id, rw.row_label, n.seat_number, rw.seat_type_id
FROM dbo.Room r
JOIN (VALUES ('2D','A',@standard,14),('2D','B',@standard,14),('2D','C',@standard,14),('2D','D',@standard,14),
             ('2D','E',@vip,14),('2D','F',@vip,14),('2D','G',@vip,14),('2D','H',@vip,14),('2D','J',@couple,12),
             ('3D','A',@standard,12),('3D','B',@standard,13),('3D','C',@standard,14),
             ('3D','D',@vip,14),('3D','E',@vip,14),('3D','F',@vip,14),('3D','G',@vip,14),('3D','H',@couple,12),
             ('IMAX','A',@standard,8),('IMAX','B',@standard,8),
             ('IMAX','C',@vip,8),('IMAX','D',@vip,8),('IMAX','E',@couple,8),
             ('4DX','A',@standard,8),('4DX','B',@standard,12),
             ('4DX','C',@vip,12),('4DX','D',@vip,12),('4DX','E',@vip,12),('4DX','F',@couple,10)
     ) AS rw(room_type, row_label, seat_type_id, seats) ON rw.room_type = r.room_type
JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14)) AS n(seat_number) ON n.seat_number <= rw.seats;

-- Hang B cua 4DX co cum giua la VIP.
UPDATE w SET w.seat_type_id = @vip
FROM @want w JOIN dbo.Room r ON r.room_id = w.room_id AND r.room_type = '4DX'
WHERE w.row_label = 'B' AND w.seat_number BETWEEN 5 AND 8;

IF EXISTS (
    SELECT 1
    FROM dbo.Seat s
    JOIN dbo.Room r ON r.room_id = s.room_id AND r.room_type IN ('2D','3D','IMAX','4DX')
    LEFT JOIN @want w ON w.room_id = s.room_id AND w.row_label = s.row_label AND w.seat_number = s.seat_number
    JOIN dbo.Ticket t ON t.seat_id = s.seat_id
    JOIN dbo.Showtime st ON st.showtime_id = t.showtime_id
    JOIN dbo.Booking b ON b.booking_id = t.booking_id
    WHERE (w.seat_type_id IS NULL OR w.seat_type_id <> s.seat_type_id)
      AND st.status = 'Scheduled' AND st.end_time > SYSDATETIME()
      AND (t.status IN ('Booked','Used') OR (t.status = 'Held' AND b.payment_expires_at > SYSDATETIME())))
    THROW 50101, N'Co ghe can doi loai hoac xoa dang co ve con hieu luc. Hay doi ghe cho khach truoc.', 1;

DECLARE @remove TABLE (seat_id INT PRIMARY KEY);
INSERT INTO @remove
SELECT s.seat_id
FROM dbo.Seat s
JOIN dbo.Room r ON r.room_id = s.room_id AND r.room_type IN ('2D','3D','IMAX','4DX')
LEFT JOIN @want w ON w.room_id = s.room_id AND w.row_label = s.row_label AND w.seat_number = s.seat_number
WHERE w.room_id IS NULL;

IF EXISTS (SELECT 1 FROM @remove x JOIN dbo.Ticket t ON t.seat_id = x.seat_id)
   OR EXISTS (SELECT 1 FROM @remove x JOIN dbo.TicketChangeHistory h ON x.seat_id IN (h.old_seat_id, h.new_seat_id))
    THROW 50102, N'Co ghe nam ngoai layout moi da co lich su ve nen khong xoa duoc.', 1;

UPDATE s SET s.pair_seat_id = NULL
FROM dbo.Seat s JOIN dbo.Room r ON r.room_id = s.room_id AND r.room_type IN ('2D','3D','IMAX','4DX');

DELETE s FROM dbo.Seat s JOIN @remove x ON x.seat_id = s.seat_id;

UPDATE s SET s.seat_type_id = w.seat_type_id
FROM dbo.Seat s
JOIN @want w ON w.room_id = s.room_id AND w.row_label = s.row_label AND w.seat_number = s.seat_number
WHERE s.seat_type_id <> w.seat_type_id;

INSERT INTO dbo.Seat (room_id, row_label, seat_number, seat_type_id, pair_seat_id, status)
SELECT w.room_id, w.row_label, w.seat_number, w.seat_type_id, NULL, 'Active'
FROM @want w
LEFT JOIN dbo.Seat s ON s.room_id = w.room_id AND s.row_label = w.row_label AND s.seat_number = w.seat_number
WHERE s.seat_id IS NULL
ORDER BY w.room_id, w.row_label, w.seat_number;

UPDATE s SET s.pair_seat_id = p.seat_id
FROM dbo.Seat s
JOIN dbo.Room r ON r.room_id = s.room_id AND r.room_type IN ('2D','3D','IMAX','4DX')
JOIN dbo.Seat p ON p.room_id = s.room_id AND p.row_label = s.row_label
    AND p.seat_number = CASE WHEN s.seat_number % 2 = 1 THEN s.seat_number + 1 ELSE s.seat_number - 1 END
WHERE s.seat_type_id = @couple;

-- Mot ghe cua cap dang bao tri thi ca cap khong ban duoc.
UPDATE s SET s.status = 'Maintenance'
FROM dbo.Seat s
JOIN dbo.Seat p ON p.seat_id = s.pair_seat_id
JOIN dbo.Room r ON r.room_id = s.room_id AND r.room_type IN ('2D','3D','IMAX','4DX')
WHERE p.status = 'Maintenance';

UPDATE dbo.Room SET capacity = CASE room_type WHEN 'IMAX' THEN 40 WHEN '3D' THEN 107 WHEN '4DX' THEN 66 ELSE 124 END WHERE room_type IN ('2D','3D','IMAX','4DX');

SELECT r.room_id, r.room_name, r.room_type, r.capacity, COUNT(*) AS seats,
       SUM(CASE WHEN t.type_name = 'Standard' THEN 1 ELSE 0 END) AS standard_seats,
       SUM(CASE WHEN t.type_name = 'VIP' THEN 1 ELSE 0 END) AS vip_seats,
       SUM(CASE WHEN t.type_name = 'Couple' THEN 1 ELSE 0 END) AS couple_seats,
       SUM(CASE WHEN s.pair_seat_id IS NOT NULL THEN 1 ELSE 0 END) AS paired_seats
FROM dbo.Room r
JOIN dbo.Seat s ON s.room_id = r.room_id
JOIN dbo.SeatType t ON t.seat_type_id = s.seat_type_id
WHERE r.room_type IN ('2D','3D','IMAX','4DX')
GROUP BY r.room_id, r.room_name, r.room_type, r.capacity
ORDER BY r.room_id;

COMMIT;
