# Script tam thoi: kiem thuc rieng phan STAFF - thu tien mat va thong bao tien thoi lai.
# Khong sua file test chinh; dung de chay nhanh khi phan ADMIN/MANAGER co loi pre-existing.
param([string]$BaseUrl = 'http://localhost:8080/CinemaWeb')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\booking-test-lib.ps1')
. (Join-Path $PSScriptRoot 'lib/test-config.ps1')
$root = Split-Path -Parent $PSScriptRoot
$sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
$sqlAuth = Get-SqlCmdAuth

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

# Gia tri so (khong dau phay) cho so tien VND.
function To-Number([string]$s) { return ($s -replace '[^\d]', '') -as [long] }

$staff = New-RoleSession 'staff@cinema.vn'
$todayEnd = (Get-Date).Date.AddDays(1).ToString('yyyy-MM-dd')
$created = @()

function Get-FreeSeatIds($S, [string]$ShowtimeId) {
    $html = (Get-Page $S "/staff/counter?action=seats&showtimeId=$ShowtimeId").Content
    return [regex]::Matches($html, 'class="seat GREEN"[^>]*data-id="(\d+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
}

Write-Step 'STAFF - man hinh thanh toan co o xem truoc tien thoi lai'
$cSt = Invoke-Sql "SELECT TOP 1 s.showtime_id FROM Showtime s WHERE s.status='Scheduled' AND s.start_time > SYSDATETIME() AND s.start_time < '$todayEnd' AND NOT EXISTS (SELECT 1 FROM Ticket t WHERE t.showtime_id=s.showtime_id) ORDER BY s.start_time"
if (-not ($cSt -match '^\d+$')) {
    Write-Host '  [INFO] khong co suat chieu hom nay de thu' -ForegroundColor Yellow
    exit (Write-Result)
}
$free = @(Get-FreeSeatIds $staff $cSt)
if ($free.Count -eq 0) { Write-Host '  [INFO] het ghe trong' -ForegroundColor Yellow; exit (Write-Result) }
$seatA = $free[0]

$r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seatA" } "/staff/counter?action=seats&showtimeId=$cSt"
$bk = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bk -match '^\d+$') "giu ghe $seatA thanh cong (booking_id=$bk)"
$created += $bk

$ck = Get-Page $staff '/staff/counter?action=checkout'
Assert-Test ($ck.StatusCode -eq 200) 'man hinh thanh toan tai quay mo duoc'
Assert-Test ($ck.Content -match 'cashChangePreview' -and $ck.Content -match 'cashChangeAmount') 'co o xem truoc tien thoi lai tren man hinh thanh toan'
# Tong phai thu duoc render thanh so (khong phai chuoi) de mayy tinh tien thoi lai.
$totalRendered = [regex]::Match($ck.Content, 'var\s+totalDue\s*=\s*(\d+)\s*;').Groups[1].Value
Assert-Test ($totalRendered -match '^\d+$' -and [long]$totalRendered -gt 0) "tong phai thu duoc truyen sang mayy tinh tien thoi lai (totalDue: $totalRendered)"
$totalDb = To-Number (Invoke-Sql "SELECT total_amount FROM Booking WHERE booking_id=$bk")
Assert-Test ("$totalRendered" -eq "$totalDb") "totalDue tren man hinh khop voi tong phai thu trong DB ($totalRendered vs $totalDb)"
Assert-Test ($ck.Content -match 'updateChangePreview') 'co script tinh tien thoi lai theo thoi gian thuc'

Write-Step 'STAFF - thu tien mat, khach dua thua -> thong bao tien thoi lai'
# Lay tong phai thu cua don vua giu de tinh tien thoi lai mong doi.
$total = To-Number (Invoke-Sql "SELECT total_amount FROM Booking WHERE booking_id=$bk")
Assert-Test ($total -gt 0) "lay duoc tong phai thu cua don (total: $total)"
$given = $total + 50000
$r = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = "$given" } '/staff/counter?action=checkout'

Assert-Test ($r.status -eq 200) 'thanh toan tien mat thanh cong'
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk") -eq 'Paid') 'don da duoc ghi nhan thanh toan'
Assert-Test ((Invoke-Sql "SELECT TOP 1 method FROM Payment WHERE booking_id=$bk ORDER BY payment_id DESC") -eq 'Cash') 'thanh toan tien mat ghi method Cash'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Ticket WHERE booking_id=$bk AND status='Booked'") -ge '1') 've da phat hanh sau khi thu tien mat'

# Thong bao tien thoi lai phai xuat hien tren man hinh hoa don.
Assert-Test ($r.flashType -eq 'success') "co thong bao thanh cong (flash: $($r.flashType))"
Assert-Test ($r.flash -match '50\.000') "thong bao co so tien thoi lai 50.000 (flash: $($r.flash))"
Assert-Test ($r.flash -match 'Trả lại khách|tra lai khach') "thong bao noi ro phai tra lai tien cho khach (flash: $($r.flash))"

