---
name: check-init
description: Read-only health check of the project_docs framework in this project
framework: K9-Claude-Framework
framework_version: 1.2.1
command_version: 1.2.1
codex_skill_version: 1.2.1
last_updated: 2026-05-12
---

Verify this project's project_docs framework is healthy. Read-only —
no writes, no fixes applied without my say-so.

## CLI Detection

Run this block first, before any other step. The variable table it produces
is the only source of CLI-specific values used throughout this command —
never hardcode paths or filenames inline.

**Signal 1 — `CLAUDECODE` env var (most reliable).**
Run: `echo "${CLAUDECODE}"`
- Output is `1` → **Claude Code confirmed.** Set the variable table and proceed.
- Output is empty → not in a Claude Code session. Continue to Signal 2.

**Signal 2 — `~/.codex/` directory.**
Run: `test -d "${HOME}/.codex" && echo "exists" || echo "absent"`
- `exists` → **Codex CLI confirmed.** Set the variable table and proceed.
- `absent` → continue to Signal 3.

**Signal 3 — `codex` binary (excluding Claude plugin cache).**
Run: `command -v codex 2>/dev/null | grep -v '\.claude/plugins' || echo "absent"`
- Non-empty path (not `absent`) → **Codex CLI confirmed.** Set variables and proceed.
- `absent` → continue to Signal 4.

**Signal 4 — Framework marker files.**
Run: `ls "${HOME}/.claude/.k9-framework-version" 2>/dev/null && echo "claude" || echo "absent"`
Run: `ls "${HOME}/.codex/.k9-framework-version" 2>/dev/null && echo "codex" || echo "absent"`
- One file exists → that CLI. If both exist, the one more recently modified wins
  (`ls -t "${HOME}/.claude/.k9-framework-version" "${HOME}/.codex/.k9-framework-version" 2>/dev/null | head -1`).

**Signal 5 — Project context file.**
Check which framework context file exists at the project root:
Run: `ls CLAUDE.md AGENTS.md 2>/dev/null`
- Only `CLAUDE.md` found → **Claude Code.**
- Only `AGENTS.md` found → **Codex CLI.**
- Both found → the one that references `agent_docs/project_state.md` was written
  by this framework; prefer it. If both reference it, fall back to Signal 6.

**Signal 6 — Fallback.**
None of the above matched. Ask: "I could not detect your CLI environment.
Are you running Claude Code or Codex? Reply `claude-code` or `codex`."
Wait for response before continuing.

---

### Variable table

Once the CLI is identified, set every value below. Reference **only** these
variables in subsequent steps — never substitute CLI names or paths inline.

| Variable                | Claude Code                          | Codex                                  |
|-------------------------|--------------------------------------|----------------------------------------|
| `$CLI`                  | `claude-code`                        | `codex`                                |
| `$CONTEXT_FILE`         | `CLAUDE.md`                          | `AGENTS.md`                            |
| `$OTHER_CONTEXT_FILE`   | `AGENTS.md`                          | `CLAUDE.md`                            |
| `$COMMANDS_DIR`         | `~/.claude/commands/`                | `~/.agents/skills/`                    |
| `$MARKER_FILE`          | `~/.claude/.k9-framework-version`    | `~/.codex/.k9-framework-version`       |
| `$INVOKE_INIT`          | `/init-project`                      | `$init-project` (or `/skills` picker)  |
| `$INVOKE_WRAP`          | `/wrap-up`                           | `$wrap-up` (or `/skills` picker)       |
| `$INVOKE_CHECK`         | `/check-init`                        | `$check-init` (or `/skills` picker)    |

For command file paths (used in Step 6), derive from `$CLI`:
- Claude Code: `~/.claude/commands/init-project.md`, `wrap-up.md`, `check-init.md`
- Codex: `~/.agents/skills/init-project/SKILL.md`, `wrap-up/SKILL.md`, `check-init/SKILL.md`

---

## Steps

