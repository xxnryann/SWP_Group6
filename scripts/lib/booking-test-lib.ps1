<#
    .SYNOPSIS
        Thu vien dung chung cho cac script kiem thuc luong dat ve online (BF-02).

    .DESCRIPTION
        Gom cac ham phuc vu:
          - Tao phien dang nhap (co CSRF token).
          - POST khong tu chuyen huong (de doc Location cua cong thanh toan).
          - Tim suat chien, tim ghe trong, giu ghe, thanh toan qua cong gia lap.

        Moi script kiem thuc nen dot-source file nay:
            . "$PSScriptRoot/lib/booking-test-lib.ps1"

    .NOTES
        PowerShell 5.1 doc file .ps1 khong BOM theo ANSI -> viet file nay voi BOM UTF-8.
#>

$ErrorActionPreference = 'Stop'

# ==================== ham HTTP ====================

function Get-Csrf {
    <#
    .SYNOPSIS
        Lay CSRF token tu trang HTML.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$Uri
    )
    $page = Invoke-WebRequest -Uri $Uri -WebSession $Session -UseBasicParsing
    if ($page.Content -match 'name="_csrf"\s+value="([^"]+)"') {
        return $Matches[1]
    }
    return $null
}

function Invoke-NoRedirect {
    <#
    .SYNOPSIS
        POST form-urlencoded va KHONG tu chuyen huong, tra ve HttpWebResponse.

    .DESCRIPTION
        Invoke-WebRequest cua PowerShell 5.1 auto-follow redirect, khi do ta khong
        doc duoc Location cua cong thanh toan (cong tra ve bang 302 kem query co
        chu ky). Ham nay dung HttpWebRequest voi AllowAutoRedirect = $false de
        lay duoc Location nguyen ban.
    #>
    param(
        [Parameter(Mandatory = $true)] [string]$Uri,
        [Parameter(Mandatory = $true)] [hashtable]$Body,
        $Session
    )
    $request = [System.Net.HttpWebRequest]::Create($Uri)
    $request.Method = 'POST'
    $request.AllowAutoRedirect = $false
    $request.ContentType = 'application/x-www-form-urlencoded'
    if ($Session) { $request.CookieContainer = $Session.Cookies }

    $pairs = @()
    foreach ($key in $Body.Keys) {
        $pairs += ([uri]::EscapeDataString($key) + '=' +
                   [uri]::EscapeDataString([string]$Body[$key]))
    }
    $data = [System.Text.Encoding]::UTF8.GetBytes(($pairs -join '&'))
    $request.ContentLength = $data.Length
    $stream = $request.GetRequestStream()
    $stream.Write($data, 0, $data.Length)
    $stream.Close()

    return [System.Net.HttpWebResponse]$request.GetResponse()
}

function Get-RedirectLocation {
    <#
    .SYNOPSIS
        Lay gia tri Location cua mot response 302 (tra ve $null neu khong phai redirect).
    #>
    param(
        [Parameter(Mandatory = $true)] $Response
    )
    $location = $Response.Headers['Location']
    if (-not $location) { return $null }
    if ($location -notmatch '^[a-zA-Z]+://') {
        $base = [Uri]$Response.ResponseUri
        $location = [Uri]::new($base, $location).AbsoluteUri
    }
    return $location
}

# ==================== ham nghiep vu ====================

function New-BookingSession {
    <#
    .SYNOPSIS
        Dang nhop khach hang va tra ve WebRequestSession.
    #>
    param(
        [Parameter(Mandatory = $true)] [string]$BaseUrl,
        [string]$Email = 'khach1@gmail.com',
        [string]$Password = '123456'
    )
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $loginUrl = "$BaseUrl/login"
    $csrf = Get-Csrf -Session $session -Uri $loginUrl
    if (-not $csrf) { throw 'khong lay duoc CSRF token cua trang dang nhap' }
    Invoke-WebRequest -Uri $loginUrl -Method Post -WebSession $session -UseBasicParsing `
        -MaximumRedirection 5 `
        -Body @{ _csrf = $csrf; identifier = $Email; password = $Password } | Out-Null
    return $session
}

