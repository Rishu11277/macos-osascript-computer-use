#!/bin/bash
# List or manage windows of a process via System Events (works for apps without a dictionary).
# Usage:
#   window.sh list   "<process>"                         READ-ONLY: index | title | x,y | w×h | minimized
#   window.sh focus  "<process>" [--index N | --title-contains T]   CHANGES UI (raise + frontmost)
#   window.sh move   "<process>" X Y   [--index N]       CHANGES UI
#   window.sh resize "<process>" W H   [--index N]       CHANGES UI
#   window.sh bounds "<process>" [--index N]             READ-ONLY: prints x,y,w,h (for screencapture -R)
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { echo "option $1 needs a value" >&2; exit 2; }; }
posint() { case "$2" in ""|*[!0-9]*) echo "$1 must be a positive integer" >&2; exit 2;; esac; [ "$2" -ge 1 ] && [ "$2" -le "${3:-100000}" ] || { echo "$1 must be 1-${3:-100000}" >&2; exit 2; }; }
op="$1"; proc="$2"; shift $(( $# < 2 ? $# : 2 ))
[ -z "$op" ] || [ "$op" = "-h" ] && { sed -n '2,8p' "$0"; [ -z "$op" ] && exit 2 || exit 0; }
[ -z "$proc" ] && { echo "process required" >&2; exit 2; }
a=""; b=""; idx=1; title=""
case "$op" in move|resize) [ $# -ge 2 ] || { echo "$op needs two integers" >&2; exit 2; }; a="$1"; b="$2"; shift 2;; esac
while [ $# -gt 0 ]; do case "$1" in --index) need "$@"; idx="$2"; shift 2;; --title-contains) need "$@"; title="$2"; shift 2;; *) echo "unknown arg: $1" >&2; exit 2;; esac; done
case "$op" in list|focus|bounds) ;; move) for v in "$a" "$b"; do [[ "$v" =~ ^-?[0-9]+$ ]] || { echo "move needs two integers" >&2; exit 2; }; done;; resize) posint width "$a" 20000; posint height "$b" 20000;; *) echo "unknown op: $op" >&2; exit 2;; esac
posint --index "$idx" 1000
osascript - "$op" "$proc" "$a" "$b" "$idx" "$title" <<'OSA'
on run argv
    set {op, procName, a, b, idx, titleQ} to {item 1 of argv, item 2 of argv, item 3 of argv, item 4 of argv, (item 5 of argv) as integer, item 6 of argv}
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        tell process procName
            set n to count of windows
            if op is "list" then
                set out to {"windows: " & n}
                repeat with i from 1 to n
                    set w to window i
                    set {px, py} to position of w
                    set {sx, sy} to size of w
                    set t to ""
                    try
                        set t to name of w as text
                    end try
                    set mz to "?"
                    try
                        set mz to value of attribute "AXMinimized" of w
                    end try
                    set end of out to (i as text) & " | " & t & " | " & px & "," & py & " | " & sx & "x" & sy & " | minimized=" & mz
                end repeat
                set AppleScript's text item delimiters to linefeed
                return out as text
            end if
            if n is 0 then error procName & " has no windows" number -1719
            if titleQ is not "" then
                set idx to 0
                repeat with i from 1 to n
                    set t to ""
                    try
                        set t to name of window i as text
                    end try
                    if t contains titleQ then
                        if idx is not 0 then error "several windows contain '" & titleQ & "'" number -1719
                        set idx to i
                    end if
                end repeat
                if idx is 0 then error "no window title contains '" & titleQ & "'" number -1728
            end if
            if idx > n then error "no window " & idx & " (has " & n & ")" number -1719
            set w to window idx
            if op is "bounds" then
                set {px, py} to position of w
                set {sx, sy} to size of w
                return (px as text) & "," & py & "," & sx & "," & sy
            else if op is "focus" then
                perform action "AXRaise" of w
                set frontmost to true
                return "focused window " & idx
            else if op is "move" then
                set position of w to {a as integer, b as integer}
                return "moved to " & a & "," & b
            else if op is "resize" then
                set size of w to {a as integer, b as integer}
                return "resized to " & a & "x" & b
            end if
        end tell
    end tell
end run
OSA
