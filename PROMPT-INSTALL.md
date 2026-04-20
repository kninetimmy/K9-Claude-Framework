# Prompt-based install

If you'd rather not run a shell script yourself, paste the prompt below
into your CLI and let it handle the install.

This is optional. The shell scripts (`install.sh` on macOS/Linux,
`install.ps1` on Windows) do the same thing and are usually faster. Use
this flow if you specifically want the CLI to perform the install step
by step.

The installer auto-detects Claude Code (`~/.claude/`), Codex CLI
(`~/.codex/` or `codex` in PATH), or both, and installs to all detected
targets.

## Prompt

Copy everything inside the fenced block and paste it to your CLI session:

```
Install the K9-Claude-Framework from
https://github.com/kninetimmy/K9-Claude-Framework. Do the following:

1. Detect my operating system.
2. Clone the repository to a temporary directory (OS-appropriate — e.g.
   ~/tmp on macOS/Linux, $env:TEMP on Windows).
3. Run the matching installer from that clone:
   - macOS/Linux: bash install.sh
   - Windows:     powershell -ExecutionPolicy Bypass -File install.ps1
4. After the installer completes, delete the temporary clone.
5. Report back with:
   - Which CLIs were detected (Claude Code, Codex, or both)
   - Which install script ran
   - What files were written and where
   - Any files that were backed up
   - The contents of any framework marker files written
     (~/.claude/.k9-framework-version and/or ~/.codex/.k9-framework-version)

Do not modify any project files. Do not touch shell rc files or CLI
settings beyond the install targets listed above. Ask before deviating
from these steps.
```

## What this does

After the install, you'll have three new commands available in every
session:

| Command        | Claude Code    | Codex                              |
|----------------|----------------|------------------------------------|
| Initialize     | `/init-project`| `$init-project` (or /skills picker)|
| End-of-session | `/wrap-up`     | `$wrap-up`                         |
| Health check   | `/check-init`  | `$check-init`                      |

From there, `cd` into any project and run the init command to try it.
