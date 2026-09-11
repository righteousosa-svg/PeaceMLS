# Replaces the hero-bg background image for a given page section in index.html
# Usage: powershell -File .claude/swap-hero.ps1 -PageId page-dispatch -Image assets/dispatch.jpg [-Position "center"]
param(
  [Parameter(Mandatory=$true)][string]$PageId,
  [Parameter(Mandatory=$true)][string]$Image,
  [string]$Position = "center"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$htmlPath = Join-Path $root 'index.html'
$imgPath  = Join-Path $root $Image
if (-not (Test-Path $imgPath)) { throw "Image not found: $imgPath" }

$ext = [System.IO.Path]::GetExtension($imgPath).ToLowerInvariant().TrimStart('.')
if ($ext -eq 'jpg') { $ext = 'jpeg' }
$b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($imgPath))
$dataUri = "data:image/$ext;base64,$b64"

$html = [System.IO.File]::ReadAllText($htmlPath)

# Find the page section, then the first hero-bg div style inside it
$secIdx = $html.IndexOf("id=`"$PageId`"")
if ($secIdx -lt 0) { throw "Page id not found: $PageId" }
$heroIdx = $html.IndexOf('<div class="hero-bg" style="background-image:url(', $secIdx)
if ($heroIdx -lt 0) { throw "hero-bg not found in $PageId" }
$styleStart = $html.IndexOf('"', $html.IndexOf('style=', $heroIdx)) + 1
$styleEnd = $html.IndexOf('"', $styleStart)
$oldStyle = $html.Substring($styleStart, $styleEnd - $styleStart)

$newStyle = "background-image:url($dataUri);background-position:$Position;background-size:cover;"
$html = $html.Substring(0, $styleStart) + $newStyle + $html.Substring($styleEnd)

[System.IO.File]::WriteAllText($htmlPath, $html)
Write-Host "Swapped hero image for $PageId  ($([math]::Round($b64.Length/1KB)) KB base64, position: $Position)"
Write-Host "Old style was: $oldStyle"
