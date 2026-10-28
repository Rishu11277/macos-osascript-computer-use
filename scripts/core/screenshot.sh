#!/bin/bash
# Screenshot one window (by its CoreGraphics window number, so covering windows are NOT captured), the
# whole screen, or a region. No sound. Screen and region modes capture whatever is visible there.
# Usage:
#   screenshot.sh window "<process>" OUT.png [--index N]
#   screenshot.sh screen OUT.png
#   screenshot.sh region X,Y,W,H OUT.png
# Side effects: WRITES OUT.png (may contain private data; delete when done). Needs Screen Recording
#   permission to capture other apps' contents; a wallpaper-only image means it is missing.
DIR="$(cd "$(dirname "$0")" && pwd)"
mode="$1"
[ -z "$mode" ] || [ "$mode" = "-h" ] && { sed -n '2,8p' "$0"; [ -z "$mode" ] && exit 2 || exit 0; }
case "$mode" in
  window) proc="$2"; out="$3"; shift 3 2>/dev/null || true
          [ -z "$proc" ] || [ -z "$out" ] && { echo "usage: $0 window <process> OUT.png [--index N]" >&2; exit 2; }
          b=$("$DIR/window.sh" bounds "$proc" "$@") || exit 1
          IFS=, read -r bx by bw bh <<< "$b"
          # capture by window number (-l) so windows covering it are NOT captured; never fall back to a region grab
          wid=$(osascript -l JavaScript "$DIR/_cg_window.js" "$proc" "$bx" "$by" "$bw" "$bh" 2>&1) || { echo "cannot identify the window for a safe capture: $wid" >&2; exit 1; }
          screencapture -x -o -l"$wid" "$out" || exit 1;;
  screen) out="$2"; [ -z "$out" ] && { echo "OUT.png required" >&2; exit 2; }; screencapture -x "$out" || exit 1;;
  region) r="$2"; out="$3"; case "$r" in *[!0-9,-]*|"") echo "region must be X,Y,W,H" >&2; exit 2;; esac
          [ -z "$out" ] && { echo "OUT.png required" >&2; exit 2; }; screencapture -x -R"$r" "$out" || exit 1;;
  *) echo "unknown mode: $mode" >&2; exit 2;;
esac
[ -s "$out" ] || { echo "screenshot not written" >&2; exit 1; }
echo "wrote $out ($(stat -f%z "$out") bytes)"