function Get-ShowtimeId {
    <#
    .SYNOPSIS
        Tra ve id suat chien dang ban (uu tien hom nay, neu khong co thi ngay mai).

    .DESCRIPTION
        Chi tra ve suat chien CON GHE TRONG va CHUA BAT DAU. Neu suat dau tien
        da het ghe (do da chay test nhieu lan) hoac da bat dau chieu
        (sp_CreateBooking tu choi suat da start), tiep tuc tim suat tiep theo.

        Suat da bat dau duoc loai bang cach so sanh gio bat dau (data-start
        cua the suat chien) voi gio hien tai.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$BaseUrl
    )
    $dates = @((Get-Date).Date.ToString('yyyy-MM-dd'))
    $dates += (Get-Date).Date.AddDays(1).ToString('yyyy-MM-dd')
    $dates += (Get-Date).Date.AddDays(2).ToString('yyyy-MM-dd')
    foreach ($date in $dates) {
        $url = if ($date -eq $dates[0]) { "$BaseUrl/showtimes" } else { "$BaseUrl/showtimes?date=$date" }
        $page = Invoke-WebRequest -Uri $url -WebSession $Session -UseBasicParsing
        # Moi the suat chien: href chua showtimeId, data-start chua gio chieu (HH:mm).
        $pattern = 'href="[^"]*booking/seats\?showtimeId=(\d+)"[^>]*data-start="(\d{1,2}:\d{2})"'
        $seen = @{}
        foreach ($m in [regex]::Matches($page.Content, $pattern)) {
            $id = [int]$m.Groups[1].Value
            if ($seen.ContainsKey($id)) { continue }
            $seen[$id] = $true
            # Bo qua suat da bat dau chieu (khong the mo phien dat ve).
            if (Test-TimeAlreadyPassed -Date $date -Time $m.Groups[2].Value) { continue }
            # Chi chon suat con ghe GREEN, neu khong thi thu suat ke tiep.
            if (Test-ShowtimeHasFreeSeat -Session $Session -BaseUrl $BaseUrl -ShowtimeId $id) {
                return $id
            }
        }
    }
    return 0
}

function Test-TimeAlreadyPassed {
    <#
    .SYNOPSIS
        Tra ve $true neu gio chieu (HH:mm) cua ngay $Date da qua so voi hien tai.
    #>
    param(
        [Parameter(Mandatory = $true)] [string]$Date,
        [Parameter(Mandatory = $true)] [string]$Time
    )
    try {
        $day = [datetime]::ParseExact($Date, 'yyyy-MM-dd', $null)
        $parts = $Time.Split(':')
        $start = $day.AddHours([int]$parts[0]).AddMinutes([int]$parts[1])
        return ($start -le (Get-Date))
    } catch {
        return $false
    }
}

function Test-ShowtimeHasFreeSeat {
    <#
    .SYNOPSIS
        Kiem tra suat chien con ghe trong (mau GREEN) hay khong.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$BaseUrl,
        [Parameter(Mandatory = $true)] [int]$ShowtimeId
    )
    try {
        $page = Invoke-WebRequest -Uri "$BaseUrl/booking/seats?showtimeId=$ShowtimeId" `
            -WebSession $Session -UseBasicParsing
        # Phai khop `data-id` de loai bo nut mau trong phan "chu thich" (legend)
        # - nut do luon co class="seat GREEN" dui chung mau.
        return $page.Content -match 'class="seat GREEN"[^>]*data-id="\d+"'
    } catch {
        return $false
    }
}

function Get-FreeSeatIds {
    <#
    .SYNOPSIS
        Chon N ghe dang trong. Neu gap ghe doi, lay luon ca cap ghiep.
    .OUTPUTS
        Hashtable: @{ ids = '1,2'; url = '<url man hinh gh>' }
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$BaseUrl,
        [Parameter(Mandatory = $true)] [int]$ShowtimeId,
        [int]$Count = 2
    )
    $seatsUrl = "$BaseUrl/booking/seats?showtimeId=$ShowtimeId"
    $page = Invoke-WebRequest -Uri $seatsUrl -WebSession $Session -UseBasicParsing
    $ids = @()
    $pattern = 'class="seat GREEN"[^>]*data-id="(\d+)"[^>]*data-pair="([^"]*)"'
    foreach ($match in [regex]::Matches($page.Content, $pattern)) {
        if ($ids.Count -ge $Count) { break }
        $ids += $match.Groups[1].Value
        $pair = $match.Groups[2].Value
        if ($pair -and $pair -ne '') { $ids += $pair }
    }
    if ($ids.Count -eq 0) {
        # Khong con ghe trong -> tra ve rong de caller bao loi ro rang
        # thay vi throw "empty string" khi gan bien.
        return @{ ids = ''; url = $seatsUrl }
    }
    return @{ ids = (($ids | Select-Object -Unique) -join ','); url = $seatsUrl }
}

function Invoke-HoldSeats {
    <#
    .SYNOPSIS
        Giu ghe cho don hien tai va chuyen sang buoc combo.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$SeatsUrl,
        [Parameter(Mandatory = $true)] [int]$ShowtimeId,
        [Parameter(Mandatory = $true)] [string]$SeatIds
    )
    $csrf = Get-Csrf -Session $Session -Uri $SeatsUrl
    Invoke-WebRequest -Uri $SeatsUrl -Method Post -WebSession $Session -UseBasicParsing `
        -Body @{ _csrf = $csrf; showtimeId = $ShowtimeId; seatIds = $SeatIds } `
        -MaximumRedirection 5 | Out-Null
}

function Get-MockPaymentUrl {
    <#
    .SYNOPSIS
        Bam "Thanh toan" o man hinh thanh toan -> tra ve URL cong gia lap.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$BaseUrl
    )
    $payUrl = "$BaseUrl/booking/payment"
    $csrf = Get-Csrf -Session $Session -Uri $payUrl
    $response = Invoke-WebRequest -Uri $payUrl -Method Post -WebSession $Session -UseBasicParsing `
        -Body @{ _csrf = $csrf; action = 'pay' } -MaximumRedirection 5
    return $response.BaseResponse.ResponseUri
}

