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

### Normalize log timestamps to UTC
- **Scope.** `LogParser` reads ISO-8601 timestamps but currently
  preserves whatever zone the log line carries. Downstream filters
  don't always compare correctly across zones. Normalize to UTC at
  parse time; preserve original-zone string for display only.
- **Affected files.** `src/LogFilter.Core/Parsing/LogParser.cs`,
  `src/LogFilter.Core/LogEntry.cs`,
  `tests/LogFilter.Tests/Parsing/LogParserTests.cs`
- **Model.** Sonnet is fine.
- **Status.** planning

### `--source` filter flag
- **Scope.** Add a `--source <name>` CLI flag that filters entries
  whose `Source` field matches. Case-insensitive. Multiple
  `--source` occurrences OR together.
- **Affected files.** `src/LogFilter.Cli/CommandLineOptions.cs`,
  `src/LogFilter.Core/Filters/SourceFilter.cs` (new),
  `tests/LogFilter.Tests/Filters/SourceFilterTests.cs` (new)
- **Status.** triaged

### Streaming JSON output mode
- **Scope.** Add a `--json` flag that emits matched entries as
  line-delimited JSON instead of the default text format. One entry
  per line. Use `System.Text.Json`.
- **Status.** triaged
- **Note.** May not ship in v1 — open question in
  `project_state.md`.

### `--follow` mode (tail-like)
- **Scope.** Poll the input file and emit matching lines as they
  arrive, similar to `tail -f | grep`. Deferred until the core
  filter set is stable.
- **Status.** blocked
- **Blocker.** Need file-watcher story first. Revisit after date
  filters ship.
