<#
.SYNOPSIS
    Build script cho project CinemaWeb (khong dung Maven).

.DESCRIPTION
    Bien dich toan bo source trong src/java vao web/WEB-INF/classes bang javac,
    roi copy app.properties. Day la cach build ma project hien tai dang dung
    (module output = web/WEB-INF/classes, javac.source=17).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/build.ps1
    powershell -ExecutionPolicy Bypass -File scripts/build.ps1 -Clean
#>
[CmdletBinding()]
param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$root      = Split-Path -Parent $PSScriptRoot
$srcDir    = Join-Path $root 'src/java'
$libDir    = Join-Path $root 'lib'
$classesDir= Join-Path $root 'web/WEB-INF/classes'
$listFile  = Join-Path $env:TEMP 'cinemaweb-sources.txt'

Write-Host '=== Build CinemaWeb ===' -ForegroundColor Cyan

if ($Clean -and (Test-Path $classesDir)) {
    Write-Host 'Cleaning web/WEB-INF/classes ...'
    Get-ChildItem $classesDir -Recurse -Force | Remove-Item -Recurse -Force
}

if (-not (Test-Path $classesDir)) {
    New-Item -ItemType Directory -Path $classesDir | Out-Null
}

# --- Gom danh sach file nguon ---
$sources = Get-ChildItem $srcDir -Recurse -Filter *.java | ForEach-Object { $_.FullName }
if (-not $sources) {
    throw "Khong tim thay file .java trong $srcDir"
}
# ASCII: javac khong doc duoc BOM o dau file argfile
$sources | Set-Content -Encoding ASCII $listFile
Write-Host ("Sources : {0} file" -f $sources.Count)

# --- Classpath ---
$jars = Get-ChildItem $libDir -Filter *.jar | ForEach-Object { $_.FullName }
$cp = ($jars -join ';')

# --- Bien dich ---
$args = @(
    '-encoding', 'UTF-8',
    '-source', '17', '-target', '17',
    '-nowarn',
    '-cp', $cp,
    '-d', $classesDir,
    "@$listFile"
)
Write-Host 'Compiling ...'
& javac @args
if ($LASTEXITCODE -ne 0) {
    throw "Build that bai (javac exit $LASTEXITCODE)"
}

# --- Copy tai nguyen runtime ---
Copy-Item (Join-Path $srcDir 'app.properties') (Join-Path $classesDir 'app.properties') -Force

# --- Tom tat ---
$classCount = (Get-ChildItem $classesDir -Recurse -Filter *.class).Count
Write-Host ("Classes : {0} file .class" -f $classCount) -ForegroundColor Green
Write-Host 'BUILD OK' -ForegroundColor Green
