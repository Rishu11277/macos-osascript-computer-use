#!/bin/bash
# Read-only dump of an app's menus and front-window UI elements (needs Accessibility).
# Usage: scripts/ui_tree.sh "<process name>" [deep]
#   deep = also print `entire contents` of window 1 (slow/huge on web views).
proc="$1"; deep="$2"
[ -z "$proc" ] && { echo "usage: $0 \"<process name>\" [deep]" >&2; exit 2; }
osascript - "$proc" "$deep" <<'OSA'
on run argv
    set p to item 1 of argv
    set deep to (count of argv) > 1 and item 2 of argv is "deep"
    set out to {}
    tell application "System Events"
        if not (exists process p) then error "No process named " & p number -1728
        tell process p
            set end of out to "MENUS: " & (my joinList(name of every menu of menu bar 1, ", "))
            if (count of windows) is 0 then
                set end of out to "WINDOWS: none"
            else
                set end of out to "WINDOW 1: " & (name of window 1 as text)
                repeat with e in (UI elements of window 1)
                    set end of out to "  " & (class of e as text) & " | " & (my safeText(name of e)) & " | " & (my safeText(role description of e))
                end repeat
                if deep then set end of out to "ENTIRE: " & ((entire contents of window 1) as text)
            end if
        end tell
    end tell
    return my joinList(out, linefeed)
end run
on safeText(v)
    if v is missing value then return "-"
    return v as text
end safeText
on joinList(L, d)
    set {o, AppleScript's text item delimiters} to {AppleScript's text item delimiters, d}
    set r to L as text
    set AppleScript's text item delimiters to o
    return r
end joinList
OSA
