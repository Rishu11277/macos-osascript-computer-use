#!/bin/bash
# Read the value of UI elements (fields, static text, checkboxes) matching role and/or label.
# Usage: get_field.sh "<process>" [--role R] [--name L] [--contains] [--window N] [--index K]
#   Default role: "text field". Without --index prints every match as "[i] value".
# Side effects: READ-ONLY.
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
LIB="$(cd "$(dirname "$0")" && pwd)/_find.applescript"
proc="$1"; shift || true
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,5p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
role="text field"; name=""; mode="exact"; win=1; idx=0
while [ $# -gt 0 ]; do case "$1" in
  --role) need "$@"; role="$2"; shift 2;; --name) need "$@"; name="$2"; shift 2;; --contains) mode="contains"; shift;;
  --window) need "$@"; win="$2"; shift 2;; --index) need "$@"; idx="$2"; shift 2;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
posint --window "$win" 50; [ "$idx" = 0 ] || posint --index "$idx" 10000
{ cat "$LIB"; cat <<'OSA'
on run argv
    set {procName, winIdx, roleQ, nameQ, matchMode, pickIdx} to {item 1 of argv, (item 2 of argv) as integer, item 3 of argv, item 4 of argv, item 5 of argv, (item 6 of argv) as integer}
    set hits to my findElements(procName, winIdx, roleQ, nameQ, matchMode)
    if (count of hits) is 0 then error "no element matches" number -1728
    set out to {}
    tell application "System Events"
        repeat with i from 1 to count of hits
            if pickIdx is 0 or pickIdx is i then
                set v to ""
                try
                    set v to value of (item i of hits)
                end try
                if v is missing value then set v to ""
                if pickIdx is 0 then
                    set end of out to "[" & i & "] " & (v as text)
                else
                    set end of out to v as text
                end if
            end if
        end repeat
    end tell
    if (count of out) is 0 then error "--index out of range" number -1719
    set AppleScript's text item delimiters to linefeed
    return out as text
end run
OSA
} | osascript - "$proc" "$win" "$role" "$name" "$mode" "$idx"
