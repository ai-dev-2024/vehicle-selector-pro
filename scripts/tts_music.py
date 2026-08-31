#!/usr/bin/env python3
"""Regenerate demo narration (distinct voices per video) and two distinct,
royalty-free music beds at a lower volume than before.

  python scripts/tts_music.py

Edits:
  - demo/video/audio/merchant/*.mp3  (male voice, en-US-AndrewNeural)
  - demo/video/audio/shopper/*.mp3   (female voice, en-US-AvaNeural)
  - demo/autoplay/audio_v3/music_bed.mp3          -> merchant bed (warm major)
  - demo/autoplay/audio_v3/music_bed_shopper.mp3  -> shopper bed (airy minor)
  - writes demo/video/audio_tmp/{video}_durations.json for scene-schedule tuning

Built entirely with free AI tooling (edge-tts neural voices + numpy audio).
"""
import asyncio
import json
import math
import os
import shutil
import subprocess
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))

FF = os.environ.get("FFMPEG") or os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~/AppData/Roaming")),
    "Python", "Python313", "site-packages", "imageio_ffmpeg", "binaries",
    "ffmpeg-win-x86_64-v7.1.exe",
)
if not os.path.exists(FF):
    FF = shutil.which("ffmpeg")
assert FF, "ffmpeg not found"

VIDEO_CONF = {
    "merchant": ("en-US-AndrewNeural", "merchant.json"),
    "shopper": ("en-US-AvaNeural", "shopper.json"),
}

SR = 44100


def load_script(video):
    path = os.path.join(ROOT, "demo", "video", "scripts", VIDEO_CONF[video][1])
    return json.load(open(path, encoding="utf-8"))


def make_silence(seconds):
    return np.zeros(int(seconds * SR), dtype=np.float32)


def fade(a, n=800):
    if n <= 0 or len(a) < 2 * n:
        return a
    e = np.linspace(0.0, 1.0, n, dtype=np.float32)
    a = a.copy()
    a[:n] *= e
    a[-n:] *= e[::-1]
    return a


def note(freq, dur, vol):
    n = int(dur * SR)
    t = np.arange(n) / SR
    # soft pluck: sine + a touch of 2nd harmonic, exp decay
    core = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * freq * 2 * t)
    env = np.exp(-t * 3.2) * vol
    return core * env


