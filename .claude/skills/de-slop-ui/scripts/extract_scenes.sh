#!/usr/bin/env bash
# Extract one frame per scene change from a video, plus a contact sheet.
#
# Usage: extract_scenes.sh <video> [out_dir] [threshold] [fallback_fps]
#   threshold:    0.0-1.0 scene-change score (default 0.25; lower = more frames)
#   fallback_fps: if scene detection keeps fewer than 3 frames (smooth UI
#                 animations and screen recordings have no hard cuts), sample
#                 at this rate instead (default 1 = one frame per second)
#
# Output:
#   <out_dir>/frame_000.png   first frame (always kept)
#   <out_dir>/frame_NNN.png   one frame per scene change (or per sample)
#   <out_dir>/timestamps.txt  frame name -> time in seconds
#   <out_dir>/contact.png     grid of all frames, for a quick overview
set -euo pipefail

video="${1:?usage: extract_scenes.sh <video> [out_dir] [threshold] [fallback_fps]}"
out="${2:-frames}"
thr="${3:-0.25}"
fps="${4:-1}"

mkdir -p "$out"
rm -f "$out"/frame_*.png "$out"/timestamps.txt "$out"/contact.png

# First frame: the "before" state is often there.
ffmpeg -hide_banner -loglevel error -i "$video" -frames:v 1 "$out/frame_000.png"

# Scene-change frames; showinfo logs each kept frame's pts_time.
{ ffmpeg -hide_banner -i "$video" \
    -vf "select='gt(scene,${thr})',showinfo" \
    -fps_mode vfr -start_number 1 "$out/frame_%03d.png" 2>&1 || true; } \
  | { grep -o 'pts_time:[0-9.]*' || true; } | cut -d: -f2 \
  | awk '{printf "frame_%03d.png %s\n", NR, $1}' > "$out/timestamps.txt"
mode="scene changes (threshold $thr)"

n=$(ls "$out"/frame_*.png | wc -l)
if [ "$n" -lt 3 ]; then
  # No hard cuts: fall back to fixed-interval sampling.
  rm -f "$out"/frame_*.png
  ffmpeg -hide_banner -loglevel error -i "$video" -vf "fps=${fps}" \
    -start_number 0 "$out/frame_%03d.png"
  ls "$out"/frame_*.png | xargs -n1 basename \
    | awk -v f="$fps" '{printf "%s %.2f\n", $1, (NR-1)/f}' > "$out/timestamps.txt"
  mode="fixed sampling at ${fps} fps (no scene changes above $thr)"
else
  sed -i '1i frame_000.png 0' "$out/timestamps.txt"
fi

n=$(ls "$out"/frame_*.png | wc -l)
echo "Extracted $n frames into $out by $mode"

# Contact sheet: 4 columns, thumbnails 480px wide.
cols=4
rows=$(( (n + cols - 1) / cols ))
ffmpeg -hide_banner -loglevel error -pattern_type glob -i "$out/frame_*.png" \
  -vf "scale=480:-2,tile=${cols}x${rows}:padding=8:color=white" \
  -frames:v 1 "$out/contact.png"
echo "Contact sheet: $out/contact.png"
