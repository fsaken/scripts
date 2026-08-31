# ============================================================
# Discord Cache Image Recovery
#
# Scans a Discord cache directory and identifies image files
# by their file signature (magic bytes), regardless of extension.
#
# Supported formats:
# JPEG, PNG, GIF, WebP, BMP, TIFF, ICO
# ============================================================

Clear-Host

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       DISCORD CACHE IMAGE RECOVERY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Ask for Discord cache path
# ------------------------------------------------------------

do {
    $BasePath = Read-Host "Enter the path of your Discord cache"

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        Write-Host "Path cannot be empty." -ForegroundColor Red
        continue
    }

    if ($BasePath -eq "Q" -or $BasePath -eq "q") {
        Write-Host "Cancelled."
        exit
    }

    # Remove surrounding quotes if user pasted a quoted path
    $BasePath = $BasePath.Trim('"')

    if (-not (Test-Path -LiteralPath $BasePath -PathType Container)) {
        Write-Host ""
        Write-Host "Directory not found:" -ForegroundColor Red
        Write-Host $BasePath -ForegroundColor Yellow
        Write-Host ""
    }

} while (-not (Test-Path -LiteralPath $BasePath -PathType Container))

# ------------------------------------------------------------
# Output directory
# ------------------------------------------------------------

$OutputDir = Join-Path $BasePath "RECOVERED_IMAGES"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Write-Host ""
Write-Host "Cache directory:" -ForegroundColor Cyan
Write-Host $BasePath -ForegroundColor Yellow

Write-Host ""
Write-Host "Output directory:" -ForegroundColor Cyan
Write-Host $OutputDir -ForegroundColor Yellow

Write-Host ""

# ------------------------------------------------------------
# Image signatures
# ------------------------------------------------------------

$Signatures = @(
    @{
        Name = "JPEG"
        Bytes = [byte[]](0xFF,0xD8,0xFF)
        Ext = ".jpg"
    },
    @{
        Name = "PNG"
        Bytes = [byte[]](0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A)
        Ext = ".png"
    },
    @{
        Name = "GIF"
        Bytes = [byte[]](0x47,0x49,0x46,0x38)
        Ext = ".gif"
    },
    @{
        Name = "WEBP"
        Bytes = [byte[]](0x52,0x49,0x46,0x46)
        Ext = ".webp"
    },
    @{
        Name = "BMP"
        Bytes = [byte[]](0x42,0x4D)
        Ext = ".bmp"
    },
    @{
        Name = "TIFF"
        Bytes = [byte[]](0x49,0x49,0x2A,0x00)
        Ext = ".tiff"
    },
    @{
        Name = "ICO"
        Bytes = [byte[]](0x00,0x00,0x01,0x00)
        Ext = ".ico"
    }
)

# ------------------------------------------------------------
# Signature comparison function
# ------------------------------------------------------------

function Test-Signature {
    param(
        [byte[]]$Data,
        [byte[]]$Signature
    )

    if ($Data.Length -lt $Signature.Length) {
        return $false
    }

    for ($i = 0; $i -lt $Signature.Length; $i++) {
        if ($Data[$i] -ne $Signature[$i]) {
            return $false
        }
    }

    return $true
}

# ------------------------------------------------------------
# Enumerate files
# ------------------------------------------------------------

Write-Host "Scanning files..." -ForegroundColor Cyan
Write-Host ""

$Files = Get-ChildItem `
    -LiteralPath $BasePath `
    -Recurse `
    -File `
    -Force `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notlike "$OutputDir*"
    }

$Total = $Files.Count
$Current = 0
$Found = 0

Write-Host "Files found: $Total" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Scan files
# ------------------------------------------------------------

foreach ($File in $Files) {

    $Current++

    Write-Progress `
        -Activity "Scanning Discord cache" `
        -Status "$Current / $Total - $($File.Name)" `
        -PercentComplete (($Current / [Math]::Max($Total, 1)) * 100)

    # Ignore very small files
    if ($File.Length -lt 100) {
        continue
    }

    try {

        $Stream = [System.IO.File]::Open(
            $File.FullName,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        # Read only the first bytes needed for signature detection
        $Buffer = New-Object byte[] 32

        $BytesRead = $Stream.Read(
            $Buffer,
            0,
            $Buffer.Length
        )

        $Stream.Close()

        foreach ($Signature in $Signatures) {

            if (Test-Signature $Buffer $Signature.Bytes) {

                $Found++

                $NewName = "{0:D5}_{1}_{2}{3}" -f `
                    $Found,
                    $Signature.Name,
                    $File.Name,
                    $Signature.Ext

                $Destination = Join-Path `
                    $OutputDir `
                    $NewName

                Copy-Item `
                    -LiteralPath $File.FullName `
                    -Destination $Destination `
                    -Force `
                    -ErrorAction SilentlyContinue

                Write-Host "[FOUND] $($Signature.Name)" -ForegroundColor Green
                Write-Host "       File: $($File.FullName)"
                Write-Host "       Size: $([Math]::Round($File.Length / 1KB, 2)) KB"
                Write-Host "       Date: $($File.LastWriteTime)"
                Write-Host ""

                break
            }
        }

    }
    catch {
        # Ignore files that cannot be read
    }
}

Write-Progress `
    -Activity "Scanning Discord cache" `
    -Completed

# ------------------------------------------------------------
# Results
# ------------------------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "                 COMPLETE"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Files scanned     : $Total"
Write-Host "Images recovered  : $Found" -ForegroundColor Green

Write-Host ""
Write-Host "Recovered images:" -ForegroundColor Cyan
Write-Host $OutputDir -ForegroundColor Yellow
Write-Host ""

# Open output directory if images were found

if ($Found -gt 0) {
    Start-Process explorer.exe -ArgumentList "`"$OutputDir`""
}
else {
    Write-Host "No supported image files were found." -ForegroundColor Yellow
}

Write-Host ""
