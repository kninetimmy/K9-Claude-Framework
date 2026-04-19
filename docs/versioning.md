# Versioning

Two kinds of versions travel with the framework. Both are visible to
the user; neither is checked remotely.

## The two levels

### `framework_version`

The version of K9-Claude-Framework as a whole. Lives in:

- `VERSION` at the repo root (single line, e.g. `1.0.0`)
- The `framework_version` field in each command file's frontmatter
- `~/.claude/.k9-framework-version` after install, written by the
  installer

A framework-wide bump happens when multiple commands change together
or when the four-file contract itself changes (e.g. adding a fifth
file, changing `.init-version` schema). All three command files carry
the same `framework_version` value at any given release.

### `command_version`

Per-command version, for changes scoped to a single command. Lives
in:

- The `command_version` field in that command's frontmatter

If only `check-init.md` changes, bump its `command_version`. The
framework version stays the same. The CHANGELOG should still note
the change.

Think of it as: `framework_version` is the shared release number;
`command_version` tracks drift between releases for individual
commands.

## Where versions live — at a glance

| Location                                   | What it stores                                                           |
|--------------------------------------------|--------------------------------------------------------------------------|
| `VERSION`                                  | Current `framework_version` of the repo                                  |
| `commands/*.md` frontmatter                | `framework_version`, `command_version`, `last_updated`                   |
| `~/.claude/commands/*.md` (after install)  | Same frontmatter, carried over from the repo by the installer           |
| `~/.claude/.k9-framework-version`          | Installed `framework_version`, install date, source (git remote + SHA)   |
| `CHANGELOG.md`                             | Human-readable history per framework release                            |

## How `/check-init` reports versions

`/check-init` now surfaces version info at the end of its report:

```
Framework: K9-Claude-Framework 1.0.0
  installed: 2026-04-18
  source: https://github.com/kninetimmy/K9-Claude-Framework@a3f2b1c
Commands:
  init-project.md  — framework 1.0.0 / command 1.0.0 (2026-04-18)
  wrap-up.md       — framework 1.0.0 / command 1.0.0 (2026-04-18)
  check-init.md    — framework 1.0.0 / command 1.0.0 (2026-04-18)
```

If the `framework_version` field differs across the three installed
command files, `/check-init` flags it as Yellow — that usually means
a partial install or a mid-update.

If a command file has no frontmatter at all (e.g. a copy of the
commands from before this framework existed), `/check-init` notes
that too and suggests re-running the installer.

## Updating — pull-based, on purpose

There is no remote version check. The framework never contacts
GitHub on its own. Updating is manual:

```
# Update the framework
cd ~/K9-Claude-Framework
git pull

# Re-run the installer
./install.sh          # macOS/Linux
./install.ps1         # Windows
```

The installer:

1. Backs up any existing command file as
   `<name>.pre-k9-backup-<timestamp>` (keeps every prior version).
2. Writes the new command files in place.
3. Rewrites `~/.claude/.k9-framework-version` with the new version,
   install date, and current git remote + commit SHA.

After update, `/check-init` inside any project will now report the
new framework version.

### Why pull-based

- **Predictability.** Your install doesn't change until you say so.
- **Offline.** Works without network access.
- **No telemetry.** The framework never calls out. If a version check
  is ever added, it'll be opt-in and explicit.

The cost is that if a bug is fixed upstream, you only get it by
pulling and re-installing. That's a deliberate trade.

## Versioning rules (for contributors or forks)

- **Patch bump** (1.0.0 → 1.0.1): fixes that don't change command
  behavior or file contracts.
- **Minor bump** (1.0.0 → 1.1.0): additive changes — new optional
  sections, new commands that don't break existing ones, new
  frontmatter fields with safe defaults.
- **Major bump** (1.0.0 → 2.0.0): breaking changes to the four-file
  contract, the command interface, or the install target layout.
  Include a migration note in the CHANGELOG.

`command_version` follows the same rules, scoped to a single command.

When bumping `framework_version`:

1. Update `VERSION`.
2. Update `framework_version` in all three `commands/*.md` files.
3. Add a `CHANGELOG.md` entry.
4. Don't retroactively rewrite older entries. The log is append-only
   in spirit, same as `project_decisions.md` in a consuming project.
