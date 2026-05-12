---
name: wrap-up
description: Summarize this session and route updates across the agent_docs/ four-file framework
framework: K9-Claude-Framework
framework_version: 1.2.0
command_version: 1.2.0
codex_skill_version: 1.2.0
last_updated: 2026-05-12
---

Update the agent_docs/ framework to capture this session's work, so a
fresh instance can pick up cleanly after starting a new session.

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

**Signal 5 — Project context file.**
Check which framework context file exists at the project root:
Run: `ls CLAUDE.md AGENTS.md 2>/dev/null`
- Only `CLAUDE.md` found → **Claude Code.**
- Only `AGENTS.md` found → **Codex CLI.**
- Both found → the one that references `agent_docs/project_state.md` was written
  by this framework; prefer it. If both reference it, fall back to Signal 6.

**Signal 6 — Fallback.**
None of the above matched. Ask: "I could not detect your CLI environment.
Are you running Claude Code or Codex? Reply `claude-code` or `codex`."
Wait for response before continuing.

---

### Variable table

Once the CLI is identified, set every value below. Reference **only** these
variables in subsequent steps — never substitute CLI names or paths inline.

| Variable         | Claude Code                          | Codex                                  |
|------------------|--------------------------------------|----------------------------------------|
| `$CLI`           | `claude-code`                        | `codex`                                |
| `$CONTEXT_FILE`  | `CLAUDE.md`                          | `AGENTS.md`                            |
| `$COMMANDS_DIR`  | `~/.claude/commands/`                | `~/.agents/skills/`                    |
| `$MARKER_FILE`   | `~/.claude/.k9-framework-version`    | `~/.codex/.k9-framework-version`       |
| `$INVOKE_INIT`   | `/init-project`                      | `$init-project` (or `/skills` picker)  |
| `$INVOKE_WRAP`   | `/wrap-up`                           | `$wrap-up` (or `/skills` picker)       |
| `$INVOKE_CHECK`  | `/check-init`                        | `$check-init` (or `/skills` picker)    |

---

## memhub detection (run after CLI detection, before Step 1)

`memhub` is an optional Rust CLI that stores durable per-repo project memory
(facts, decisions, tasks, audit log) in a local SQLite database. When it is
installed and enabled in this repo, `/wrap-up` mirrors approved updates from
the four Markdown files into memhub so the database stays in sync with the
narrative. memhub is entirely optional — when it isn't there, this command
behaves exactly as it always has.

Run the two checks below, in order. Use the results to set `$MEMHUB_ENABLED`
for the rest of this command.

**Check 1 — binary on PATH.**
Run: `command -v memhub >/dev/null 2>&1 && echo "present" || echo "absent"`
- `absent` → set `$MEMHUB_ENABLED=false`. Skip every memhub-specific note
  in the steps below. Proceed with the pure-Markdown flow.
- `present` → continue to Check 2.

**Check 2 — repo-level gate.**
Run: `memhub integrations check-k9 >/dev/null 2>&1 && echo "enabled" || echo "disabled"`
- `enabled` (exit 0) → `.memhub/project.sqlite` exists AND `[integrations.k9].enabled = true`
  in `.memhub/config.toml`. Set `$MEMHUB_ENABLED=true`.
- `disabled` (any non-zero exit) → set `$MEMHUB_ENABLED=false`. The user may have
  memhub installed elsewhere but not enabled in this repo. Skip the memhub path.
  Do not warn — `disabled` is a legitimate state, not an error.

The gate is a contract: when it returns 0, the rest of this command may shell
out to memhub using the v1 CLI contract (`memhub fact add`, `memhub decision
add`, `memhub task add`, `memhub task done`, `memhub review accept`,
`memhub review reject`, all with `--json --actor k9:wrap-up`). When it
returns non-zero, do not call any other `memhub` command in this run.

---

## Steps

1. **Locate the framework.** Look for `agent_docs/.init-version` and
   the four `project_*.md` files.
   - If `.init-version` is missing but a single
     `agent_docs/project_state.md` exists (old format), fall back to
     the old wrap-up behavior: update that one file only. Then
     suggest I run `$INVOKE_INIT` to migrate to the four-file
     framework.
   - If nothing exists, stop. Tell me. Ask if I want to run
     `$INVOKE_INIT`, or if this is a repo where state tracking
     isn't set up.

2. **Read all four files** so you know what's already there and
   don't duplicate or contradict anything.

3. **Check git for ground truth.** Run `git log --oneline` for
   commits since the last "Last session" entry in
   `project_state.md` (or the last ~10 commits if unclear). These
   are what actually shipped — anchor updates to them.

   **If `$MEMHUB_ENABLED=true`, also fetch staged memhub proposals.**
   Run: `memhub review list --status pending --json`
   Parse the `pending_writes` array. Each entry is a `fact` or
   `decision` proposal that a memhub MCP client (a previous Claude Code
   or Codex session over `memhub serve`) staged but a human never
   reviewed. Surface them in the draft assembly: each one is a candidate
   for the same approval gate as the Markdown updates. If the array is
   empty, just note "no pending memhub proposals" in your internal
   tracking and move on.