1. **File presence.** Confirm each expected file exists:
   - Context file at the project root — check for both `$CONTEXT_FILE`
     and `$OTHER_CONTEXT_FILE`:
     - Both present → cross-CLI project; note as Yellow (see Notes).
     - Only `$CONTEXT_FILE` present → normal.
     - Only `$OTHER_CONTEXT_FILE` present → initialized for the other
       CLI only; note as Yellow (see Notes). Use `$OTHER_CONTEXT_FILE`
       for the pointer check in Step 3.
     - Neither present → Red.
   - `agent_docs/.init-version`
   - `agent_docs/project_state.md`
   - `agent_docs/project_backlog.md`
   - `agent_docs/project_decisions.md`
   - `agent_docs/project_arch.md`

2. **Non-empty check.** Each file should have real content, not
   just skeleton headers or placeholder TODOs left from init. Flag
   any that look untouched since bootstrap.

3. **Context file pointers.** Read whichever context file(s) are
   present (`$CONTEXT_FILE`, `$OTHER_CONTEXT_FILE`, or both) and
   confirm each references all four `agent_docs/project_*.md` files.
   Missing pointers in a present file are a drift signal.

4. **Internal consistency.**
   - Check the "Last updated" date in `project_state.md`. Run
     `git log --oneline -5` — if there are commits newer than that
     date, flag `$INVOKE_WRAP` as overdue.
   - Count lines in `project_state.md`. Flag if over ~100 (hard
     ceiling) or creeping past ~75 (approaching the ceiling).
   - Scan "Open questions" in `project_state.md` — if any look
     stale (answered in commits, or clearly belong in
     `project_decisions.md` by now), call them out.

5. **Placeholder detection.** Search all five content files for
   `TODO`, `FIXME`, `[fill in]`, `<...>` template placeholders, and
   lorem-ipsum text that should've been replaced during init. List
   each hit with its file and line.

6. **memhub coexistence check (read-only, optional).** memhub is an
   optional companion CLI that stores structured project memory in
   `.memhub/project.sqlite`. If it's present in this repo, surface
   its health alongside the K9 health. Skip entirely if no memhub
   signals are found — its absence is not a finding.

   Probes (run them all, then summarize):
   - `test -d .memhub && echo present || echo absent` — is the repo
     memhub-initialized?
   - `command -v memhub >/dev/null 2>&1 && echo present || echo absent`
     — is the binary installed?
   - If both above are `present`, run `memhub integrations status`
     and capture its output. Look for the `K9 detected` and
     `K9 integration` lines.
   - Read whichever context file is present and check for the
     `<!-- memhub:managed:start -->` / `<!-- memhub:managed:end -->`
     marker pair. Both must be present and in that order to be valid.

   Findings to report (each is informational unless marked):
   - `.memhub/` present, binary absent → note that memhub data exists
     locally but no CLI is installed on this machine. Informational.
   - `.memhub/` present, binary present, `memhub integrations status`
     shows `K9 detected: yes / K9 integration: enabled` → Green for
     memhub. Note the `agent_docs_path`.
   - `K9 detected: yes` but `K9 integration: disabled` → Yellow
     (memhub flag points at this repo but is disabled). Suggested
     fix: `memhub integrations enable-k9`.
   - `K9 enabled in config but agent_docs/project_state.md is missing`
     drift note in status → Yellow. Suggested fix: either re-run
     `$INVOKE_INIT` or `memhub integrations disable-k9`.
   - `.memhub/` present and context file lacks the managed block
     markers → Yellow. Suggested fix: run `memhub sync-md`.
   - Managed block marker pair is mismatched or out of order →
     Yellow. The block must be regenerated; manual edits can corrupt
     it. Suggested fix: `memhub sync-md`.
   - `.memhub/` present, binary present, K9 enabled, but memhub's
     durable tables are empty while `agent_docs/project_decisions.md`
     and `project_backlog.md` are populated → Yellow. This is the
     cross-machine clone scenario (memhub freshly installed here, K9
     history accumulated elsewhere). Probe with `memhub decision list`
     and `memhub task list` (both returning zero rows means empty)
     and `wc -l` on the two K9 files (non-trivial line counts mean
     populated). Suggested fix:
     ```
     memhub integrations bootstrap-k9 --dry-run   # preview parsed rows
     memhub integrations bootstrap-k9             # apply
     ```
     First-install-only by design; memhub refuses on any non-empty
     target. Do not surface this finding when the DB already has
     rows, when the K9 files are bare skeletons, or when K9 is
     disabled in `[integrations.k9]`.
   - `.memhub/` absent → skip this entire section. Do not warn that
     memhub is missing — it's optional.

