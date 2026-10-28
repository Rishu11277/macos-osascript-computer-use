-- Shared finder: returns UI elements of window `winIdx` of process `procName`
-- whose role description / class / name / description / title / value match.
-- roleQ: "" or a role description ("button", "text field") or AX role ("AXButton").
-- nameQ: "" or text to match (exact unless matchMode is "contains").
on findElements(procName, winIdx, roleQ, nameQ, matchMode)
    tell application "System Events"
        if not (exists process procName) then error "no process named " & procName number -1728
        tell process procName
            if (count of windows) < winIdx then error "process " & procName & " has no window " & winIdx number -1719
            set allEls to entire contents of window winIdx
        end tell
        set hits to {}
        repeat with e in allEls
            set ok to true
            if roleQ is not "" then
                set roleDesc to ""
                set axRole to ""
                try
                    set roleDesc to role description of e
                end try
                try
                    set axRole to role of e
                end try
                if not (roleDesc is roleQ or axRole is roleQ) then set ok to false
            end if
            if ok and nameQ is not "" then
                set labels to {}
                repeat with propName in {"name", "description", "title", "help"}
                    try
                        if propName as text is "name" then set lblVal to name of e
                        if propName as text is "description" then set lblVal to description of e
                        if propName as text is "title" then set lblVal to value of attribute "AXTitle" of e
                        if propName as text is "help" then set lblVal to help of e
                        if lblVal is not missing value then set end of labels to lblVal as text
                    end try
                end repeat
                set ok to false
                repeat with lbl in labels
                    if matchMode is "contains" then
                        if (lbl as text) contains nameQ then set ok to true
                    else
                        if (lbl as text) is nameQ then set ok to true
                    end if
                end repeat
            end if
            if ok then set end of hits to contents of e
        end repeat
        return hits
    end tell
end findElements
