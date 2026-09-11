# Crop a rectangle from an image, then re-encode as JPEG.
# Coords are in SOURCE pixels. Usage:
# powershell -File .claude/crop-img.ps1 -In assets/brokerage.png -Out assets/brokerage.jpg -X 95 -Y 585 -W 1095 -H 430 -Quality 84
param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [Parameter(Mandatory=$true)][int]$X,
  [Parameter(Mandatory=$true)][int]$Y,
  [Parameter(Mandatory=$true)][int]$W,
  [Parameter(Mandatory=$true)][int]$H,
  [int]$MaxWidth = 1600,
  [int]$Quality = 84
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile((Resolve-Path $In))
try {
  $srcRect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
  $dst = New-Object System.Drawing.Bitmap $W, $H
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()

  if ($W -gt $MaxWidth) {
    $scale = $MaxWidth / $W
    $nw = [int]$MaxWidth
    $nh = [int][math]::Round($H * $scale)
    $rz = New-Object System.Drawing.Bitmap $nw, $nh
    $g2 = [System.Drawing.Graphics]::FromImage($rz)
    $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g2.DrawImage($dst, 0, 0, $nw, $nh)
    $g2.Dispose()
    $dst.Dispose()
    $dst = $rz
  }

  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $params = New-Object System.Drawing.Imaging.EncoderParameters 1
  $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$Quality)
  $full = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $OutPath))
  $dst.Save($full, $codec, $params)
  $kb = [math]::Round((Get-Item $full).Length / 1KB)
  Write-Host "$In -> $OutPath  crop ${W}x${H} @ ($X,$Y)  final $($dst.Width)x$($dst.Height)  $kb KB"
  $dst.Dispose()
} finally {
  $src.Dispose()
}
