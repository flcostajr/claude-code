#!/usr/bin/env bash
# Extract one frame per scene change from a video, plus a contact sheet.
#
# Usage: extract_scenes.sh <video> [out_dir] [threshold]
#   threshold: 0.0-1.0 scene-change score (default 0.25; lower = more frames)
#
# Output:
#   <out_dir>/frame_000.png   first frame (always kept)
#   <out_dir>/frame_NNN.png   one frame per detected scene change
#   <out_dir>/timestamps.txt  frame name -> time in seconds
#   <out_dir>/contact.png     grid of all frames, for a quick overview
set -euo pipefail

video="${1:?usage: extract_scenes.sh <video> [out_dir] [threshold]}"
out="${2:-frames}"
thr="${3:-0.25}"

mkdir -p "$out"
rm -f "$out"/frame_*.png "$out"/timestamps.txt "$out"/contact.png

# First frame: the "before" state is often there.
ffmpeg -hide_banner -loglevel error -i "$video" -frames:v 1 "$out/frame_000.png"

# Scene-change frames; showinfo logs each kept frame's pts_time.
ffmpeg -hide_banner -i "$video" \
  -vf "select='gt(scene,${thr})',showinfo" \
  -fps_mode vfr -start_number 1 "$out/frame_%03d.png" 2>&1 \
  | grep -o 'pts_time:[0-9.]*' | cut -d: -f2 \
  | awk '{printf "frame_%03d.png %s\n", NR, $1}' > "$out/timestamps.txt"
sed -i '1i frame_000.png 0' "$out/timestamps.txt"

n=$(ls "$out"/frame_*.png | wc -l)
echo "Extracted $n frames into $out (threshold $thr)"

# Contact sheet: 4 columns, thumbnails 480px wide.
cols=4
rows=$(( (n + cols - 1) / cols ))
ffmpeg -hide_banner -loglevel error -pattern_type glob -i "$out/frame_*.png" \
  -vf "scale=480:-2,tile=${cols}x${rows}:padding=8:color=white" \
  -frames:v 1 "$out/contact.png"
echo "Contact sheet: $out/contact.png"
