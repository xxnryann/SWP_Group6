<#
    Cau hinh dung chung cho cac script kiem thu / tien ich (dot-source: . lib\test-config.ps1).

    Bien moi truong (deu tuy chon):
      CINEMA_BASE_URL      Dia chi goc ung dung, vd http://localhost:9999/CinemaTest
                           (khong dat -> tu do thu cac dia chi mac dinh, lay dia chi dang chay)
      CINEMA_TEST_PASSWORD Mat khau cac tai khoan seed dung de dang nhap (mac dinh: mat khau seed trong README)
      CINEMA_DB_WINAUTH    =1 de sqlcmd dung xac thuc Windows (-E), khong can mat khau SQL
      CINEMA_DB_USER       Tai khoan SQL (mac dinh doc db.user trong src/java/app.properties)
      CINEMA_DB_PASSWORD   Mat khau SQL    (mac dinh doc db.password trong src/java/app.properties)

    Mat khau SQL KHONG BAO GIO duoc truyen qua tham so dong lenh (-P) vi se hien trong danh sach tien trinh;
    no duoc dua cho sqlcmd qua bien moi truong SQLCMDPASSWORD cua rieng tien trinh nay.
#>

$script:CinemaRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Get-CinemaBaseUrl {
    if ($env:CINEMA_BASE_URL) { return $env:CINEMA_BASE_URL.TrimEnd('/') }
    $candidates = @('http://localhost:9999/CinemaTest', 'http://localhost:8080/CinemaWeb')
    foreach ($url in $candidates) {
        try {
            $null = Invoke-WebRequest "$url/login" -UseBasicParsing -TimeoutSec 3
            return $url
        } catch { }
    }
    return $candidates[-1]
}

function Get-CinemaTestPassword {
    if ($env:CINEMA_TEST_PASSWORD) { return $env:CINEMA_TEST_PASSWORD }
    return '123456'
}

function Get-AppProperty([string]$Key) {
    $file = Join-Path $script:CinemaRoot 'src\java\app.properties'
    if (-not (Test-Path $file)) { return $null }
    $line = Get-Content $file | Where-Object { $_ -match ('^\s*' + [regex]::Escape($Key) + '\s*=') } | Select-Object -First 1
    if (-not $line) { return $null }
    return ($line -split '=', 2)[1].Trim()
}

<#
    Tra ve mang tham so xac thuc cho sqlcmd ('-E' hoac '-U <user>') va dat SQLCMDPASSWORD trong tien trinh nay.
    Dung: & sqlcmd -S server @(Get-SqlCmdAuth) -d CinemaWebDB ...
#>
function Get-SqlCmdAuth {
    if ($env:CINEMA_DB_WINAUTH -eq '1') { return @('-E') }
    $user = if ($env:CINEMA_DB_USER) { $env:CINEMA_DB_USER } else { Get-AppProperty 'db.user' }
    $pass = if ($env:CINEMA_DB_PASSWORD) { $env:CINEMA_DB_PASSWORD } else { Get-AppProperty 'db.password' }
    if (-not $user) { throw 'Thieu tai khoan SQL: dat CINEMA_DB_USER / CINEMA_DB_PASSWORD, hoac CINEMA_DB_WINAUTH=1.' }
    $env:SQLCMDPASSWORD = $pass
    return @('-U', $user)
}
