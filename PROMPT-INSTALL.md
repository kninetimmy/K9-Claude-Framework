# Prompt-based install

If you'd rather not run a shell script yourself, paste the prompt below
into Claude Code and let it handle the install.

This is optional. The shell scripts (`install.sh` on macOS/Linux,
`install.ps1` on Windows) do the same thing and are usually faster. Use
this flow if you specifically want Claude to perform the install step
by step.

## Prompt

Copy everything inside the fenced block and paste it to Claude Code:

```
Install the K9-Claude-Framework from
https://github.com/kninetimmy/K9-Claude-Framework into my Claude Code
setup. Do the following:

1. Detect my operating system.
2. Clone the repository to a temporary directory (OS-appropriate — e.g.
   ~/tmp on macOS/Linux, $env:TEMP on Windows).
3. Run the matching installer from that clone:
   - macOS/Linux: bash install.sh
   - Windows:     powershell -ExecutionPolicy Bypass -File install.ps1
4. After the installer completes, delete the temporary clone.
5. Report back with:
   - Which install script ran
   - What files it wrote to ~/.claude/commands/ (or the Windows
     equivalent)
   - Any files it backed up
   - The contents of ~/.claude/.k9-framework-version

Do not modify any project files. Do not touch my shell rc files or
Claude Code settings beyond the ~/.claude/commands/ directory and the
framework marker file. Ask before deviating from these steps.
```

## What this does

After the install, you'll have three new global commands available in
every Claude Code session:

- `/init-project` — bootstrap a new or cloned project with the
  four-file framework
- `/wrap-up` — end-of-session ritual that routes updates across the
  four files
- `/check-init` — read-only health check

From there, `cd` into any project and run `/init-project` to try it.
