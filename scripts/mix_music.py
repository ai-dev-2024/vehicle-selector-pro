#!/usr/bin/env python3
"""Add a light music bed (ducked under narration) to a rendered video, and
output the final 1280x720 h264/aac mp4 with faststart.

Usage: python scripts/mix_music.py IN.mp4 OUT.mp4 [MUSIC_MP3 [VOL]]
  MUSIC_MP3  explicit music bed file (default demo/autoplay/audio_v3/music_bed.mp3)
  VOL        narration-room music volume 0..1 (default 0.24)
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FF = os.environ.get("FFMPEG") or os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~/AppData/Roaming")),
    "Python", "Python313", "site-packages", "imageio_ffmpeg", "binaries",
    "ffmpeg-win-x86_64-v7.1.exe",
)
if not os.path.exists(FF):
    FF = shutil.which("ffmpeg")
assert FF, "ffmpeg not found"

src, dst = sys.argv[1], sys.argv[2]
music = sys.argv[3] if len(sys.argv) > 3 else os.path.join(ROOT, "demo", "autoplay", "audio_v3", "music_bed.mp3")
vol = float(sys.argv[4]) if len(sys.argv) > 4 else 0.24
if not os.path.exists(music):
    raise SystemExit(f"music file missing: {music}")

# Duck music under narration via a sidechain on the narration channel, kept low.
fc = (
    f"[1:a]aresample=48000,aformat=channel_layouts=stereo,volume={vol:.2f}[mus];"
    "[0:a]aresample=48000,aformat=channel_layouts=stereo[nar];"
    "[mus][nar]sidechaincompress=threshold=0.04:ratio=5:attack=20:release=400:makeup=1[duck];"
    "[duck][nar]amix=inputs=2:normalize=0[mix];"
    "[mix]alimiter=limit=0.95[aout]"
)
cmd = [FF, "-y", "-hide_banner", "-loglevel", "error",
       "-i", src, "-i", music,
       "-filter_complex", fc,
       "-map", "0:v", "-map", "[aout]",
       "-vf", "scale=1280:720",
       "-c:v", "libx264", "-preset", "medium", "-crf", "23",
       "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", "30",
       "-c:a", "aac", "-b:a", "160k", "-ar", "48000",
       "-movflags", "+faststart", dst]
subprocess.run(cmd, check=True)
print("WROTE", dst)