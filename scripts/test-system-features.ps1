<#
.SYNOPSIS
    Kiem thu 4 chuc nang: Receive Email Notifications (29), Showtime Reminder Email (31),
    Ticket Check-in QR (32), System Management (38).

.DESCRIPTION
    Thao tac that qua HTTP va stored procedure. GHI VAO CSDL nhung tu dua du lieu ve nhu cu:
    phim/voucher ZZTEST, thong bao, nhat ky do test sinh ra deu bi xoa o cuoi; ve va suat chieu
    muon tam duoc khoi phuc. Moi lan chay tao MOT file .bak that trong thu muc backup cua SQL Server.

    Can Node.js de giai ma anh QR bang web/assets/js/vendor/jsQR.js.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\test-system-features.ps1 -BaseUrl http://localhost:9999/CinemaTest
#>
[CmdletBinding()]
param(
    [string]$BaseUrl,
    [string]$Server = 'localhost,1433',
    [string]$Database = 'CinemaWebDB'
)

. "$PSScriptRoot/lib/test-config.ps1"
. "$PSScriptRoot/lib/booking-test-lib.ps1"
if (-not $BaseUrl) { $BaseUrl = Get-CinemaBaseUrl }
$BaseUrl = $BaseUrl.TrimEnd('/')
$script:Failures = @()
$auth = Get-SqlCmdAuth
$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ("cinema-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
$bom = New-Object Text.UTF8Encoding($true)

function Sql([string]$query) {
    $in = Join-Path $tmpDir 'q.sql'; $out = Join-Path $tmpDir 'o.txt'
    [IO.File]::WriteAllText($in, "SET NOCOUNT ON;`n$query", $bom)
    & sqlcmd -S $Server -d $Database @auth -C -I -f 65001 -W -h -1 -s '|' -i $in -o $out
    @(Get-Content $out -Encoding UTF8 | Where-Object { $_ -ne '' })
}
function Scalar([string]$query) { "$(Sql $query | Select-Object -First 1)".Trim() }

function Html($session, [string]$path) {
    try {
        $r = Invoke-WebRequest "$BaseUrl$path" -WebSession $session -UseBasicParsing -TimeoutSec 90
        [pscustomobject]@{ Code = [int]$r.StatusCode; Text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) }
    } catch {
        $resp = $_.Exception.Response
        [pscustomobject]@{ Code = $(if ($resp) { [int]$resp.StatusCode } else { 0 }); Text = '' }
    }
}
function Post($session, [string]$path, [hashtable]$fields, [string]$csrfPage) {
    $page = (Html $session $(if ($csrfPage) { $csrfPage } else { $path })).Text
    $csrf = [regex]::Match($page, 'name="_csrf"\s+value="([^"]+)"').Groups[1].Value
    $pairs = @("_csrf=$([uri]::EscapeDataString($csrf))")
    foreach ($k in $fields.Keys) { $pairs += "$k=$([uri]::EscapeDataString([string]$fields[$k]))" }
    try {
        $r = Invoke-WebRequest "$BaseUrl$path" -Method Post -WebSession $session -UseBasicParsing -TimeoutSec 180 `
            -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' -Body ([Text.Encoding]::UTF8.GetBytes(($pairs -join '&')))
        $text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
        [pscustomobject]@{ Code = [int]$r.StatusCode; Text = $text
            Flash = [Net.WebUtility]::HtmlDecode([regex]::Match($text, 'data-flash="([^"]*)"').Groups[1].Value)
            FlashType = [regex]::Match($text, 'data-flash-type="([^"]*)"').Groups[1].Value }
    } catch {
        $resp = $_.Exception.Response
        [pscustomobject]@{ Code = $(if ($resp) { [int]$resp.StatusCode } else { 0 }); Text = ''; Flash = ''; FlashType = '' }
    }
}
function Wait-Until([scriptblock]$check, [int]$seconds = 100) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        if (& $check) { return $true }
        Start-Sleep -Seconds 5
    }
    return $false
}

$admin = New-BookingSession -BaseUrl $BaseUrl -Email 'admin@cinema.vn'
$manager = New-BookingSession -BaseUrl $BaseUrl -Email 'manager@cinema.vn'
$staff = New-BookingSession -BaseUrl $BaseUrl -Email 'staff@cinema.vn'
$customer = New-BookingSession -BaseUrl $BaseUrl -Email 'khach1@gmail.com'
$cust = [int](Scalar "SELECT account_id FROM dbo.Account WHERE email='khach1@gmail.com';")

# Moc de don du lieu test sinh ra.
$notif0 = [int](Scalar 'SELECT ISNULL(MAX(notif_id),0) FROM dbo.EmailNotification;')
$log0 = [int](Scalar 'SELECT ISNULL(MAX(log_id),0) FROM dbo.SystemLog;')
$activeCustomers = [int](Scalar "SELECT COUNT(*) FROM dbo.Customer c JOIN dbo.Account a ON a.account_id=c.customer_id WHERE a.status='Active';")
$configBackup = Sql "SELECT config_key + '|' + config_value FROM dbo.SystemConfig;"
$voucherCode = 'ZZTESTVC' + (Get-Random -Maximum 99999)
$richVoucher = 'ZZTESTVR' + (Get-Random -Maximum 99999)
$movieTitle = 'ZZTEST PHIM ' + (Get-Random -Maximum 99999)
$restore = @()

try {
    # ==================== 31. Showtime Reminder ====================
    Write-Step '31. Showtime Reminder Email (job nen)'
    $bk = Sql "SELECT TOP 1 b.booking_id, s.showtime_id, CONVERT(VARCHAR(30),s.start_time,121), CONVERT(VARCHAR(30),s.end_time,121), s.status, b.status FROM dbo.Booking b JOIN dbo.Showtime s ON s.showtime_id=b.showtime_id WHERE b.customer_id=$cust AND b.status='Paid' ORDER BY b.booking_id DESC;"
    $bid, $sid, $oldStart, $oldEnd, $oldSt, $oldBk = "$bk".Split('|')
    Assert-Test ([bool]$bid) 'co don da thanh toan de muon tam'
    $restore += "UPDATE dbo.Showtime SET start_time='$oldStart', end_time='$oldEnd', status='$oldSt' WHERE showtime_id=$sid;"
    # Lui gio chieu vao trong 3 gio toi; giu lai reminder cu de phuc hoi.
    $oldReminders = Sql "SELECT notif_id FROM dbo.EmailNotification WHERE booking_id=$bid AND notif_type='ShowtimeReminder';"
    if ($oldReminders.Count -gt 0) {
        $restore += "UPDATE dbo.EmailNotification SET notif_type='ShowtimeReminder' WHERE notif_id IN ($($oldReminders -join ','));"
        Sql "UPDATE dbo.EmailNotification SET notif_type='NewMovie' WHERE notif_id IN ($($oldReminders -join ','));" | Out-Null
    }
    Sql "UPDATE dbo.Showtime SET status='Scheduled', start_time=DATEADD(MINUTE,90,SYSDATETIME()), end_time=DATEADD(MINUTE,200,SYSDATETIME()) WHERE showtime_id=$sid;" | Out-Null
    $countReminder = "SELECT COUNT(*) FROM dbo.EmailNotification WHERE booking_id=$bid AND notif_type='ShowtimeReminder' AND notif_id>$notif0;"
    # Job thuc chay 15 phut/lan: goi dung procedure ma job goi.
    Sql 'EXEC dbo.sp_QueueShowtimeReminders 3;' | Out-Null
    Assert-Test ((Scalar $countReminder) -eq '1') 'suat trong 3 gio toi duoc xep email nhac lich'
    Sql 'EXEC dbo.sp_QueueShowtimeReminders 3;' | Out-Null
    Assert-Test ((Scalar $countReminder) -eq '1') 'chay lai khong gui trung'
    Assert-Test (Wait-Until { (Scalar "SELECT COUNT(*) FROM dbo.EmailNotification WHERE booking_id=$bid AND notif_type='ShowtimeReminder' AND notif_id>$notif0 AND status='Sent';") -eq '1' }) 'job gui email chuyen thu sang Sent'
    $inbox = (Html $customer '/account/inbox').Text
    Assert-Test ($inbox -match 'inbox-item is-reminder') 'khach thay nhac lich trong hop thu'
    Sql "UPDATE dbo.Showtime SET start_time=DATEADD(HOUR,30,SYSDATETIME()), end_time=DATEADD(HOUR,32,SYSDATETIME()) WHERE showtime_id=$sid; DELETE FROM dbo.EmailNotification WHERE notif_id>$notif0 AND booking_id=$bid; EXEC dbo.sp_QueueShowtimeReminders 3;" | Out-Null
    Assert-Test ((Scalar $countReminder) -eq '0') 'suat con xa chua nhac'

    # ==================== 29. Email phim moi / voucher ====================
    Write-Step '29. Receive Email Notifications (phim moi, voucher)'
    # Them phim that qua form Manager (multipart duoc servlet chap nhan ca urlencoded).
    $genre = Scalar 'SELECT TOP 1 genre_id FROM dbo.Genre ORDER BY genre_id;'
    $release = (Get-Date).AddDays(10).ToString('yyyy-MM-dd')
    $end = (Get-Date).AddDays(40).ToString('yyyy-MM-dd')
    $r = Post $manager '/manage/movies' @{ action = 'save'; id = '0'; title = $movieTitle; durationMinutes = '100'; ageRating = 'P'; releaseDate = $release; endDate = $end; genreIds = $genre; synopsis = 'zz'; director = 'zz'; mainCast = 'zz'; spokenLanguage = 'zz'; country = 'zz' } '/manage/movies?action=new'
    $movieId = Scalar "SELECT movie_id FROM dbo.Movie WHERE title=N'$movieTitle';"
    Assert-Test ([bool]$movieId) "manager them phim moi (flash: $($r.Flash))"
    if ($movieId) {
        $n = [int](Scalar "SELECT COUNT(*) FROM dbo.EmailNotification WHERE notif_type='NewMovie' AND movie_id=$movieId;")
        Assert-Test ($n -eq $activeCustomers) "xep email cho moi khach dang hoat dong ($n/$activeCustomers)"
        Sql "EXEC dbo.sp_QueueNewMovieEmail $movieId;" | Out-Null
        Assert-Test ([int](Scalar "SELECT COUNT(*) FROM dbo.EmailNotification WHERE notif_type='NewMovie' AND movie_id=$movieId;") -eq $n) 'goi lai khong gui trung'
        $inbox = (Html $customer '/account/inbox').Text
        Assert-Test ($inbox.Contains($movieTitle) -and $inbox.Contains("movies/detail?id=$movieId")) 'hop thu khach co phim moi kem link'
    }
    $from = (Get-Date).ToString('yyyy-MM-dd'); $to = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
    $vf = @{ action = 'save'; id = '0'; code = $voucherCode; description = ''; discountType = 'Percent'; discountValue = '10'; usageLimit = '5'; perCustomerLimit = '1'; validFrom = $from; validTo = $to; status = 'Disabled' }
    $r = Post $manager '/manager/vouchers' $vf
    $countV = "SELECT COUNT(*) FROM dbo.EmailNotification WHERE notif_type='Voucher' AND subject LIKE N'%$voucherCode';"
    Assert-Test ($r.FlashType -eq 'success') "them voucher dang tat (flash: $($r.Flash))"
    Assert-Test ((Scalar $countV) -eq '0') 'voucher dang tat khong gui email'
    $vid = Scalar "SELECT voucher_id FROM dbo.Voucher WHERE code='$voucherCode';"
    Post $manager '/manager/vouchers' @{ action = 'toggle'; id = $vid; status = 'Allowed' } | Out-Null
    $nv = [int](Scalar $countV)
    Assert-Test ($nv -eq $activeCustomers) "bat voucher thi xep email ($nv/$activeCustomers)"
    Post $manager '/manager/vouchers' @{ action = 'toggle'; id = $vid; status = 'Disabled' } | Out-Null
    Post $manager '/manager/vouchers' @{ action = 'toggle'; id = $vid; status = 'Allowed' } | Out-Null
    Assert-Test ([int](Scalar $countV) -eq $nv) 'tat roi bat lai khong gui trung'
    Assert-Test ((Html $customer '/account/inbox').Text.Contains($voucherCode)) 'hop thu khach co voucher'
    # Voucher yeu cau chi tieu rat cao: khong ai du dieu kien.
    $vf2 = $vf.Clone(); $vf2.code = $richVoucher; $vf2.status = 'Allowed'; $vf2.minCumulativeSpending = '999999999999'
    Post $manager '/manager/vouchers' $vf2 | Out-Null
    Assert-Test ((Scalar "SELECT COUNT(*) FROM dbo.EmailNotification WHERE subject LIKE N'%$richVoucher';") -eq '0') 'khach khong du chi tieu thi khong nhan voucher'
    Assert-Test (Wait-Until { (Scalar "SELECT COUNT(*) FROM dbo.EmailNotification WHERE notif_type='Voucher' AND subject LIKE N'%$voucherCode' AND status='Pending';") -eq '0' }) 'job gui het email voucher'

    # ==================== 32. Check-in QR ====================
    Write-Step '32. Ticket Check-in (QR Scan)'
    $t = Sql "SELECT TOP 1 t.ticket_id, t.ticket_code, t.status, s.showtime_id, CONVERT(VARCHAR(30),s.start_time,121), CONVERT(VARCHAR(30),s.end_time,121), s.status FROM dbo.Ticket t JOIN dbo.Booking b ON b.booking_id=t.booking_id JOIN dbo.Showtime s ON s.showtime_id=t.showtime_id WHERE b.customer_id=$cust AND b.status='Paid' AND t.status IN ('Expired','Booked') ORDER BY t.ticket_id DESC;"
    $tid, $tcode, $tOld, $s2, $st2, $en2, $ss2 = "$t".Split('|')
    Assert-Test ([bool]$tid) 'co ve de muon tam'
    $restore += "UPDATE dbo.Ticket SET status='$tOld', checked_in_at=NULL, checked_in_by=NULL WHERE ticket_id=$tid;"
    $restore += "UPDATE dbo.Showtime SET start_time='$st2', end_time='$en2', status='$ss2' WHERE showtime_id=$s2;"
    Sql "UPDATE dbo.Ticket SET status='Booked' WHERE ticket_id=$tid; UPDATE dbo.Showtime SET status='Scheduled', start_time=DATEADD(MINUTE,10,SYSDATETIME()), end_time=DATEADD(MINUTE,120,SYSDATETIME()) WHERE showtime_id=$s2;" | Out-Null

    # Giai ma that anh QR cua khach bang chinh thu vien jsQR ma trang soat ve dung.
    $png = Join-Path $tmpDir 'qr.png'
    Invoke-WebRequest "$BaseUrl/account/tickets/qr?ticketId=$tid" -WebSession $customer -UseBasicParsing -OutFile $png -TimeoutSec 60
    $node = Join-Path $tmpDir 'decode.js'
    $jsQr = (Resolve-Path "$PSScriptRoot/../web/assets/js/vendor/jsQR.js").Path.Replace('\', '/')
    $pngPath = $png.Replace('\', '/')
    @"
const zlib = require('zlib'), fs = require('fs');
const jsQR = require('$jsQr');
const b = fs.readFileSync('$pngPath');
let p = 8, w, h, bits, ct, idat = [];
while (p < b.length) {
  const len = b.readUInt32BE(p), type = b.toString('ascii', p + 4, p + 8), d = b.slice(p + 8, p + 8 + len);
  if (type === 'IHDR') { w = d.readUInt32BE(0); h = d.readUInt32BE(4); bits = d[8]; ct = d[9]; }
  if (type === 'IDAT') idat.push(d);
  p += 12 + len;
}
const channels = { 0: 1, 2: 3, 4: 2, 6: 4, 3: 1 }[ct], raw = zlib.inflateSync(Buffer.concat(idat));
if (bits !== 8 && bits !== 1) throw new Error('bit depth ' + bits);
const stride = bits === 1 ? Math.ceil(w / 8) : w * channels, rgba = new Uint8ClampedArray(w * h * 4);
const bpp = bits === 1 ? 1 : channels; let prev = Buffer.alloc(stride), q = 0;
for (let y = 0; y < h; y++) {
  const f = raw[q++], line = Buffer.from(raw.slice(q, q + stride)); q += stride;
  for (let i = 0; i < stride; i++) {
    const a = i >= bpp ? line[i - bpp] : 0, u = prev[i], c = i >= bpp ? prev[i - bpp] : 0;
    let v = 0;
    if (f === 1) v = a; else if (f === 2) v = u; else if (f === 3) v = (a + u) >> 1;
    else if (f === 4) { const t = a + u - c, pa = Math.abs(t - a), pb = Math.abs(t - u), pc = Math.abs(t - c); v = pa <= pb && pa <= pc ? a : pb <= pc ? u : c; }
    line[i] = (line[i] + v) & 255;
  }
  for (let x = 0; x < w; x++) {
    const g = bits === 1 ? ((line[x >> 3] >> (7 - (x & 7))) & 1) * 255 : line[x * channels];
    const k = (y * w + x) * 4; rgba[k] = rgba[k + 1] = rgba[k + 2] = g; rgba[k + 3] = 255;
  }
  prev = line;
}
const r = jsQR(rgba, w, h); process.stdout.write(r ? r.data : '');
"@ | Set-Content -Path $node -Encoding ASCII
    $decoded = "$(& node $node 2>&1)".Trim()
    Assert-Test ($decoded -eq $tcode) "jsQR doc dung ma ve tu anh QR that ($decoded)"

    $page = (Html $staff '/staff/checkin').Text
    Assert-Test ($page -match 'id="qrCameraBtn"' -and $page -match 'id="qrImage"' -and $page -match 'vendor/jsQR\.js') 'trang soat ve co quet camera, chon anh, thu vien QR'
    Assert-Test ((Html $staff '/assets/js/vendor/jsQR.js').Code -eq 200 -and (Html $staff '/assets/js/checkin-scan.js').Code -eq 200) 'file JS quet QR tai duoc'
    $r = Post $staff '/staff/checkin' @{ ticketCode = 'KHONGTONTAI' }
    Assert-Test ($r.Text -match 'alert-error') 'ma khong ton tai bi tu choi'
    $r = Post $staff '/staff/checkin' @{ ticketCode = $decoded.ToLower() }
    Assert-Test ($r.Text -match 'alert-success') 'soat bang ma doc tu QR thanh cong (khong phan biet hoa thuong)'
    Assert-Test ((Scalar "SELECT status FROM dbo.Ticket WHERE ticket_id=$tid;") -eq 'Used') 've chuyen sang Used'
    Assert-Test ((Scalar "SELECT CASE WHEN checked_in_by IS NOT NULL AND checked_in_at IS NOT NULL THEN 1 ELSE 0 END FROM dbo.Ticket WHERE ticket_id=$tid;") -eq '1') 'luu nguoi soat va thoi diem'
    $r = Post $staff '/staff/checkin' @{ ticketCode = $decoded }
    Assert-Test ($r.Text -match 'alert-error') 'quet lan hai bi tu choi'
    Sql "UPDATE dbo.Ticket SET status='Booked', checked_in_at=NULL, checked_in_by=NULL WHERE ticket_id=$tid; UPDATE dbo.Showtime SET start_time=DATEADD(HOUR,8,SYSDATETIME()), end_time=DATEADD(HOUR,10,SYSDATETIME()) WHERE showtime_id=$s2;" | Out-Null
    $r = Post $staff '/staff/checkin' @{ ticketCode = $decoded }
    Assert-Test ($r.Text -match 'alert-error') 'qua som so voi gio chieu bi tu choi'
    Assert-Test ((Html $customer '/staff/checkin').Code -eq 403) 'khach khong vao duoc trang soat ve'

    # ==================== 38. System Management ====================
    Write-Step '38. System Management'
    Assert-Test ((Html $admin '/dashboard/admin').Text.Contains('/admin/system')) 'menu admin co Quan ly he thong'
    foreach ($s in @($manager, $staff, $customer)) { Assert-Test ((Html $s '/admin/system').Code -eq 403) 'vai tro khac admin bi chan (403)' }
    $cfgField = @{}
    foreach ($line in $configBackup) { $k, $v = $line.Split('|'); $cfgField[$k] = $v }
    $page = Html $admin '/admin/system?tab=config'
    Assert-Test ($page.Code -eq 200 -and $page.Text.Contains('name="CANCEL_BEFORE_HOURS"')) 'tab cau hinh hien thi'
    # --- Cau hinh
    $bad = $cfgField.Clone(); $bad.action = 'saveConfig'; $bad.CANCEL_BEFORE_HOURS = '999'; $bad.CHECKIN_EARLY_MINUTES = '45'
    $r = Post $admin '/admin/system' $bad '/admin/system?tab=config'
    Assert-Test ($r.FlashType -eq 'error') 'gia tri ngoai khoang bi tu choi'
    Assert-Test ((Scalar "SELECT config_value FROM dbo.SystemConfig WHERE config_key='CHECKIN_EARLY_MINUTES';") -eq $cfgField.CHECKIN_EARLY_MINUTES) 'loi thi khong luu khoa nao'
    $bad.CANCEL_BEFORE_HOURS = 'abc'
    Assert-Test ((Post $admin '/admin/system' $bad '/admin/system?tab=config').FlashType -eq 'error') 'gia tri khong phai so bi tu choi'
    $good = $cfgField.Clone(); $good.action = 'saveConfig'; $good.CHECKIN_EARLY_MINUTES = '45'; $good.CANCEL_BEFORE_HOURS = '3'
    $r = Post $admin '/admin/system' $good '/admin/system?tab=config'
    Assert-Test ($r.FlashType -eq 'success') 'luu cau hinh hop le'
    Assert-Test ((Scalar "SELECT config_value FROM dbo.SystemConfig WHERE config_key='CHECKIN_EARLY_MINUTES';") -eq '45') 'gia tri moi nam trong CSDL'
    # Cau hinh co tac dung that: mo cua som 45 phut -> ve chieu sau 40 phut soat duoc.
    Sql "UPDATE dbo.Showtime SET start_time=DATEADD(MINUTE,40,SYSDATETIME()), end_time=DATEADD(MINUTE,150,SYSDATETIME()) WHERE showtime_id=$s2;" | Out-Null
    Assert-Test ((Post $staff '/staff/checkin' @{ ticketCode = $decoded }).Text -match 'alert-success') 'CHECKIN_EARLY_MINUTES co tac dung that'
    # Khoa la bi bo qua; CSRF sai bi chan.
    $evil = $cfgField.Clone(); $evil.action = 'saveConfig'; $evil.HACK_KEY = '1'
    Post $admin '/admin/system' $evil '/admin/system?tab=config' | Out-Null
    Assert-Test ((Scalar "SELECT COUNT(*) FROM dbo.SystemConfig WHERE config_key='HACK_KEY';") -eq '0') 'khoa la khong duoc tao'
    try {
        Invoke-WebRequest "$BaseUrl/admin/system" -Method Post -WebSession $admin -UseBasicParsing -Body @{ action = 'backup'; _csrf = 'sai' } | Out-Null
        Assert-Test $false 'CSRF sai phai bi chan'
    } catch { Assert-Test ([int]$_.Exception.Response.StatusCode -eq 403) 'CSRF sai bi chan' }

    # --- Sao luu: file phai khoi phuc duoc that
    $r = Post $admin '/admin/system' @{ action = 'backup' } '/admin/system?tab=backup'
    Assert-Test ($r.FlashType -eq 'success') "sao luu thanh cong ($($r.Flash))"
    $bakPath = ($r.Flash -replace '^.* v\S+o ', '').Trim()
    $backupPage = Html $admin '/admin/system?tab=backup'
    Assert-Test ($backupPage.Text.Contains([IO.Path]::GetFileName($bakPath))) 'lich su sao luu co file vua tao'
    if ($bakPath -match '\.bak$') {
        $verify = Sql "BEGIN TRY RESTORE VERIFYONLY FROM DISK=N'$bakPath' WITH CHECKSUM; SELECT 'VERIFY_OK'; END TRY BEGIN CATCH SELECT ERROR_MESSAGE(); END CATCH"
        Assert-Test (($verify -join ' ') -match 'VERIFY_OK') 'RESTORE VERIFYONLY: file hop le'
        $rd = 'CinemaWebDB_RestoreTest'
        $moves = Sql @"
DECLARE @t TABLE (LogicalName NVARCHAR(128), PhysicalName NVARCHAR(260), Type CHAR(1), FileGroupName NVARCHAR(128), Size NUMERIC(20,0), MaxSize NUMERIC(20,0), FileID BIGINT, CreateLSN NUMERIC(25,0), DropLSN NUMERIC(25,0), UniqueID UNIQUEIDENTIFIER, ReadOnlyLSN NUMERIC(25,0), ReadWriteLSN NUMERIC(25,0), BackupSizeInBytes BIGINT, SourceBlockSize INT, FileGroupID INT, LogGroupGUID UNIQUEIDENTIFIER, DifferentialBaseLSN NUMERIC(25,0), DifferentialBaseGUID UNIQUEIDENTIFIER, IsReadOnly BIT, IsPresent BIT, TDEThumbprint VARBINARY(32), SnapshotUrl NVARCHAR(360));
INSERT @t EXEC('RESTORE FILELISTONLY FROM DISK=N''$bakPath''');
DECLARE @dir NVARCHAR(400) = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(400));
DECLARE @move NVARCHAR(MAX) = (SELECT STRING_AGG('MOVE N''' + LogicalName + ''' TO N''' + @dir + '$rd' + '_' + CAST(FileID AS VARCHAR(5)) + '.tmp''', ',') FROM @t);
DECLARE @sql NVARCHAR(MAX) = 'RESTORE DATABASE [$rd] FROM DISK=N''$bakPath'' WITH ' + @move;
BEGIN TRY EXEC(@sql); SELECT 'RESTORE_OK'; END TRY BEGIN CATCH SELECT ERROR_MESSAGE(); END CATCH
"@
        Assert-Test (($moves -join ' ') -match 'RESTORE_OK') "khoi phuc that ra CSDL tam ($($moves | Select-Object -Last 1))"
        $srcMovies = Scalar 'SELECT COUNT(*) FROM dbo.Movie;'
        $restored = Scalar "SELECT COUNT(*) FROM [$rd].dbo.Movie;"
        Assert-Test ($restored -eq $srcMovies) "du lieu khoi phuc khop ($restored phim)"
        Sql "IF DB_ID('$rd') IS NOT NULL BEGIN ALTER DATABASE [$rd] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$rd]; END" | Out-Null
        Assert-Test ((Scalar "SELECT COUNT(*) FROM sys.databases WHERE name='$rd';") -eq '0') 'da xoa CSDL tam'
    }

    # --- Nhat ky
    $page = Html $admin '/admin/system?tab=logs'
    Assert-Test ($page.Code -eq 200 -and $page.Text.Contains('CHECKIN_EARLY_MINUTES')) 'nhat ky ghi gia tri cau hinh cu va moi'
    $logQuery = "SELECT COUNT(*) FROM dbo.SystemLog WHERE log_id>$log0 AND"
    Assert-Test ([int](Scalar "$logQuery action='/admin/system : backup' AND detail LIKE N'%file=%';") -ge 1) 'nhat ky ghi thao tac sao luu kem file'
    Assert-Test ([int](Scalar "$logQuery action='/staff/checkin' AND detail LIKE '%ticketCode=KHONGTONTAI%';") -ge 1) 'nhat ky ghi soat ve that bai'
    Assert-Test ([int](Scalar "$logQuery action='/manager/vouchers : toggle';") -ge 1) 'nhat ky ghi thao tac voucher'
    Assert-Test ([int](Scalar "$logQuery action='/manage/movies : save';") -ge 1) 'nhat ky ghi thao tac phim'
    Assert-Test ((Scalar "SELECT TOP 1 CASE WHEN detail LIKE '%Th%t b%i%' THEN 1 ELSE 0 END FROM dbo.SystemLog WHERE log_id>$log0 AND action='/admin/system : saveConfig' ORDER BY log_id ASC;") -eq '1') 'luu cau hinh sai ghi la That bai'
    $badLogin = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $marker = 'zztest' + (Get-Random -Maximum 99999) + '@x.vn'
    Post $badLogin '/login' @{ identifier = $marker; password = 'SaiMatKhauZZ!' } | Out-Null
    $row = Sql "SELECT detail FROM dbo.SystemLog WHERE log_id>$log0 AND action='LOGIN' AND detail LIKE '%$marker%';"
    Assert-Test ($row.Count -eq 1) 'dang nhap sai duoc ghi kem tai khoan'
    Assert-Test ([int](Scalar "SELECT COUNT(*) FROM dbo.SystemLog WHERE log_id>$log0 AND (detail LIKE '%SaiMatKhauZZ%' OR detail LIKE '%_csrf%');") -eq 0) 'nhat ky khong chua mat khau va CSRF'
    $staffLogin = New-BookingSession -BaseUrl $BaseUrl -Email 'staff@cinema.vn'
    Assert-Test ([int](Scalar "$logQuery action='LOGIN' AND account_id=(SELECT account_id FROM dbo.Account WHERE email='staff@cinema.vn');") -ge 1) 'dang nhap nhan su duoc ghi'
    Post $staffLogin '/logout' @{} '/dashboard/staff' | Out-Null
    Assert-Test ([int](Scalar "$logQuery action='/logout' AND account_id=(SELECT account_id FROM dbo.Account WHERE email='staff@cinema.vn');") -ge 1) 'dang xuat duoc ghi'
    # Loc
    $filtered = (Html $admin "/admin/system?tab=logs&q=$marker").Text
    Assert-Test ($filtered.Contains($marker) -and -not $filtered.Contains('CHECKIN_EARLY_MINUTES')) 'loc theo tu khoa'
    Assert-Test ((Html $admin '/admin/system?tab=logs&q=%25').Code -eq 200) 'tu khoa co ky tu dac biet khong loi'
    $tomorrow = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
    Assert-Test ((Html $admin "/admin/system?tab=logs&from=$tomorrow").Text -notmatch '<tbody>\s*<tr') 'loc theo ngay'
    Assert-Test ((Html $admin '/admin/system?tab=logs&from=khonghople').Code -eq 200) 'ngay sai khong gay loi'
    $xss = '<script>zz' + (Get-Random -Maximum 9999)
    Post $badLogin '/login' @{ identifier = $xss; password = 'x' } | Out-Null
    $xp = (Html $admin '/admin/system?tab=logs').Text
    Assert-Test (-not $xp.Contains($xss)) 'noi dung nhat ky duoc escape HTML'
}
finally {
    Write-Step 'Don du lieu test'
    $cfgRestore = foreach ($line in $configBackup) { $k, $v = $line.Split('|'); "UPDATE dbo.SystemConfig SET config_value=N'$v' WHERE config_key='$k';" }
    Sql ($cfgRestore -join "`n") | Out-Null
    Sql "DELETE FROM dbo.EmailNotification WHERE notif_id>$notif0;" | Out-Null
    # Khoi phuc nguoc thu tu: suat chieu co the bi muon hai lan, gia tri goc la gia tri luu dau tien.
    if ($restore.Count) { [array]::Reverse($restore); Sql ($restore -join "`n") | Out-Null }
    Sql "DELETE FROM dbo.EmailNotification WHERE notif_id>$notif0;" | Out-Null
    Sql "DELETE FROM dbo.MovieGenre WHERE movie_id IN (SELECT movie_id FROM dbo.Movie WHERE title LIKE 'ZZTEST PHIM%'); DELETE FROM dbo.Movie WHERE title LIKE 'ZZTEST PHIM%'; DELETE FROM dbo.Voucher WHERE code LIKE 'ZZTESTV%';" | Out-Null
    Sql "DELETE FROM dbo.SystemLog WHERE log_id>$log0;" | Out-Null
    Assert-Test ((Sql "SELECT config_key + '|' + config_value FROM dbo.SystemConfig;" | Out-String) -eq ($configBackup | Out-String)) 'cau hinh ve nhu cu'
    Assert-Test ((Scalar "SELECT COUNT(*) FROM dbo.Movie WHERE title LIKE 'ZZTEST%';") -eq '0') 'khong con phim test'
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
exit (Write-Result)
