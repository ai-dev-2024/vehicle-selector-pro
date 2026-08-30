# build-video.ps1 — Combine screenshots + audio into a polished MP4
param(
  [string]$ManifestPath = "$PSScriptRoot\manifest.json",
  [string]$FramesDir = "$PSScriptRoot\frames",
  [string]$AudioDir = "$PSScriptRoot\audio",
  [string]$OutputPath = "$PSScriptRoot\Vehicle_Selector_Pro_Demo.mp4"
)

$manifest = Get-Content $ManifestPath | ConvertFrom-Json
$tempDir = "$PSScriptRoot\temp_segments"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$segments = @()

foreach ($scene in $manifest) {
  $img = Join-Path $FramesDir "$($scene.name).png"
  $wav = Join-Path $AudioDir "$($scene.name).wav"
  $segment = Join-Path $tempDir "seg_$($scene.name).mp4"

  if (-not (Test-Path $img)) { Write-Host "SKIP  missing $img"; continue }
  if (-not (Test-Path $wav)) { Write-Host "SKIP  missing $wav"; continue }

  $dur = & ffprobe -v error -show_entries format=duration -of csv=p=0 "$wav" 2>$1
  $dur = $dur.Trim()
  if (-not $dur -or $dur -eq 'N/A') { $dur = '4' }
  $totalDur = [math]::Round([double]$dur + 0.8, 2)

  Write-Host "BUILD  $($scene.name)  dur=${totalDur}s"

  & ffmpeg -y -loop 1 -i "$img" -i "$wav" `
    -c:v libx264 -tune stillimage -pix_fmt yuv420p `
    -af "aresample=44100" -c:a aac -b:a 128k -strict -2 `
    -t "$totalDur" -shortest `
    "$segment" 2>$1

  if ((Test-Path $segment) -and (Get-Item $segment).Length -gt 0) {
    $segments += $segment
    Write-Host "  OK  $segment"
  } else {
    Write-Host "  FAIL"
  }
}

if ($segments.Count -eq 0) {
  Write-Host "No segments created. Aborting."
  exit 1
}

# Build concat filter
$inputs = ""
for ($i = 0; $i -lt $segments.Count; $i++) {
  $inputs += "-i `"$($segments[$i])`" "
}
$filter = ""
for ($i = 0; $i -lt $segments.Count; $i++) {
  $filter += "[$i:v:0][$i:a:0]"
}
$filter += "concat=n=$($segments.Count):v=1:a=1[outv][outa]"

Write-Host "`nCONCAT $($segments.Count) segments → $OutputPath"

$cmd = "ffmpeg -y $inputs -filter_complex `"$filter`" -map `"[outv]`" -map `"[outa]`" -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 128k -strict -2 `"$OutputPath`""
Invoke-Expression $cmd 2>$1

if ((Test-Path $OutputPath) -and (Get-Item $OutputPath).Length -gt 0) {
  $size = (Get-Item $OutputPath).Length / 1MB
  $dur = & ffprobe -v error -show_entries format=duration -of csv=p=0 "$OutputPath" 2>$1
  Write-Host "DONE  $OutputPath ($([math]::Round($size, 1)) MB, $([math]::Round([double]$dur.Trim(), 1))s)"
} else {
  Write-Host "FAIL  Output not created"
}

Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
