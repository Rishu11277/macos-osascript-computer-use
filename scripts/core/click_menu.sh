#!/bin/bash
# Click a menu-bar item by path, any depth: "File > Export > PDF". Verifies the item exists and is enabled first.
# Usage: click_menu.sh "<process>" "<Menu > Item [> Subitem…]>" [--dry-run] [--list]
#   --dry-run: check only.  --list: print items of the given menu path (e.g. "File") instead of clicking.
#   Ellipsis "…" is one character; "..." in the path also matches it.
# Side effects: CHANGES UI (brings app to front, runs a menu command). --dry-run also brings the app to
#   front (needed to read enabled state); --list is read-only.
# Example: click_menu.sh "TextEdit" "Format > Font > Bold"
proc="$1"; path="$2"; opt="$3"
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,7p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
[ -z "$path" ] && { echo "menu path required" >&2; exit 2; }
osascript - "$proc" "$path" "$opt" <<'OSA'
on run argv
    set {procName, menuPath, opt} to {item 1 of argv, item 2 of argv, item 3 of argv}
    set AppleScript's text item delimiters to ">"
    set rawParts to text items of menuPath
    set AppleScript's text item delimiters to ""
    set parts to {}
    repeat with p in rawParts
        set t to my trimText(p as text)
        if t is not "" then set end of parts to t
    end repeat
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        tell process procName
            -- menu items report disabled while the app is in the background, so bring it forward first
            -- (except for read-only --list)
            if opt is not "--list" then
                set frontmost to true
                repeat 25 times
                    if frontmost then exit repeat
                    delay 0.2
                end repeat
                if not frontmost then error procName & " could not be brought to the front" number -1719
            end if
            set cur to menu bar 1
            set depth to count of parts
            repeat with i from 1 to depth
                set nm to item i of parts
                if i is 1 then
                    set found to my pickName(name of every menu bar item of cur, nm)
                    if found is "" then error "menu '" & nm & "' not found. Menus: " & my joinNames(name of every menu bar item of cur) number -1728
                    set cur to menu 1 of menu bar item found of cur
                else
                    set found to my pickName(name of every menu item of cur, nm)
                    if found is "" then error "item '" & nm & "' not found. Items: " & my joinNames(name of every menu item of cur) number -1728
                    if i < depth then
                        set cur to menu 1 of menu item found of cur
                    else
                        set target to menu item found of cur
                    end if
                end if
            end repeat
            if opt is "--list" then
                if depth > 1 then
                    try
                        set cur to menu 1 of target
                    on error
                        error "'" & found & "' has no submenu to list" number -1728
                    end try
                end if
                return my joinNames(name of every menu item of cur)
            end if
            if depth < 2 then error "path needs at least Menu > Item" number -50
            if not (enabled of target) then error "menu item '" & found & "' is disabled" number -10003
            if opt is "--dry-run" then return "ok (dry run): " & menuPath
            click target
        end tell
    end tell
    return "clicked: " & menuPath
end run
on pickName(namesList, wanted)
    set alt to my replaceText(wanted, "...", "…")
    repeat with n in namesList
        if n is not missing value then
            if (n as text) is wanted or (n as text) is alt then return n as text
        end if
    end repeat
    return ""
end pickName
on replaceText(s, a, b)
    set AppleScript's text item delimiters to a
    set L to text items of s
    set AppleScript's text item delimiters to b
    set r to L as text
    set AppleScript's text item delimiters to ""
    return r
end replaceText
on trimText(s)
    repeat while s starts with " "
        set s to text 2 thru -1 of s
        if s is "" then return ""
    end repeat
    repeat while s ends with " "
        set s to text 1 thru -2 of s
        if s is "" then return ""
    end repeat
    return s
end trimText
on joinNames(L)
    set out to {}
    repeat with x in L
        set x to contents of x
        if x is missing value then
            set end of out to "—"
        else
            set end of out to x as text
        end if
    end repeat
    set AppleScript's text item delimiters to ", "
    set r to out as text
    set AppleScript's text item delimiters to ""
    return r
end joinNames
OSA
