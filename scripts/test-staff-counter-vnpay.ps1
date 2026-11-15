# Script tam thoi: kiem thuc rieng phan STAFF - ban ve tai quay (VNPay + loc suat chien).
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

$staff = New-RoleSession 'staff@cinema.vn'
$todayEnd = (Get-Date).Date.AddDays(1).ToString('yyyy-MM-dd')

Write-Step 'STAFF - danh sach suat chien chi trong hom nay'
Assert-Test ((Get-Page $staff '/staff/counter').StatusCode -eq 200) 'trang ban ve tai quay mo duoc'
$listPage = Get-Page $staff '/staff/counter'
$listedIds = [regex]::Matches($listPage.Content, 'action=seats&showtimeId=(\d+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
Write-Host "  [INFO] so suat chien trong danh sach: $($listedIds.Count)"
if ($listedIds.Count -gt 0) {
    $inList = ($listedIds | ForEach-Object { "'$_'" }) -join ','
    $futureDay = Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE showtime_id IN ($inList) AND start_time >= '$todayEnd'"
    Assert-Test ($futureDay -eq '0') "danh sach khong co suat chien cua ngay sau (so sai: $futureDay)"
    $past = Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE showtime_id IN ($inList) AND start_time <= SYSDATETIME()"
    Assert-Test ($past -eq '0') "danh sach khong co suat chien da qua gio (so sai: $past)"
    $allToday = Invoke-Sql "SELECT COUNT(*) FROM Showtime WHERE showtime_id IN ($inList) AND start_time < '$todayEnd'"
    Assert-Test ($allToday -eq $listedIds.Count) 'moi suat chien trong danh sach deu thuoc hom nay'
} else {
    Write-Host '  [INFO] hom nay khong co suat chien con ban duoc'
}

$cSt = Invoke-Sql "SELECT TOP 1 s.showtime_id FROM Showtime s WHERE s.status='Scheduled' AND s.start_time > SYSDATETIME() AND s.start_time < '$todayEnd' AND NOT EXISTS (SELECT 1 FROM Ticket t WHERE t.showtime_id=s.showtime_id) ORDER BY s.start_time"
if (-not ($cSt -match '^\d+$')) {
    Write-Host '  [INFO] khong co suat chieu hom nay de thu' -ForegroundColor Yellow
    exit (Write-Result)
}

Write-Step 'STAFF - chon ghế + man hinh thanh toan'
$sp = Get-Page $staff "/staff/counter?action=seats&showtimeId=$cSt"
Assert-Test ($sp.StatusCode -eq 200) "so do ghe tai quay cho suat $cSt mo duoc"
Assert-Test ($sp.Content -match 'sg-type' -and $sp.Content -match 'id="selTotal"') 'so do ghe co chu thich loai ghe, gia ve va tam tinh'
$free = [regex]::Matches($sp.Content, 'class="seat GREEN"[^>]*data-id="(\d+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
Assert-Test ($free.Count -gt 0) "co ghhe trong de chon (so ghe: $($free.Count))"
$seat1 = @($free)[0]; $seat2 = @($free)[1]
$r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seat1" } "/staff/counter?action=seats&showtimeId=$cSt"
$bk = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bk -match '^\d+$') "giu ghe $seat1 thanh cong (booking_id=$bk)"
$ck = Get-Page $staff '/staff/counter?action=checkout'
Assert-Test ($ck.StatusCode -eq 200) 'man hinh thanh toan tai quay mo duoc'
Assert-Test ($ck.Content -match 'payGateway' -and $ck.Content -match 'VNPAY') 'man hinh thanh toan co lua chon VNPAY'
Assert-Test ($ck.Content -match 'cashReceived' -and $ck.Content -match 'data-pay-method="cash"') 'man hinh thanh toan giu lua chon tien mat'

Write-Step 'STAFF - thanh toan VNPAY'
$payRes = Invoke-NoRedirect -Uri "$BaseUrl/staff/counter" -Body @{ _csrf = (Get-Token $staff '/staff/counter?action=checkout'); action = 'payGateway' } -Session $staff
$gatewayLocation = Get-RedirectLocation -Response $payRes
$payRes.Close()
Assert-Test ($gatewayLocation -match '/mock/payment|/paymentv2|vnpayment') "chuyen huong sang cong thanh toan (dia chi: $gatewayLocation)"
$txnRef = ([regex]::Match($gatewayLocation, 'vnp_TxnRef=([^&]+)')).Groups[1].Value
Assert-Test ($txnRef -match '^BK') "vnp_TxnRef la ma don tai quay (txnRef: $txnRef)"
Assert-Test ($gatewayLocation -match 'staff%2Fcounter%2Fpayment%2Freturn') 'returnUrl tro ve kenh quay'
$isMockGateway = $gatewayLocation -match '/mock/payment'
if ($isMockGateway) {
    $ret = Invoke-MockPayment -Session $staff -MockUrl $gatewayLocation -Decision 'success'
    Assert-Test ($ret -like '*/staff/counter/payment/return*') 'cong gia lap tra ve kem chu ky hop ve kenh quay'
    # Lan truy cap DONG dau tien: session con giu booking_id -> man hinh hoa don.
    # (Truy cap them lan nua se bi chuyen ve danh sach vi da xoa booking_id khoi session.)
    $final = Invoke-WebRequest -Uri $ret -WebSession $staff -UseBasicParsing -MaximumRedirection 5
    Assert-Test ($final.Content -match 'Thanh toán thành công') 'hien thi man hinh hoa don sau khi thanh toan VNPAY'
    Assert-Test ($final.Content -match 'voucher-code') 'hoa don co ma ve de soat'
} else {
    # Cong VNPAY that (sandbox.vnpayment.vn): phai thao tac tay tren trinh duyet
    # cua VNPAY nen khong kiem tra duoc phan ghi nhan thanh toan.
    Write-Host '  [INFO] dang dung cong VNPAY that - BO QUA buoc xac nhan thanh toan tu dong.' -ForegroundColor Yellow
    Write-Host '         Hay mo link cong tren trinh duyet, thanh toan tren sandbox,' -ForegroundColor Yellow
    Write-Host '         roi chay lai script de kiem tra don hang.' -ForegroundColor Yellow
}
if ($isMockGateway) {
    $vnpPaid = Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk"
    Assert-Test ($vnpPaid -eq 'Paid') "don da duoc ghi nhan thanh toan (trang thai: $vnpPaid)"
    $vnpMethod = Invoke-Sql "SELECT TOP 1 method FROM Payment WHERE booking_id=$bk ORDER BY payment_id DESC"
    Assert-Test ($vnpMethod -eq 'BankTransfer') "thanh toan VNPAY ghi method BankTransfer (method: $vnpMethod)"
    $vnpTxn = Invoke-Sql "SELECT TOP 1 ISNULL(gateway_txn_id,'') FROM Payment WHERE booking_id=$bk ORDER BY payment_id DESC"
    Assert-Test ($vnpTxn -ne '') "giao dich VNPAY co ma giao dich (txn: $vnpTxn)"
    Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Ticket WHERE booking_id=$bk AND status='Booked'") -ge '1') 've da phat hanh (Booked)'
}

Write-Step 'STAFF - thanh toan tien mat (luu duong cu)'
$r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seat2" } "/staff/counter?action=seats&showtimeId=$cSt"
$bkCash = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
$r = Send-Form $staff '/staff/counter' @{ action = 'pay'; cashReceived = '1000000' } '/staff/counter?action=checkout'
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bkCash") -eq 'Paid') 'thanh toan tien mat thanh cong'
Assert-Test ((Invoke-Sql "SELECT TOP 1 method FROM Payment WHERE booking_id=$bkCash ORDER BY payment_id DESC") -eq 'Cash') 'thanh toan tien mat ghi method Cash'
Assert-Test ((Invoke-Sql "SELECT COUNT(*) FROM Ticket WHERE booking_id=$bkCash AND status='Booked'") -ge '1') 've da phat hanh sau khi thu tien mat'

Write-Step 'STAFF - huy don giu cho'
# Phai dung ghe TRONG: ghe $seat2 da duoc ban trong buoc thanh toan tien mat.
$free2 = [regex]::Matches((Get-Page $staff "/staff/counter?action=seats&showtimeId=$cSt").Content, 'class="seat GREEN"[^>]*data-id="(\d+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$seatCancel = @($free2)[0]
$r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $cSt; seatIds = "$seatCancel" } "/staff/counter?action=seats&showtimeId=$cSt"
$bk2 = Invoke-Sql "SELECT TOP 1 booking_id FROM Booking WHERE channel='Counter' AND showtime_id=$cSt AND status IN ('Selecting','PendingPayment') ORDER BY booking_id DESC"
Assert-Test ($bk2 -match '^\d+$') "giu ghe $seatCancel de huy (booking_id=$bk2)"
$r = Send-Form $staff '/staff/counter' @{ action = 'cancelBooking' } '/staff/counter?action=checkout'
Assert-Test ((Invoke-Sql "SELECT status FROM Booking WHERE booking_id=$bk2") -in 'Cancelled', 'Expired') 'huy don dang giu cho tra ghe'

Write-Step 'STAFF - tu choi suat chien da qua gio'
$pastSt = Invoke-Sql "SELECT TOP 1 showtime_id FROM Showtime WHERE status='Scheduled' AND start_time <= SYSDATETIME() ORDER BY start_time DESC"
if ($pastSt -match '^\d+$') {
    $before = Invoke-Sql "SELECT COUNT(*) FROM Booking WHERE channel='Counter' AND showtime_id=$pastSt"
    $r = Send-Form $staff '/staff/counter' @{ action = 'hold'; showtimeId = $pastSt; seatIds = "$seat1" } "/staff/counter?action=seats&showtimeId=$pastSt"
    $after = Invoke-Sql "SELECT COUNT(*) FROM Booking WHERE channel='Counter' AND showtime_id=$pastSt"
    Assert-Test ($after -eq $before) 'khong tao duoc don cho suat chien da qua gio'
    Assert-Test ($r.flashType -eq 'error' -or $r.status -ge 400) "thong bao loi khi chon suat chien da qua gio (flash: $($r.flashType))"
} else {
    Write-Host '  [INFO] khong co suat chien da qua gio de thu'
}

Write-Step 'DON DEP'
$ids = @($bk, $bkCash, $bk2) | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique
if ($ids.Count -gt 0) {
    $idList = ($ids | ForEach-Object { "$_" }) -join ','
    $null = Invoke-Sql "UPDATE Ticket SET status='Cancelled' WHERE booking_id IN ($idList); UPDATE Booking SET status='Cancelled' WHERE booking_id IN ($idList)"
}
Write-Host '  da huy cac don thu'

exit (Write-Result)
