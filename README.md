# K9-Claude-Framework

A lightweight session-continuity framework for the Claude Code CLI.
Four Markdown files, three slash commands, zero dependencies.

---

## The problem

Claude Code is great in a single session. Across sessions, the seams
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
  locked-in calls. Loaded on demand when Claude needs to check a
  constraint.
- **`agent_docs/project_arch.md`** — architecture reference. The
  source of truth for how the project is built. Loaded on demand.

`CLAUDE.md` at the project root becomes a thin pointer that tells
Claude to auto-load `project_state.md` and load the others as needed.
It stops being the place architecture, decisions, and backlog get
dumped.

## Three global commands

Installed once into `~/.claude/commands/`, available in every project:

- **`/init-project`** — bootstraps a new or cloned project with the
  four-file framework. Detects existing AI-context systems (GAAI,
  Cursor rules, aider, etc.) and offers to migrate, coexist, or
  cancel. Approval gate on every write.
- **`/wrap-up`** — end-of-session ritual. Reads the four files, runs
  `git log` for ground truth, drafts updates for each file
  separately, waits for per-file approval before writing.
- **`/check-init`** — read-only health check. Reports green / yellow /
  red on file presence, pointer consistency, state-file size budget,
  placeholder detection, and framework version info.

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

Both installers:

- Copy the three commands into `~/.claude/commands/` (or the Windows
  equivalent `$env:USERPROFILE\.claude\commands\`).
- Back up any pre-existing command files as
  `<name>.pre-k9-backup-<timestamp>` before overwriting.
- Write a framework marker at `~/.claude/.k9-framework-version` with
  the version, install date, and source (git remote + commit SHA).

Running the installer a second time is safe — it re-backs-up and
re-installs.

### Optional — prompt-based install

If you'd rather have Claude Code do the install for you, see
[`PROMPT-INSTALL.md`](PROMPT-INSTALL.md). Paste the prompt, Claude
clones the repo to a temp dir, runs the installer, cleans up, and
reports back.

## Quick start

```bash
git clone https://github.com/kninetimmy/K9-Claude-Framework
cd K9-Claude-Framework
bash install.sh          # or install.ps1 on Windows

cd ~/some-project
claude
```

Then in the Claude Code session:

```
/init-project
```

Answer the interview questions, approve the drafts, and the project
now has a working memory. At end of session, run `/wrap-up`. In any
session after that, run `/check-init` when you want to verify health.

## How it differs from alternatives

There are other good ways to do session continuity for Claude Code.
This one makes different trade-offs:

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
  Claude response, which lets them handle in-session context
  compaction that this framework can't. If you routinely run
  multi-hour sessions that hit Claude Code's internal compaction,
  you'll want a hook-based tool *in addition to* (not instead of)
  this one. The approaches are complementary, not competing.
- **vs. remote / cloud-backed memory.** There are systems that store
  project memory in a hosted service. That's powerful, but it's also
  a dependency, an account, and a trust boundary you don't need if
  your project state is small. This framework stays local and stays
  in git.

Pick the tool that matches the size of your problem. This one is
aimed at solo developers and small teams working one repo at a time
with Claude Code as the primary assistant.

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
  walkthroughs of a typical session and an `/init-project` run
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
