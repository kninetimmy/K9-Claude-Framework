# Changelog

All notable changes to K9-Claude-Framework are documented here. Format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
