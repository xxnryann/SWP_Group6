/*
    Migration for an existing CinemaWebDB:
    - Replace the five fixed TimeSlot rows with one neutral pricing dimension.
    - Preserve existing showtimes and the first slot's ticket pricing through the neutral row.
    - Configure six rooms: four 2D, one 3D and one IMAX.
    - Add seats for newly created rooms.
*/

USE CinemaWebDB;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @flexibleSlotId INT;

SELECT TOP (1) @flexibleSlotId = slot_id
FROM dbo.TimeSlot
ORDER BY slot_id;

IF @flexibleSlotId IS NULL
BEGIN
    INSERT dbo.TimeSlot(slot_name, start_time, end_time)
    VALUES (N'Flexible', '00:00', '23:59:59.9999999');
    SET @flexibleSlotId = CONVERT(INT, SCOPE_IDENTITY());
END
ELSE
BEGIN
    UPDATE dbo.TimeSlot
    SET slot_name = N'Flexible',
        start_time = '00:00',
        end_time = '23:59:59.9999999'
    WHERE slot_id = @flexibleSlotId;
END;

UPDATE dbo.Showtime
SET slot_id = @flexibleSlotId;

DELETE FROM dbo.TicketPrice
WHERE slot_id <> @flexibleSlotId;

DELETE FROM dbo.TimeSlot
WHERE slot_id <> @flexibleSlotId;

UPDATE dbo.Room SET room_type = '2D'
WHERE room_name IN (N'Phòng 1', N'Phòng 2', N'Phòng 3', N'Phòng 4');

IF NOT EXISTS (SELECT 1 FROM dbo.Room WHERE room_name = N'Phòng 5')
    INSERT dbo.Room(cinema_id, room_name, room_type, capacity)
    SELECT TOP (1) cinema_id, N'Phòng 5', '3D', 50
    FROM dbo.Cinema ORDER BY cinema_id;
ELSE
    UPDATE dbo.Room SET room_type = '3D' WHERE room_name = N'Phòng 5';

IF NOT EXISTS (SELECT 1 FROM dbo.Room WHERE room_name = N'Phòng 6')
    INSERT dbo.Room(cinema_id, room_name, room_type, capacity)
    SELECT TOP (1) cinema_id, N'Phòng 6', 'IMAX', 50
    FROM dbo.Cinema ORDER BY cinema_id;
ELSE
    UPDATE dbo.Room SET room_type = 'IMAX' WHERE room_name = N'Phòng 6';

INSERT dbo.Seat(room_id, row_label, seat_number, seat_type_id)
SELECT r.room_id, rw.row_label, n.seat_number,
       CASE WHEN rw.row_label IN ('A','B','C') THEN standardType.seat_type_id
            WHEN rw.row_label = 'D' THEN vipType.seat_type_id
            ELSE coupleType.seat_type_id END
FROM dbo.Room r
CROSS JOIN (VALUES ('A'),('B'),('C'),('D'),('E')) AS rw(row_label)
CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS n(seat_number)
CROSS JOIN (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'Standard') standardType
CROSS JOIN (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'VIP') vipType
CROSS JOIN (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'Couple') coupleType
WHERE r.room_name IN (N'Phòng 5', N'Phòng 6')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.Seat existing
      WHERE existing.room_id = r.room_id
  );

UPDATE s
SET s.pair_seat_id = p.seat_id
FROM dbo.Seat s
JOIN dbo.Seat p ON p.room_id = s.room_id
               AND p.row_label = s.row_label
               AND p.seat_number = CASE WHEN s.seat_number % 2 = 1
                                         THEN s.seat_number + 1
                                         ELSE s.seat_number - 1 END
WHERE s.seat_type_id = (SELECT seat_type_id FROM dbo.SeatType WHERE type_name = N'Couple');

COMMIT TRANSACTION;
GO
