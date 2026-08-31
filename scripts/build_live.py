#!/usr/bin/env python3
"""Assemble the third (live) demo video: narration cues layered over the
Playwright screen recording of the deployed app, synchronized via measured
scene timestamps plus the capture lead-in, with a light music bed. Outputs
demo/vehicle-selector-pro-live.mp4.
"""
import json
import os
import shutil
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FF = os.environ.get("FFMPEG") or os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~/AppData/Roaming")),
    "Python", "Python313", "site-packages", "imageio_ffmpeg", "binaries",
    "ffmpeg-win-x86_64-v7.1.exe",
)
if not os.path.exists(FF):
    FF = shutil.which("ffmpeg")
assert FF, "ffmpeg not found"

LEAD = 3.6          # seconds of blank capture before the scene timeline starts
AUD = os.path.join(ROOT, "demo", "video", "audio", "live")
RAW = os.path.join(ROOT, "demo", "autoplay", "video_live", "live-tour.webm")
TMP = os.path.join(ROOT, "demo", "autoplay", "video_live")
OUT = os.path.join(ROOT, "demo", "vehicle-selector-pro-live.mp4")
MUSIC = os.path.join(ROOT, "demo", "autoplay", "audio_v3", "music_bed.mp3")
SCHED = json.load(open(os.path.join(ROOT, "demo", "autoplay", "live_schedule.json"), encoding="utf-8"))
DUR = json.load(open(os.path.join(ROOT, "demo", "video", "audio_tmp", "live_durations.json"), encoding="utf-8"))

order = [(s["id"], (s.get("atMs", s["plannedAtMs"]) / 1000.0) + LEAD) for s in SCHED["scenes"]]
end_sec = max(int(SCHED["totalMs"] / 1000), int(order[-1][1] + DUR.get(order[-1][0], 5.0) + 1.5))

# 1) Narration + music bed mixed onto the full length.
inputs = [["-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo"]]
for sid, _ in order:
    inputs.append(["-i", os.path.join(AUD, f"{sid}.mp3")])
inputs.append(["-i", MUSIC])
n = len(order)

fc = f"anullsrc=r=48000:cl=stereo,atrim=end_sample={end_sec*48000}[bed];"
for i, (sid, t) in enumerate(order, 1):
    ms = int(round(t * 1000))
    fc += f"[{i}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={ms}|{ms}[d{i}];"
fc += "[bed]" + "".join(f"[d{i}]" for i in range(1, n + 1))
fc += f"amix=inputs={n+1}:normalize=0[nar];"
fc += f"[{n+1}:a]aresample=48000,aformat=channel_layouts=stereo,volume=0.9[mus];"
fc += "[mus][nar]sidechaincompress=threshold=0.028:ratio=6:attack=15:release=350:makeup=1[duck];"
fc += "[duck][nar]amix=inputs=2:normalize=0,alimiter=limit=0.95[aout]"

mix_args = [FF, "-y", "-hide_banner", "-loglevel", "error"]
for a in inputs:
    mix_args += a
mix_args += ["-filter_complex", fc, "-map", "[aout]", "-t", str(end_sec),
             "-c:a", "aac", "-b:a", "192k", os.path.join(TMP, "narration.aac")]
subprocess.run(mix_args, check=True)

# 2) Transcode recorded webm -> h264 (video only).
subprocess.run([FF, "-y", "-hide_banner", "-loglevel", "error", "-i", RAW,
                "-vf", "scale=1280:720", "-t", str(end_sec),
                "-c:v", "libx264", "-preset", "medium", "-crf", "23",
                "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", "30",
                "-an", os.path.join(TMP, "live-video.mp4")], check=True)

# 3) Mux.
subprocess.run([FF, "-y", "-hide_banner", "-loglevel", "error",
                "-i", os.path.join(TMP, "live-video.mp4"), "-i", os.path.join(TMP, "narration.aac"),
                "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "copy",
                "-movflags", "+faststart", OUT], check=True)
print("WROTE", OUT, f"({end_sec}s)")