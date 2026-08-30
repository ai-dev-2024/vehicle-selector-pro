# narrate.ps1 — Generate TTS audio for each scene using Windows Speech Synthesis
# Reads manifest.json from capture.js, outputs one .wav per scene

param(
  [string]$ManifestPath = "$PSScriptRoot\manifest.json",
  [string]$OutDir = "$PSScriptRoot\audio"
)

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

# Pick a natural voice
$voice = ($synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -like 'en-*' } | Select-Object -First 1)
if ($voice) {
  $synth.SelectVoice($voice.VoiceInfo.Name)
  Write-Host "Using voice: $($voice.VoiceInfo.Name)"
} else {
  Write-Host "WARNING: No English voice found, using default"
}

$synth.Rate = 1  # slightly faster than normal

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$manifest = Get-Content $ManifestPath | ConvertFrom-Json

foreach ($scene in $manifest) {
  $wavPath = Join-Path $OutDir "$($scene.name).wav"
  Write-Host "TTS   $($scene.name) → $wavPath"
  $synth.SetOutputToWaveFile($wavPath)
  $synth.Speak($scene.narrate)
  $synth.SetOutputToNull()
  Write-Host "  OK  $wavPath"
}

$synth.Dispose()
Write-Host "`nDone. $($manifest.Count) audio files in $OutDir"
