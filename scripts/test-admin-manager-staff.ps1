<#
    .SYNOPSIS
        Kiem thu chuc nang cua ADMIN, MANAGER, STAFF (thao tac that: tao / sua / xoa, kiem tra CSDL).

    .DESCRIPTION
        Chi chay tren may phat trien (localhost). Moi du lieu thu deu co tien to ZZTEST va duoc don dep o cuoi.
          ADMIN   : danh sach + loc nguoi dung, khoa / doi vai tro, phong chieu (tao, sua, dong/mo, xoa), so do ghe
                    (tao layout, doi loai hang, bao tri / mo lai ghe).
          MANAGER : phim (tao, sua, ngung, chieu lai, xoa, kiem tra rang buoc), suat chieu (tao, trung lich, xoa,
                    sinh lich tu dong), tin tuc, voucher, gia ve (ngay le), cau hinh MyPoint.
          STAFF   : combo (tao, sua, xoa), ban ve tai quay (giu ghe, thanh toan tien mat), soat ve, doi ghe,
                    hop thu email.
          PHAN QUYEN: moi vai tro bi chan (403) o trang cua vai tro khac.

        Cach chay (mat khau tai khoan seed: bien CINEMA_TEST_PASSWORD, mac dinh la mat khau seed trong README):
          $env:CINEMA_BASE_URL='http://localhost:9999/CinemaTest'   (khong dat thi tu do cong dang chay)
          $env:CINEMA_DB_USER / CINEMA_DB_PASSWORD, hoac CINEMA_DB_WINAUTH=1, neu khong muon doc tu app.properties
          powershell -ExecutionPolicy Bypass -File scripts/test-admin-manager-staff.ps1
#>
param([string]$BaseUrl = '')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\booking-test-lib.ps1')
. (Join-Path $PSScriptRoot 'lib/test-config.ps1')
if (-not $BaseUrl) { $BaseUrl = Get-CinemaBaseUrl }

# ---------- ha tang ----------
$root = Split-Path -Parent $PSScriptRoot
$sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
$sqlAuth = Get-SqlCmdAuth   # mat khau SQL di qua SQLCMDPASSWORD, khong qua tham so -P

function Invoke-Sql([string]$Query) {
    $out = & $sqlcmd -S localhost @sqlAuth -d CinemaWebDB -C -I -h -1 -W -Q "SET NOCOUNT ON; $Query" 2>&1
    return (($out | Where-Object { $_ -and $_ -notmatch '^\s*$' }) -join "`n").Trim()
}

