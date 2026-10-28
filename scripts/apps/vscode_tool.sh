#!/bin/bash
# VS Code CLI. Usage: vscode_tool.sh extensions | open PATH | goto PATH:LINE[:COLUMN]
# Example: vscode_tool.sh extensions. Side effects: open/goto change UI.
set -u
usage(){ echo 'Usage: vscode_tool.sh extensions | open PATH | goto PATH:LINE[:COLUMN]'; }
[[ ${1:-} == -h ]] && { usage; exit 0; }
[[ $# -ge 1 ]] || { usage >&2; exit 2; }
codebin=$(command -v code || true)
[[ -n $codebin ]] || codebin='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
[[ -x $codebin ]] || { echo 'VS Code CLI unavailable; inspect its UI with the core helpers.' >&2; exit 1; }
case "$1" in
 extensions) [[ $# == 1 ]] || exit 2; exec "$codebin" --list-extensions ;;
 open) [[ $# == 2 && -e $2 ]] || { usage >&2; exit 2; }; exec "$codebin" -- "$2" ;;
 goto) [[ $# == 2 && $2 =~ :[0-9]+(:[0-9]+)?$ ]] || { usage >&2; exit 2; }; exec "$codebin" --goto "$2" ;;
 *) usage >&2; exit 2;;
esac
