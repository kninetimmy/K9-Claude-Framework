---
name: init-project
description: Bootstrap a new or cloned project with the project_docs framework (CLAUDE.md or AGENTS.md + agent_docs/)
framework: K9-Claude-Framework
framework_version: 1.1.1
command_version: 1.1.1
codex_skill_version: 1.1.1
last_updated: 2026-04-19
---

Set up this project with the project_docs framework: a lightweight
session-continuity system split across `$CONTEXT_FILE` and four files in
`agent_docs/`.

## CLI Detection

Run this block first, before any other step. The variable table it produces
is the only source of CLI-specific values used throughout this command —
never hardcode paths or filenames inline.

**Signal 1 — `CLAUDECODE` env var (most reliable).**
Run: `echo "${CLAUDECODE}"`
- Output is `1` → **Claude Code confirmed.** Set the variable table and proceed.
- Output is empty → not in a Claude Code session. Continue to Signal 2.

**Signal 2 — `~/.codex/` directory.**
Run: `test -d "${HOME}/.codex" && echo "exists" || echo "absent"`
- `exists` → **Codex CLI confirmed.** Set the variable table and proceed.
- `absent` → continue to Signal 3.

**Signal 3 — `codex` binary (excluding Claude plugin cache).**
Run: `command -v codex 2>/dev/null | grep -v '\.claude/plugins' || echo "absent"`
- Non-empty path (not `absent`) → **Codex CLI confirmed.** Set variables and proceed.
- `absent` → continue to Signal 4.

**Signal 4 — Framework marker files.**
Run: `ls "${HOME}/.claude/.k9-framework-version" 2>/dev/null && echo "claude" || echo "absent"`
Run: `ls "${HOME}/.codex/.k9-framework-version" 2>/dev/null && echo "codex" || echo "absent"`
- One file exists → that CLI. If both exist, the one more recently modified wins
  (`ls -t "${HOME}/.claude/.k9-framework-version" "${HOME}/.codex/.k9-framework-version" 2>/dev/null | head -1`).

**Signal 5 — Fallback.**
None of the above matched. Ask: "I could not detect your CLI environment.
Are you running Claude Code or Codex? Reply `claude-code` or `codex`."
Wait for response before continuing.

---

### Variable table

Once the CLI is identified, set every value below. Reference **only** these
variables in subsequent steps — never substitute CLI names or paths inline.

| Variable                | Claude Code                          | Codex                                  |
|-------------------------|--------------------------------------|----------------------------------------|
| `$CLI`                  | `claude-code`                        | `codex`                                |
| `$CONTEXT_FILE`         | `CLAUDE.md`                          | `AGENTS.md`                            |
| `$OTHER_CONTEXT_FILE`   | `AGENTS.md`                          | `CLAUDE.md`                            |
| `$COMMANDS_DIR`         | `~/.claude/commands/`                | `~/.agents/skills/`                    |
| `$MARKER_FILE`          | `~/.claude/.k9-framework-version`    | `~/.codex/.k9-framework-version`       |
| `$INVOKE_INIT`          | `/init-project`                      | `$init-project` (or `/skills` picker)  |
| `$INVOKE_WRAP`          | `/wrap-up`                           | `$wrap-up` (or `/skills` picker)       |
| `$INVOKE_CHECK`         | `/check-init`                        | `$check-init` (or `/skills` picker)    |

---

## Steps

