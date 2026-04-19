---
description: Bootstrap a new or cloned project with the project_docs framework (CLAUDE.md + agent_docs/)
framework: K9-Claude-Framework
framework_version: 1.0.0
command_version: 1.0.0
last_updated: 2026-04-18
---

Set up this project with the project_docs framework: a lightweight
session-continuity system split across `CLAUDE.md` and four files in
`agent_docs/`.

## Steps

1. **Detect whether the project is already initialized.** Check for
   `agent_docs/.init-version`.
   - If it exists and the structure matches the current framework
     (all four `project_*.md` files present, `CLAUDE.md` has the
     expected pointers to them), refuse politely. Tell me to use
     `/wrap-up` to update state, or `/check-init` to verify health.
     Stop here.
   - If `.init-version` exists but the structure has drifted (files
     missing, `CLAUDE.md` missing pointers), show me what's out of
     spec and offer two choices: (a) nuke `agent_docs/` + `CLAUDE.md`
     and re-bootstrap from scratch, or (b) leave everything alone
     and exit. No silent migration. Wait for my pick.
     - If I pick (a), tell me up front exactly what will happen:
       the existing `agent_docs/` folder will be backed up as
       `agent_docs.pre-init-backup/` (preserving full structure), and
       `CLAUDE.md` will be backed up as `CLAUDE.md.pre-init-backup`,
       before anything is deleted. If those backup paths already
       exist from a previous init, append a date suffix
       (`agent_docs.pre-init-backup-YYYY-MM-DD/`); if that also
       exists, append a counter (`-YYYY-MM-DD-2/`, `-3/`, …).

2. **Classify the project state.** If `.init-version` doesn't exist,
   decide which path this is:
   - **Brand new** — mostly empty folder, no source, no README.
   - **Existing cloned repo** — has source, README, build configs,
     and/or an existing `CLAUDE.md`.

3. **Foreign session-continuity scan (cloned repos only).** Skip for
   brand-new projects and for repos already initialized with this
   framework (Step 1 handles those). Do a lightweight, one-level
   scan for signs that the repo already uses a different AI-context
   system. Use judgment — these are heuristics, not a checklist. A
   `NOTES.md` full of shopping lists is not a session-continuity
   system; a `NOTES.md` with dated session summaries probably is.

   Signals to look for:
   - Folders at the root: `.gaai/`, `.cursor/rules/`, `.ai/`,
     `memory-bank/`, `docs/ai/`, `ai_docs/`, `context/`, `.aider*`.
     (Do NOT flag `.claude/` on its own — that's Claude Code's own
     settings directory. Only flag `.claude/` if it contains custom
     context files like `.claude/context.md` or `.claude/notes.md`,
     not just `settings.json` / `commands/`.)
   - Files matching: `*state*.md`, `*context*.md`, `*memory*.md`,
     `CONTEXT.md`, `NOTES.md`, `AGENT*.md`, `AGENTS.md`,
     `.cursorrules`, `.windsurfrules`, `GEMINI.md`.
   - Any existing `CLAUDE.md` that does NOT reference
     `agent_docs/project_state.md` (i.e., a foreign `CLAUDE.md` not
     written by this framework).

   If nothing matches, proceed silently to the next step.

   If anything matches, pause. Show me:
   - A bulleted list: each hit as `path — one-line description of
     what it appears to be` (peek at content to describe, don't
     paraphrase it at length).
   - The question: "This repo appears to already use a different
     AI-context system. How do you want to proceed?"
   - Three choices:
     - **(a) Proceed anyway** — install project_docs alongside the
       existing system. Foreign files are left untouched. Warn that
       running two systems in parallel may cause confusion or token
       bloat if both get auto-loaded into context.
     - **(b) Proceed and migrate** — install project_docs, and read
       the foreign system's content to seed `project_state.md`,
       `project_arch.md`, and `project_decisions.md` where the
       content fits. Do NOT delete or move foreign files. In the new
       `project_state.md`, add a note under "Last session" listing
       which foreign paths were read and flagging that I may want to
       archive or delete them manually.
     - **(c) Cancel** — exit without writing anything.

   Wait for my choice before continuing.

4. **Stack detection (cloned repos only).** Medium depth — enough
   for a useful `project_arch.md`, not an audit.
   - Stack markers at the root: `*.csproj`, `*.sln`, `package.json`,
     `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`,
     etc. Note language/runtime and any lockfiles.
   - Read `README.md` if present. Summarize the purpose.
   - Top-level folders only (one level deep, no recursion). Infer
     role from names.
   - CI config: `.github/workflows/` or equivalent.
   - Obvious security-relevant patterns (encryption, auth, secrets
     handling mentioned anywhere).

   Do NOT read every source file. Do NOT scan deep trees.

