<#
.SYNOPSIS
    So sanh stored procedure giua file SQL trong repo voi DB da deploy.

.DESCRIPTION
    Tach file .sql theo cac batch "GO" (dung cach dung cho SQL Server), giu
    cac batch co CREATE [OR ALTER] PROCEDURE, roi doi chieu tung procedure
    voi OBJECT_DEFINITION trong DB. Bao cao procedure nao THIEU hoac KHAC
    nhau (DB chua duoc cap nhat sau khi sua file .sql).

    Che do -Sync se tu doi chieu va tao lai procedure dang KHAC trong DB.
    Luu y: -Sync chi dung khi file .sql la nguon su that moi nhat.

.PARAMETER SqlFile
    File .sql chua schema/procedure. Mac dinh "sql/new.sql".

.PARAMETER Server
    Chuoi ket noi sqlcmd (mac dinh doc tu app.properties).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/compare-procedures.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/compare-procedures.ps1 -Sync
#>
[CmdletBinding()]
param(
    [string]$SqlFile,
    [string]$Server = 'localhost,1433',
    [string]$Database = 'CinemaWebDB',
    [string]$User = 'sa',
    [string]$Password = '123',
    [switch]$Sync
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $SqlFile) { $SqlFile = Join-Path $root 'sql/new.sql' }

$sqlcmd = 'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE'
if (-not (Test-Path $sqlcmd)) {
    $found = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if (-not $found) { throw 'khong tim thay sqlcmd' }
    $sqlcmd = $found.Source
}

# --- Doc file SQL ---
$text = Get-Content $SqlFile -Raw -Encoding UTF8

# --- Tach batch theo "GO" o dau dong ---
$batches = [regex]::Split($text, '(?m)^\s*GO\s*$')

$defs = [ordered]@{}
foreach ($batch in $batches) {
    if ($batch -notmatch '(?i)CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?') {
        continue
    }
    $name = $Matches[1]
    # Loai phan comment dau file cua procedure
    $body = $batch.Trim()
    $defs[$name] = $body
}

Write-Host "File SQL   : $SqlFile" -ForegroundColor Cyan
Write-Host "Procedures : $($defs.Count)" -ForegroundColor Cyan

# --- Chuan hoa de so sanh ---
function Normalize-Sql {
    param([string]$s)
    if (-not $s) { return '' }
    # QUAN TRONG: phai xoa comment khoi BLOCK truoc, roi den comment dong.
    # Neu xoa comment dong truoc, duong ke "---...--- */" trong khoi /* ... */
    # bi cat mat dau "*/" => regex block khong dong duoc => nuot ca than procedure
    # => moi procedure deu bi bao "KHAC nhau" (false positive).
    $s = [regex]::Replace($s, '(?s)/\*.*?\*/', ' ')
    $s = [regex]::Replace($s, '(?m)--[^\r\n]*', ' ')
    # "CREATE OR ALTER" va "CREATE" la cung mot procedure -> quy ve mot dang
    $s = [regex]::Replace($s, '(?i)\bCREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\b', 'CREATE PROCEDURE')
    $s = [regex]::Replace($s, '\s+', ' ')
    return $s.Trim().ToLowerInvariant()
}

$mismatch = @()
$missing = @()
$same = @()

foreach ($name in $defs.Keys) {
    $query = "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$name')) AS def;"
    $out = & $sqlcmd -S $Server -U $User -P $Password -d $Database -C -Q $query -y 0 -Y 0 2>&1 | Out-String
    $dbDef = $out.Trim()
    $idx = $dbDef.IndexOf('CREATE')
    if ($idx -lt 0) {
        $missing += $name
        continue
    }
    $dbDef = $dbDef.Substring($idx)

    if ((Normalize-Sql $defs[$name]) -eq (Normalize-Sql $dbDef)) {
        $same += $name
    } else {
        $mismatch += $name
    }
}

Write-Host ""
Write-Host "Khop        : $($same.Count)" -ForegroundColor Green
if ($missing.Count) {
    Write-Host "THIEU trong DB ($($missing.Count)):" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" }
}
if ($mismatch.Count) {
    Write-Host "KHAC nhau ($($mismatch.Count)):" -ForegroundColor Red
    $mismatch | ForEach-Object { Write-Host "  - $_" }
}

if ($missing.Count -eq 0 -and $mismatch.Count -eq 0) {
    Write-Host 'TAT CA PROCEDURE DA DONG BO' -ForegroundColor Green
    return
}

if (-not $Sync) {
    Write-Host ''
    Write-Host 'Dung -Sync de tao lai procedure dang khac trong DB.' -ForegroundColor Yellow
    return
}

# --- Sync: tao lai procedure ---
Write-Host ''
Write-Host '--- Dong bo DB ---' -ForegroundColor Cyan
$targets = @($missing) + @($mismatch)
foreach ($name in $targets) {
    $body = $defs[$name]
    # Dam bao dung CREATE OR ALTER de idempotent
    if ($body -notmatch '(?i)CREATE\s+OR\s+ALTER\s+PROC') {
        $body = [regex]::Replace($body, '(?i)CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?', 'CREATE OR ALTER PROCEDURE', 1)
    }
    $tmp = Join-Path $env:TEMP ("sync_{0}.sql" -f $name)
    # File phai la UTF-8 co BOM de sqlcmd doc dung tieng Viet
    [System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding($true)))
    $out = & $sqlcmd -S $Server -U $User -P $Password -d $Database -C -i $tmp 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK]   $name" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        Write-Host $out
    }
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
Write-Host 'DONG BO XONG' -ForegroundColor Green
