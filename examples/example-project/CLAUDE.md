# log-filter

A small cross-platform CLI that reads log files and filters lines by
level, date range, and source. Built in .NET 9.

## Session continuity

At session start, read @agent_docs/project_state.md — it's the
dashboard. Load on demand:
- `agent_docs/project_arch.md` — architecture, stack, layout
- `agent_docs/project_decisions.md` — locked-in decisions
- `agent_docs/project_backlog.md` — planned work

## Build / test / run

- `dotnet build` — build the solution
- `dotnet test` — run xUnit test suite
- `dotnet run --project src/LogFilter.Cli -- --help` — show CLI usage

## Project-specific Claude instructions

- Keep the CLI dependency-light. No extra NuGet packages without
  checking first — we're staying close to the .NET base class library.
- Prefer `IAsyncEnumerable<T>` over materialized `List<T>` for
  anything streamable. Log files can be large.
