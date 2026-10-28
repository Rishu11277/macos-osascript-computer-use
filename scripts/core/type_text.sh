#!/bin/bash
# Type text into the frontmost field of a process, but ONLY after confirming that process is frontmost.
# Usage: type_text.sh "<process>" "<text>" [--activate] [--any-focus]
#   --activate: bring the process to front first (otherwise refuse if it isn't).
#   For long or non-ASCII text prefer paste_text.sh (keystroke can drop/mangle characters on some layouts).
# Refuses unless a text field has keyboard focus (override: --any-focus, e.g. for canvases/terminals).
# Side effects: CHANGES UI (types keystrokes).
proc="$1"; txt="$2"; opt="$3"; anyfocus=0
for x in "${@:3}"; do case "$x" in --activate) opt=--activate;; --any-focus) anyfocus=1;; *) echo "unknown arg: $x" >&2; exit 2;; esac; done
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,6p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
[ $# -lt 2 ] && { echo "text required" >&2; exit 2; }
# Refuse unless a text field has keyboard focus (prevents stray keystrokes into the wrong control/app).
focus_guard() {
  [ "$anyfocus" = 1 ] && return 0
  . "$(dirname "$0")/_pid.sh"; proc_pid "$proc"
  local f; f=$(python3 -I "$(dirname "$0")/_ax_focus.py" "$PROC_PID") || exit 1
  case "$f" in *$'\t'1) return 0;; esac
  echo "no text field has keyboard focus in $proc (focused: ${f%%$'\t'*}); refusing. Click/focus a field first, or pass --any-focus." >&2
  exit 1
}
[ "$opt" = --activate ] && { "$(dirname "$0")/activate_app.sh" "$proc" >/dev/null 2>&1 || osascript - "$proc" <<<'on run argv
tell application "System Events" to set frontmost of process (item 1 of argv) to true
end run' >/dev/null; sleep 0.3; }
focus_guard
osascript - "$proc" "$txt" "$opt" <<'OSA'
on run argv
    set {procName, theText, opt} to {item 1 of argv, item 2 of argv, item 3 of argv}
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        if opt is "--activate" then
            set frontmost of process procName to true
            repeat 25 times
                if frontmost of process procName then exit repeat
                delay 0.2
            end repeat
        end if
        if not (frontmost of process procName) then error procName & " is not frontmost; refusing to type (use --activate)" number -1719
        keystroke theText
    end tell
    return "typed " & (length of theText) & " chars"
end run
OSA
