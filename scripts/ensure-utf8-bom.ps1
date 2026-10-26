<#
    .SYNOPSIS
        Chuyen mot file text sang UTF-8 co BOM (bat buoc cho PowerShell 5.1).

    .DESCRIPTION
        PowerShell 5.1 doc file .ps1 khong BOM theo ANSI (Windows-1252), nen chuoi
        tieng Viet trong script bi sai. File da co BOM se duoc giu nguyen.

    .PARAMETER Path
        Duong dan file (hoac thu muc se quet tat ca file .ps1 ben trong).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path
)

$encoding = New-Object System.Text.UTF8Encoding($true)
$changed = @()

foreach ($item in $Path) {
    $files = if (Test-Path -LiteralPath $item -PathType Container) {
        Get-ChildItem -LiteralPath $item -Recurse -Filter *.ps1 -File
    } else {
        Get-Item -LiteralPath $item
    }

    foreach ($file in $files) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $hasBom = $bytes.Length -ge 3 -and
                   $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        if ($hasBom) { continue }

        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        [System.IO.File]::WriteAllText($file.FullName, $content, $encoding)
        $changed += $file.FullName
    }
}

if ($changed.Count -eq 0) {
    Write-Host 'Moi file da co BOM UTF-8.' -ForegroundColor Green
} else {
    Write-Host ('Da them BOM UTF-8 cho ' + $changed.Count + ' file:') -ForegroundColor Yellow
    $changed | ForEach-Object { Write-Host "  $_" }
}
