# Resize + re-encode an image to JPEG. Usage:
# powershell -File .claude/optimize-img.ps1 -In assets/dispatch.png -Out assets/dispatch.jpg -MaxWidth 1600 -Quality 82
param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$MaxWidth = 1600,
  [int]$Quality = 82
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile((Resolve-Path $In))
try {
  $w = $src.Width; $h = $src.Height
  if ($w -gt $MaxWidth) {
    $scale = $MaxWidth / $w
    $nw = [int]$MaxWidth
    $nh = [int][math]::Round($h * $scale)
  } else {
    $nw = $w; $nh = $h
  }
  $bmp = New-Object System.Drawing.Bitmap $nw, $nh
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($src, 0, 0, $nw, $nh)
  $g.Dispose()

  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $params = New-Object System.Drawing.Imaging.EncoderParameters 1
  $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$Quality)
  $outFull = Join-Path (Split-Path -Parent (Resolve-Path $In)) (Split-Path -Leaf $Out)
  $outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out))
  $bmp.Save($outFull, $codec, $params)
  $bmp.Dispose()
  $kb = [math]::Round((Get-Item $outFull).Length / 1KB)
  Write-Host "$In ($w x $h) -> $Out ($nw x $nh, $kb KB)"
} finally {
  $src.Dispose()
}
