<#
.SYNOPSIS
    Kiem thuc cac nhanh loi cua luong dat ve online (BF-02).

.DESCRIPTION
    Kiem tra 4 nhanh quan trong:
      A. HUY tren cong thanh toan -> don bi huy, ghe duoc tra ve (GREEN).
      B. WEBHOOK sai chu ky -> RspCode 97, don khong bi cap nhat.
      C. THANH TOAN TRUNG LAP (idempotency) -> ve khong duoc cap phat 2 lan.
      D. GHE CHUYEN RED sau khi thanh toan thanh cong.

    LUU Y: file nay phai duoc luu voi BOM UTF-8. Chay
    `scripts\ensure-utf8-bom.ps1 scripts` sau khi sua file.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/test-booking-errors.ps1
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://localhost:8080/CinemaWeb',
    [string]$Email = 'khach1@gmail.com',
    [string]$Password = '123456'
)

$ErrorActionPreference = 'Stop'
$script:Failures = @()

. "$PSScriptRoot\lib\booking-test-lib.ps1"

# =====================================================================
Write-Step 'A. HUY TREN CONG THANH TOAN'
$session = New-BookingSession -BaseUrl $BaseUrl -Email $Email -Password $Password
$showtimeId = Get-ShowtimeId -Session $session -BaseUrl $BaseUrl
Assert-Test ($showtimeId -gt 0) "lay duoc suat chien $showtimeId"

$seat = Get-FreeSeatIds -Session $session -BaseUrl $BaseUrl -ShowtimeId $showtimeId -Count 2
Assert-Test ([bool]$seat.ids) "chon ghe: $($seat.ids)"
if (-not $seat.ids) {
    Write-Host '  [LOI] khong con ghe trong o suat chien nay - het data test' -ForegroundColor Red
    $script:Failures += 'khong con ghe trong'
    exit (Write-Result)
}
$firstSeatId = ($seat.ids -split ',')[0]

Invoke-HoldSeats -Session $session -SeatsUrl $seat.url -ShowtimeId $showtimeId -SeatIds $seat.ids

# Ghe phai chuyen sang YELLOW (dang giu) sau khi giu.
$holdPage = Invoke-WebRequest -Uri $seat.url -WebSession $session -UseBasicParsing
Assert-Test ($holdPage.Content -match ('class="seat YELLOW"[^>]*data-id="' + $firstSeatId + '"')) `
    "ghe $firstSeatId dang duoc giu (YELLOW)"

$mockUrl = Get-MockPaymentUrl -Session $session -BaseUrl $BaseUrl
Assert-Test ($mockUrl.AbsolutePath -like '*/mock/payment*') 'den cong gia lap'

# Chon "Huy" -> cong gia lap chuyen ve voi vnp_ResponseCode != 00
$cancelReturn = Invoke-MockPayment -Session $session -MockUrl $mockUrl.AbsoluteUri -Decision 'cancel'
Write-Host "  cong tra ve: $cancelReturn"
Assert-Test ($cancelReturn -match 'vnp_ResponseCode=(?!00)') 'cong bao giao dich khong thanh cong'

# Phai theo chinh redirect cua cong de server xu ly ket qua huy.
$cancelCallback = Invoke-WebRequest -Uri $cancelReturn -WebSession $session -UseBasicParsing -MaximumRedirection 5
Assert-Test ($cancelCallback.BaseResponse.ResponseUri.AbsolutePath -like '*/booking/cancel-result*') `
    "server xu ly huy -> chuyen toi trang ket qua (thuoc: $($cancelCallback.BaseResponse.ResponseUri.AbsolutePath))"

$cancelPage = Invoke-WebRequest -Uri "$BaseUrl/booking/cancel-result" -WebSession $session -UseBasicParsing
Assert-Test ($cancelPage.StatusCode -eq 200) 'mo duoc trang ket qua huy'
Assert-Test ($cancelPage.Content.Contains(([char]0x0111 + [char]0x00E3))) `
    'trang ket qua huy co thong bao tieng Viet'

# Ghe phai duoc tra ve GREEN ngay sau khi huy (GBR-01).
# Kiem tra o day truoc khi buoc C giu lai ghe, neu khong se khong phan biet
# "ghe chua duoc tra" voi "ghe dang bi giu boi buoc sau".
$seatPage = Invoke-WebRequest -Uri $seat.url -WebSession $session -UseBasicParsing
$stillGreen = $false
if ($seatPage.Content -match ('class="seat GREEN"[^>]*data-id="' + $firstSeatId + '"')) {
    $stillGreen = $true
}
Assert-Test $stillGreen "ghe $firstSeatId da duoc tra ve trang thai GREEN"

# =====================================================================
Write-Step 'B. WEBHOOK SAI CHU KY'
$webhookUrl = "$BaseUrl/api/v1/commerce/payment/webhook/vnpay"
$before = Get-PaidTicketCount -Session $session -BaseUrl $BaseUrl

$body = @{
    vnp_TxnRef         = 'BK-NOT-EXIST'
    vnp_Amount         = '100000'
    vnp_TransactionNo  = 'FAKE-TXN'
    vnp_ResponseCode   = '00'
    vnp_SecureHash     = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
}
try {
    $hook = Invoke-WebRequest -Uri $webhookUrl -Method Post -Body $body -UseBasicParsing -TimeoutSec 20
    Write-Host "  phan hoi webhook: $($hook.Content)"
    Assert-Test ($hook.Content -match '"RspCode"\s*:\s*"97"') 'webhook tra RspCode 97 (chu ky sai)'
} catch {
    Assert-Test $false "webhook loi: $($_.Exception.Message)"
}

$after = Get-PaidTicketCount -Session $session -BaseUrl $BaseUrl
Assert-Test ($after.paid -eq $before.paid) `
    "webhook sai chu ky khong phat sinh ve moi (truoc: $($before.paid), sau: $($after.paid))"

