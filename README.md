# K9-Claude-Framework

A lightweight session-continuity framework for Claude Code and Codex CLI.
Four Markdown files, three commands, zero dependencies.

---

## The problem

LLM coding CLIs are great in a single session. Across sessions, the seams
show. Context bloats as projects grow. State gets summarized into
ever-longer files that eat token budget before the real work starts.
Claude hallucinates progress that didn't happen because nothing is
grounding its summaries to what actually shipped. Every project ends
up with its own ad-hoc notes file, and none of them age gracefully.

K9-Claude-Framework is the smallest thing that fixes this without
introducing a new dependency or a new lock-in. It's Markdown and
shell scripts.

## The solution — four files, not one

Session memory gets split by lifespan:

- **`agent_docs/project_state.md`** — the dashboard. Always loaded at
  session start. Hard ceiling ~100 lines. Gets pruned every session.
- **`agent_docs/project_backlog.md`** — planned work. Loaded on
  demand when you're picking up a task.
- **`agent_docs/project_decisions.md`** — append-only log of
  locked-in calls. Loaded on demand when the agent needs to check a
  constraint.
- **`agent_docs/project_arch.md`** — architecture reference. The
  source of truth for how the project is built. Loaded on demand.

A thin context file at the project root (`CLAUDE.md` for Claude Code,
`AGENTS.md` for Codex) tells the CLI to load `project_state.md` at
session start and points to the others for on-demand use. It stops being
the place architecture, decisions, and backlog get dumped.

## Three global commands

Installed once, available in every project:

- **`/init-project`** (`$init-project` in Codex) — bootstraps a new or
  cloned project with the four-file framework. Detects existing AI-context
  systems (GAAI, Cursor rules, aider, etc.) and offers to migrate,
  coexist, or cancel. Handles cross-CLI projects (e.g. adds `AGENTS.md`
  alongside an existing `CLAUDE.md` without touching `agent_docs/`).
  Approval gate on every write.
- **`/wrap-up`** (`$wrap-up`) — end-of-session ritual. Reads the four
  files, runs `git log` for ground truth, drafts updates for each file
  separately, waits for per-file approval before writing.
- **`/check-init`** (`$check-init`) — read-only health check. Reports
  green / yellow / red on file presence, pointer consistency, state-file
  size budget, placeholder detection, and framework version info.
  Cross-CLI states (e.g. project initialized for one CLI, running the
  other) report Yellow rather than Red.

## Supported CLIs

| CLI          | Command invocation   | Context file | Install target                      |
|--------------|----------------------|--------------|-------------------------------------|
| Claude Code  | `/command-name`      | `CLAUDE.md`  | `~/.claude/commands/`               |
| Codex CLI    | `$command-name`      | `AGENTS.md`  | `~/.agents/skills/<name>/SKILL.md`  |

The same Markdown file serves both CLIs — frontmatter carries fields for
both (`command_version` for Claude Code, `codex_skill_version` for Codex).
A project can be initialized for both CLIs simultaneously; they share the
same `agent_docs/` folder.

## Install

### Recommended — shell script

Clone the repo and run the installer for your OS.

```bash
# macOS / Linux
git clone https://github.com/kninetimmy/K9-Claude-Framework
cd K9-Claude-Framework
bash install.sh
```

```powershell
# Windows
git clone https://github.com/kninetimmy/K9-Claude-Framework
cd K9-Claude-Framework
powershell -ExecutionPolicy Bypass -File install.ps1
```

Both installers auto-detect which CLIs are present and install to all of
them in one run:

- **Claude Code** (`~/.claude/` exists) → copies commands to
  `~/.claude/commands/` as `.md` files.
- **Codex CLI** (`~/.codex/` exists or `codex` is in PATH) → copies
  commands to `~/.agents/skills/<name>/SKILL.md`.
- **Both** → installs to both targets simultaneously.

Note: a `codex` binary cached inside `~/.claude/plugins/` is ignored —
that's Claude Code's own plugin asset, not a standalone Codex install.

Pre-existing command files are backed up as
`<name>.pre-k9-backup-<timestamp>` before overwriting. Running the
installer again is safe.

**Added a CLI after the initial install?** Just re-run the installer.
It detects whatever CLIs are present at run time, so it picks up the
new one without disturbing the existing install.

### Optional — prompt-based install

If you'd rather have the CLI do the install for you, see
[`PROMPT-INSTALL.md`](PROMPT-INSTALL.md). Paste the prompt into Claude
Code or Codex, it clones the repo to a temp dir, runs the installer,
cleans up, and reports back.

## Quick start

```bash
git clone https://github.com/kninetimmy/K9-Claude-Framework
cd K9-Claude-Framework
bash install.sh          # or install.ps1 on Windows

cd ~/some-project
claude                   # or: codex
```

Then in your session:

