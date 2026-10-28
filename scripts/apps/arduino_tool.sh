#!/bin/bash
# Arduino CLI discovery, boards, compilation, or upload.
# Usage: arduino_tool.sh detect | boards | compile FQBN SKETCH | upload --confirm-upload FQBN PORT SKETCH
# Example: arduino_tool.sh boards. Side effects: compile writes build files; upload changes a board.
set -u
usage(){ echo 'Usage: arduino_tool.sh detect | boards | compile FQBN SKETCH | upload --confirm-upload FQBN PORT SKETCH'; }
[[ ${1:-} == -h ]] && { usage; exit 0; }
[[ $# -ge 1 ]] || { usage >&2; exit 2; }
cli=$(command -v arduino-cli || true)
if [[ $1 == detect && $# == 1 ]]; then
 if [[ -n $cli ]]; then echo "$cli"; else echo 'arduino-cli unavailable; Arduino IDE UI may be used with core helpers.'; fi
 exit 0
fi
[[ -n $cli ]] || { echo 'arduino-cli unavailable; inspect Arduino IDE with core UI helpers.' >&2; exit 1; }
case "$1" in
 boards) [[ $# == 1 ]] || exit 2; exec "$cli" board list ;;
 compile) [[ $# == 3 && -d $3 && -n $2 ]] || { usage >&2; exit 2; }; exec "$cli" compile --fqbn "$2" "$3" ;;
 upload) [[ $# == 5 && $2 == --confirm-upload && -n $3 && -n $4 && -d $5 ]] || { usage >&2; exit 2; }; exec "$cli" upload --fqbn "$3" --port "$4" "$5" ;;
 *) usage >&2; exit 2;;
esac
