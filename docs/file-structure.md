# File structure

After `/init-project` (or `$init-project`), a project using this
framework has:

```
<project root>/
├── CLAUDE.md                       # thin pointer for Claude Code
├── AGENTS.md                       # thin pointer for Codex (same role)
└── agent_docs/
    ├── .init-version               # framework marker
    ├── project_state.md            # dashboard — always loaded
    ├── project_backlog.md          # planned work — loaded on demand
    ├── project_decisions.md        # append-only history — loaded on demand
    └── project_arch.md             # architecture reference — loaded on demand
```

`CLAUDE.md` and `AGENTS.md` are not both required — only the one(s)
matching the CLI(s) you use will be present. A project can have both
if it's shared across teams using different CLIs; they point to the
same `agent_docs/` folder.

This doc is the reference for what goes in each file, when it gets
loaded, and what does *not* belong in it.

---

## `CLAUDE.md` / `AGENTS.md` (project root)

**Purpose.** The CLI's native entry point. Auto-loaded at session
start. In this framework it's a thin pointer — it tells the CLI where
the real content lives rather than duplicating it inline.

`CLAUDE.md` is for Claude Code; `AGENTS.md` is the equivalent for
Codex CLI. Their content is nearly identical — the only difference is
that Claude Code supports native `@path` imports for auto-loading
`project_state.md`, while `AGENTS.md` uses a text instruction to the
same effect.

**Loaded.** Every session, automatically, by the CLI itself.

**Sections.**
- Project name + 1–2 sentence description
- Session continuity (pointers to the four `agent_docs/` files,
  usually via native `@path` imports so `project_state.md` auto-loads)
- Build / test / run commands
- Project-specific Claude instructions (if any)

**Does not belong here.**
- Architecture detail (goes in `project_arch.md`)
- Decision history (goes in `project_decisions.md`)
- Active task list (goes in `project_state.md` "Next up")
- Backlog items (goes in `project_backlog.md`)

**Good entry.**

```markdown
## Session continuity

At session start, read `@agent_docs/project_state.md`. Load on demand:
- `agent_docs/project_arch.md` for architecture / stack
- `agent_docs/project_decisions.md` for locked-in decisions
- `agent_docs/project_backlog.md` for planned work
```

**Bad entry.** (Whole architecture section inlined — belongs in
`project_arch.md`.)

```markdown
## Architecture

The application is built on .NET 9 using the generic host pattern.
The main entry point is Program.cs which wires up dependency
injection... [continues for 200 lines]
```

---

## `agent_docs/project_state.md`

**Purpose.** The dashboard. Captures what's being worked on right now,
what's up next, and what happened in the last session or two. Tight by
design.

**Loaded.** Every session (via the `@path` import in `CLAUDE.md`).

**Budget.** Target ~50 lines. Hard ceiling ~100 lines. `/check-init`
warns past 75, flags past 100.

**Sections.**
- `Last updated: YYYY-MM-DD`
- `Currently building` — 1–3 sentences on the active focus.
  "Between tasks" is valid.
- `Next up` — short ordered list, usually 3 items.
- `Last session` — 1–2 dated entries max. Older entries get pruned,
  because git has the real history.
- `Open questions` — active only. Answered questions get removed, not
  struck through.

**Does not belong here.**
- Decisions that are settled and won't be revisited (go to
  `project_decisions.md`)
- Backlog items not being worked on this session (go to
  `project_backlog.md`)
- Architectural detail (go to `project_arch.md`)
- Full session transcripts (git log is the transcript)

**Good entry under "Last session".**

```markdown
## Last session
2026-04-18 — Wired up log-filter CLI. Added --level and --since
flags (commits a3f2b1, 8c9d4e). Hit a snag with timezone handling
that we're deferring; tracked as backlog item "normalize log
timestamps."
```

**Bad entry.**

```markdown
## Last session
2026-04-18 — Did a bunch of work on the CLI. Made several
improvements. The code is now better. [no commits referenced,
no specifics, padded]
```

---

## `agent_docs/project_backlog.md`

**Purpose.** Planned work. Triaged items with scope, affected files,
and status. This is where "we should do X eventually" goes instead of
cluttering `project_state.md`.

**Loaded.** On demand, when Claude is asked to pick up a backlog item
or plan a new one.

