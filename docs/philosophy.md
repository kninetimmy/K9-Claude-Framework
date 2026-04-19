# Philosophy

The design choices behind K9-Claude-Framework come from watching a lot
of other session-continuity approaches drift into one of three failure
modes: context bloat (files that accumulate forever and silently blow
out the token budget), hallucinated progress (Claude summarizing work
that didn't actually happen), and framework lock-in (the tool that was
supposed to help you becomes load-bearing infrastructure you can't
move away from).

Every principle below exists to prevent one of those.

## Four files instead of one

A single `NOTES.md` or `CONTEXT.md` grows without bound. Different
kinds of information have different lifespans:

- **State** changes every session and should be aggressively pruned.
- **Backlog** changes when you triage, not every session.
- **Decisions** never change — they're append-only history.
- **Architecture** changes only when the system's shape changes.

Mixing these in one file means the churn of state updates constantly
rewrites neighboring content, and the file gets loaded in full every
session regardless of what you actually need. Splitting them lets
`project_state.md` stay tight (~50 lines, hard ceiling 100), while
`project_arch.md` can be detailed without weighing down every session
start.

The practical consequence: at session start only `project_state.md`
auto-loads. The other three get read on demand, when the task actually
calls for them.

## Approval gates on writes

Claude is good at summarizing sessions. Claude is also good at
inventing accomplishments that didn't happen, especially in a long
session where exploration didn't lead anywhere. The fix is human
approval on every file write.

`/wrap-up` drafts changes to each of the four files separately and
shows them to you before touching disk. You can approve one file and
reject another. You can ask for revisions. Nothing gets written until
you explicitly say so.

This costs a minute per session and catches hallucinated progress
before it contaminates future sessions. That trade is worth making
every time.

## Git is the real log

`project_state.md` contains a "Last session" section that's capped at
two entries. That isn't an oversight. The full history of what
happened in this repo lives in `git log` — with exact timestamps,
exact diffs, and exact commit messages. Trying to mirror that in
Markdown is a losing game: the Markdown summary will eventually
contradict the actual commits, and then you have two sources of truth
disagreeing with each other.

`/wrap-up` explicitly runs `git log --oneline` and anchors its state
updates to real commits. If a session produced no commits, the state
update says that, instead of making something up.

## Zero dependencies

The entire framework is Markdown files and shell scripts. There is no
runtime, no package manager, no lock file, no plugin system.

This matters because:

- You can read every file in the framework by eye. No black box.
- Moving between machines means copying files. No reinstall dance.
- If Claude Code itself changes, none of the framework's core
  artifacts need to change — they're just Markdown that Claude reads.
- There is no version-lock between the framework and a specific
  Claude Code release. The install script can be re-run any time.

The price is that anything dynamic (auto-update checks, remote
telemetry, rich CLI tooling) is off the table on purpose. That's a
feature, not a limitation.

## Bias toward less content

Every file in the framework has an implicit "how much is too much"
ceiling. `project_state.md` is the strictest — a hard cap at ~100
lines, a target of ~50. `project_arch.md` has no numeric cap but is
meant to be skimmable in under a minute.

Padding files with speculative content ("future considerations," "if
we ever scale to…", "might want to add…") makes them longer without
making them more useful. The commands actively resist this: the
`/init-project` skeleton is deliberately sparse, and `/wrap-up`
reminds Claude to prefer a tight true summary over a long padded one.

If the framework feels empty after you run `/init-project` on a new
project, that's correct. It fills up as real work happens, not as a
prophecy.

## `project_arch.md` is the arch source of truth, not CLAUDE.md

A common pattern elsewhere is to stuff architecture, decisions, and
build commands all into `CLAUDE.md`. That file then gets loaded in
full at every session start, which means the architecture section is
burning tokens even when the session is about fixing a typo.

This framework inverts that: `CLAUDE.md` is a thin pointer. It says
"at session start, read `project_state.md`; load the others on
demand." The architectural detail lives in `project_arch.md`, which
only gets loaded when the work actually needs it.

The result is a smaller fixed token cost at session start and a
clearer mental model: `CLAUDE.md` answers "what is this repo, how do
I behave in it"; `project_arch.md` answers "how is it built."

## What this framework is not good at

Being honest about the limits so nobody's surprised:

- **Mid-session compaction.** Hook-based systems that run on every
  response can handle in-session context growth better than a
  wrap-at-the-end ritual. If you routinely run multi-hour sessions
  that get compacted by Claude Code, you'll want a hook-based tool in
  addition to (not instead of) this one.
- **Multi-repo coordination.** Each project has its own `agent_docs/`.
  There's no cross-repo aggregation. If you're coordinating work
  across ten repos at once, this framework won't help you see the big
  picture.
- **Structured data.** Everything is Markdown. If you want your
  backlog in a queryable format (JSON, SQLite, a real issue tracker),
  use a real issue tracker.

Pick the tool that fits the scale of your problem. This one is
optimized for a solo developer or small team working one repo at a
time with Claude Code as the primary assistant.