def build_bed(bpm, progression, bass_freqs, seconds=80, brightness=0.5,
              arp=True, timbre="warm", chord_freqs=None):
    """Cheap procedural ambient bed: pad chords + optional arpeggio + bass."""
    beat = 60.0 / bpm
    n = int(seconds * SR)
    out = np.zeros(n, dtype=np.float32)
    idx = 0
    bars = 0
    while idx < n:
        cname = progression[bars % len(progression)]
        chord = chord_freqs.get(cname, [261.63, 329.63, 392.00]) if chord_freqs else \
            [261.63, 329.63, 392.00]
        bass_f = bass_freqs[bars % len(bass_freqs)]
        # bass note
        bdur = beat * 2
        b = note(bass_f, min(bdur, (n - idx) / SR if n - idx < bdur * SR else bdur), 0.16) \
            if timbre != "light" else note(bass_f * 2, min(bdur, 2), 0.10)
        end = min(idx + int(bdur * SR), n)
        out[idx:end] += b[:end - idx]
        # chords spread over two beats
        bar_dur = beat * 4
        remain = bar_dur
        step = 0
        while remain > 0 and idx < n:
            seg = min(beat, remain, (n - idx) / SR)
            for f, mult in zip(chord, [1.0, 1.25, 1.5]):
                g = bat = note(f * mult, seg, 0.06 * brightness)
                end = min(idx + int(seg * SR), n)
                out[idx:end] += g[:end - idx]
            if arp and step % 2 == 1:
                f = chord[(step // 2) % len(chord)] * 2
                a = note(f, seg, 0.045)
                end = min(idx + int(seg * SR), n)
                out[idx:end] += a[:end - idx]
            idx += int(seg * SR)
            remain -= seg
            step += 1
        bars += 1
    out = fade(out)
    # gentle limiter
    peak = max(abs(out).max(), 1e-6)
    if peak > 0.95:
        out = out * (0.95 / peak)
    return out


def synthesize_bed(out_path, kind):
    rng = math.pi  # deterministic variation
    if kind == "merchant":
        # warm, mid-tempo major — confident / professional
        sr = SR
        chord_freqs = {
            "C": [261.63, 329.63, 392.00],
            "A": [220.00, 277.18, 329.63],
            "F": [174.61, 220.00, 261.63],
            "G": [196.00, 246.94, 293.66],
        }
        prog = ["C", "G", "A", "F"]
        bass = [130.81, 196.00, 110.00, 174.61]
        audio = build_bed(bpm=84, progression=prog, bass_freqs=bass,
                          seconds=170, brightness=0.5, arp=True, timbre="warm",
                          chord_freqs=chord_freqs)
        vol = 0.50  # lower than the old music bed
    else:
        # shopper: airy, slower minor — friendly / calm
        chord_freqs = {
            "Am": [220.00, 261.63, 329.63],
            "F": [174.61, 220.00, 261.63],
            "C": [261.63, 329.63, 392.00],
            "G": [196.00, 246.94, 293.66],
        }
        prog = ["Am", "F", "C", "G"]
        bass = [110.00, 87.31, 130.81, 98.00]
        audio = build_bed(bpm=66, progression=prog, bass_freqs=bass,
                          seconds=170, brightness=0.35, arp=True, timbre="light",
                          chord_freqs=chord_freqs)
        vol = 0.40
    audio = audio * vol
    int16 = (np.clip(audio, -1, 1) * 32767).astype(np.int16)
    import wave
    tmp = out_path + ".wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(int16.tobytes())
    subprocess.run([FF, "-y", "-hide_banner", "-loglevel", "error",
                    "-i", tmp, "-b:a", "160k", out_path], check=True)
    os.remove(tmp)
    print("WROTE", out_path)


async def synth_vo(video, text, outpath):
    import edge_tts
    voice = VIDEO_CONF[video][0]
    comm = edge_tts.Communicate(text, voice, rate="+4%", pitch="+1Hz")
    await comm.save(outpath)


def gen_video(video):
    script = load_script(video)
    dur = {}
    os.makedirs(os.path.join(ROOT, "demo", "video", "audio", video), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "demo", "video", "audio_tmp"), exist_ok=True)
    for scene in script["scenes"]:
        sid = scene["id"]
        text = scene["narration"]
        raw = os.path.join(ROOT, "demo", "video", "audio_tmp", f"{video}_{sid}.mp3")
        out = os.path.join(ROOT, "demo", "video", "audio", video, f"{sid}.mp3")
        asyncio.run(synth_vo(video, text, raw))
        # measure
        probe = subprocess.run([FF, "-i", raw], capture_output=True, text=True)
        line = [x for x in probe.stderr.splitlines() if "Duration" in x]
        dstr = line[0].split()[1].strip(",") if line else "0:00:00"
        h, m, s = dstr.split(":")
        sec = int(h) * 3600 + int(m) * 60 + float(s)
        dur[sid] = round(sec, 2)
        # normalize quiet up, then encode at speech-friendly loudness
        subprocess.run([FF, "-y", "-hide_banner", "-loglevel", "error",
                        "-i", raw,
                        "-af", "loudnorm=I=-23:LRA=11:TP=-1.5",
                        "-ar", "24000", "-ac", "1", "-c:a", "libmp3lame",
                        "-b:a", "48k", out], check=True)
        os.remove(raw)
        print(f"  {video}/{sid}: {dur[sid]}s")
    with open(os.path.join(ROOT, "demo", "video", "audio_tmp", f"{video}_durations.json"), "w") as fh:
        json.dump(dur, fh, indent=2)


def main():
    audio_dir = os.path.join(ROOT, "demo", "autoplay", "audio_v3")
    os.makedirs(audio_dir, exist_ok=True)
    synthesize_bed(os.path.join(audio_dir, "music_bed.mp3"), "merchant")
    synthesize_bed(os.path.join(audio_dir, "music_bed_shopper.mp3"), "shopper")
    for video in ["merchant", "shopper"]:
        gen_video(video)
    print("DONE")


if __name__ == "__main__":
    main()