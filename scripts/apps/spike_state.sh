#!/bin/bash
# Read SPIKE process/window/menu names without launching it.
# Usage: spike_state.sh. Example: spike_state.sh. Side effects: READ-ONLY.
[[ ${1:-} == -h ]] && { echo 'Usage: spike_state.sh'; exit 0; }
[[ $# == 0 ]] || { echo 'Usage: spike_state.sh' >&2; exit 2; }
osascript <<'OSA'
tell application "System Events"
 if not (exists process "SPIKE") then error "SPIKE is not running" number -600
 tell process "SPIKE"
  set windowNames to name of every window
  set menuNames to name of every menu bar item of menu bar 1
  return {windowNames, menuNames}
 end tell
end tell
OSA
