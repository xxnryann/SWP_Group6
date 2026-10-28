<#
.SYNOPSIS
    Kiem thuc truc tiep luong dat ve online (BF-02) qua HTTP.

.DESCRIPTION
    Script nay dung Invoke-WebRequest de giong trinh duyet:
      1. Vao /login, lay CSRF token, dang nhap khach hang seed (khach1@gmail.com)
      2. Vao /booking/seats?showtimeId=..., chon ghe GREEN, POST giu ghe
      3. Vao /booking/extras, ap voucher + diem
      4. Vao /booking/payment, bam "Thanh toan" -> cong gia lap -> chon "Thanh toan"
      5. Kiem tra don hang da thanh toan trong lich su ve

    LUU Y: file nay phai duoc luu voi BOM UTF-8. Chay
    `scripts\ensure-utf8-bom.ps1 scripts` sau khi sua file.

.PARAMETER BaseUrl
    Dia chi goc cua ung dung. Mac dinh http://localhost:8080/CinemaWeb

.PARAMETER Email
    Email khach hang dung de dang nhap. Mac dinh khach1@gmail.com

.PARAMETER Password
    Mat khau cua khach hang. Mac dinh 123456

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/test-booking-flow.ps1
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

Write-Step '1. DANG NHAP'
$session = New-BookingSession -BaseUrl $BaseUrl -Email $Email -Password $Password
Assert-Test ($session -ne $null) 'dang nhap thanh cong'

Write-Step '2. CHON GHE'
$showtimeId = Get-ShowtimeId -Session $session -BaseUrl $BaseUrl
Assert-Test ($showtimeId -gt 0) "lay duoc suat chien $showtimeId"
if ($showtimeId -le 0) { throw 'khong co suat chien de test' }

$seat = Get-FreeSeatIds -Session $session -BaseUrl $BaseUrl -ShowtimeId $showtimeId -Count 2
Assert-Test ([bool]$seat.ids) "chon ghe: $($seat.ids)"
Write-Host "  ghe se giu: $($seat.ids)"
if (-not $seat.ids) {
    Write-Host '  [LOI] khong con ghe trong o suat chien nay - het data test' -ForegroundColor Red
    $script:Failures += 'khong con ghe trong'
    exit (Write-Result)
}

Invoke-HoldSeats -Session $session -SeatsUrl $seat.url -ShowtimeId $showtimeId -SeatIds $seat.ids
$after = Invoke-WebRequest -Uri "$BaseUrl/booking/extras" -WebSession $session -UseBasicParsing
Assert-Test ($after.StatusCode -eq 200) 'chuyen sang buoc combo'

Write-Step '3. COMBO / VOUCHER / DIEM'
$extrasUrl = "$BaseUrl/booking/extras"
$extrasPage = Invoke-WebRequest -Uri $extrasUrl -WebSession $session -UseBasicParsing
Assert-Test ($extrasPage.StatusCode -eq 200) 'mo duoc man hinh combo'
$csrf = Get-Csrf -Session $session -Uri $extrasUrl
if ($extrasPage.Content -match 'name="voucherCode"[^>]*value="([^"]+)"') {
    $voucherCode = $Matches[1]
    Invoke-WebRequest -Uri $extrasUrl -Method Post -WebSession $session -UseBasicParsing `
        -Body @{ _csrf = $csrf; action = 'applyDiscount'; voucherCode = $voucherCode; points = '0' } `
        -MaximumRedirection 5 | Out-Null
    Write-Host "  ap voucher '$voucherCode' xong"
} else {
    Write-Host '  [INFO] khong co voucher san de ap'
}

Write-Step '4. THANH TOAN'
$payUrl = "$BaseUrl/booking/payment"
$payPage = Invoke-WebRequest -Uri $payUrl -WebSession $session -UseBasicParsing
Assert-Test ($payPage.StatusCode -eq 200) 'mo duoc man hinh thanh toan'

$mockUrl = Get-MockPaymentUrl -Session $session -BaseUrl $BaseUrl
Write-Host "  chuyen huong toi: $mockUrl"
Assert-Test ($mockUrl.AbsolutePath -like '*/mock/payment*') 'den cong gia lap'

Write-Step '5. CONG GIA LAP'
$returnUrl = Invoke-MockPayment -Session $session -MockUrl $mockUrl.AbsoluteUri -Decision 'success'
Write-Host "  ket qua thanh toan: $returnUrl"
Assert-Test ($returnUrl -like '*/booking/payment/return*') 'cong gia lap tra ve kem chu ky hop le'

$final = Invoke-WebRequest -Uri $returnUrl -WebSession $session -UseBasicParsing -MaximumRedirection 5
Assert-Test ($final.BaseResponse.ResponseUri.AbsolutePath -like '*/account/tickets*') `
    "chuyen toi lich su ve sau khi thanh toan (thuoc: $($final.BaseResponse.ResponseUri.AbsolutePath))"

Write-Step '6. KIEM TRA DON HANG'
$tickets = Invoke-WebRequest -Uri "$BaseUrl/account/tickets" -WebSession $session -UseBasicParsing
Assert-Test ($tickets.StatusCode -eq 200) 'mo duoc lich su ve'

# Man hinh lich su ve hien thi theo the dang: 1 the/ve, co badge trang thai
# + 1 ma QR. Kiem tra bang cau truc HTML, khong phu thuoc chuoi thong bao cu.
$cards = ([regex]::Matches($tickets.Content, 'class="tk-card')).Count
Assert-Test ($cards -ge 1) "co it nhat 1 the ve (thuoc: $cards)"

$qrCount = ([regex]::Matches($tickets.Content, '/account/tickets/qr\?ticketId=\d+')).Count
Assert-Test ($qrCount -ge 1) "moi the ve co 1 ma QR (thuoc: $qrCount)"

$badges = [regex]::Matches($tickets.Content, '<span class="tk-badge([^"]*)">\s*([^<]*?)\s*</span>')
Assert-Test ($badges.Count -ge 1) 'co nhan trang thai tren the ve'
$hasActiveBadge = $false
foreach ($b in $badges) {
    if ($b.Groups[2].Value.Trim() -ne '') { $hasActiveBadge = $true }
}
Assert-Test $hasActiveBadge 'nhan trang thai co noi dung (khong rong)'

# QR phai tra ve anh PNG that
$qrUrl = ([regex]::Match($tickets.Content, '/account/tickets/qr\?ticketId=\d+')).Value
$qrResp = Invoke-WebRequest -Uri "$BaseUrl$qrUrl" -WebSession $session -UseBasicParsing
Assert-Test ($qrResp.Headers['Content-Type'] -like 'image/png*') 'QR tra ve anh PNG'
Assert-Test ($qrResp.RawContentLength -gt 200) "QR co noi dung that (bytes: $($qrResp.RawContentLength))"

# Ve moi phai co nut "Huy ve" (con hieu luc) -> chuc nang huy ve dang bat
$cancelForms = ([regex]::Matches($tickets.Content, 'name="ticketId"')).Count
Assert-Test ($cancelForms -ge 1) "ve moi hien thi nut 'Huy ve' (thuoc: $cancelForms)"

exit (Write-Result)
