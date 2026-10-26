<#
    .SYNOPSIS
        Kiem thuer nhanh toan bo ung dung (smoke test).

    .DESCRIPTION
        Kiem tra nhanh cac trang chinh cua 5 vai tro tra HTTP 200:
          - Guest   : trang chu, danh sach phim, lich chien, tin tuc, dang nhap, dang ky
          - Customer: ho so, lich su ve, bien dong MyPoint, doi mat khau
          - Staff   : ban ve tai quay, quan ly combo
          - Manager : quan ly phim, lich chien, tin tuc
          - Admin   : quan ly nguoi dung, phong, so do ghe

        Kiem tra them: /booking/* yeu cau dang nhap (chuyen ve /login).

    .EXAMPLE
        powershell -ExecutionPolicy Bypass -File scripts/test-smoke.ps1
#>
$ErrorActionPreference = 'Stop'

$BaseUrl = if ($env:CINEMA_BASE_URL) { $env:CINEMA_BASE_URL } else { 'http://localhost:8080/CinemaWeb' }
$script:Fail = 0

function New-LoggedSession {
    <#
    .SYNOPSIS
        Dang nhop va tra ve WebRequestSession.
    #>
    param([Parameter(Mandatory = $true)][string]$Email)
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $loginUrl = "$BaseUrl/login"
    $page = Invoke-WebRequest -Uri $loginUrl -WebSession $session -UseBasicParsing
    $match = [regex]::Match($page.Content, 'name="_csrf"\s+value="([^"]+)"')
    if (-not $match.Success) { throw 'khong lay duoc CSRF token cua trang dang nhap' }
    Invoke-WebRequest -Uri $loginUrl -Method Post -WebSession $session -UseBasicParsing `
        -MaximumRedirection 5 `
        -Body @{ _csrf = $match.Groups[1].Value; identifier = $Email; password = '123456' } | Out-Null
    return $session
}

function Test-Page {
    <#
    .SYNOPSIS
        Kiem tra mot URL tra HTTP 200.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        $Session,
        [string]$Label = ''
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -WebSession $Session -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host ("  [OK]   {0,-10} {1,-28} HTTP {2}" -f $Label, $Url, $response.StatusCode) -ForegroundColor Green
        } else {
            Write-Host ("  [FAIL] {0,-10} {1,-28} HTTP {2}" -f $Label, $Url, $response.StatusCode) -ForegroundColor Red
            $script:Fail++
        }
    } catch {
        Write-Host ("  [FAIL] {0,-10} {1,-28} {2}" -f $Label, $Url, $_.Exception.Message) -ForegroundColor Red
        $script:Fail++
    }
}

Write-Host "`n=== GUEST ===" -ForegroundColor Cyan
$guest = New-Object Microsoft.PowerShell.Commands.WebRequestSession
foreach ($path in @('/', '/movies', '/showtimes', '/news', '/login', '/register')) {
    Test-Page -Url ($BaseUrl + $path) -Session $guest -Label 'GUEST'
}

Write-Host "`n=== CUSTOMER ===" -ForegroundColor Cyan
$customer = New-LoggedSession -Email 'khach1@gmail.com'
foreach ($path in @('/account/profile', '/account/tickets', '/account/points', '/account/password')) {
    Test-Page -Url ($BaseUrl + $path) -Session $customer -Label 'CUSTOMER'
}

Write-Host "`n=== STAFF ===" -ForegroundColor Cyan
$staff = New-LoggedSession -Email 'staff@cinema.vn'
foreach ($path in @('/staff/counter', '/staff/combo')) {
    Test-Page -Url ($BaseUrl + $path) -Session $staff -Label 'STAFF'
}

Write-Host "`n=== MANAGER ===" -ForegroundColor Cyan
$manager = New-LoggedSession -Email 'manager@cinema.vn'
foreach ($path in @('/manage/movies', '/manage/showtimes', '/manager/news')) {
    Test-Page -Url ($BaseUrl + $path) -Session $manager -Label 'MANAGER'
}

Write-Host "`n=== ADMIN ===" -ForegroundColor Cyan
$admin = New-LoggedSession -Email 'admin@cinema.vn'
# /admin/seats can roomId de load so do ghe.
foreach ($path in @('/admin/users', '/admin/rooms', '/admin/seats?roomId=1')) {
    Test-Page -Url ($BaseUrl + $path) -Session $admin -Label 'ADMIN'
}

Write-Host "`n=== BAO VE /booking/* ===" -ForegroundColor Cyan
$request = [System.Net.HttpWebRequest]::Create("$BaseUrl/booking/seats?showtimeId=2")
$request.AllowAutoRedirect = $false
$request.UserAgent = 'smoke-test'
$code = 0
$location = ''
try {
    $response = $request.GetResponse()
    $code = [int]$response.StatusCode
    $location = $response.Headers['Location']
    $response.Close()
} catch [System.Net.WebException] {
    $errorResponse = $_.Exception.Response
    $code = [int]$errorResponse.StatusCode
    $location = $errorResponse.Headers['Location']
    $errorResponse.Close()
}
if ($code -eq 302 -and $location -like '*login*') {
    Write-Host '  [OK]   /booking/seats chuyen ve /login khi chua dang nhap' -ForegroundColor Green
} else {
    Write-Host ("  [FAIL] /booking/seats tra {0} (Location={1})" -f $code, $location) -ForegroundColor Red
    $script:Fail++
}

if ($script:Fail -eq 0) {
    Write-Host "`nSMOKE TEST PASS" -ForegroundColor Green
    exit 0
}
Write-Host ("`nSMOKE TEST FAIL: {0} loi" -f $script:Fail) -ForegroundColor Red
exit 1
