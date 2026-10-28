/*
  Thong tin ca nhan mo rong cho Users (CMND/CCCD, tinh/thanh, quan/huyen, dia chi, anh dai dien).
  Chay tren DB DA TON TAI (DB tao moi tu sql/new.sql da co san cac cot nay). An toan khi chay lai.
    sqlcmd -S localhost -U sa -P <mat_khau> -C -d CinemaWebDB -I -i sql\migrate_user_profile.sql
*/
IF COL_LENGTH('dbo.Users', 'IdNumber')  IS NULL ALTER TABLE dbo.Users ADD IdNumber  VARCHAR(20)   NULL;
IF COL_LENGTH('dbo.Users', 'Province')  IS NULL ALTER TABLE dbo.Users ADD Province  NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'District')  IS NULL ALTER TABLE dbo.Users ADD District  NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.Users', 'Address')   IS NULL ALTER TABLE dbo.Users ADD Address   NVARCHAR(255) NULL;
IF COL_LENGTH('dbo.Users', 'AvatarUrl') IS NULL ALTER TABLE dbo.Users ADD AvatarUrl VARCHAR(100)  NULL;