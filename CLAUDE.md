# RAMMonitor — Rules for Claude

<!-- HARNESS:BEGIN — managed by claude-harness, do not edit this block -->

Inherits every rule in `~/.claude/CLAUDE.md` and `~/claude-projects/CLAUDE.md`. Only project deltas go below; duplicating global rules makes maintenance lossy.

## Project MUST DO

1. **Verify before committing** — run `swift test` (suite in `tests/RAMMonitorTests`; CI runs it on every push to main), plus a `./bundle.sh` live check for UI changes.

## Project PREFER

1. **Assess blast radius before broad changes** — if a task touches 10+ files, consider breaking it up.
2. **Structural/architectural changes** — suggest new rules and wait for review before restructuring.

<!-- HARNESS:END -->

---

## Project-Specific Rules

<!-- Add your project-specific rules below. Everything above this line is managed by claude-harness. -->


