# Project State

Last updated: 2026-04-15

## Currently building

Wiring up the `--since` / `--until` date filters for `log-filter`.
Level filter (`--level`) is already live. The date-filter work is
mid-stream; the tokenizer handles ISO-8601 but we're still deciding
how to treat log lines with missing or malformed timestamps.

## Next up

1. Finish `--since` / `--until` filter wiring in
   `LogFilter.Core.Filters`.
2. Add test fixtures for mixed-zone timestamps.
3. Draft the `--source` filter (filter by named log source).

## Last session

2026-04-15 — Added the `--level` CLI flag end-to-end (commits
a3f2b1c, 8c9d4e2). Includes xUnit coverage for
`LevelFilter.ShouldInclude`. Partial work on `--since`: flag parses
but downstream filter is stubbed.

2026-04-12 — Set up project scaffolding. Solution, three projects
(Cli / Core / Tests), GitHub Actions workflow for build + test. No
functional code yet.

## Open questions

- How do we handle log lines with no timestamp? Drop, pass through,
  or error? Leaning "pass through" with a warning but not committed.
- Do we need streaming JSON output? Backlog item exists but may not
  ship in v1.
