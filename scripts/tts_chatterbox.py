"""Regenerate demo narration clips with Chatterbox-TTS (built-in voice).

Usage: python scripts/tts_chatterbox.py merchant|shopper

Writes 24000 Hz mono 48 kbps mp3s (matching the existing edge-tts format) into
demo/video/audio/<video>/*.mp3, and saves per-scene durations to
demo/video/audio_tmp/<video>_durations.json for scene-schedule tuning.

The previous edge-tts clips are git-tracked, so they remain recoverable.
"""
import json
import os
import shutil
import subprocess
import sys
import time

import torchaudio as ta
from chatterbox.tts_turbo import ChatterboxTurboTTS

VIDEO = sys.argv[1] if len(sys.argv) > 1 else "merchant"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO_DIR = os.path.join(ROOT, "demo", "video", "audio", VIDEO)
TMP_DIR = os.path.join(ROOT, "demo", "video", "audio_tmp")
SCRIPT = json.load(
    open(os.path.join(ROOT, "demo", "video", "scripts", f"{VIDEO}.json"), encoding="utf-8")
)

FF = os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~/AppData/Roaming")),
    "Python", "Python313", "site-packages", "imageio_ffmpeg", "binaries",
    "ffmpeg-win-x86_64-v7.1.exe",
)
if not os.path.exists(FF):
    FF = shutil.which("ffmpeg")
assert FF, "ffmpeg not found"

os.makedirs(TMP_DIR, exist_ok=True)
os.makedirs(AUDIO_DIR, exist_ok=True)

turbo = ChatterboxTurboTTS.from_pretrained(device="cpu")
sr = int(turbo.sr)
print(f"sample rate: {sr}")

durations = {}
t0 = time.time()
for scene in SCRIPT["scenes"]:
    sid, text = scene["id"], scene["narration"]
    wav = turbo.generate(text).detach().cpu()
    tmp = os.path.join(TMP_DIR, f"{VIDEO}_{sid}.wav")
    ta.save(tmp, wav, sr)
    dur = wav.shape[1] / sr
    mp3 = os.path.join(AUDIO_DIR, f"{sid}.mp3")
    subprocess.run(
        [FF, "-y", "-hide_banner", "-loglevel", "error", "-i", tmp,
         "-af", "loudnorm=I=-23:LRA=11:TP=-1.5",
         "-ar", "24000", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "48k", mp3],
        check=True,
    )
    os.remove(tmp)
    durations[sid] = round(dur, 2)
    print(f"{sid}: {dur:.2f}s speech | {time.time() - t0:.0f}s elapsed")

with open(os.path.join(TMP_DIR, f"{VIDEO}_durations.json"), "w") as fh:
    json.dump(durations, fh, indent=2)
print(f"DONE {VIDEO}: total {time.time() - t0:.0f}s")