function Invoke-MockPayment {
    <#
    .SYNOPSIS
        Giao dich tren cong gia lap ('success' | 'cancel') va tra ve URL quay ve
        cua cong (co chu ky HMAC-SHA512 hop le).
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$MockUrl,
        [ValidateSet('success', 'cancel')][string]$Decision = 'success'
    )
    $response = Invoke-NoRedirect -Uri $MockUrl -Body @{ decision = $Decision } -Session $Session
    $location = Get-RedirectLocation -Response $response
    $response.Close()
    if (-not $location) { throw 'cong gia lap khong tra ve Location' }
    return $location
}

function Get-PaidTicketCount {
    <#
    .SYNOPSIS
        Dem so vé còn hiệu lực (trạng thái 'Booked') trên trang lịch sử vé.

    .DESCRIPTION
        Màn hình lịch sử vé hiển thị dạng thẻ (mỗi vé 1 thẻ + 1 mã QR).
        Vé còn hiệu lực có badge class "st-active" (nhãn "Còn hiệu lực"),
        còn vé đã huỷ / hết hạn / đã soát mang badge khác.

        Hàm này dùng để kiểm tra idempotency: giao dịch lặp lại KHÔNG được
        phát hành vé lần 2 -> số vé còn hiệu lực không được tăng.
    #>
    param(
        [Parameter(Mandatory = $true)] $Session,
        [Parameter(Mandatory = $true)] [string]$BaseUrl
    )
    $page = Invoke-WebRequest -Uri "$BaseUrl/account/tickets" -WebSession $Session -UseBasicParsing
    # Mỗi vé còn hiệu lực -> đúng 1 badge "st-active"
    $active = ([regex]::Matches($page.Content, 'tk-badge st-active')).Count
    $all = ([regex]::Matches($page.Content, 'class="tk-card')).Count
    return @{ paid = $active; rows = $all }
}

function Assert-Test {
    <#
    .SYNOPSIS
        Kiem tra dieu kien va ghi ket qua (khong nem exception de chay tiep cac buoc sau).
    #>
    param(
        [Parameter(Mandatory = $true)] $Condition,
        [Parameter(Mandatory = $true)] [string]$Message
    )
    if ($Condition) {
        Write-Host "  [OK]   $Message" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $Message" -ForegroundColor Red
        $script:Failures += $Message
    }
}

function Write-Step {
    param([Parameter(Mandatory = $true)] [string]$Text)
    Write-Host "`n=== $Text ===" -ForegroundColor Cyan
}

function Write-Result {
    <#
    .SYNOPSIS
        In ket qua tong hop; tra ve exit code (0 = pass).
    #>
    if ($script:Failures.Count -eq 0) {
        Write-Host 'TAT CA BUOC PASS' -ForegroundColor Green
        return 0
    }
    Write-Host ("FAIL: " + ($script:Failures -join '; ')) -ForegroundColor Red
    return 1
}
