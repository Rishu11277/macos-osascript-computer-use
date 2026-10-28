#!/bin/bash
# Click (AXPress) exactly ONE UI element found by role and/or label. Refuses if 0 or >1 match unless --index picks one.
# Usage: click_element.sh "<process>" [--role R] [--name L] [--contains] [--window N] [--index K] [--action AXPress|AXConfirm|AXShowMenu]
#                        [--depth N] [--max-nodes N] [--slow]
#   DEFAULT is FAST mode (Accessibility API, depth 40) for a unique match + AXPress; --index/--action or --slow use
#   the System Events walk.
# Side effects: CHANGES UI (presses a control). Check with ui_find.sh first.
# Example: click_element.sh "TextEdit" --role "button" --name "Don’t Save"
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
LIB="$(cd "$(dirname "$0")" && pwd)/_find.applescript"
proc="$1"; shift || true
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,5p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
role=""; name=""; mode="exact"; win=1; idx=0; action="AXPress"; depth=auto; maxnodes=3000
while [ $# -gt 0 ]; do case "$1" in
  --role) need "$@"; role="$2"; shift 2;; --name) need "$@"; name="$2"; shift 2;; --contains) mode="contains"; shift;;
  --window) need "$@"; win="$2"; shift 2;; --index) need "$@"; idx="$2"; shift 2;; --action) need "$@"; action="$2"; shift 2;;
  --depth) need "$@"; depth="$2"; shift 2;; --max-nodes) need "$@"; maxnodes="$2"; shift 2;; --slow) depth=0; shift;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
posint --window "$win" 50; [ "$idx" = 0 ] || posint --index "$idx" 10000
[ -z "$role$name" ] && { echo "give --role and/or --name" >&2; exit 2; }
# default: fast Accessibility-API search when it can serve the request (unique match + AXPress)
if [ "$depth" = auto ]; then if [ "$idx" = 0 ] && [ "$action" = AXPress ]; then depth=40; else depth=0; fi; fi
[ "$depth" = 0 ] || { posint --depth "$depth" 50; posint --max-nodes "$maxnodes" 100000;
  [ "$idx" = 0 ] && [ "$action" = AXPress ] || { echo "--depth mode supports AXPress on a unique match only" >&2; exit 2; }
  . "$(dirname "$0")/_pid.sh"; proc_pid "$proc"; exec python3 -I "$(dirname "$0")/_ax_walk.py" "$PROC_PID" "$win" "$role" "$name" "$mode" 1 "$depth" "$maxnodes" press; }
{ cat "$LIB"; cat <<'OSA'
on run argv
    set {procName, winIdx, roleQ, nameQ, matchMode, pickIdx, act} to {item 1 of argv, (item 2 of argv) as integer, item 3 of argv, item 4 of argv, item 5 of argv, (item 6 of argv) as integer, item 7 of argv}
    set hits to my findElements(procName, winIdx, roleQ, nameQ, matchMode)
    set n to count of hits
    if n is 0 then error "no element matches role='" & roleQ & "' name='" & nameQ & "'" number -1728
    if pickIdx is 0 then
        if n > 1 then error (n as text) & " elements match; narrow the query or pass --index (see ui_find.sh)" number -1719
        set pickIdx to 1
    end if
    if pickIdx > n then error "--index " & pickIdx & " but only " & n & " matches" number -1719
    set target to item pickIdx of hits
    tell application "System Events" to perform action act of target
    return "pressed: " & act
end run
OSA
} | osascript - "$proc" "$win" "$role" "$name" "$mode" "$idx" "$action"