1. **Detect whether the project is already initialized.** Check for
   `agent_docs/.init-version`.

   **If `.init-version` exists, evaluate these cases in order:**

   - **Already initialized for current CLI:** All four `project_*.md`
     files are present AND `$CONTEXT_FILE` exists with pointers to all
     four files → refuse politely. Tell me to use `$INVOKE_WRAP` to
     update state, or `$INVOKE_CHECK` to verify health. Stop here.

   - **Cross-CLI scenario:** `$CONTEXT_FILE` is absent, but
     `$OTHER_CONTEXT_FILE` exists and references
     `agent_docs/project_state.md`. The project was initialized for
     the other CLI. Offer:
     > "This project is already initialized for the other CLI
     > (`$OTHER_CONTEXT_FILE` + `agent_docs/`). Add `$CLI` support
     > by writing `$CONTEXT_FILE` alongside it?"
     - **(a) Yes** — read the existing `agent_docs/project_arch.md`
       and `agent_docs/project_state.md` for context, draft only
       `$CONTEXT_FILE` (using the template below), show it for
       approval, then write it. Do NOT touch `agent_docs/` or
       `$OTHER_CONTEXT_FILE`. Skip to Step 7 (approval gate). After
       writing, remind me that both CLIs now share the same
       `agent_docs/` — `$INVOKE_WRAP` updates work regardless of
       which CLI I use.
     - **(b) No** — exit without changes.
     Wait for my pick before continuing.

   - **Drifted:** `.init-version` exists, `$CONTEXT_FILE` is missing or
     missing pointers, AND the cross-CLI condition above does not apply.
     Show me what's out of spec and offer two choices: **(a) nuke**
     `agent_docs/` + `$CONTEXT_FILE` and re-bootstrap from scratch, or
     **(b) leave everything alone** and exit. No silent migration. Wait
     for my pick.
     - If I pick (a), tell me up front exactly what will happen:
       the existing `agent_docs/` folder will be backed up as
       `agent_docs.pre-init-backup/` (preserving full structure),
       `$CONTEXT_FILE` will be backed up as
       `$CONTEXT_FILE.pre-init-backup` (if it exists), **and
       `$OTHER_CONTEXT_FILE` will be backed up as
       `$OTHER_CONTEXT_FILE.pre-init-backup`** (if it exists), before
       anything is deleted. If those backup paths already exist from a
       previous init, append a date suffix
       (`agent_docs.pre-init-backup-YYYY-MM-DD/`); if that also
       exists, append a counter (`-YYYY-MM-DD-2/`, `-3/`, …).

2. **Classify the project state.** If `.init-version` doesn't exist,
   decide which path this is:
   - **Brand new** — mostly empty folder, no source, no README.
   - **Existing cloned repo** — has source, README, build configs,
     and/or an existing `$CONTEXT_FILE`.

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
     `CONTEXT.md`, `NOTES.md`, `.cursorrules`, `.windsurfrules`,
     `GEMINI.md`.
   - `AGENT*.md` files and `AGENTS.md`:
     - If `$CLI == claude-code`: flag `AGENTS.md` and `AGENT*.md` as
       foreign signals. Only exception: if `AGENTS.md` references
       `agent_docs/project_state.md`, it was written by this framework
       in a prior Codex session — treat it as a potential migration
       candidate, not a foreign system.
     - If `$CLI == codex`: `AGENTS.md` is this framework's own context
       file. Only flag it as foreign if it exists and does NOT reference
       `agent_docs/project_state.md`.
   - `CLAUDE.md`: flag as foreign only if it does NOT reference
     `agent_docs/project_state.md`. (Same logic for both CLIs — a
     framework-written `CLAUDE.md` from a prior Claude Code session is
     a migration candidate, not a foreign system.)

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
   - `$CONTEXT_FILE` (template below — use the section matching `$CLI`)
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
   - Back up any existing context files before overwriting: if
     `$CONTEXT_FILE` exists, back it up as
     `$CONTEXT_FILE.pre-init-backup`; if `$OTHER_CONTEXT_FILE` exists,
     back it up as `$OTHER_CONTEXT_FILE.pre-init-backup`. (Use the
     same date/counter fallback for each if a backup already exists.)
   - Create `agent_docs/` if needed.
   - Write the approved content files.
   - Tell me what was written, explicitly list every backup path
     that was created, and remind me that `$INVOKE_WRAP` now routes
     updates across the four files.

## Templates

### `$CONTEXT_FILE` (lightweight pointer, not an architecture dump)

Use the template that matches `$CLI`:

---

**If `$CLI == claude-code` — write as `CLAUDE.md`:**

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

---

**If `$CLI == codex` — write as `AGENTS.md`:**

```markdown
# <project name>

<1–2 sentence description>

## Session continuity

At the start of every session, read `agent_docs/project_state.md` —
it is the dashboard. Load on demand when the task calls for it:
- `agent_docs/project_arch.md` — architecture, stack, layout. The
  source of truth for how the project is built.
- `agent_docs/project_decisions.md` — locked-in decisions,
  append-only.
- `agent_docs/project_backlog.md` — planned work.

## Build / test / run

<commands from detection or interview>

## Project-specific instructions

<things that affect how this agent behaves in this project — not what
the project is. Leave blank if nothing special.>
```

---

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
- Adopted the project_docs session-continuity framework: `$CONTEXT_FILE`
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
- Don't run `$INVOKE_WRAP` or `/clear` automatically — always tell me to
  do it.
- If something's ambiguous, ask rather than guess.
