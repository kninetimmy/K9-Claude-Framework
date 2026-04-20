# Changelog

All notable changes to K9-Claude-Framework are documented here. Format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-04-19

### Added
- Codex CLI support. All three commands now work as Codex Agent Skills
  (`~/.agents/skills/<name>/SKILL.md`) in addition to Claude Code slash
  commands. Detection uses a five-signal hierarchy: `CLAUDECODE` env var,
  `~/.codex/` directory, `codex` binary in PATH (excluding the Claude
  Code plugin cache at `~/.claude/plugins/`), framework marker files, and
  project context file presence.
- `$OTHER_CONTEXT_FILE` variable in all three command variable tables,
  enabling safe cross-CLI project handling. A project initialized for one
  CLI is recognized as such when the other CLI runs its init command —
  the command offers to add the current CLI's context file alongside the
  existing one rather than falling into the nuke path.
- `codex_skill_version` and `name` frontmatter fields on all command files
  (required by the Codex Agent Skills spec).
- Dual installer behavior: both `install.sh` and `install.ps1` now detect
  Claude Code (`~/.claude/`), Codex CLI (`~/.codex/` or `codex` binary
  not in the Claude plugin cache), or both, and install to all detected
  targets in a single run. Codex installs go to
  `~/.agents/skills/<name>/SKILL.md`.
- Separate framework marker files: `~/.claude/.k9-framework-version` for
  Claude Code and `~/.codex/.k9-framework-version` for Codex, written
  independently.

### Changed
- All three commands now open with a CLI Detection block and variable
  table that sets `$CONTEXT_FILE`, `$OTHER_CONTEXT_FILE`, `$MARKER_FILE`,
  `$INVOKE_*`, etc. once at the top — no inline CLI name hardcoding.
- `check-init` cross-CLI awareness: a project initialized for the other
  CLI only reports Yellow (informational) rather than Red (error).
- `init-project` nuke path now backs up both `$CONTEXT_FILE` and
  `$OTHER_CONTEXT_FILE` before deleting anything.

---

## [1.0.0] — 2026-04-18

Initial public release.

### Added
- Four-file project memory system under `agent_docs/`:
  `project_state.md`, `project_backlog.md`, `project_decisions.md`,
  `project_arch.md`.
- Three global slash commands for Claude Code: `/init-project`,
  `/wrap-up`, `/check-init`.
- Version frontmatter on every command file
  (`framework_version`, `command_version`, `last_updated`).
- Install scripts for macOS/Linux (`install.sh`) and Windows
  (`install.ps1`). Both back up any pre-existing command files with a
  timestamped suffix and write a framework marker at
  `~/.claude/.k9-framework-version` recording version, install date,
  and source (git remote + commit SHA when available).
- Prompt-based install (`PROMPT-INSTALL.md`) for users who prefer
  having Claude Code perform the install.
- Example project under `examples/example-project/` showing the
  framework applied to a small C# .NET CLI tool, including a
  best-practice `CLAUDE.md` that uses native `@path` imports.
- Documentation covering philosophy, file structure, session flow,
  and versioning under `docs/`.
