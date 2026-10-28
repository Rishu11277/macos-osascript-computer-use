#!/bin/bash
# Find UI elements in an app window by role and/or label; prints one line per match.
# Usage: ui_find.sh "<process>" [--role "<role description|AXRole>"] [--name "<label>"] [--contains] [--window N] [--max N]
#                   [--depth N] [--max-nodes N] [--slow]
#   DEFAULT is FAST mode (depth 40). --slow: old System Events `entire contents` walk (also matches AXTitle via
#   System Events names; use only if fast mode misses something).
#   --depth N: FAST mode (direct Accessibility API; ~1000x faster on big web views like SPIKE/Electron/browsers):
#              breadth-first, limited to N levels and --max-nodes elements (default 3000); stops at --max matches.
#              Labels: title/description/help (+value with --contains). Reports how many elements were searched.
#   Labels checked: name, description, AXTitle, help. Matching is case-insensitive: exact by default, substring with --contains.
#   Walks `entire contents`, so large windows (Finder, web views) can take many seconds.
# Side effects: READ-ONLY (needs Accessibility). Slow on big web views (walks `entire contents`).
# Example: ui_find.sh "TextEdit" --role "button" --contains --name "Save"
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
LIB="$(cd "$(dirname "$0")" && pwd)/_find.applescript"
proc="$1"; shift || true
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,7p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
role=""; name=""; mode="exact"; win=1; max=50; depth=40; maxnodes=3000
while [ $# -gt 0 ]; do case "$1" in
  --role) need "$@"; role="$2"; shift 2;; --name) need "$@"; name="$2"; shift 2;; --contains) mode="contains"; shift;;
  --window) need "$@"; win="$2"; shift 2;; --max) need "$@"; max="$2"; shift 2;;
  --depth) need "$@"; depth="$2"; shift 2;; --max-nodes) need "$@"; maxnodes="$2"; shift 2;; --slow) depth=0; shift;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
posint --window "$win" 50; posint --max "$max" 1000
[ "$depth" = 0 ] || { posint --depth "$depth" 50; posint --max-nodes "$maxnodes" 100000;
  . "$(dirname "$0")/_pid.sh"; proc_pid "$proc"; exec python3 -I "$(dirname "$0")/_ax_walk.py" "$PROC_PID" "$win" "$role" "$name" "$mode" "$max" "$depth" "$maxnodes" list; }
{ cat "$LIB"; cat <<'OSA'
on run argv
    set {procName, winIdx, roleQ, nameQ, matchMode, maxN} to {item 1 of argv, (item 2 of argv) as integer, item 3 of argv, item 4 of argv, item 5 of argv, (item 6 of argv) as integer}
    set hits to my findElements(procName, winIdx, roleQ, nameQ, matchMode)
    set out to {"matches: " & (count of hits)}
    set i to 0
    tell application "System Events"
        repeat with e in hits
            set i to i + 1
            if i > maxN then exit repeat
            set {c, n, d, v, roleDesc} to {"", "", "", "", ""}
            try
                set c to class of e as text
            end try
            try
                set n to name of e
            end try
            try
                set d to description of e
            end try
            try
                set roleDesc to role description of e
            end try
            try
                set v to value of e
            end try
            set end of out to "[" & i & "] " & roleDesc & " | name=" & my s(n) & " | desc=" & my s(d) & " | value=" & my s(v)
        end repeat
    end tell
    set AppleScript's text item delimiters to linefeed
    return out as text
end run
on s(x)
    if x is missing value then return "-"
    try
        set t to x as text
    on error
        return "(non-text)"
    end try
    if length of t > 80 then set t to (text 1 thru 80 of t) & "…"
    return t
end s
OSA
} | osascript - "$proc" "$win" "$role" "$name" "$mode" "$max"
