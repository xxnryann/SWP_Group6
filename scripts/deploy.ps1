<#
.SYNOPSIS
    Dong goi va trien khai project CinemaWeb len Tomcat (khong dung Maven).

.DESCRIPTION
    Bien dich source (scripts/build.ps1), roi copy thu muc web/ sang
    webapps/<context> cua Tomcat. Script tu dong:
      - Tim CATALINA_HOME (System property -> bien moi truong -> duong dan mac dinh)
      - Copy WEB-INF/classes, WEB-INF/views, WEB-INF/lib, web.xml, assets
      - Xoa thu muc temp/work cua ứng dụng để Tomcat nạp lại servlet

.PARAMETER TomcatHome
    Thu muc cai dat Tomcat. Mac dinh la bien moi truong CATALINA_HOME hoac
    "C:\Program Files\Apache Software Foundation\Tomcat 10.1".

.PARAMETER Context
    Context path cua ung dung. Mac dinh "CinemaWeb".

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/deploy.ps1
#>
[CmdletBinding()]
param(
    [string]$TomcatHome,
    [string]$Context = 'CinemaWeb'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

# --- Tim Tomcat ---
if (-not $TomcatHome) { $TomcatHome = $env:CATALINA_HOME }
if (-not $TomcatHome) { $TomcatHome = $env:CATALINA_BASE }
if (-not $TomcatHome) {
    $candidates = Get-ChildItem 'C:\Program Files\Apache Software Foundation' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'Tomcat*' }
    if ($candidates) { $TomcatHome = $candidates[0].FullName }
}
if (-not $TomcatHome -or -not (Test-Path (Join-Path $TomcatHome 'bin'))) {
    throw 'Khong tim thay Tomcat. Hay truyen -TomcatHome hoac dat CATALINA_HOME.'
}
Write-Host "Tomcat   : $TomcatHome"

# --- Build truoc ---
Write-Host '--- Build ---' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'build.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Build that bai.' }

# --- Deploy ---
$webSrc  = Join-Path $root 'web'
$webDest = Join-Path $TomcatHome "webapps\$Context"

Write-Host "Deploy  : $webDest" -ForegroundColor Cyan
if (-not (Test-Path $webDest)) {
    New-Item -ItemType Directory -Path $webDest | Out-Null
}

foreach ($item in @('assets', 'WEB-INF')) {
    $from = Join-Path $webSrc $item
    $to   = Join-Path $webDest $item
    if (-not (Test-Path $from)) { continue }
    if (Test-Path $to) {
        Remove-Item $to -Recurse -Force
    }
    Copy-Item $from $to -Recurse -Force
    Write-Host "  copied $item"
}

# --- Chuan hoa moi thoi gian file vua copy ---
# Tomcat cache JarFile theo (duong dan, lastModified, size). Copy-Item GIU NGUYEN
# LastWriteTime cua file nguon, nen jar moi co cung ten + cung size + cung
# LastWriteTime voi jar cu -> Tomcat tra ve Cache cu (tro toi file DA BI XOA)
# -> ClassNotFoundException (vi du JstlCoreTLV) va moi trang bao loi 500.
# Cham lai moi file da copy de buoc cache bi invalidate.
Get-ChildItem $webDest -Recurse -File -Force | ForEach-Object {
    $_.LastWriteTime = Get-Date
}

$webXml = Join-Path $webSrc 'WEB-INF\web.xml'
if (Test-Path $webXml) {
    Copy-Item $webXml (Join-Path $webDest 'WEB-INF\web.xml') -Force
}

# --- Don cache deploy (JSP bien dich + work dir) ---
foreach ($temp in @("$TomcatHome\work\Catalina\localhost\$Context",
                    "$TomcatHome\temp\work\Catalina\localhost\$Context")) {
    if (Test-Path $temp) {
        Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Bat buoc Tomcat reload context ---
# Copy-Item GIU NGUYEN LastWriteTime, nen Tomcat (autoDeploy=true) khong nhan
# ra thay doi -> webapp classloader van giu class CU (da het han) trong bo nho.
# Hieu ung: deploy xong ma app van dung code cu -> moi .class co bien khong?
#
# Cach kich hoat lai: dat lai moc thoi gian cua web.xml da deploy (noi Tomcat
# theo doi) -> Tomcat unload + reload context, classloader moi duoc tao va nap
# class moi tu dia chi.
$deployedXml = Join-Path $webDest 'WEB-INF\web.xml'
if (Test-Path $deployedXml) {
    (Get-Item $deployedXml).LastWriteTime = Get-Date
    Write-Host "  touched web.xml -> Tomcat se reload context $Context"
}

Write-Host 'DEPLOY OK' -ForegroundColor Green
# Cong HTTP that su cua Tomcat (doc tu conf/server.xml) - khong gia dinh 8080.
$httpPort = 8080
$serverXml = Join-Path $TomcatHome 'conf\server.xml'
if (Test-Path $serverXml) {
    $m = [regex]::Match((Get-Content $serverXml -Raw), '<Connector\s+port="(\d+)"\s+protocol="HTTP/1\.1"')
    if ($m.Success) { $httpPort = $m.Groups[1].Value }
}
Write-Host "Mo: http://localhost:$httpPort/$Context/" -ForegroundColor Green
