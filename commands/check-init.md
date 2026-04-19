---
description: Read-only health check of the project_docs framework in this project
framework: K9-Claude-Framework
framework_version: 1.0.0
command_version: 1.0.0
last_updated: 2026-04-18
---

Verify this project's project_docs framework is healthy. Read-only —
no writes, no fixes applied without my say-so.

## Steps

1. **File presence.** Confirm each expected file exists:
   - `CLAUDE.md` at the project root
   - `agent_docs/.init-version`
   - `agent_docs/project_state.md`
   - `agent_docs/project_backlog.md`
   - `agent_docs/project_decisions.md`
   - `agent_docs/project_arch.md`

2. **Non-empty check.** Each file should have real content, not
   just skeleton headers or placeholder TODOs left from init. Flag
   any that look untouched since bootstrap.

3. **CLAUDE.md pointers.** Read `CLAUDE.md` and confirm it
   references all four `agent_docs/project_*.md` files. Missing
   pointers are a drift signal.

4. **Internal consistency.**
   - Check the "Last updated" date in `project_state.md`. Run
     `git log --oneline -5` — if there are commits newer than that
     date, flag `/wrap-up` as overdue.
   - Count lines in `project_state.md`. Flag if over ~100 (hard
     ceiling) or creeping past ~75 (approaching the ceiling).
   - Scan "Open questions" in `project_state.md` — if any look
     stale (answered in commits, or clearly belong in
     `project_decisions.md` by now), call them out.

5. **Placeholder detection.** Search all five content files for
   `TODO`, `FIXME`, `[fill in]`, `<...>` template placeholders, and
   lorem-ipsum text that should've been replaced during init. List
   each hit with its file and line.

6. **Framework version report.** Gather version info from the
   installed framework and include it in the final report:
   - Read the YAML frontmatter of each installed command file at
     `~/.claude/commands/init-project.md`, `~/.claude/commands/wrap-up.md`,
     and `~/.claude/commands/check-init.md`. Pull `framework`,
     `framework_version`, `command_version`, and `last_updated` from
     each. If any command file is missing frontmatter (e.g. a
     pre-framework version), note that.
   - Read `~/.claude/.k9-framework-version` if it exists. Report the
     installed framework version, install date, and source (git
     remote + commit SHA when present).
   - If `framework_version` differs across the three command files,
     flag it as Yellow — the install is mid-update or was applied
     inconsistently.
   - Do NOT contact GitHub. This command does not check for newer
     versions remotely. Updating is manual: `git pull` the framework
     repo and re-run its installer.

7. **Report.** Summarize as one of:
   - **Green** — all files present, populated, within budget, no
     placeholders, pointers intact. One-line summary. Include the
     framework version info at the end.
   - **Yellow** — minor issues. List each with a suggested fix.
     Still no writes. Include the framework version info.
   - **Red** — missing files or major drift (no `.init-version`,
     no `CLAUDE.md`, or several files absent). List the gaps and
     suggest re-running `/init-project` with the "nuke and
     rebootstrap" option. Include the framework version info.

## Notes

- Read-only. Never write, edit, or create files from this command.
- If the project has no `agent_docs/` at all, report Red and
  suggest `/init-project` rather than running further checks.
- Back-compat: if only a single `agent_docs/project_state.md`
  exists (old format, no `.init-version`), report Yellow with one
  finding — the project predates the four-file framework and
  should be migrated via `/init-project`.
- The version report is informational. Version mismatches between
  the project and the installed framework don't require action
  unless something actually broke.
