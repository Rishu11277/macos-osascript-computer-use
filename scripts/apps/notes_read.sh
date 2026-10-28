#!/bin/bash
# Purpose: Read one note by exact ID. Side effects: READ-ONLY; may request Automation.
# Usage: notes_read.sh NOTE_ID [--json]
# Example: notes_read.sh --help
# JSON output; HTML body retained. Obtain ID from notes_list.sh.
set -e
if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then sed -n '2,5p' "$0"; exit 0; fi
[[ $# -eq 1 || ( $# -eq 2 && "$2" == '--json' ) ]] || { echo 'Expected NOTE_ID [--json]' >&2; exit 2; }
/usr/bin/osascript -l JavaScript - "$1" <<'JXA' || exit 1
function run(args) {
 var app=Application('Notes');
 if(!app.running()) throw Error('Notes is not running');
 var notes=app.notes.whose({id:args[0]})();
 if(notes.length!==1) throw Error('Expected one exact note ID');
 return JSON.stringify({id:notes[0].id(),name:notes[0].name(),body:notes[0].body()});
}
JXA
