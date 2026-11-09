<#
    Mo trang thong tin ve (QR) ra Internet bang Cloudflare Quick Tunnel, de dien thoai o mang bat ky (ca 4G) quet duoc.

    - Chay scripts\ticket-proxy.js: chi cho /ticket/view?code=TK... di qua, moi trang khac tra 404.
    - Chay cloudflared tunnel toi proxy, lay dia chi https://xxx.trycloudflare.com.
    - Ghi dia chi do vao file app.public.url.file (trong src\java\app.properties); ung dung doc file nay moi lan
      sinh QR nen KHONG can deploy lai. Tat tunnel => xoa file => QR quay ve app.public.url.

    Dung:
      .\scripts\public-qr.ps1          # bat; giu cua so mo, nhan Ctrl+C hoac Enter de tat
      .\scripts\public-qr.ps1 -Stop    # tat tunnel dang chay (vd khi da chay o cua so khac)

    Luu y: dia chi trycloudflare doi moi lan bat lai, QR cu se khong mo duoc nua (QR tren trang ve luon sinh lai theo dia chi moi).
#>
param(
    [switch]$Stop,
    [string]$Cloudflared = "$env:USERPROFILE\tools\cloudflared\cloudflared.exe",
    [string]$AppUrl = 'http://127.0.0.1:9999/CinemaTest',
    [int]$ProxyPort = 9998
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\test-config.ps1')

$urlFile = Get-AppProperty 'app.public.url.file'
if (-not $urlFile) { throw 'Thieu app.public.url.file trong src\java\app.properties (xem app.properties.example).' }
$stateDir = Split-Path -Parent $urlFile
$pidFile = Join-Path $stateDir 'public-qr.pids'
$logFile = Join-Path $stateDir 'cloudflared.log'

function Stop-PublicQr {
    if (Test-Path $pidFile) {
        foreach ($id in (Get-Content $pidFile)) { Stop-Process -Id ([int]$id) -Force -ErrorAction SilentlyContinue }
        Remove-Item $pidFile -Force
    }
    if (Test-Path $urlFile) { Remove-Item $urlFile -Force }
}

if ($Stop) { Stop-PublicQr; 'Da tat tunnel. QR quay ve dia chi app.public.url.'; return }

if (-not (Test-Path $Cloudflared)) { throw "Khong thay cloudflared: $Cloudflared" }
New-Item -ItemType Directory -Force $stateDir | Out-Null
Stop-PublicQr
if (Test-Path $logFile) { Remove-Item $logFile -Force }

try {
    $null = Invoke-WebRequest "$AppUrl/login" -UseBasicParsing -TimeoutSec 15
} catch { throw "Website chua chay tai $AppUrl" }

$proxy = Start-Process node -ArgumentList @("`"$(Join-Path $PSScriptRoot 'ticket-proxy.js')`"", $ProxyPort, $AppUrl) -WindowStyle Hidden -PassThru
$tunnel = Start-Process $Cloudflared -ArgumentList @('tunnel', '--no-autoupdate', '--protocol', 'http2', '--url', "http://127.0.0.1:$ProxyPort", '--logfile', "`"$logFile`"") -WindowStyle Hidden -PassThru
@($proxy.Id, $tunnel.Id) | Set-Content $pidFile

try {
    $public = $null
    $deadline = (Get-Date).AddSeconds(60)
    while (-not $public -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if ($tunnel.HasExited) { throw 'cloudflared da dung, xem log: ' + $logFile }
        if (Test-Path $logFile) {
            $m = Select-String -Path $logFile -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -First 1
            if ($m) { $public = $m.Matches[0].Value }
        }
    }
    if (-not $public) { throw 'Khong lay duoc dia chi tunnel sau 60 giay, xem log: ' + $logFile }
    # cho tunnel ket noi that toi Cloudflare (co dia chi chua chac da ket noi duoc)
    $deadline = (Get-Date).AddSeconds(60)
    while (-not (Select-String -Path $logFile -Pattern 'Registered tunnel connection' -Quiet)) {
        if ($tunnel.HasExited -or (Get-Date) -gt $deadline) { throw 'Tunnel khong ket noi duoc toi Cloudflare (mang chan?), xem log: ' + $logFile }
        Start-Sleep -Milliseconds 500
    }

    # cho DNS cua dia chi moi san sang
    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
        try { $null = Invoke-WebRequest "$public/ticket/view?code=TK000000" -UseBasicParsing -TimeoutSec 10; break }
        catch { if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) { break }; Start-Sleep 2 }
    }

    [IO.File]::WriteAllText($urlFile, $public)
    ''
    "Tunnel dang chay: $public"
    'QR tren trang ve gio tro toi dia chi nay. Nhan Ctrl+C hoac Enter de tat.'
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        $null = Read-Host
    } else {
        while (-not $tunnel.HasExited) { Start-Sleep 5 }
    }
} finally {
    # Chi don file trang thai neu van la cua lan chay nay (khong xoa cua mot lan chay khac da bat lai sau do)
    if ((Test-Path $pidFile) -and @(Get-Content $pidFile) -contains "$($tunnel.Id)") {
        Stop-PublicQr
    } else {
        foreach ($p in $proxy, $tunnel) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    }
    'Da tat tunnel.'
}
