#!/bin/bash
# Set the value of exactly ONE field (text field, text area, combo box, checkbox 0/1, slider) and read it back.
# Usage: set_field.sh "<process>" --value "<text>" [--role R] [--name L] [--contains] [--window N] [--index K]
#   Default role: "text field". Value is passed as an argument (never spliced into code).
# Side effects: CHANGES UI (edits a field). Exit 1 if the read-back differs.
# Example: set_field.sh "TextEdit" --role "text area" --index 1 --value "hello"
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
LIB="$(cd "$(dirname "$0")" && pwd)/_find.applescript"
proc="$1"; shift || true
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,6p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
role="text field"; name=""; mode="exact"; win=1; idx=0; val=""; hasval=0
while [ $# -gt 0 ]; do case "$1" in
  --role) need "$@"; role="$2"; shift 2;; --name) need "$@"; name="$2"; shift 2;; --contains) mode="contains"; shift;;
  --window) need "$@"; win="$2"; shift 2;; --index) need "$@"; idx="$2"; shift 2;; --value) [ $# -ge 2 ] || { echo "option --value needs a value" >&2; exit 2; }; val="$2"; hasval=1; shift 2;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
[ $hasval = 1 ] || { echo "--value is required" >&2; exit 2; }
posint --window "$win" 50; [ "$idx" = 0 ] || posint --index "$idx" 10000
{ cat "$LIB"; cat <<'OSA'
on run argv
    set {procName, winIdx, roleQ, nameQ, matchMode, pickIdx, newVal} to {item 1 of argv, (item 2 of argv) as integer, item 3 of argv, item 4 of argv, item 5 of argv, (item 6 of argv) as integer, item 7 of argv}
    set hits to my findElements(procName, winIdx, roleQ, nameQ, matchMode)
    set n to count of hits
    if n is 0 then error "no field matches role='" & roleQ & "' name='" & nameQ & "'" number -1728
    if pickIdx is 0 then
        if n > 1 then error (n as text) & " fields match; pass --name or --index" number -1719
        set pickIdx to 1
    end if
    if pickIdx > n then error "--index " & pickIdx & " but only " & n & " matches" number -1719
    set f to item pickIdx of hits
    tell application "System Events"
        try
            set focused of f to true
        end try
        set value of f to newVal
        delay 0.1
        set got to value of f as text
    end tell
    if got is not newVal then error "read-back mismatch: field now holds '" & got & "'" number -10006
    return "set ok"
end run
OSA
} | osascript - "$proc" "$win" "$role" "$name" "$mode" "$idx" "$val"
