# Changelog

All notable changes to K9-Claude-Framework are documented here. Format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] — 2026-05-12

### Added
- `/init-project` Step 8 surfaces the new `memhub integrations bootstrap-k9`
  command when `.memhub/` exists alongside populated K9 history with an
  empty memhub database. This is the cross-machine clone scenario where
  memhub was just installed here but the K9 Markdown carries months of
  decisions and backlog from elsewhere. The reminder is gated on the same
  optionality contract as the rest of the memhub interop — silent skip
  when memhub is absent, disabled, the DB already has rows, or the K9
  files are bare skeletons.
- `/check-init` Step 6 reports a new Yellow finding for the same
  cross-machine-clone scenario, with the same suggested-fix block. Stays
  Yellow per the existing memhub-is-optional rule (memhub findings are
  never Red).

### Changed
- Bumped `framework_version` to `1.2.1` across all three commands.
  `/init-project` and `/check-init` also moved their per-command
  `command_version` and `codex_skill_version` to `1.2.1` because their
  bodies changed; `/wrap-up` keeps `command_version: 1.2.0` /
  `codex_skill_version: 1.2.0` because its body is unchanged.

### Compatibility
- Fully additive. Pure-Markdown K9 behavior is unchanged. The new
  bootstrap reminders only fire inside the existing `.memhub/`-present
  conditional branches and add no new gating to the standalone flow.
  memhub-side support for `memhub integrations bootstrap-k9` shipped in
  the memhub repo on 2026-05-12 (commit `58f526b`).

---

## [1.2.0] — 2026-05-12

### Added
- Optional memhub interop for `/wrap-up`, `/init-project`, and `/check-init`.
  When the `memhub` binary is on `PATH` and `memhub integrations check-k9`
  returns 0 in the current repo, K9 mirrors approved structured updates
  (decisions, tasks, facts) into memhub's local SQLite store with
  `--actor k9:wrap-up`, then runs `memhub sync-md` to refresh the
  `<!-- memhub:managed:start -->` block in the context file. Pure-Markdown
  behavior is preserved when memhub is absent or the gate returns non-zero
  — no changes to the K9 standalone flow.
- `/wrap-up` now fetches pending memhub proposals via
  `memhub review list --status pending --json` during draft assembly and
  surfaces them in the per-file approval gate as `memhub review accept`
  or `memhub review reject` candidates.
- `/wrap-up` enforces "DB writes first, Markdown writes second" sequencing
  per the v1 memhub `/wrap-up` contract. Any non-zero exit from a memhub
  mutating command is a hard abort before any `agent_docs/*.md` write.
- `/init-project` reminds the user to run `memhub sync-md` after re-writing
  `$CONTEXT_FILE` (nuke and cross-CLI paths) when `.memhub/` exists, so the
  managed block is regenerated rather than left out.
- `/check-init` reports memhub health (presence of `.memhub/`, binary
  install, integration enabled/disabled, managed-block markers, drift
  notes) when memhub signals are detected. Memhub findings are Yellow at
  most — memhub is optional and its absence is never a finding.
- README section "Pairs with memhub" describing the integration model.

### Changed
- Bumped `framework_version` to `1.2.0` and per-command `command_version`
  and `codex_skill_version` to `1.2.0` across all three commands. Frontmatter
  `last_updated` set to `2026-05-12`.

### Compatibility
- Fully additive. K9 standalone behavior is unchanged when memhub is not
  installed or `memhub integrations check-k9` returns non-zero. Projects
  initialized under earlier K9 versions continue to work without
  modification.

---

## [1.1.1] — 2026-04-20

### Fixed
- `init-project` Step 8 no longer instructs the agent to write all five
  content files unconditionally. In the cross-CLI path, only `$CONTEXT_FILE`
  is approved; the previous wording could cause skeleton templates to
  overwrite existing `agent_docs/` files. Changed to "Write the approved
  content files."
- VERSION and command frontmatters now correctly reflect the patch version.

---

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
