# Makes the iPad home screen icon from the HoMM2 icon of an installed GOG game (not committed: the art is not ours).
# Usage: powershell -File ios5\make_icon.ps1 "C:\Games\HoMM 2 Gold\goggame-1207658785.ico"
param([Parameter(Mandatory = $true)][string]$IcoPath)

Add-Type -AssemblyName System.Drawing

$bytes = [System.IO.File]::ReadAllBytes($IcoPath)
$count = [BitConverter]::ToUInt16($bytes, 4)
$png = $null
for ($i = 0; $i -lt $count; $i++) {
    $entry = 6 + 16 * $i
    $size = [BitConverter]::ToUInt32($bytes, $entry + 8)
    $offset = [BitConverter]::ToUInt32($bytes, $entry + 12)
    # The 256x256 entry is stored as PNG.
    if ($bytes[$offset] -eq 0x89 -and $bytes[$offset + 1] -eq 0x50) {
        $png = New-Object byte[] $size
        [Array]::Copy($bytes, $offset, $png, 0, $size)
    }
}
if (-not $png) { throw "No PNG image inside $IcoPath" }

$source = [System.Drawing.Image]::FromStream((New-Object System.IO.MemoryStream(, $png)))
$outDir = Join-Path $PSScriptRoot 'package'
# iPad (iOS 5): 72x72 home screen icon, 50x50 for Spotlight/Settings.
foreach ($pair in @(@('Icon.png', 72), @('Icon-Small-50.png', 50))) {
    $bitmap = New-Object System.Drawing.Bitmap($pair[1], $pair[1])
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($source, 0, 0, $pair[1], $pair[1])
    $bitmap.Save((Join-Path $outDir $pair[0]), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}
$source.Save((Join-Path $env:TEMP 'homm2_icon_256.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "Icons written to $outDir"