**Budget.** No hard cap, but practical: if you're past ~500 lines,
you're not using it as a backlog, you're using it as a journal.

**Sections.**
- Workflow instructions at the top (how to pull from this file —
  lives in the `/init-project` template)
- Items, each carrying: scope, affected files, staging if
  multi-stage, model recommendation, design decisions, status
  marker (`triaged` / `planning` / `in-progress` / `blocked` / `done`).

**Does not belong here.**
- Tasks active this session (they're in `project_state.md` "Next up"
  or `Currently building`)
- Decisions about how to do the work (go to `project_decisions.md`
  once settled)
- Done items older than a few sessions — let git and the decisions
  log handle history. Backlog is for upcoming, not past.

**Good entry.**

```markdown
### Normalize log timestamps
- **Scope.** LogParser reads ISO-8601 timestamps but assumes local
  time. Needs to detect and preserve the zone, or normalize to UTC.
- **Affected files.** `src/LogFilter/Parsing/LogParser.cs`,
  `tests/LogFilter.Tests/Parsing/LogParserTests.cs`
- **Status.** triaged
- **Design note.** Prefer normalizing to UTC in-memory; keep
  original-zone display at render time.
```

**Bad entry.**

```markdown
### Fix timestamps
TODO: make timestamps work better
```

---

## `agent_docs/project_decisions.md`

**Purpose.** Append-only record of locked-in decisions. Architectural
calls, security choices, workflow commitments. Once written, entries
are never revised — superseding decisions are new dated entries that
reference the old ones.

**Loaded.** On demand, when Claude needs to check a constraint or
confirm a prior call.

**Sections.**
- Brief preamble explaining the append-only rule
- Dated entries, newest at the bottom (or top — be consistent within
  a file; newest-at-bottom matches how git history reads)

**Does not belong here.**
- Still-open questions (they're in `project_state.md` "Open questions")
- Implementation detail (that's in the code, or in `project_arch.md`)
- Things that might change later (if it's not settled, don't commit
  it here yet)

**Good entry.**

```markdown
## 2026-04-12 — Use System.Text.Json, not Newtonsoft
- Picked `System.Text.Json` because it ships in-box with .NET, has
  no external deps, and our payloads are trivial (no polymorphism,
  no custom converters needed).
- Revisit only if we hit a missing feature that would cost more to
  work around than to migrate.
```

**Bad entry.**

```markdown
## 2026-04-12 — Maybe we should use System.Text.Json?
- Seems fine, let's try it
- Might switch later
```

(If it's tentative, it's not a decision yet. Keep it in
`project_state.md` as an open question until it's settled.)

---

## `agent_docs/project_arch.md`

**Purpose.** The architecture reference. Purpose, stack, layout, key
subsystems, security invariants, runtime layout, known gaps. This is
the source of truth for how the project is built.

**Loaded.** On demand, when a task touches architecture or when a
backlog item explicitly references it.

**Sections.**
- Purpose (elevator pitch, 2–3 sentences)
- Stack and versions
- Layout (one level of folder structure with role per folder)
- Key subsystems and how they interact
- Security invariants (must-always-hold rules)
- Runtime layout (processes, ports, external deps)
- Known gaps / out of scope

**Does not belong here.**
- Session-specific status ("we're currently refactoring X" — goes to
  `project_state.md`)
- Decision rationale ("we picked X because Y" — goes to
  `project_decisions.md`; `project_arch.md` states *what*, not *why*)
- Backlog items (go to `project_backlog.md`)

**Good entry (a subsystem).**

```markdown
### LogFilter.Parsing

Reads log files line by line and emits `LogEntry` records. Supports
ISO-8601 timestamps and three common level conventions
(lowercase `info`, uppercase `INFO`, bracketed `[INFO]`). Zone
handling is UTC-normalized at parse time.

Interacts with: `LogFilter.Cli` (consumes the `IAsyncEnumerable<LogEntry>`),
`LogFilter.Core.Filters` (applies user filters downstream).
```

**Bad entry.**

```markdown
### LogFilter.Parsing

This is the parsing code. We chose it because parsing is important
and we need to parse logs. It was written after a lot of
discussion about whether to use regex or a real parser. In the
end we went with... [drifts into decision history]
```