```
/init-project            # Claude Code
$init-project            # Codex
```

Answer the interview questions, approve the drafts, and the project
now has a working memory. At end of session, run `/wrap-up` (or
`$wrap-up`). In any session after that, run `/check-init` (or
`$check-init`) to verify health.

## How it differs from alternatives

There are other good ways to do session continuity. This one makes
different trade-offs:

- **vs. a single `CONTEXT.md` / `NOTES.md` file.** One file is simpler
  to set up but mixes lifespans: state churn constantly rewrites
  neighboring content, and you pay the full file's token cost every
  session. The four-file split costs a little more structure up front
  and pays it back every session thereafter.
- **vs. GAAI-style rule-based systems.** GAAI and its siblings are
  richer — hierarchical rule sets, tagging, pattern matching. If you
  want that level of structure, use GAAI. This framework deliberately
  stops at "four Markdown files plus three commands" because most
  solo-dev use cases don't need more.
- **vs. hook-based systems (Claude Baton, etc.).** Hooks run on every
  response, which lets them handle in-session context compaction that
  this framework can't. If you routinely run multi-hour sessions that
  hit the CLI's internal compaction, you'll want a hook-based tool *in
  addition to* (not instead of) this one. The approaches are
  complementary, not competing.
- **vs. remote / cloud-backed memory.** There are systems that store
  project memory in a hosted service. That's powerful, but it's also
  a dependency, an account, and a trust boundary you don't need if
  your project state is small. This framework stays local and stays
  in git.

Pick the tool that matches the size of your problem. This one is
aimed at solo developers and small teams working one repo at a time
with an LLM CLI as the primary assistant.

## Pairs with memhub

K9 handles the *narrative* side of session continuity — four Markdown files
under `agent_docs/` plus a thin context file at the project root. If you also
want the *structured* side — a queryable, auditable per-repo database of
facts, decisions, tasks, and command history — pair K9 with
[memhub](https://github.com/kninetimmy/memhub), a local-first Rust CLI for
durable per-repo project memory. Both tools run fine on their own; together
they form a Markdown-for-humans / SQLite-for-queries split.

What happens when both are installed:

- `memhub init` detects K9 by the presence of `agent_docs/project_state.md`
  and writes `[integrations.k9]` into `.memhub/config.toml`.
- `/wrap-up` (K9 1.2.0+) runs `memhub integrations check-k9` near the top.
  When the gate returns 0, the approval gate covers a "memhub mirror plan"
  alongside the Markdown drafts. After approval, K9 shells out to memhub
  with `--actor k9:wrap-up` to mirror approved decisions, tasks, and facts
  into durable tables, then writes Markdown second. Any memhub failure
  hard-aborts the wrap-up before Markdown is touched, so the two views
  can't drift mid-write.
- After the four-file writes, K9 runs `memhub sync-md` to refresh the
  `<!-- memhub:managed:start -->` block in `CLAUDE.md` / `AGENTS.md`.
- `/check-init` reports memhub health alongside K9 health when `.memhub/`
  is present. Findings stay Yellow at most — memhub is optional.

If memhub isn't installed or the gate returns non-zero, K9 behaves exactly
as it does without memhub: pure-Markdown flow, no DB writes, no `sync-md`.
The integration is purely opportunistic.

The CLI contract between the two tools (gate semantics, JSON shapes, exit
codes, audit actor) is versioned and lives in memhub's repo at
`docs/reference/k9-wrap-up-contract.md`.

## Design philosophy

The short version: curate, don't accumulate; human approval on every
write; git is the real log; zero dependencies.

The long version is in [`docs/philosophy.md`](docs/philosophy.md).

## Documentation

- [`docs/philosophy.md`](docs/philosophy.md) — design principles and
  honest limits
- [`docs/file-structure.md`](docs/file-structure.md) — per-file
  reference for the four `agent_docs/` files, with good-vs-bad
  examples
- [`docs/session-flow.md`](docs/session-flow.md) — narrative
  walkthroughs of a typical session and an init run
- [`docs/versioning.md`](docs/versioning.md) — how framework and
  per-command versions work, and how to update

An example project lives at
[`examples/example-project/`](examples/example-project/) showing the
framework applied to a small C# .NET CLI tool.

## Contributing

This is a personal project maintained by one person. PRs and issues
are welcome, but response time varies and not everything gets
addressed. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT. See [`LICENSE`](LICENSE).

## Acknowledgments

The design borrows liberally from patterns that have emerged in the
Claude Code community:

- The CLAUDE.md best-practices pattern for session startup.
- The decision-log pattern from ADR culture and several community
  frameworks — the idea that architectural calls deserve their own
  append-only file.
- The state-vs-backlog-vs-arch split that multiple community
  frameworks have converged on independently. This one's
  contribution is mostly in the commands that enforce the split and
  the approval-gate discipline, not the file layout itself.