5. **Interview.** For brand-new projects, ask these one at a time:
   1. Project name and a 1–2 sentence purpose.
   2. Target platform (cross-platform, Windows, Linux, macOS, web,
      CLI, etc.).
   3. Language/runtime — explicitly offer "help me pick" as an
      option. If picked, propose 2–3 options with tradeoffs anchored
      to the stated purpose.
   4. Known dependencies or frameworks already decided (or "none
      yet").
   5. Test framework preference (or "pick the idiomatic one for the
      chosen stack").
   6. CI/CD target (default: GitHub Actions).

   For cloned repos, only ask about things detection couldn't
   determine. Confirm high-level inferences rather than
   interrogating.

6. **Draft all files.** Produce drafts of:
   - `CLAUDE.md` (template below)
   - `agent_docs/project_state.md` — skeleton, seeded with one "Last
     session" entry: `YYYY-MM-DD — Initialized project_docs
     framework.` If migrate was chosen in the foreign-system scan,
     append to that same entry: `Migrated content from: <path1>,
     <path2>, … — consider archiving or deleting these manually.`
   - `agent_docs/project_backlog.md` — skeleton with workflow
     instructions at the top and an empty backlog.
   - `agent_docs/project_decisions.md` — skeleton with
     initialization as the first dated entry.
   - `agent_docs/project_arch.md` — populated from detection +
     interview. Sparse for brand-new projects; the main artifact for
     cloned repos.
   - `agent_docs/.init-version`:
     ```
     version: 1
     initialized: YYYY-MM-DD
     framework: project_docs
     ```

7. **Approval gate.** Show me every draft. Do not write anything to
   disk yet. I may ask for changes on any file — apply them and
   re-show only the files that changed. Wait for explicit approval.

8. **Write and confirm.**
   - If re-bootstrapping (Step 1 nuke path): before deleting
     anything, back up the existing `agent_docs/` folder as
     `agent_docs.pre-init-backup/` (copy the whole tree, not just
     individual files). If that path exists, fall back to
     `agent_docs.pre-init-backup-YYYY-MM-DD/`; if that also exists,
     append `-2/`, `-3/`, etc. Only after the backup completes,
     remove the old `agent_docs/`.
   - If a `CLAUDE.md` already existed at the project root, back it
     up as `CLAUDE.md.pre-init-backup` before overwriting. (Use the
     same date/counter fallback if a backup already exists.)
   - Create `agent_docs/` if needed.
   - Write all five content files and `.init-version`.
   - Tell me what was written, explicitly list every backup path
     that was created (both `agent_docs/` and `CLAUDE.md`), and
     remind me that `/wrap-up` now routes updates across the four
     files.

## Templates

### `CLAUDE.md` (lightweight pointer, not an architecture dump)

```markdown
# <project name>

<1–2 sentence description>

## Session continuity

At session start, read `agent_docs/project_state.md` — it's the
dashboard. Load on demand when the task calls for it:
- `agent_docs/project_arch.md` — architecture, stack, layout. The
  source of truth for how the project is built.
- `agent_docs/project_decisions.md` — locked-in decisions,
  append-only.
- `agent_docs/project_backlog.md` — planned work.

## Build / test / run

<commands from detection or interview>

## Project-specific Claude instructions

<things that affect how Claude behaves in this project — not what
the project is. Leave blank if nothing special.>
```

### `project_state.md` (target ~50 lines, ceiling ~100)

```markdown
# Project State

Last updated: YYYY-MM-DD

## Currently building
<1–3 sentences on the active focus. "Between tasks" is fine.>

## Next up
1. <item>
2. <item>
3. <item>

## Last session
YYYY-MM-DD — Initialized project_docs framework.

## Open questions
<active only. Answered questions get removed, not struck through.>
```

### `project_backlog.md`

```markdown
# Project Backlog

## How to pull from this file

When I ask you to "tackle section X" or "pick up backlog item Y":
1. Read only the item in question plus any items it references.
2. Check the item's status marker — skip if `done` or `blocked`
   without first unblocking.
3. Re-read `project_arch.md` if the item touches architecture.
4. Check `project_decisions.md` for constraints that shape the
   approach.
5. Before implementing, confirm scope with me if the item is more
   than a few weeks old — conditions may have changed.

Each item carries: scope, affected files, staging (if multi-stage),
model recommendation (Sonnet/Opus), design decisions, status
(triaged / planning / in-progress / blocked / done).

## Items

<empty for now>
```

### `project_decisions.md`

```markdown
# Project Decisions

Append-only. Once written, entries are not revised. Superseding
decisions are new dated entries that reference the old one.

---

## YYYY-MM-DD — Initialized project_docs framework
- Adopted the project_docs session-continuity framework: `CLAUDE.md`
  + `agent_docs/` split across state / backlog / decisions / arch.
```

### `project_arch.md`

```markdown
# Project Architecture

## Purpose
<elevator pitch — 2–3 sentences>

## Stack and versions
<language, runtime, key deps with versions>

## Layout
<folder/solution structure — one level, with role per folder>

## Key subsystems
<named subsystems and how they interact. Skip if not yet
applicable.>

## Security invariants
<things that must always hold — encryption defaults, secret
handling, input validation boundaries. Leave blank until
established.>

## Runtime layout
<processes, services, ports, external dependencies. Skip if N/A.>

## Known gaps / out of scope
<things deliberately not handled yet, or not this project's job>
```

## Notes

- Approval gate stays on. Never write without explicit confirmation.
- Bias toward less content. Skeleton files are fine; padding them
  with fake content is not. No lorem ipsum, no placeholder TODOs
  left behind.
- Don't run `/wrap-up` or `/clear` automatically — always tell me to
  do it.
- If something's ambiguous, ask rather than guess.
