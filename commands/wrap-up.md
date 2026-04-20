---
name: wrap-up
description: Summarize this session and route updates across the agent_docs/ four-file framework
framework: K9-Claude-Framework
framework_version: 1.1.1
command_version: 1.1.0
codex_skill_version: 1.1.0
last_updated: 2026-04-19
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

7. **Write the approved files.**

8. **Remind me what's next.** Tell me I can now start a new session
   (Claude Code: `/clear` or restart `claude`; Codex: start a new
   session). Don't run `/clear` yourself — that's my call.

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
