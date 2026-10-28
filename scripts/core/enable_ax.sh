#!/bin/bash
# Expose an Electron/Chromium app's web UI to Accessibility (sets AXManualAccessibility = true on the app).
# Electron apps (Arduino IDE 2, VS Code, GitHub Desktop, Slack, SPIKE, ...) show only an empty "group" to
# ui_find/click_element until this is set. Lasts until the app quits. Then re-run ui_find/ui_tree.
# Usage: enable_ax.sh "<process>"      Side effects: CHANGES the app's accessibility mode (no visible change).
proc="$1"
[ -z "$proc" ] || [ "$proc" = "-h" ] && { sed -n '2,6p' "$0"; [ -z "$proc" ] && exit 2 || exit 0; }
osascript - "$proc" <<'OSA'
on run argv
    set p to item 1 of argv
    tell application "System Events"
        if not (exists process p) then error "no process named " & p number -1728
        tell process p
            try
                set value of attribute "AXManualAccessibility" to true
            on error m number n
                error "could not set AXManualAccessibility (not an Electron app?): " & m number n
            end try
            set c to 0
            repeat 10 times
                delay 0.3
                try
                    set c to count of (entire contents of window 1)
                end try
                if c > 0 then exit repeat
            end repeat
            return "AXManualAccessibility on; window 1 now exposes " & c & " elements"
        end tell
    end tell
end run
OSA
