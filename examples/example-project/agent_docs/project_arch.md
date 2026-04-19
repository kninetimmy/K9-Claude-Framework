# Project Architecture

## Purpose

`log-filter` is a cross-platform command-line tool that reads log
files and emits the subset of entries matching user-specified
filters (level, date range, source). Built as a learning project
and as a practical tool for searching large server logs without
loading them into memory.

## Stack and versions

- .NET 9 (SDK 9.0.x)
- xUnit 2.x for tests
- `System.CommandLine` (preview) for CLI parsing
- `System.Text.Json` for the (planned) JSON output mode
- No other NuGet dependencies

## Layout

```
log-filter/
├── LogFilter.sln
├── src/
│   ├── LogFilter.Cli/        entry point, argument parsing
│   └── LogFilter.Core/       parsing, filtering, streaming pipeline
├── tests/
│   └── LogFilter.Tests/      xUnit suite for Core (Cli is thin)
├── .github/workflows/
│   └── ci.yml                build + test on push
└── agent_docs/               session-continuity framework
```

## Key subsystems

### LogFilter.Core.Parsing

Reads log files line by line and emits `LogEntry` records via
`IAsyncEnumerable<LogEntry>`. Supports three level conventions
(lowercase `info`, uppercase `INFO`, bracketed `[INFO]`) and
ISO-8601 timestamps. Zone handling currently preserves original
zone; planned shift to UTC normalization (see
`project_backlog.md`).

### LogFilter.Core.Filters

Pipeline of filters applied to the parser output. Each filter
implements `ILogFilter`, which exposes a single
`bool ShouldInclude(LogEntry)` method. Filters compose via a
simple chain: every filter must include the entry for it to pass.

Current filters: `LevelFilter`. Planned: `DateRangeFilter`,
`SourceFilter`.

### LogFilter.Cli

Thin shell. Parses CLI arguments into a `FilterOptions` object,
constructs the filter chain, wires it to the parser, and streams
matching entries to stdout. No business logic — it's a translation
layer between `args` and `LogFilter.Core`.

## Security invariants

- No arbitrary file paths are shelled out. File I/O uses
  `File.OpenRead` with the user-supplied path, which .NET handles
  safely for path traversal.
- No external process execution.
- No network I/O in v1.

## Runtime layout

Single process, single executable. Reads one file at a time
(streamed), writes to stdout. No background workers, no ports, no
services.

## Known gaps / out of scope

- Multi-file input (only one file per invocation in v1).
- Structured log formats beyond plain text (JSON log *input* is
  out of scope; JSON *output* is a backlog item).
- Log rotation / live tail (`--follow`) — blocked, backlog item.
- Remote log sources (S3, HTTP, etc.) — not planned.
