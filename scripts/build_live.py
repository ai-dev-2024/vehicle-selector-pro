#!/usr/bin/env python3
"""Assemble the third (live) demo video: narration cues layered over the
Playwright screen recording of the deployed app, synchronized via measured
scene timestamps plus the capture lead-in.

  video: demo/autoplay/video_live/live-tour.webm (from live_record.js)
  narration: demo/video/audio/live/*.mp3 (from scripts/tts_chatterbox.py live)
  output: demo/vehicle-selector-pro-live.mp4
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
SCHED = json.load(open(os.path.join(ROOT, "demo", "autoplay", "live_schedule.json"), encoding="utf-8"))
DUR = json.load(open(os.path.join(ROOT, "demo", "video", "audio_tmp", "live_durations.json"), encoding="utf-8"))

# Narration placements in VIDEO time (sec): measured wall offset + lead-in.
order = [(s["id"], (s.get("atMs", s["plannedAtMs"]) / 1000.0) + LEAD) for s in SCHED["scenes"]]

# Clip the video so it ends just after the last narration finishes.
last_dur = DUR.get(order[-1][0], 5.0)
end_sec = order[-1][1] + last_dur + 1.5
end_sec = int(round(end_sec))

# 1) Narration mix over a silent bed.
bed = f"anullsrc=r=24000:cl=mono,atrim=end_sample={end_sec*24000}[bed];"
inputs, fc = [["-f", "lavfi", "-i", "anullsrc=r=24000:cl=mono"]], bed
for i, (sid, t) in enumerate(order, 1):
    mp3 = os.path.join(AUD, f"{sid}.mp3")
    ms = int(round(t * 1000))
    inputs.append(["-i", mp3])
    fc += f"[{i}:a]adelay={ms}|{ms}[d{i}];"
fc += "[bed]" + "".join(f"[d{i}]" for i in range(1, len(order) + 1))
fc += f"amix=inputs={len(order)+1}:normalize=0[mix];[mix]loudnorm=I=-23:LRA=11:TP=-1.5,aresample=24000[aout]"
mix_args = [FF, "-y", "-hide_banner", "-loglevel", "error"]
for a in inputs:
    mix_args += a
mix_args += ["-filter_complex", fc, "-map", "[aout]", "-t", str(end_sec),
             "-c:a", "aac", "-b:a", "128k", os.path.join(TMP, "narration.aac")]
subprocess.run(mix_args, check=True)

# 2) Transcode recorded webm -> h264 (video only).
vid_args = [FF, "-y", "-hide_banner", "-loglevel", "error", "-i", RAW,
            "-vf", "scale=1280:720", "-t", str(end_sec),
            "-c:v", "libx264", "-preset", "medium", "-crf", "23",
            "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", "30",
            "-an", os.path.join(TMP, "live-video.mp4")]
subprocess.run(vid_args, check=True)

# 3) Mux.
mux_args = [FF, "-y", "-hide_banner", "-loglevel", "error",
            "-i", os.path.join(TMP, "live-video.mp4"), "-i", os.path.join(TMP, "narration.aac"),
            "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "copy",
            "-movflags", "+faststart", OUT]
subprocess.run(mux_args, check=True)
print("WROTE", OUT, f"({end_sec}s)")