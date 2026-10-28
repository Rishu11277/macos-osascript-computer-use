#!/bin/bash
# Validate the skill, then install this copy into ~/.claude/skills and ~/.codex/skills (replacing older copies).
# Usage: scripts/sync.sh [--check]   (--check validates only)
# Side effects: WRITES ~/.claude/skills/macos-osascript-computer-use and ~/.codex/skills/macos-osascript-computer-use
set -u
SRC="$(cd "$(dirname "$0")/.." && pwd)"; NAME=macos-osascript-computer-use
[ "${1:-}" = -h ] && { sed -n '2,4p' "$0"; exit 0; }
fail=0
for f in "$SRC"/scripts/*/*.sh "$SRC"/scripts/*.sh; do bash -n "$f" || { echo "syntax: $f" >&2; fail=1; }; done
for f in "$SRC"/scripts/core/*.py; do python3 -I -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f" || { echo "python: $f" >&2; fail=1; }; done
t=$(mktemp -d); awk -v d="$t" '/^ *```applescript/{n++; g=sprintf("%s/b%02d.applescript",d,n); inb=1; next} /^ *```/{inb=0; next} inb{print > g}' "$SRC/SKILL.md"
for g in "$t"/*.applescript; do osacompile -o "$t/x.scpt" "$g" 2>/dev/null || { echo "AppleScript block fails: $(basename "$g")" >&2; fail=1; }; done; rm -rf "$t"
desc=$(sed -n 's/^description: //p' "$SRC/SKILL.md" | head -1); [ ${#desc} -le 1024 ] || { echo "description > 1024 chars" >&2; fail=1; }
[ $fail = 0 ] || { echo "validation FAILED; nothing installed" >&2; exit 1; }
echo "validation OK"
[ "${1:-}" = --check ] && exit 0
for d in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
  [ "$d/$NAME" = "$SRC" ] && continue
  mkdir -p "$d"; rm -rf "$d/$NAME.tmp"; cp -R "$SRC" "$d/$NAME.tmp" && rm -rf "$d/$NAME" && mv "$d/$NAME.tmp" "$d/$NAME"
  find "$d/$NAME" \( -name .git -o -name __pycache__ -o -name .DS_Store \) -prune -exec rm -rf {} +
  echo "installed: $d/$NAME"
done