4. **Route this session's changes across the four files.** Draft
   updates for each file separately. For each, if no changes apply,
   say so explicitly — don't touch the file.

   - **`project_state.md`** — always updated.
     - Update "Last updated" to today.
     - Roll "Currently building" into "Last session." New dated
       entry at the top: 2–4 sentences on what actually got done,
       anchored to commits where possible (short hashes). Note
       notable dead ends — future-me will thank you.
     - Revise "Currently building" to reflect the new state
       ("Between tasks" is fine).
     - Revise "Next up" based on what's genuinely next *now*.
     - Update "Open questions": remove answered ones, add new ones.
     - Prune "Last session" to the 2 most recent dated entries.
       Older history lives in git.

   - **`project_decisions.md`** — append only.
     - For each architectural / security / UI / workflow decision
       locked in this session, ask me: does this go here (settled,
       won't be revisited), or stay in `project_state.md` as
       still-actively-referenced?
     - For ones that go here, append a new dated entry with a short
       rationale. Never revise past entries — superseding decisions
       are new dated entries that reference the old one.

   - **`project_backlog.md`** — status updates + new items.
     - Update status markers on backlog items touched this session.
     - Add new backlog items discussed but not yet tackled.

   - **`project_arch.md`** — touch only if architectural changes
     were made this session (new subsystem, changed folder layout,
     new security invariant, stack change). Otherwise leave alone.

5. **Token budget check on `project_state.md`.** After drafting,
   estimate line count. If over ~100 lines, flag it and suggest
   specific migrations — usually a decision ready to move to
   `project_decisions.md`, or older "Last session" entries that can
   drop.

6. **Show me each file's proposed changes separately.** Per-file
   approval: I might approve `project_state.md` but reject
   `project_decisions.md` changes. Do not write until I've approved
   each file individually, or explicitly said "all good."

   **If `$MEMHUB_ENABLED=true`, also show a "memhub mirror plan."**
   For each approved file, list the discrete records that will be
   mirrored to memhub *after* I approve:
   - New `project_decisions.md` entries → `memhub decision add <title> --rationale "..."`
   - New backlog items in `project_backlog.md` → `memhub task add <title>`
   - Backlog items moved to status `done` this session → `memhub task done <id>`
     (look up the memhub task id by title via `memhub review list` /
     `memhub task list` output if shown to you, otherwise ask me)
   - Build/test/run commands or other durable facts captured in
     `project_state.md` or `project_arch.md` → `memhub fact add <key> <value>`
   - Each pending memhub proposal from Step 3 → either
     `memhub review accept <id>` (promote to durable table) or
     `memhub review reject <id> --reason "..."` (drop)

   I approve the mirror plan per item. Items I reject are simply not
   mirrored — the Markdown still goes through. Items I accept are
   queued for the DB-writes-first phase in Step 7.

   If the mapping is fuzzy (a long state-file paragraph isn't a clean
   fact/decision/task), don't force it. Ask me, or omit it from the
   mirror plan. memhub is for structured records; freeform narrative
   stays in the Markdown only.

7. **Write the approved changes — DB writes first, then Markdown.**

   This sequencing is required by the v1 memhub contract:
   `docs/reference/k9-wrap-up-contract.md` in the memhub repo. The
   rationale is that DB writes are durable and recoverable; if memhub
   fails partway through, the user can re-run `/wrap-up` and pick up
   where they left off. Markdown writes after the DB succeeds avoid
   leaving the narrative and database out of sync.

   **Phase a — DB writes (only if `$MEMHUB_ENABLED=true`).**
   For each approved mirror item from Step 6, invoke the matching
   command with `--json --actor k9:wrap-up`. Parse the JSON response
   to recover new row ids. Example shapes:

   ```
   memhub fact add build-command "cargo build" --json --actor k9:wrap-up
   memhub decision add "Adopt the kraken pattern" --rationale "..." --json --actor k9:wrap-up
   memhub task add "Ship K9 contract" --json --actor k9:wrap-up
   memhub task done 3 --json --actor k9:wrap-up
   memhub review accept 4 --json --actor k9:wrap-up
   memhub review reject 5 --reason "stale proposal" --json --actor k9:wrap-up
   ```

   Any non-zero exit from any of these commands is a **hard abort**.
   Stop here. Do not write any Markdown. Tell me which command failed,
   what stderr said, and that the DB writes that did succeed are
   durable — I can fix the cause and re-run `/wrap-up` to pick up the
   rest.

   **Phase b — Markdown writes.** Write the approved files to
   `agent_docs/*.md` exactly as they were approved.

   **Phase c — refresh memhub managed block (only if `$MEMHUB_ENABLED=true`).**
   After the four agent_docs files are written, run `memhub sync-md` to
   regenerate the `<!-- memhub:managed:start -->` block in
   `$CONTEXT_FILE` so it reflects the new DB state. Treat any non-zero
   exit as informational, not a hard abort — the durable writes already
   landed, sync-md is a view refresh.

8. **Remind me what's next.** Tell me I can now start a new session
   (Claude Code: `/clear` or restart `claude`; Codex: start a new
   session). Don't run `/clear` yourself — that's my call.

   If `$MEMHUB_ENABLED=true`, also remind me I can audit what got
   written via `memhub stats --window 7d` (groups writes by actor and
   table) or `memhub review list --status all` for pending-write
   triage.

## Notes

- Bias toward less content. A tight, true summary beats a long,
  padded one. If this session was mostly exploration with no
  concrete outcomes, say so — don't invent accomplishments.
- If I worked on something that shouldn't go in the state doc
  (experiments, throwaway branches, personal scratch), ask before
  including it.
- Summarizing a session unsupervised is where hallucinated
  accomplishments creep in. The approval gate is the defense —
  don't skip it.
- Don't touch `project_arch.md` for routine session updates. It's
  the stable reference. Only architectural shifts belong there.
- The memhub path is opportunistic. If `command -v memhub` fails, or
  `memhub integrations check-k9` returns non-zero, behave exactly as
  pre-1.2.0 — pure-Markdown flow, no DB writes, no `sync-md`. Never
  install memhub on the user's behalf; never call any other memhub
  subcommand when the gate is closed.
- The DB-writes-first ordering is not arbitrary. It is the v1 contract
  in the memhub repo; deviating means risking Markdown that says one
  thing and a DB that says another after a failure.
