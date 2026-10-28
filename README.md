# macos-osascript-computer-use

An agent skill for Claude Code and Codex that controls macOS apps with `osascript` (AppleScript/JXA) and the
Accessibility API when no computer-use tools are loaded. `SKILL.md` holds the knowledge; `scripts/` holds 49
helper files (core UI helpers plus Chrome, VS Code, GitHub Desktop, Arduino IDE, SPIKE, Spark, and native-app helpers).

## Install on another Mac
1. Get the files: clone this Buzz repository (an agent can clone it with its `repo` tool), or copy the folder.
2. Install for both agents:
   ```sh
   SRC=/path/to/macos-osascript-computer-use
   for d in ~/.claude/skills ~/.codex/skills; do mkdir -p "$d" && rm -rf "$d/macos-osascript-computer-use" && cp -R "$SRC" "$d/"; done
   chmod +x ~/.claude/skills/macos-osascript-computer-use/scripts/*/*.sh ~/.codex/skills/macos-osascript-computer-use/scripts/*/*.sh
   ```
3. Grant permissions to the app that runs the agent (Terminal, iTerm, Claude, Codex) in System Settings → Privacy & Security:
   **Accessibility** (UI scripting, keystrokes), **Automation** (prompted per target app on first use), and
   **Screen Recording** (screenshots). For Chrome page scripting, enable View → Developer → Allow JavaScript from Apple Events.
4. Verify: `~/.claude/skills/macos-osascript-computer-use/scripts/core/probe.sh Finder` should report `accessibility … OK`.
5. Restart the agent session so it picks up the new skill.

Requirements: macOS with `osascript`, `python3`, `perl` (all preinstalled). Optional: `spark` CLI (Spark Desktop),
VS Code's bundled `code`, `git`, `arduino-cli`. No Xcode needed.

## Updating
Edit the source copy, then run `scripts/sync.sh`. It validates everything, then copies to `~/.claude/skills` and
`~/.codex/skills`. Then ask an agent to commit and push this repo and republish the Buzz note
`macos-osascript-computer-use` (those two steps need an agent's Buzz tools).