function New-RoleSession([string]$Email, [string]$Password = (Get-CinemaTestPassword)) {
    $s = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $p = Invoke-WebRequest "$BaseUrl/login" -WebSession $s -UseBasicParsing
    $c = [regex]::Match($p.Content, 'name="_csrf"\s+value="([^"]+)"').Groups[1].Value
    $null = Invoke-WebRequest "$BaseUrl/login" -Method Post -WebSession $s -UseBasicParsing -MaximumRedirection 5 `
        -Body @{ _csrf = $c; identifier = $Email; password = $Password }
    return $s
}

function Get-Page($S, [string]$Path) { return Invoke-WebRequest "$BaseUrl$Path" -WebSession $S -UseBasicParsing -MaximumRedirection 5 }

function Get-Token($S, [string]$Path) {
    $h = (Get-Page $S $Path).Content
    $m = [regex]::Match($h, 'name="_csrf"\s+value="([^"]+)"')
    if (-not $m.Success) { $m = [regex]::Match($h, 'value="([^"]+)"\s+name="_csrf"') }
    return $m.Groups[1].Value
}

function Get-Flash([string]$Html) {
    $type = [regex]::Match($Html, 'data-flash-type="([^"]*)"').Groups[1].Value
    $msg = [System.Net.WebUtility]::HtmlDecode([regex]::Match($Html, 'data-flash="([^"]*)"').Groups[1].Value)
    return @{ type = $type; msg = $msg }
}

# POST dang form; tra ve noi dung trang sau khi chuyen huong + thong bao flash
function Send-Form($S, [string]$Path, [hashtable]$Fields, [string]$TokenPage = $null) {
    if (-not $TokenPage) { $TokenPage = $Path }
    $body = @{ _csrf = (Get-Token $S $TokenPage) }
    foreach ($k in $Fields.Keys) { $body[$k] = $Fields[$k] }
    try {
        $r = Invoke-WebRequest "$BaseUrl$Path" -Method Post -Body $body -WebSession $S -UseBasicParsing -MaximumRedirection 5
        $f = Get-Flash $r.Content
        return @{ status = [int]$r.StatusCode; html = $r.Content; flashType = $f.type; flash = $f.msg }
    } catch {
        $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        return @{ status = $code; html = ''; flashType = 'http-error'; flash = $_.Exception.Message }
    }
}

# POST multipart (form phim); Fields: ten -> gia tri hoac mang gia tri
function Send-Multipart($S, [string]$Path, [hashtable]$Fields, [string]$TokenPage) {
    $boundary = '----zztest' + [guid]::NewGuid().ToString('N')
    $all = [ordered]@{ _csrf = (Get-Token $S $TokenPage) }
    foreach ($k in $Fields.Keys) { $all[$k] = $Fields[$k] }
    $sb = New-Object System.Text.StringBuilder
    foreach ($k in $all.Keys) {
        foreach ($v in @($all[$k])) {
            [void]$sb.Append("--$boundary`r`nContent-Disposition: form-data; name=`"$k`"`r`n`r`n$v`r`n")
        }
    }
    [void]$sb.Append("--$boundary--`r`n")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    try {
        $r = Invoke-WebRequest "$BaseUrl$Path" -Method Post -Body $bytes -ContentType "multipart/form-data; boundary=$boundary" `
            -WebSession $S -UseBasicParsing -MaximumRedirection 5
        $f = Get-Flash $r.Content
        return @{ status = [int]$r.StatusCode; html = $r.Content; flashType = $f.type; flash = $f.msg }
    } catch {
        $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        return @{ status = $code; html = ''; flashType = 'http-error'; flash = $_.Exception.Message }
    }
}

function Get-Status($S, [string]$Path) {
    # Khong tu theo chuyen huong de thay ro 302 / 403 (HttpWebRequest, dung chung cookie cua phien).
    $req = [System.Net.HttpWebRequest]::Create("$BaseUrl$Path")
    $req.AllowAutoRedirect = $false
    $req.CookieContainer = $S.Cookies
    try {
        $resp = $req.GetResponse()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return $code
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

function Test-Ok($R, [string]$What) { Assert-Test ($R.flashType -eq 'success') "$What (flash: $($R.flashType) $($R.flash))" }
function Test-Err($R, [string]$What) { Assert-Test ($R.flashType -eq 'error' -or $R.status -ge 400) "$What (flash: $($R.flashType) $($R.flash))" }

$tag = 'ZZTEST' + (Get-Date -Format 'HHmmss')
$tomorrow = (Get-Date).AddDays(1).ToString('yyyy-MM-dd')
$farDate = (Get-Date).AddDays(9).ToString('yyyy-MM-dd')

Write-Step "Dang nhap 3 vai tro (admin / manager / staff)"
$admin = New-RoleSession 'admin@cinema.vn'
$manager = New-RoleSession 'manager@cinema.vn'
$staff = New-RoleSession 'staff@cinema.vn'
Assert-Test ((Get-Status $admin '/dashboard/admin') -eq 200) 'admin vao duoc dashboard admin'
Assert-Test ((Get-Status $manager '/dashboard/manager') -eq 200) 'manager vao duoc dashboard manager'
Assert-Test ((Get-Status $staff '/dashboard/staff') -eq 200) 'staff vao duoc dashboard staff'

try {
# =====================================================================
Write-Step "PHAN QUYEN CHEO"
Assert-Test ((Get-Status $staff '/admin/users') -eq 403) 'staff khong vao /admin/users'
Assert-Test ((Get-Status $staff '/manage/movies') -eq 403) 'staff khong vao /manage/movies'
Assert-Test ((Get-Status $staff '/manager/vouchers') -eq 403) 'staff khong vao /manager/vouchers'
Assert-Test ((Get-Status $manager '/admin/rooms') -eq 403) 'manager khong vao /admin/rooms'
Assert-Test ((Get-Status $manager '/admin/users') -eq 403) 'manager khong vao /admin/users'
Assert-Test ((Get-Status $admin '/manage/movies') -eq 403) 'admin khong vao /manage/movies (khu vuc cua manager)'
$guest = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Assert-Test ((Get-Status $guest '/staff/counter') -in 302, 401, 403) 'khach chua dang nhap khong vao /staff/counter'

# =====================================================================
Write-Step "ADMIN - nguoi dung"
$users = Get-Page $admin '/admin/users'
Assert-Test ($users.StatusCode -eq 200 -and $users.Content -match 'khach1@gmail.com') 'danh sach nguoi dung co khach1'
Assert-Test ((Get-Page $admin '/admin/users?q=khach1').Content -notmatch 'staff@cinema.vn') 'loc theo tu khoa q=khach1 an staff'
Assert-Test ((Get-Page $admin '/admin/users?role=STAFF').Content -match 'staff@cinema.vn') 'loc theo vai tro STAFF thay staff'
Assert-Test ((Get-Page $admin '/admin/users?status=ACTIVE').StatusCode -eq 200) 'loc theo trang thai ACTIVE'

$victim = Invoke-Sql "SELECT TOP 1 UserId FROM Users WHERE Role='CUSTOMER' AND Email<>'khach1@gmail.com' AND Status='ACTIVE' ORDER BY UserId"
if ($victim -match '^\d+$') {
    $r = Send-Form $admin '/admin/users' @{ action = 'status'; value = 'BLOCKED'; userId = $victim } '/admin/users'
    Assert-Test ((Invoke-Sql "SELECT Status FROM Users WHERE UserId=$victim") -eq 'BLOCKED') "khoa tai khoan #$victim (CSDL = BLOCKED)"
    $r = Send-Form $admin '/admin/users' @{ action = 'status'; value = 'ACTIVE'; userId = $victim } '/admin/users'
    Assert-Test ((Invoke-Sql "SELECT Status FROM Users WHERE UserId=$victim") -eq 'ACTIVE') "mo khoa tai khoan #$victim (CSDL = ACTIVE)"
    $r = Send-Form $admin '/admin/users' @{ action = 'role'; value = 'STAFF'; userId = $victim } '/admin/users'
    Assert-Test ((Invoke-Sql "SELECT Role FROM Users WHERE UserId=$victim") -eq 'STAFF') "doi vai tro #$victim thanh STAFF"
    $r = Send-Form $admin '/admin/users' @{ action = 'role'; value = 'CUSTOMER'; userId = $victim } '/admin/users'
    Assert-Test ((Invoke-Sql "SELECT Role FROM Users WHERE UserId=$victim") -eq 'CUSTOMER') "doi vai tro #$victim ve CUSTOMER"
} else { Write-Host '  [INFO] khong co tai khoan khach thu hai de thu khoa / doi vai tro' }
$adminId = Invoke-Sql "SELECT UserId FROM Users WHERE Email='admin@cinema.vn'"
$null = Send-Form $admin '/admin/users' @{ action = 'status'; value = 'BLOCKED'; userId = $adminId } '/admin/users'
Assert-Test ((Invoke-Sql "SELECT Status FROM Users WHERE UserId=$adminId") -eq 'ACTIVE') 'admin khong tu khoa duoc chinh minh'

# =====================================================================
Write-Step "ADMIN - phong chieu"
$cinemaId = Invoke-Sql "SELECT TOP 1 cinema_id FROM Cinema ORDER BY cinema_id"
$roomName = "$tag-R"
Assert-Test ((Get-Page $admin '/admin/rooms').StatusCode -eq 200) 'danh sach phong mo duoc'
$r = Send-Form $admin '/admin/rooms' @{ action = 'save'; roomName = $roomName; roomType = '2D'; capacity = '20'; cinemaId = $cinemaId } '/admin/rooms?action=new'
$roomId = Invoke-Sql "SELECT room_id FROM Room WHERE room_name=N'$roomName'"
Assert-Test ($roomId -match '^\d+$') "tao phong $roomName (room_id=$roomId)"
$r = Send-Form $admin '/admin/rooms' @{ action = 'save'; roomName = $roomName; roomType = '3D'; capacity = '20'; cinemaId = $cinemaId } '/admin/rooms?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Room WHERE room_name=N'$roomName'") -eq '1') 'khong tao phong trung ten trong cung rap'
$r = Send-Form $admin '/admin/rooms' @{ action = 'save'; roomName = "$tag-bad"; roomType = '9D'; capacity = '20'; cinemaId = $cinemaId } '/admin/rooms?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Room WHERE room_name=N'$tag-bad'") -eq '0') 'tu choi loai phong khong hop le'
$r = Send-Form $admin '/admin/rooms' @{ action = 'save'; roomName = "$tag-bad"; roomType = '2D'; capacity = '0'; cinemaId = $cinemaId } '/admin/rooms?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Room WHERE room_name=N'$tag-bad'") -eq '0') 'tu choi suc chua = 0'
$r = Send-Form $admin '/admin/rooms' @{ action = 'save'; id = $roomId; roomName = $roomName; roomType = '3D'; capacity = '24'; cinemaId = $cinemaId; status = 'Active' } "/admin/rooms?action=edit&id=$roomId"
Assert-Test ((Invoke-Sql "SELECT room_type + '/' + CAST(capacity AS varchar(5)) FROM Room WHERE room_id=$roomId") -eq '3D/24') 'sua phong: loai 3D, suc chua 24'

Write-Step "ADMIN - so do ghe"
$seatTypes = (Invoke-Sql "SELECT STRING_AGG(CAST(seat_type_id AS varchar(5)), ',') FROM SeatType WHERE is_couple = 0") -split ','
$t1 = $seatTypes[0]; $t2 = $seatTypes[-1]
Assert-Test ((Get-Page $admin "/admin/seats?roomId=$roomId").StatusCode -eq 200) 'trang so do ghe mo duoc'
$r = Send-Form $admin '/admin/seats' @{ action = 'generate'; roomId = $roomId; rows = '2'; cols = '4'; rowTypes = "$t1,$t2" } "/admin/seats?roomId=$roomId"
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Seat WHERE room_id=$roomId") -eq '8') 'tao layout 2 hang x 4 ghe = 8 ghe'
Test-Ok $r 'thong bao tao layout'
$r = Send-Form $admin '/admin/seats' @{ action = 'generate'; roomId = $roomId; rows = '0'; cols = '4'; rowTypes = '' } "/admin/seats?roomId=$roomId"
Test-Err $r 'tu choi layout khong hop le'
$r = Send-Form $admin '/admin/seats' @{ action = 'rowType'; roomId = $roomId; row = 'A'; typeId = $t2 } "/admin/seats?roomId=$roomId"
Assert-Test ((Invoke-Sql "SELECT COUNT(DISTINCT seat_type_id) FROM Seat WHERE room_id=$roomId AND row_label='A'") -eq '1' -and (Invoke-Sql "SELECT MIN(seat_type_id) FROM Seat WHERE room_id=$roomId AND row_label='A'") -eq $t2) 'doi loai ghe hang A'
$seatId = Invoke-Sql "SELECT TOP 1 seat_id FROM Seat WHERE room_id=$roomId ORDER BY seat_id"
$r = Send-Form $admin '/admin/seats' @{ action = 'maintain'; roomId = $roomId; seatIds = $seatId } "/admin/seats?roomId=$roomId"
Assert-Test ((Invoke-Sql "SELECT status FROM Seat WHERE seat_id=$seatId") -eq 'Maintenance') 'dua ghe vao bao tri'
$r = Send-Form $admin '/admin/seats' @{ action = 'reopen'; roomId = $roomId; seatIds = $seatId } "/admin/seats?roomId=$roomId"
Assert-Test ((Invoke-Sql "SELECT status FROM Seat WHERE seat_id=$seatId") -eq 'Active') 'mo lai ghe sau bao tri'

Write-Step "ADMIN - dong / mo / xoa phong"
$r = Send-Form $admin '/admin/rooms' @{ action = 'toggle'; id = $roomId } '/admin/rooms'
$st = Invoke-Sql "SELECT status FROM Room WHERE room_id=$roomId"
Assert-Test ($st -eq 'Closed') "dong phong (status = $st)"
$r = Send-Form $admin '/admin/rooms' @{ action = 'toggle'; id = $roomId } '/admin/rooms'
Assert-Test ((Invoke-Sql "SELECT status FROM Room WHERE room_id=$roomId") -eq 'Active') 'mo lai phong'
$r = Send-Form $admin '/admin/rooms' @{ action = 'delete'; id = $roomId } '/admin/rooms'
$left = Invoke-Sql "SELECT COUNT(*) FROM Room WHERE room_id=$roomId"
Assert-Test ($left -eq '0') "xoa phong thu (con lai: $left; flash: $($r.flash))"

# =====================================================================
Write-Step "MANAGER - phim"
$title = "$tag Movie"
$movieFields = @{ action = 'save'; id = '0'; title = $title; originalTitle = "$tag Original"; synopsis = 'Phim thu nghiem tu dong.'
    director = 'Test Director'; mainCast = 'Test Cast'; durationMinutes = '100'; ageRating = 'T13'; country = 'Viet Nam'
    spokenLanguage = 'Tieng Viet'; releaseDate = $tomorrow; endDate = (Get-Date).AddDays(31).ToString('yyyy-MM-dd')
    genreIds = @('1'); posterUrl = ''; trailerUrl = '' }
$r = Send-Multipart $manager '/manage/movies' $movieFields '/manage/movies?action=new'
$movieId = Invoke-Sql "SELECT movie_id FROM Movie WHERE title=N'$title'"
Assert-Test ($movieId -match '^\d+$') "tao phim moi (movie_id=$movieId; flash: $($r.flash))"
Assert-Test ((Invoke-Sql "SELECT status FROM Movie WHERE movie_id=$movieId") -eq 'Upcoming') 'phim ngay khoi chieu o tuong lai -> Sap chieu'
Assert-Test ((Get-Page $manager '/manage/movies?page=1').Content -match 'ZZTEST' -or (Get-Page $manager '/manage/movies').StatusCode -eq 200) 'danh sach quan ly phim mo duoc'
$r = Send-Multipart $manager '/manage/movies' $movieFields '/manage/movies?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Movie WHERE title=N'$title'") -eq '1') 'khong tao phim trung ten'
$bad = $movieFields.Clone(); $bad.title = "$tag Past"; $bad.releaseDate = (Get-Date).AddDays(-3).ToString('yyyy-MM-dd')
$r = Send-Multipart $manager '/manage/movies' $bad '/manage/movies?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Movie WHERE title=N'$tag Past'") -eq '0') 'tu choi ngay khoi chieu o qua khu'
$bad = $movieFields.Clone(); $bad.title = "$tag Long"; $bad.durationMinutes = '9999'
$r = Send-Multipart $manager '/manage/movies' $bad '/manage/movies?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Movie WHERE title=N'$tag Long'") -eq '0') 'tu choi thoi luong khong hop le'
$edit = $movieFields.Clone(); $edit.id = $movieId; $edit.synopsis = 'Noi dung da sua.'; $edit.durationMinutes = '110'
$r = Send-Multipart $manager '/manage/movies' $edit "/manage/movies?id=$movieId"
Assert-Test ((Invoke-Sql "SELECT duration_minutes FROM Movie WHERE movie_id=$movieId") -eq '110') 'sua phim: thoi luong 110'
Assert-Test ((Get-Page $manager "/manage/movies?action=cancel-preview&id=$movieId").StatusCode -eq 200) 'xem truoc huy phim mo duoc'
$r = Send-Form $manager '/manage/movies' @{ action = 'stop'; id = $movieId } '/manage/movies'
Assert-Test ((Invoke-Sql "SELECT status FROM Movie WHERE movie_id=$movieId") -eq 'Stopped') 'ngung chieu phim'
Assert-Test ((Get-Page $manager "/manage/movies?action=rerun&id=$movieId").Content -match 'name="reschedule"') 'form chieu lai mo duoc cho phim da ngung'
$rer = @{ action = 'save'; id = $movieId; reschedule = 'true'; releaseDate = $tomorrow; endDate = (Get-Date).AddDays(20).ToString('yyyy-MM-dd') }
$r = Send-Multipart $manager '/manage/movies' $rer "/manage/movies?action=rerun&id=$movieId"
Assert-Test ((Invoke-Sql "SELECT status FROM Movie WHERE movie_id=$movieId") -eq 'Upcoming') "chieu lai phim -> Sap chieu (flash: $($r.flash))"
Assert-Test ((Get-Status $manager '/manage/movies?action=rerun&id=4') -eq 400) 'khong cho chieu lai phim dang chieu (400)'
$vis = (Get-Page $guest '/movies?status=Upcoming').Content
Assert-Test ($vis -match [regex]::Escape($title)) 'phim vua tao hien o trang Phim sap chieu cua khach'

Write-Step "MANAGER - suat chieu"
# Chon mot ngay xa chua co suat nao va co phim dang phat hanh vao ngay do (de ket qua khong phu thuoc lich hien co).
$farDate = $null; $showMovie = $null
foreach ($d in 41..53) {
    $cand = (Get-Date).AddDays($d).ToString('yyyy-MM-dd')
    $busy = [int](Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE CAST(start_time AS date)='$cand'")
    $mvc = Invoke-Sql "SELECT TOP 1 movie_id FROM Movie WHERE status<>'Stopped' AND release_date <= '$cand' AND end_date >= '$cand' ORDER BY movie_id"
    if ($busy -eq 0 -and $mvc -match '^\d+$') { $farDate = $cand; $showMovie = $mvc; break }
}
if (-not $farDate) { throw 'khong tim duoc ngay trong de thu suat chieu' }
$room1 = Invoke-Sql "SELECT TOP 1 room_name FROM Room WHERE status='Active' ORDER BY room_id"
Assert-Test ((Get-Page $manager '/manage/showtimes?action=new').StatusCode -eq 200) 'form them suat chieu mo duoc'
$times = (Get-Page $manager "/manage/showtimes?action=available-times&date=$farDate&movieId=$showMovie&roomName=$([uri]::EscapeDataString($room1))").Content
Assert-Test ($times -match '^\s*\[') "API gio con trong tra ve danh sach (vi du: $($times.Substring(0,[Math]::Min(60,$times.Length))))"
$freeTime = [regex]::Match($times, '"(\d{2}:\d{2})"').Groups[1].Value
$freeNext = ([datetime]::ParseExact($freeTime, 'HH:mm', $null)).AddMinutes(15).ToString('HH:mm')
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = $freeTime } '/manage/showtimes?action=new'
$stId = Invoke-Sql "SELECT TOP 1 showtime_id FROM Showtime WHERE movie_id=$showMovie AND room_name=N'$room1' AND start_time='$farDate $($freeTime):00' AND status='Scheduled'"
Assert-Test ($stId -match '^\d+$') "them suat chieu $farDate $freeTime (showtime_id=$stId; flash: $($r.flash))"
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = $freeNext } '/manage/showtimes?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE room_name=N'$room1' AND start_time='$farDate $($freeNext):00'") -eq '0') 'tu choi suat trung lich phong'
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = '10:07' } '/manage/showtimes?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE room_name=N'$room1' AND start_time='$farDate 10:07:00'") -eq '0') 'tu choi gio khong nam tren luoi 15 phut'
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = '23:30' } '/manage/showtimes?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE room_name=N'$room1' AND start_time='$farDate 23:30:00'") -eq '0') 'tu choi suat ket thuc sau gio dong cua'
$r = Send-Form $manager '/manage/showtimes' @{ action = 'delete'; id = $stId } '/manage/showtimes'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE showtime_id=$stId") -eq '0') 'xoa suat chieu thu'

# Gio cua suat da huy phai dung lai duoc (UQ_Showtime_Room_Start chi tinh suat chua huy)
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = $freeTime } '/manage/showtimes?action=new'
$stA = Invoke-Sql "SELECT TOP 1 showtime_id FROM Showtime WHERE room_name=N'$room1' AND start_time='$farDate $($freeTime):00' AND status='Scheduled'"
$null = Invoke-Sql "UPDATE Showtime SET status='Cancelled' WHERE showtime_id=$stA"
$r = Send-Form $manager '/manage/showtimes' @{ action = 'save'; movieId = $showMovie; roomName = $room1; showDate = $farDate; showTime = $freeTime } '/manage/showtimes?action=new'
$stB = Invoke-Sql "SELECT TOP 1 showtime_id FROM Showtime WHERE room_name=N'$room1' AND start_time='$farDate $($freeTime):00' AND status='Scheduled'"
Assert-Test ($stB -match '^\d+$' -and $stB -ne $stA) "tao lai suat o gio da co suat bi huy (flash: $($r.flashType) $($r.flash))"
$null = Invoke-Sql "DELETE FROM Showtime WHERE showtime_id IN ($stA, $stB)"

$genDate = (Get-Date).AddDays(40).ToString('yyyy-MM-dd')
$genMovies = Invoke-Sql "SELECT COUNT(*) FROM Movie WHERE status<>'Stopped' AND release_date <= '$genDate' AND end_date >= '$genDate'"
$gp = Get-Page $manager "/manage/showtimes?action=generate&date=$genDate"
Assert-Test ($gp.StatusCode -eq 200 -and $gp.Content -match 'name="roomNames"') 'trang sinh lich tu dong mo duoc'
if ([int]$genMovies -gt 0) {
    $rooms = [regex]::Matches($gp.Content, 'name="roomNames" value="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    $mv = [regex]::Matches($gp.Content, 'name="movieIds" value="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    $tok = [regex]::Match($gp.Content, 'name="_csrf" value="([^"]+)"').Groups[1].Value
    $body = "_csrf=$tok&action=generate&showDate=$genDate&openTime=09:00&" + (($rooms | ForEach-Object { 'roomNames=' + [uri]::EscapeDataString($_) }) -join '&') + '&' + (($mv | ForEach-Object { "movieIds=$_" }) -join '&')
    $before = [int](Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE CAST(start_time AS date)='$genDate'")
    $resp = Invoke-WebRequest "$BaseUrl/manage/showtimes" -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded' -WebSession $manager -UseBasicParsing -MaximumRedirection 5
    $after = [int](Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE CAST(start_time AS date)='$genDate'")
    Assert-Test ($after -gt $before) "sinh lich tu dong tao $($after - $before) suat cho $genDate"
    Assert-Test ([int](Invoke-Sql "SELECT COUNT(*) FROM Showtime a JOIN Showtime b ON a.room_name=b.room_name AND a.showtime_id<b.showtime_id AND CAST(a.start_time AS date)='$genDate' AND CAST(b.start_time AS date)='$genDate' AND a.start_time < DATEADD(MINUTE,15,b.end_time) AND b.start_time < DATEADD(MINUTE,15,a.end_time)") -eq 0) 'lich sinh ra khong co suat nao de len nhau'
    Assert-Test ([int](Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE CAST(start_time AS date)='$genDate' AND (end_time > '$genDate 23:00:00' OR DATEPART(MINUTE,start_time)%15<>0)") -eq 0) 'moi suat ket thuc truoc 23:00 va nam tren luoi 15 phut'
    $null = Invoke-Sql "DELETE FROM Showtime WHERE CAST(start_time AS date)='$genDate' AND created_by IS NULL AND NOT EXISTS (SELECT 1 FROM Ticket t WHERE t.showtime_id=Showtime.showtime_id)"
} else { Write-Host "  [INFO] khong co phim phat hanh ngay $genDate de thu sinh lich" }

Write-Step "MANAGER - xoa phim thu"
$r = Send-Form $manager '/manage/movies' @{ action = 'delete'; id = $movieId } '/manage/movies'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Movie WHERE movie_id=$movieId") -eq '0') "xoa phim thu (flash: $($r.flash))"

Write-Step "MANAGER - tin tuc"
$newsTitle = "$tag News"
Assert-Test ((Get-Page $manager '/manager/news').StatusCode -eq 200) 'danh sach tin tuc mo duoc'
$r = Send-Form $manager '/manager/news' @{ id = ''; title = $newsTitle; content = 'Noi dung tin thu nghiem.'; thumbnailUrl = ''; status = 'Draft' } '/manager/news?action=add'
$newsId = Invoke-Sql "SELECT TOP 1 news_id FROM News WHERE title=N'$newsTitle'"
Assert-Test ($newsId -match '^\d+$') "dang tin moi (news_id=$newsId)"
Assert-Test ((Get-Page $guest '/news').Content -notmatch [regex]::Escape($newsTitle)) 'ban nhap khong hien o trang tin tuc cong khai'
$r = Send-Form $manager '/manager/news' @{ id = $newsId; title = $newsTitle; content = 'Noi dung da sua.'; thumbnailUrl = ''; status = 'Published' } "/manager/news?action=edit&id=$newsId"
Assert-Test ((Invoke-Sql "SELECT status FROM News WHERE news_id=$newsId") -eq 'Published') 'sua tin: xuat ban'
Assert-Test ((Get-Page $guest '/news').Content -match [regex]::Escape($newsTitle)) 'tin xuat ban hien o trang tin tuc cong khai'
$r = Send-Form $manager '/manager/news' @{ id = ''; title = "$tag Bad"; content = 'x'; thumbnailUrl = 'ftp://x/y.png'; status = 'Published' } '/manager/news?action=add'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM News WHERE title=N'$tag Bad'") -eq '0') 'tu choi link anh khong hop le'
$r = Send-Form $manager '/manager/news' @{ action = 'delete'; id = $newsId } '/manager/news'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM News WHERE news_id=$newsId") -eq '0') 'xoa tin thu'

Write-Step "MANAGER - voucher"
$code = $tag
$vf = @{ action = 'save'; id = '0'; code = $code; description = 'Voucher thu nghiem'; discountType = 'Percent'; discountValue = '10'
    maxDiscount = '20000'; minOrderAmount = '50000'; minCumulativeSpending = '0'; usageLimit = '5'; perCustomerLimit = '1'
    validFrom = (Get-Date).ToString('yyyy-MM-dd'); validTo = (Get-Date).AddDays(10).ToString('yyyy-MM-dd'); status = 'Allowed' }
$r = Send-Form $manager '/manager/vouchers' $vf '/manager/vouchers?action=new'
$vid = Invoke-Sql "SELECT voucher_id FROM Voucher WHERE code='$code'"
Assert-Test ($vid -match '^\d+$') "tao voucher $code (voucher_id=$vid)"
Assert-Test ((Get-Page $guest '/promotions').Content -match $code) 'voucher dang cho phep hien o trang Khuyen mai'
$dup = Send-Form $manager '/manager/vouchers' $vf '/manager/vouchers?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Voucher WHERE code='$code'") -eq '1') 'khong tao voucher trung ma'
$badv = $vf.Clone(); $badv.code = "$($tag)X"; $badv.discountValue = '150'
$r = Send-Form $manager '/manager/vouchers' $badv '/manager/vouchers?action=new'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Voucher WHERE code='$($tag)X'") -eq '0') 'tu choi giam phan tram > 100'
$r = Send-Form $manager '/manager/vouchers' @{ action = 'toggle'; id = $vid; status = 'Disabled' } '/manager/vouchers'
Assert-Test ((Invoke-Sql "SELECT status FROM Voucher WHERE voucher_id=$vid") -eq 'Disabled') 'tat voucher'
Assert-Test ((Get-Page $guest '/promotions').Content -notmatch $code) 'voucher da tat khong hien o trang Khuyen mai'
$ed = $vf.Clone(); $ed.id = $vid; $ed.discountValue = '15'; $ed.status = 'Allowed'
$r = Send-Form $manager '/manager/vouchers' $ed "/manager/vouchers?edit=$vid"
Assert-Test ((Invoke-Sql "SELECT CAST(discount_value AS int) FROM Voucher WHERE voucher_id=$vid") -eq '15') 'sua voucher: giam 15%'
$r = Send-Form $manager '/manager/vouchers' @{ action = 'delete'; id = $vid } '/manager/vouchers'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Voucher WHERE voucher_id=$vid") -eq '0') 'xoa voucher chua dung'

Write-Step "MANAGER - gia ve va MyPoint"
$pp = Get-Page $manager '/manager/prices'
Assert-Test ($pp.StatusCode -eq 200 -and $pp.Content -match 'holidayDate') 'trang gia ve mo duoc'
$hol = (Get-Date).AddDays(200).ToString('yyyy-MM-dd')
$r = Send-Form $manager '/manager/prices' @{ action = 'addHoliday'; holidayDate = $hol; holidayName = "$tag Holiday" } '/manager/prices'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Holiday WHERE holiday_date='$hol'") -eq '1') "them ngay le $hol"
$r = Send-Form $manager '/manager/prices' @{ action = 'deleteHoliday'; holidayDate = $hol } '/manager/prices'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Holiday WHERE holiday_date='$hol'") -eq '0') 'xoa ngay le'
$mp = Get-Page $manager '/manager/mypoint'
Assert-Test ($mp.StatusCode -eq 200 -and $mp.Content -match 'earnRatePercent') 'trang cau hinh MyPoint mo duoc'
$earn = [regex]::Match($mp.Content, 'name="earnRatePercent"[^>]*value="([^"]*)"').Groups[1].Value
$maxr = [regex]::Match($mp.Content, 'name="maxRedeemPercent"[^>]*value="([^"]*)"').Groups[1].Value
$pv = [regex]::Match($mp.Content, 'name="pointValueVnd"[^>]*value="([^"]*)"').Groups[1].Value
$r = Send-Form $manager '/manager/mypoint' @{ earnRatePercent = '-5'; maxRedeemPercent = $maxr; pointValueVnd = $pv } '/manager/mypoint'
Assert-Test ($r.flashType -eq 'error' -or $r.html -match 'error|alert') 'tu choi ty le tich diem am'
$r = Send-Form $manager '/manager/mypoint' @{ earnRatePercent = $earn; maxRedeemPercent = $maxr; pointValueVnd = $pv } '/manager/mypoint'
Assert-Test ($r.status -eq 200) 'luu lai cau hinh MyPoint (giu nguyen gia tri)'

# =====================================================================
Write-Step "STAFF - combo"
$comboName = "$tag Combo"
Assert-Test ((Get-Page $staff '/staff/combo').StatusCode -eq 200) 'danh sach combo mo duoc'
$r = Send-Form $staff '/staff/combo' @{ id = ''; comboName = $comboName; description = 'Combo thu'; price = '55000'; stock = '10'; status = 'Active' } '/staff/combo?action=add'
$comboId = Invoke-Sql "SELECT TOP 1 combo_id FROM Combo WHERE combo_name=N'$comboName'"
Assert-Test ($comboId -match '^\d+$') "tao combo (combo_id=$comboId)"
$r = Send-Form $staff '/staff/combo' @{ id = $comboId; comboName = $comboName; description = 'Combo thu'; price = '60000'; stock = '7'; status = 'Active' } "/staff/combo?action=edit&id=$comboId"
Assert-Test ((Invoke-Sql "SELECT CAST(price AS int) FROM Combo WHERE combo_id=$comboId") -eq '60000') 'sua combo: gia 60.000'
$r = Send-Form $staff '/staff/combo' @{ id = ''; comboName = "$tag Neg"; description = ''; price = '-1'; stock = '1'; status = 'Active' } '/staff/combo?action=add'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Combo WHERE combo_name=N'$tag Neg'") -eq '0') 'tu choi gia combo am'
Assert-Test ((Get-Page $staff '/staff/combo?q=ZZTEST').Content -match [regex]::Escape($comboName)) 'tim combo theo tu khoa'

Write-Step "STAFF - ban ve tai quay"
Assert-Test ((Get-Page $staff '/staff/counter').StatusCode -eq 200) 'trang ban ve tai quay mo duoc'
$cSt = Invoke-Sql "SELECT TOP 1 s.showtime_id FROM Showtime s WHERE s.status='Scheduled' AND s.start_time > DATEADD(DAY,3,SYSDATETIME()) AND NOT EXISTS (SELECT 1 FROM Ticket t WHERE t.showtime_id=s.showtime_id) ORDER BY s.start_time"
if (-not ($cSt -match '^\d+$')) {
    # khong co suat xa va trong -> tao nhanh bang trinh sinh lich cho mot ngay tuong lai
    Write-Host '  [INFO] khong co suat chieu xa va chua ban de thu ban ve tai quay'
} else {
    $sp = Get-Page $staff "/staff/counter?action=seats&showtimeId=$cSt"
    Assert-Test ($sp.StatusCode -eq 200) "so do ghe tai quay cho suat $cSt mo duoc"
    $free = [regex]::Matches($sp.Content, 'data-seat-id="(\d+)"[^>]*data-status="(?:GREEN|Green|green)"|data-status="(?:GREEN|Green|green)"[^>]*data-seat-id="(\d+)"') | ForEach-Object { $_.Groups[1].Value + $_.Groups[2].Value }
    if (-not $free) { $free = Invoke-Sql "SELECT TOP 3 seat_id FROM Seat WHERE room_id=(SELECT room_id FROM Showtime WHERE showtime_id=$cSt) AND status='Active' AND seat_type_id IN (SELECT seat_type_id FROM SeatType WHERE is_couple=0) ORDER BY seat_id" | ForEach-Object { $_ -split "`n" } }
    $seat1 = @($free)[0]; $seat2 = @($free)[1]
    $r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seat1" } "/staff/counter?action=seats&showtimeId=$cSt"
    $bk = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
    Assert-Test ($bk -match '^\d+$') "giu ghe $seat1 (booking_id=$bk)"
    $ck = Get-Page $staff '/staff/counter?action=checkout'
    Assert-Test ($ck.StatusCode -eq 200 -and $ck.Content -match 'cashReceived') 'man hinh thanh toan tai quay mo duoc'
    $r = Send-Form $staff '/staff/counter' @{ action = 'updateCombos'; comboId = $comboId; qty = '1' } '/staff/counter?action=checkout'
    Assert-Test ((Invoke-Sql "SELECT ISNULL(SUM(quantity),0) FROM BookingCombo WHERE booking_id=$bk") -eq '1') 'them combo vao don'
    $r = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = '1000000' } '/staff/counter?action=checkout'
    $paid = Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk"
    Assert-Test ($paid -eq 'Paid') "thanh toan tien mat (trang thai don: $paid)"
    $tk = Invoke-Sql "SELECT TOP 1 ticket_code FROM Ticket WHERE booking_id=$bk"
    $tkId = Invoke-Sql "SELECT TOP 1 ticket_id FROM Ticket WHERE booking_id=$bk"
    Assert-Test ($tk -match '^TK') "co ve duoc cap (ma $tk)"
    Assert-Test ((Invoke-Sql "SELECT status FROM Ticket WHERE ticket_id=$tkId") -eq 'Booked') 've o trang thai Booked'
    Assert-Test ((Get-Status $staff "/staff/tickets/qr?ticketId=$tkId") -eq 200) 'QR ve ban tai quay tra ve duoc'
    # huy don giu cho
    $r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seat2" } "/staff/counter?action=seats&showtimeId=$cSt"
    $bk2 = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
    $r = Send-Form $staff '/staff/counter' @{ action = 'cancelBooking' } '/staff/counter?action=checkout'
    Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk2") -in 'Cancelled', 'Expired') 'huy don dang giu cho tra ghe'

    Write-Step "STAFF - soat ve va doi ghe"
    Assert-Test ((Get-Page $staff '/staff/checkin').StatusCode -eq 200) 'trang soat ve mo duoc'
    $r = Send-Form $staff '/staff/checkin' @{ ticketCode = 'TKKHONGTONTAI' } '/staff/checkin'
    Assert-Test ($r.html -notmatch 'Exception') 'soat ma ve khong ton tai khong gay loi he thong'
    Assert-Test ((Invoke-Sql "SELECT status FROM Ticket WHERE ticket_id=$tkId") -eq 'Booked') 'ma sai khong lam doi trang thai ve that'
    $r = Send-Form $staff '/staff/checkin' @{ ticketCode = $tk } '/staff/checkin'
    $afterCheck = Invoke-Sql "SELECT status FROM Ticket WHERE ticket_id=$tkId"
    Write-Host "  [INFO] soat ve suat xa 3 ngay -> trang thai ve: $afterCheck (flash: $($r.flashType) $($r.flash))"
    Assert-Test ($afterCheck -in 'Booked', 'Used') 'soat ve cho ket qua hop le (Used neu trong khung gio, Booked neu con som)'

    $sc = Get-Page $staff "/staff/seat-change?code=$tk"
    Assert-Test ($sc.StatusCode -eq 200) 'trang doi ghe mo duoc'
    $newSeat = Invoke-Sql "SELECT TOP 1 seat_id FROM Seat WHERE room_id=(SELECT room_id FROM Showtime WHERE showtime_id=$cSt) AND status='Active' AND seat_id NOT IN (SELECT seat_id FROM Ticket WHERE showtime_id=$cSt AND status IN ('Held','Booked','Used')) AND seat_type_id=(SELECT seat_type_id FROM Seat WHERE seat_id=(SELECT seat_id FROM Ticket WHERE ticket_id=$tkId)) AND pair_seat_id IS NULL ORDER BY seat_id DESC"
    $oldSeat = Invoke-Sql "SELECT seat_id FROM Ticket WHERE ticket_id=$tkId"
    if ($afterCheck -eq 'Booked' -and $newSeat -match '^\d+$') {
        $r = Send-Form $staff '/staff/seat-change' @{ code = $tk; ticketId = $tkId; newSeatId = $newSeat; reason = 'Kiem thu doi ghe' } "/staff/seat-change?code=$tk"
        Assert-Test ((Invoke-Sql "SELECT seat_id FROM Ticket WHERE ticket_id=$tkId") -eq $newSeat) "doi ghe $oldSeat -> $newSeat (flash: $($r.flashType) $($r.flash))"
    } else { Write-Host '  [INFO] bo qua buoc doi ghe (ve da Used hoac khong co ghe trong cung loai)' }

    # don dep du lieu ban tai quay: tra ve ghe de khong de ve thu chiem cho
    $null = Invoke-Sql "UPDATE Ticket SET status='Cancelled' WHERE booking_id=$bk; UPDATE Booking SET status='Cancelled' WHERE booking_id=$bk"
}