7. **Framework version report.** Gather version info from the
   installed framework and include it in the final report:
   - Read the YAML frontmatter of each installed command file.
     For Claude Code, read:
       `~/.claude/commands/init-project.md`
       `~/.claude/commands/wrap-up.md`
       `~/.claude/commands/check-init.md`
     For Codex, read:
       `~/.agents/skills/init-project/SKILL.md`
       `~/.agents/skills/wrap-up/SKILL.md`
       `~/.agents/skills/check-init/SKILL.md`
     Pull `framework`, `framework_version`, `command_version`,
     `codex_skill_version` (if present), and `last_updated` from
     each. If any command file is missing frontmatter (e.g. a
     pre-framework version), note that.
   - Read `$MARKER_FILE` if it exists. Report the installed framework
     version, install date, and source (git remote + commit SHA
     when present).
   - If `framework_version` differs across the three command files,
     flag it as Yellow — the install is mid-update or was applied
     inconsistently.
   - Also check whether both CLIs have the framework installed: if
     `~/.claude/.k9-framework-version` and
     `~/.codex/.k9-framework-version` both exist, report both
     installs and their versions. A version mismatch between them is
     informational — the user may have updated one CLI's install
     without the other.
   - Do NOT contact GitHub. This command does not check for newer
     versions remotely. Updating is manual: `git pull` the framework
     repo and re-run its installer.

8. **Report.** Summarize as one of:
   - **Green** — all files present, populated, within budget, no
     placeholders, pointers intact. One-line summary. Include the
     framework version info and detected CLI at the end. If Step 6
     found memhub and it's healthy, add a one-line memhub summary
     (e.g. `memhub: enabled (agent_docs path)`).
   - **Yellow** — minor issues. List each with a suggested fix.
     Still no writes. Include version info and detected CLI. memhub
     findings from Step 6 fold into this list — they are Yellow at
     most, never Red (memhub is optional).
   - **Red** — missing files or major drift (no `.init-version`,
     no context file at all, or several files absent). List the gaps
     and suggest re-running `$INVOKE_INIT` with the "nuke and
     rebootstrap" option. Include version info and detected CLI.
     memhub findings stay Yellow even inside a Red K9 report.

## Notes

- Read-only. Never write, edit, or create files from this command.
- If the project has no `agent_docs/` at all, report Red and
  suggest `$INVOKE_INIT` rather than running further checks.
- Back-compat: if only a single `agent_docs/project_state.md`
  exists (old format, no `.init-version`), report Yellow with one
  finding — the project predates the four-file framework and
  should be migrated via `$INVOKE_INIT`.
- The version report is informational. Version mismatches between
  the project and the installed framework don't require action
  unless something actually broke.
- memhub is optional. Its absence is never a finding. Only surface
  memhub state when `.memhub/` exists in the repo.
- Cross-CLI context file states are Yellow, not Red:
  - Both `CLAUDE.md` and `AGENTS.md` present and both reference
    `agent_docs/project_state.md` → initialized for both CLIs. Valid;
    whichever file the current CLI loaded is the active one.
  - Only `$OTHER_CONTEXT_FILE` present (not `$CONTEXT_FILE`) →
    initialized for the other CLI only. Suggest running `$INVOKE_INIT`
    to add `$CONTEXT_FILE` for the current CLI.