Assert-Test ($r.html -match 'change-box') 'hoa don co khung thong bao tien thoi lai'
Assert-Test ($r.html -match 'Trả lại khách') 'hoa don co dong "Tra lai khach"'
Assert-Test ($r.html -match '50\.000') 'hoa don hien so tien thoi lai 50.000'
$givenLabel = ([long]$given).ToString('#,###', [System.Globalization.CultureInfo]::InvariantCulture).Replace(',', '.')
Assert-Test ($r.html -match [regex]::Escape($givenLabel)) "hoa don hien tien khach dua theo dinh dang $givenLabel"
Assert-Test ($r.html -notmatch ">${given} đ<") 'hoa don khong hien tien chua dinh dang dau phay'
Assert-Test ($r.html -match 'Tiền thối lại khách') 'hoa don co dong "Tien thoi lai khach"'

Write-Step 'STAFF - khach dua dung tien -> khong co tien thoi lai'

Write-Step 'STAFF - server doc dung so tien co dau cham (140.000)'
# O nhap tien mat hien thi theo dinh dang 140.000 nen gui len server co dau cham.
# Server phai bo dau cham phan cach nghin va ghi nhan dung so tien.
$freeG = @(Get-FreeSeatIds $staff $cSt)
$seatG = $freeG[0]
$rG = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seatG" } "/staff/counter?action=seats&showtimeId=$cSt"
$bkG = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bkG -match '^\d+$') "giu ghe $seatG cho truong hop so tien co dau cham (booking_id=$bkG)"
$created += $bkG
$totalG = To-Number (Invoke-Sql "SELECT total_amount FROM Booking WHERE booking_id=$bkG")
$givenG = $totalG + 50000
$givenGText = ([long]$givenG).ToString('#,###', [System.Globalization.CultureInfo]::InvariantCulture).Replace(',', '.')
$rG = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = $givenGText } '/staff/counter?action=checkout'
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bkG") -eq 'Paid') "server chap nhan so tien co dau cham '$givenGText' va ghi nhan thanh toan"
Assert-Test ($rG.flash -match '50\.000') "thong bao tien thoi lai dung dinh dang (flash: $($rG.flash))"
Assert-Test ($rG.html -match [regex]::Escape($givenGText)) 'hoa don hien so tien khach dua dung dinh dang'
Assert-Test ($rG.html -notmatch ">${givenG} đ<") 'khong con so tien chua dinh dang tren hoa don'

$free2 = @(Get-FreeSeatIds $staff $cSt)
$seatB = $free2[0]
$r2 = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seatB" } "/staff/counter?action=seats&showtimeId=$cSt"
$bk2 = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bk2 -match '^\d+$') "giu ghe $seatB cho truong hop dua dung tien (booking_id=$bk2)"
$created += $bk2
$total2 = To-Number (Invoke-Sql "SELECT total_amount FROM Booking WHERE booking_id=$bk2")
$r2 = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = "$total2" } '/staff/counter?action=checkout'
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk2") -eq 'Paid') 'thanh toan tien mat (dung tien) thanh cong'
Assert-Test ($r2.flash -match 'đúng|đu') "thong bao bao khach dua dung tien (flash: $($r2.flash))"
Assert-Test ($r2.flash -notmatch 'Trả lại khách') 'khong thong bao tra lai tien khi khach dua dung so tien'
Assert-Test ($r2.html -match 'is-exact|exact') 'hoa don co trang thai khong co tien thoi lai'

Write-Step 'STAFF - khach dua chua du -> bi tu choi, khong duoc ghi nhan'
$free3 = @(Get-FreeSeatIds $staff $cSt)
$seatC = $free3[0]
$r3 = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seatC" } "/staff/counter?action=seats&showtimeId=$cSt"
$bk3 = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bk3 -match '^\d+$') "giu ghe $seatC cho truong hop dua thieu (booking_id=$bk3)"
$created += $bk3
$total3 = To-Number (Invoke-Sql "SELECT total_amount FROM Booking WHERE booking_id=$bk3")
$r3 = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = ($total3 - 10000) } '/staff/counter?action=checkout'
Assert-Test ($r3.flashType -eq 'error') "thong bao loi khi tien chua du (flash: $($r3.flashType))"
Assert-Test ($r3.flash -match 'chưa đủ|chua du') "thong bao noi ro tien chua du (flash: $($r3.flash))"
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk3") -ne 'Paid') 'don khong bi ghi nhan thanh toan khi tien chua du'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Payment WHERE booking_id=$bk3") -eq '0') 'khong sinh ban ghi Payment khi tien chua du'
$null = Send-Form $staff '/staff/counter' @{ action = 'cancelBooking' } '/staff/counter?action=checkout'

Write-Step 'DON DEP'
$ids = @($created) | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique
if ($ids.Count -gt 0) {
    $idList = ($ids | ForEach-Object { "$_" }) -join ','
    $null = Invoke-Sql "UPDATE Ticket SET status='Cancelled' WHERE booking_id IN ($idList); UPDATE Booking SET status='Cancelled' WHERE booking_id IN ($idList)"
    Write-Host '  da huy cac don thu'
}
exit (Write-Result)