Write-Step "DASHBOARD"
$dm = (Get-Page $manager '/dashboard/manager').Content
$da = (Get-Page $admin '/dashboard/admin').Content
$ds = (Get-Page $staff '/dashboard/staff').Content
Assert-Test ($da -match 'admin-kpi') 'dashboard admin co the KPI'
Assert-Test ($dm -match 'admin-kpi|dashboard') 'dashboard manager hien thi'
Assert-Test ($ds -match 'dashboard') 'dashboard staff hien thi'
Assert-Test ($da -notmatch 'Exception' -and $dm -notmatch 'Exception' -and $ds -notmatch 'Exception') 'dashboard khong co loi he thong'
}
finally {
    Write-Step "DON DEP DU LIEU THU"
    # Don ban tai quay cua bai thu da bi huy o tren; go dong combo cua don do roi moi xoa combo thu.
    $null = Invoke-Sql "DELETE FROM BookingCombo WHERE combo_id IN (SELECT combo_id FROM Combo WHERE combo_name LIKE N'ZZTEST%')"
    $null = Invoke-Sql "DELETE FROM Combo WHERE combo_name LIKE N'ZZTEST%' AND NOT EXISTS (SELECT 1 FROM BookingCombo bc WHERE bc.combo_id = Combo.combo_id)"
    $null = Invoke-Sql "UPDATE Combo SET status='Hidden' WHERE combo_name LIKE N'ZZTEST%'"
    $null = Invoke-Sql "DELETE FROM MovieGenre WHERE movie_id IN (SELECT movie_id FROM Movie WHERE title LIKE N'ZZTEST%')"
    $null = Invoke-Sql "DELETE FROM Movie WHERE title LIKE N'ZZTEST%' AND NOT EXISTS (SELECT 1 FROM Showtime s WHERE s.movie_id = Movie.movie_id)"
    $null = Invoke-Sql "DELETE FROM Room WHERE room_name LIKE N'ZZTEST%' AND NOT EXISTS (SELECT 1 FROM Showtime s WHERE s.room_id = Room.room_id)"
    $null = Invoke-Sql "DELETE FROM News WHERE title LIKE N'ZZTEST%'"
    $null = Invoke-Sql "DELETE FROM Voucher WHERE code LIKE 'ZZTEST%' AND NOT EXISTS (SELECT 1 FROM VoucherUsage vu WHERE vu.voucher_id = Voucher.voucher_id)"
    $null = Invoke-Sql "DELETE FROM Holiday WHERE holiday_name LIKE N'ZZTEST%'"
    $null = Invoke-Sql "UPDATE Users SET Status='ACTIVE' WHERE Email='admin@cinema.vn'"
    Write-Host '  da don du lieu ZZTEST (phim, phong, combo, tin tuc, voucher, ngay le)'
}

exit (Write-Result)
