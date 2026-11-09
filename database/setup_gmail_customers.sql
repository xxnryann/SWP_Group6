-- Chay SAU schema.sql + seed.sql tren may khac de dung chung 3 tai khoan khach
-- dungcaohung2410+khach1/2/3@gmail.com (mat khau 123456) giong may chu.
-- Chay lai nhieu lan van an toan.
USE CinemaWebDB;
SET QUOTED_IDENTIFIER ON;
GO

-- khach1, khach2: doi email tu seed sang Gmail alias
UPDATE dbo.Account SET email = N'dungcaohung2410+khach1@gmail.com' WHERE account_id = 4;
UPDATE dbo.Account SET email = N'dungcaohung2410+khach2@gmail.com' WHERE account_id = 5;
UPDATE dbo.Users   SET Email = N'dungcaohung2410+khach1@gmail.com' WHERE UserId = 4;
UPDATE dbo.Users   SET Email = N'dungcaohung2410+khach2@gmail.com' WHERE UserId = 5;
GO

-- khach3: seed khong co -> tao moi (id 6), mat khau 123456 (cung hash voi seed)
IF NOT EXISTS (SELECT 1 FROM dbo.Account WHERE email = N'dungcaohung2410+khach3@gmail.com')
BEGIN
    DECLARE @id INT = CASE WHEN EXISTS (SELECT 1 FROM dbo.Account WHERE account_id = 6) THEN NULL ELSE 6 END;
    IF @id IS NULL
    BEGIN
        INSERT dbo.Account (role_id, full_name, email, phone, password_hash, status)
        VALUES (4, N'Nguyễn Minh Chiến', N'dungcaohung2410+khach3@gmail.com', '0932523443',
                '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active');
        SET @id = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        SET IDENTITY_INSERT dbo.Account ON;
        INSERT dbo.Account (account_id, role_id, full_name, email, phone, password_hash, status)
        VALUES (6, 4, N'Nguyễn Minh Chiến', N'dungcaohung2410+khach3@gmail.com', '0932523443',
                '$2a$12$ln5sTwQVMwH5waVgtDmxJOiZ9KzquzuB2pmistvei4mGJZcQeHCmi', 'Active');
        SET IDENTITY_INSERT dbo.Account OFF;
    END
    IF NOT EXISTS (SELECT 1 FROM dbo.Customer WHERE customer_id = @id)
        INSERT dbo.Customer (customer_id, my_point_balance, total_spent) VALUES (@id, 0, 0);
END
GO

SELECT account_id, email FROM dbo.Account WHERE email LIKE N'dungcaohung2410+%';
