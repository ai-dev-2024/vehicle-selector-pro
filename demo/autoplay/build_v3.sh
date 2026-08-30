#!/usr/bin/env bash
# Assemble the professional demo video:
#   video = real screen recording (video_v3/walkthrough.webm, vp8 -> h264)
#   audio = 13 narration clips synced to walkthrough cue times + quiet music bed
#   final = loudnorm to ~-16 LUFS so the voiceover is clearly audible
set -e
cd "$(dirname "$0")"

VID=video_v3/walkthrough.webm
AUD=audio_v3
OUT=../Vehicle_Selector_Pro_Demo_v3.mp4

# cue filename -> start time (ms), matching demoScript cue times
declare -A CUES=(
  [cue_000.mp3]=500
  [cue_012.mp3]=12500
  [cue_024.mp3]=24500
  [cue_036.mp3]=36500
  [cue_050.mp3]=50500
  [cue_064.mp3]=64500
  [cue_076.mp3]=76500
  [cue_090.mp3]=90500
  [cue_102.mp3]=102500
  [cue_112.mp3]=112500
  [cue_124.mp3]=124500
  [cue_134.mp3]=134500
  [cue_144.mp3]=144500
)

# Build ffmpeg inputs: 0 = video, 1..13 = narration, 14 = music
INPUTS=(-i "$VID")
for f in $(printf '%s\n' "${!CUES[@]}" | sort); do INPUTS+=(-i "$AUD/$f"); done
INPUTS+=(-stream_loop -1 -i "$AUD/music_bed.mp3")

# Narration chain: delay each clip to its cue time, normalize, mix
FILTER=""
i=1
for f in $(printf '%s\n' "${!CUES[@]}" | sort); do
  FILTER+="[$i:a]aresample=48000,adelay=${CUES[$f]}|${CUES[$f]},volume=2.0[n$i];"
  i=$((i+1))
done
NMIX=$(printf '[n%s]' $(seq 1 13))
FILTER+="${NMIX}amix=inputs=13:normalize=0[narr];"
# Music bed: trim to video length, duck under narration
FILTER+="[14:a]aresample=48000,volume=0.14[mus];"
FILTER+="[narr][mus]amix=inputs=2:duration=first:normalize=0[premix];"
FILTER+="[premix]loudnorm=I=-15:TP=-1.5:LRA=11,alimiter=limit=0.95[aout]"

echo "FILTER: $FILTER"
ffmpeg -y "${INPUTS[@]}" \
  -filter_complex "$FILTER" \
  -map 0:v -map "[aout]" \
  -t 156 \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -ar 48000 \
  -movflags +faststart \
  "$OUT"

echo "--- verifying ---"
ffprobe -v error -show_entries format=duration -show_entries stream=codec_type,codec_name -of default=noprint_wrappers=1 "$OUT"
ffmpeg -i "$OUT" -af volumedetect -f null - 2>&1 | grep -E "mean_volume|max_volume"
ls -la "$OUT"
