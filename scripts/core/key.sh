#!/bin/bash
# Send a key or shortcut to a process, only if it is frontmost (or --activate).
# Usage: key.sh "<process>" "<combo>" [--activate]
#   combo: modifiers joined by + then a key: cmd+s, cmd+shift+t, ctrl+tab, return, esc, tab, space,
#          delete, fwddelete, up, down, left, right, home, end, pageup, pagedown, f1-f12, or a single character.
# Side effects: CHANGES UI.
proc="$1"; combo="$2"; opt="$3"
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,6p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
[ -z "$combo" ] && { echo "combo required" >&2; exit 2; }
osascript - "$proc" "$combo" "$opt" <<'OSA'
on run argv
    set {procName, combo, opt} to {item 1 of argv, item 2 of argv, item 3 of argv}
    set AppleScript's text item delimiters to "+"
    set parts to text items of combo
    set AppleScript's text item delimiters to ""
    set keyName to item -1 of parts
    if keyName is "" and (count of parts) > 1 then set keyName to "+"
    set mods to {}
    set modNames to {}
    if (count of parts) > 1 then set modNames to items 1 thru -2 of parts
    repeat with m in modNames
        set m to m as text
        if m is in {"cmd", "command"} then
            set end of mods to command down
        else if m is in {"shift"} then
            set end of mods to shift down
        else if m is in {"opt", "option", "alt"} then
            set end of mods to option down
        else if m is in {"ctrl", "control"} then
            set end of mods to control down
        else if m is not "" then
            error "unknown modifier: " & m number -50
        end if
    end repeat
    set codes to {{"return", 36}, {"enter", 76}, {"tab", 48}, {"space", 49}, {"delete", 51}, {"esc", 53}, {"escape", 53}, {"fwddelete", 117}, {"left", 123}, {"right", 124}, {"down", 125}, {"up", 126}, {"home", 115}, {"end", 119}, {"pageup", 116}, {"pagedown", 121}, {"f1", 122}, {"f2", 120}, {"f3", 99}, {"f4", 118}, {"f5", 96}, {"f6", 97}, {"f7", 98}, {"f8", 100}, {"f9", 101}, {"f10", 109}, {"f11", 103}, {"f12", 111}}
    set kc to -1
    repeat with c in codes
        if (item 1 of c) is keyName then set kc to item 2 of c
    end repeat
    if kc is -1 and (length of keyName) is not 1 then error "unknown key: " & keyName number -50
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        if opt is "--activate" then
            set frontmost of process procName to true
            repeat 25 times
                if frontmost of process procName then exit repeat
                delay 0.2
            end repeat
        end if
        if not (frontmost of process procName) then error procName & " is not frontmost; refusing (use --activate)" number -1719
        if kc is -1 then
            keystroke keyName using mods
        else
            key code kc using mods
        end if
    end tell
    return "sent " & combo
end run
OSA
