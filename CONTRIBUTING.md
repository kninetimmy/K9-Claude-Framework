# Contributing

K9-Claude-Framework is a personal project maintained by one person. I'm
not actively recruiting contributors, but if you want to help, PRs and
issues are welcome — just understand that response time varies.

## Filing an issue

- **Bug reports** should include a minimal reproduction: which command,
  what project state, what happened vs. what you expected. Version info
  from `/check-init` is helpful.
- **Feature requests** — open an issue to discuss before writing code.
  A lot of ideas that sound useful turn out to conflict with the "curate
  don't accumulate" design goal, and I'd rather surface that up front
  than reject a finished PR.

## Pull requests

- Keep changes scoped. One logical change per PR.
- Shell scripts should pass `shellcheck`.
- Markdown should be readable as plain text — no clever formatting
  tricks that only render on GitHub.
- If you touch a command file, bump its `command_version` in the
  frontmatter. If a change is framework-wide, bump `framework_version`
  in `VERSION`, all three command files, and add a `CHANGELOG.md`
  entry.
- No CLA. No code of conduct file. Be decent.

## What's explicitly out of scope

- Auto-update / phone-home checks. The framework is pull-based on
  purpose. If you want that behavior, fork.
- Non-Markdown content files. Binaries, images, audio — not a fit.
- Anything that adds a runtime dependency. Shell scripts and Markdown
  only.
