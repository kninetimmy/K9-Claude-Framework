# Project Decisions

Append-only. Once written, entries are not revised. Superseding
decisions are new dated entries that reference the old one.

---

## 2026-04-12 — Initialized project_docs framework
- Adopted the project_docs session-continuity framework:
  `CLAUDE.md` + `agent_docs/` split across state / backlog /
  decisions / arch.

## 2026-04-12 — .NET 9 over Go or Rust
- Picked .NET 9 because the developer's primary environment is
  Windows with deep .NET experience, cross-platform publish works
  cleanly for Linux/macOS targets, and the BCL covers every
  dependency needed for a log CLI (file I/O, regex, command-line
  parsing).
- Considered Go for the simpler cross-compile story but the
  velocity cost of a less-familiar language outweighed the build
  simplicity.

## 2026-04-12 — Single-file publish, no external runtime
- Ship via `dotnet publish -c Release -r <rid> --self-contained
  true -p:PublishSingleFile=true`. Users shouldn't need to install
  a .NET runtime.
- Trade-off: binaries are ~60 MB per platform. Acceptable for a
  CLI tool distributed via GitHub releases.

## 2026-04-14 — Use System.Text.Json, not Newtonsoft
- `System.Text.Json` ships in-box with .NET, has no external
  dependency, and our payloads are trivial (no polymorphism, no
  custom converters). Newtonsoft is richer but adds a dependency
  we don't need.
- Revisit only if we hit a missing feature that would cost more to
  work around than to migrate.
