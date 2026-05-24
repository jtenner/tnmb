# Project Agents.md Guide

MoonBit TELNET protocol library: `moonbit-telnet/telnet`.

## Repository map

- `moon.mod.json` — module metadata.
- `moon.pkg` — root library package manifest.
- `telnet.mbt` — public TELNET model/types.
- `api.mbt` — parser, encoder, negotiator, option mapping, and codecs.
- `pkg.generated.mbti` — generated public interface; update with `moon info`.
- `*_test.mbt` / `*_wbtest.mbt` — blackbox and whitebox tests.
- `cmd/main/` — tiny runnable package: `moon run cmd/main`.
- `cmd/bench/` — benchmark package; `main.mbt` is the suite, `time.c` is the
  native timing stub.
- `docs/wiki/` — design/compliance source of truth. Start at
  `docs/wiki/README.md`.
- `.githooks/` — optional hooks: `git config core.hooksPath .githooks`.

## Commands

```sh
moon fmt
moon info
moon test
moon run cmd/main
moon run --target js cmd/bench
moon run --target native cmd/bench
```

Use `moon test --update` only for intentional snapshot updates. Before finishing
code changes, run `moon info && moon fmt` and `moon test`, then inspect `.mbti`
diffs for expected public API changes.

## Benchmarks

Run from the repo root:

```sh
moon run --target js cmd/bench
moon run --target native cmd/bench
```

Benchmarks report elapsed ms, ops/sec, approximate MB/s, and a checksum. Native
benchmark timing depends on `cmd/bench/time.c` via `native-stub`.

## Documentation rules

- Treat `docs/wiki/` as the source of truth for protocol/design decisions.
- Protocol claims should cite RFC Editor, IETF Datatracker, or IANA registry
  URLs in the wiki.
- Each implemented behavior should have a linked wiki section and tests.
- If the IANA option registry changes, update both `docs/wiki/00-sources.md` and
  `docs/wiki/04-options-catalog.md`.

## Conventions

- MoonBit packages live in directories with `moon.pkg`.
- Code is block-style; blocks are separated by `///|`.
- Prefer explicit assertions (`assert_eq`, `assert_true(pattern is Pattern(...))`)
  for stable protocol behavior; use snapshots when outputs are intentionally
  recorded.
- Put deprecated blocks in `deprecated.mbt` when needed.
- Useful tools: `moon ide` for navigation and
  `moon coverage analyze > uncovered.log` for coverage review.