# =====================================================================
Write-Step 'C. THANH TOAN TRUNG LAP (IDEMPOTENCY)'
$session = New-BookingSession -BaseUrl $BaseUrl -Email $Email -Password $Password
$showtimeId = Get-ShowtimeId -Session $session -BaseUrl $BaseUrl
$seat = Get-FreeSeatIds -Session $session -BaseUrl $BaseUrl -ShowtimeId $showtimeId -Count 2
Assert-Test ([bool]$seat.ids) "chon ghe: $($seat.ids)"
if (-not $seat.ids) {
    Write-Host '  [LOI] khong con ghe trong o suat chien nay - het data test' -ForegroundColor Red
    $script:Failures += 'khong con ghe trong'
    exit (Write-Result)
}
Invoke-HoldSeats -Session $session -SeatsUrl $seat.url -ShowtimeId $showtimeId -SeatIds $seat.ids

$mockUrl = Get-MockPaymentUrl -Session $session -BaseUrl $BaseUrl
$txnRef = ([regex]::Match($mockUrl.Query, 'vnp_TxnRef=([^&]+)')).Groups[1].Value
Assert-Test ([bool]$txnRef) "ma don: $txnRef"

$paidBefore = Get-PaidTicketCount -Session $session -BaseUrl $BaseUrl

# Thanh toan thanh cong — giu lai URL quay ve cua cong (co chu ky hop le).
$returnUrl = Invoke-MockPayment -Session $session -MockUrl $mockUrl.AbsoluteUri -Decision 'success'
Write-Host "  quay ve: $returnUrl"
Assert-Test ($returnUrl -match 'vnp_ResponseCode=00') 'cong bao thanh toan thanh cong'

$first = Invoke-WebRequest -Uri $returnUrl -WebSession $session -UseBasicParsing -MaximumRedirection 5
Assert-Test ($first.BaseResponse.ResponseUri.AbsolutePath -like '*/account/tickets*') `
    "chuyen toi lich su ve sau khi thanh toan (thuoc: $($first.BaseResponse.ResponseUri.AbsolutePath))"

$paidAfterFirst = Get-PaidTicketCount -Session $session -BaseUrl $BaseUrl
# Man hinh lich su ve hien thi 1 THE = 1 VE, nen so ve moi phai tang dung
# bang so ghe vua dat (ke ca ghe doi thi 2 the).
$expectedNew = ($seat.ids -split ',').Count
Assert-Test ($paidAfterFirst.paid -eq ($paidBefore.paid + $expectedNew)) `
    "ve duoc cap phat 1 lan: +$expectedNew the (truoc: $($paidBefore.paid), sau: $($paidAfterFirst.paid))"

# Goi lai chinh tham so do cong tra ve (mo phong webhook/IPN lap) -> khong cap phat ve 2 lan
$again = Invoke-WebRequest -Uri $returnUrl -WebSession $session -UseBasicParsing -MaximumRedirection 5
Assert-Test ($again.StatusCode -eq 200) 'goi lai callback khong loi'
Assert-Test ($again.BaseResponse.ResponseUri.AbsolutePath -like '*/account/tickets*') `
    "van chuyen toi lich su ve (thuoc: $($again.BaseResponse.ResponseUri.AbsolutePath))"

$paidAfterSecond = Get-PaidTicketCount -Session $session -BaseUrl $BaseUrl
Assert-Test ($paidAfterSecond.paid -eq $paidAfterFirst.paid) `
    "ve KHONG duoc cap phat 2 lan (truoc: $($paidAfterFirst.paid), sau: $($paidAfterSecond.paid))"

# =====================================================================
Write-Step 'D. GHE DUOC TRA LAI SAU KHI THANH TOAN THAT BAI'
# Don da thanh toan -> ghe phai chuyen RED (da ban), khong phai GREEN.
$seatPage2 = Invoke-WebRequest -Uri $seat.url -WebSession $session -UseBasicParsing
$seatAfterPay = ($seat.ids -split ',')[0]
$isRed = $false
if ($seatPage2.Content -match ('class="seat RED"[^>]*data-id="' + $seatAfterPay + '"')) {
    $isRed = $true
}
Assert-Test $isRed "ghe $seatAfterPay da chuyen sang RED sau khi thanh toan"

exit (Write-Result)
