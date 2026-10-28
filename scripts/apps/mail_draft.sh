#!/bin/bash
# Purpose: Create unsent Apple Mail draft. Side effects: WRITES draft; may launch Mail.
# Usage: mail_draft.sh RECIPIENT SUBJECT BODY_FILE
# Example: mail_draft.sh person@example.com Hello /tmp/body.txt
# Never sends. Explicitly saves, closes, and verifies the draft in Drafts.
# Returns the persisted Mail message ID; partial failures may leave a draft.
# Body arguments may be visible to local process inspection.
set -e
if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then sed -n '2,5p' "$0"; exit 0; fi
[[ $# -eq 3 && -r "$3" && -f "$3" ]] || { echo 'Expected RECIPIENT SUBJECT readable BODY_FILE' >&2; exit 2; }
body=$(cat -- "$3")
/usr/bin/osascript - "$1" "$2" "$body" <<'OSA' || exit 1
on run argv
 tell application "Mail"
  set previousIDs to id of every message of drafts mailbox
  set draftMessage to make new outgoing message with properties {subject:item 2 of argv, content:item 3 of argv, visible:false}
  tell draftMessage
   make new to recipient at end of to recipients with properties {address:item 1 of argv}
  end tell
  save draftMessage
  close draftMessage saving yes
  repeat 40 times
   set matches to (messages of drafts mailbox whose subject is (item 2 of argv))
   repeat with savedMessage in matches
    if (id of savedMessage) is not in previousIDs and (address of every to recipient of savedMessage) contains (item 1 of argv) then
     if (content of savedMessage as text) contains (item 3 of argv) then return id of savedMessage
    end if
   end repeat
   delay 0.25
  end repeat
  error "Mail did not expose a saved draft in Drafts within 10 seconds; inspect Drafts before retrying" number -1712
 end tell
end run
OSA
