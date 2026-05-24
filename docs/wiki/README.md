# Telnet MoonBit Wiki

This directory is the source-of-truth wiki for the MoonBit Telnet library.
Treat these pages as living design records: implementation tasks, tests, and
public APIs should point back here before code is merged.

## Wiki map

- [00-sources.md](00-sources.md) — normative RFC/IANA source inventory and update policy.
- [01-project-scope.md](01-project-scope.md) — implementation scope, non-goals, and release phases.
- [02-protocol-model.md](02-protocol-model.md) — TELNET byte stream, NVT model, commands, and parser events.
- [03-option-negotiation.md](03-option-negotiation.md) — WILL/WON'T/DO/DON'T negotiation and RFC 1143 Q method.
- [04-options-catalog.md](04-options-catalog.md) — option support matrix and per-option implementation notes.
- [05-moonbit-architecture.md](05-moonbit-architecture.md) — proposed package structure and public API shape.
- [06-testing-compliance.md](06-testing-compliance.md) — compliance tests, fixtures, fuzz/property strategy.
- [07-maintenance.md](07-maintenance.md) — wiki stewardship, source updates, release checklist.
- [08-test-first-type-scope.md](08-test-first-type-scope.md) — test-first API surface and performance-oriented type inventory.
- [09-verification-corpus.md](09-verification-corpus.md) — provenance and coverage notes for the initial test-fixture corpus.

## Rules for maintaining the wiki

1. Every protocol claim must cite a normative RFC Editor, IETF Datatracker, or IANA registry URL.
2. Each implemented behavior should have a linked wiki section and at least one test fixture.
3. When the IANA option registry changes, update `00-sources.md` and `04-options-catalog.md` in the same change.
4. Avoid copying large RFC text into the repo; summarize and link to the authoritative document.
