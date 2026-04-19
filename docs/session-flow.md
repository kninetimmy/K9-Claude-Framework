# Session flow

Two walkthroughs: (1) a typical working session on a project that's
already initialized, and (2) the `/init-project` interview flow on a
brand-new project.

---

## Walkthrough 1 — a typical session

You're picking up work on an existing project with the framework
already installed. Here's the full arc from opening the terminal to
closing it.

### 1. Start of session

```
$ cd ~/projects/log-filter
$ claude
```

Claude Code starts. It auto-loads `CLAUDE.md`, which contains a
native `@agent_docs/project_state.md` import. `project_state.md` is
now in context.

You see (paraphrased) what Claude sees:

- Project name and short description
- Session continuity pointers
- Build/test/run commands
- Current "Currently building" / "Next up" / "Last session" /
  "Open questions" from `project_state.md`

None of `project_arch.md`, `project_decisions.md`, or
`project_backlog.md` has been loaded yet. That's by design — they
cost tokens you don't need to pay until the work calls for them.

### 2. Working on a backlog item

You say: *"Let's pick up the 'normalize log timestamps' backlog
item."*

Claude reads `project_backlog.md`, finds the item, then reads
`project_arch.md` because the item touches the `LogFilter.Parsing`
subsystem. Claude also checks `project_decisions.md` for any prior
call that might constrain the approach.

Claude proposes a plan. You approve. Claude implements, runs tests,
you review, commits go in.

### 3. A decision gets locked in

During the work, you agree to normalize timestamps to UTC at parse
time and keep original-zone display at render time. This is a real
architectural call — it'll shape every downstream consumer of
`LogEntry`.

You don't run a separate command for this. It stays an open question
in `project_state.md` (or a comment on the backlog item) until
`/wrap-up`, when it either gets promoted to `project_decisions.md` or
noted somewhere else. The point is you don't interrupt the work to
curate the memory files.

### 4. End of session

You say: *"/wrap-up"*

Claude:

1. Confirms the framework is in place.
2. Reads all four `agent_docs/` files.
3. Runs `git log --oneline` for recent commits.
4. Drafts updates for each of the four files separately and shows
   them to you:
   - `project_state.md` — updated "Last session" entry referencing
     the commits, revised "Currently building" and "Next up," the
     "timestamp zone handling" question removed, a new open question
     added if one exists.
   - `project_decisions.md` — a new dated entry for the UTC
     normalization call, if you confirm it belongs here rather than
     staying in state.
   - `project_backlog.md` — status updated on the timestamp item
     (now `done`), any new items discussed but not tackled.
   - `project_arch.md` — no change proposed unless the architecture
     actually shifted.
5. Waits for your per-file approval.
6. Writes the approved files.
7. Reminds you to `/clear` (or exit and restart).

You approve `project_state.md` and `project_backlog.md` as drafted,
ask for a tighter one-line rationale on the decisions entry, and
leave `project_arch.md` untouched. Claude revises the decisions
entry, re-shows it, you approve, it writes.

### 5. Next session

Fresh Claude instance. Auto-loads `CLAUDE.md` and
`project_state.md`. Picks up cleanly where you left off — new
"Currently building," updated "Next up," the decisions log now has
the UTC call for future reference.

No hallucinated history. No token bloat. Work continues.

---

## Walkthrough 2 — `/init-project` on a brand-new project

You just made a new folder and you want to start from scratch.

```
$ mkdir ~/projects/new-tool && cd ~/projects/new-tool
$ claude
```

### 1. Run the command

You say: *"/init-project"*

Claude:

1. Checks for `agent_docs/.init-version` — not there, so this is a
   fresh init.
2. Classifies the project state. Folder is basically empty — this
   is the **brand new** path, so no foreign-scan or stack-detection
   steps are needed.
3. Starts the interview.

### 2. The interview

Questions come one at a time. Example run:

> **Claude:** Project name and a 1–2 sentence purpose?
>
> **You:** `new-tool`. A local CLI that deduplicates downloaded
> files by content hash and organizes them by type.
>
> **Claude:** Target platform?
>
> **You:** Cross-platform, but I mostly run Windows.
>
> **Claude:** Language/runtime? Or "help me pick"?
>
> **You:** Help me pick.
>
> **Claude:** Given cross-platform + local CLI + primary Windows,
> three options: (1) .NET 9 — first-class Windows, single-file
> publish for Linux/macOS works cleanly; (2) Go — simplest
> cross-compile story, no runtime required; (3) Rust — if you want
> the strictest safety + performance and don't mind slower build
> times. Any preference?
>
> **You:** .NET 9. I know the ecosystem.
>
> **Claude:** Known dependencies?
>
> **You:** None yet.
>
> **Claude:** Test framework? Or pick the idiomatic one?
>
> **You:** Idiomatic — xUnit is fine.
>
> **Claude:** CI/CD target? Default is GitHub Actions.
>
> **You:** GitHub Actions.

### 3. Drafts

Claude drafts all five files in memory and shows them:

- `CLAUDE.md` — the pointer template, with `@agent_docs/project_state.md`
  import wired in, build/test/run section with `dotnet build`,
  `dotnet test`, `dotnet run` placeholders.
- `project_state.md` — skeleton, "Between tasks," one "Last session"
  entry: `2026-04-18 — Initialized project_docs framework.`
- `project_backlog.md` — workflow preamble, empty items list.
- `project_decisions.md` — one entry: `2026-04-18 — Initialized
  project_docs framework` plus a second: `2026-04-18 — Picked .NET 9
  for runtime` with the rationale captured from the interview.
- `project_arch.md` — sparse skeleton. Purpose filled in from the
  interview. Stack set to ".NET 9, xUnit for tests." Layout noted
  as "not yet established." Security invariants blank.
- `.init-version` — framework marker.

### 4. Approval

You scan the drafts. You don't like the phrasing on the decision
entry for .NET. You say so. Claude revises, re-shows only that
file, you approve.

You say: *"all good, write them."*

### 5. Write

Claude creates `agent_docs/`, writes the five content files plus
`.init-version`, and tells you:

- What was written
- No backups were created (nothing to back up on a fresh init)
- Reminder that `/wrap-up` now routes updates across the four files

You're done. The project has a working memory. Next session you'll
pick up from `project_state.md` automatically.

---

## What not to do mid-session

Both flows assume you don't run `/wrap-up` or `/clear` in the middle
of working. The state files are designed to be updated once per
session, at the end. If you hit a mid-session wall (context getting
too heavy, or you want to switch machines), finish with `/wrap-up`
then open a fresh session — don't try to hand-edit the state files
while working.
