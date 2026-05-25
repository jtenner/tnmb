# Agent TODO: TELNET Test Blind Spots Active Backlog

**Finished tasks do not belong in this file.** This file is only for active, incomplete, independently actionable work. When a task is completed, remove it from this file instead of adding completion notes, historical run logs, or reproduction details. Completed work belongs in tests, docs, git history, commit messages, or issue/PR discussion.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes. In this workspace, the installed `moon` may require the local `moon.mod` metadata-key workaround documented in the current thread.

## Backlog policy

- Keep only unfinished work here.
- Remove each item once the corresponding tests/docs are merged.
- Prefer executable production-API tests over fixture-only tests.
- Do **not** add self-equality, fixture-only, or tautological assertions.
- Do **not** change production code unless the user explicitly approves it later.
- If a proposed normative test exposes a real bug/design gap, either:
  - add a passing characterization test for current behavior, or
  - document the failing normative expectation in `docs/wiki/test-plan-negotiator-session.md` or another test-plan doc.
- Keep tests deterministic and target-stable across wasm/js/native.
- Update `docs/wiki/09-verification-corpus.md` and `docs/wiki/conformance-matrix.md` whenever adding new test files or materially new coverage areas.

## Validation commands for future agents

Use the local `moon.mod` workaround when running full validation:

```sh
cp moon.mod /tmp/tnmb.moon.mod.bak && \
  awk '/^(readme|repository|license|keywords|description) =/ {next} {print}' moon.mod > /tmp/tnmb.moon.mod.new && \
  mv /tmp/tnmb.moon.mod.new moon.mod && \
  moon info && moon fmt && moon test && moon test --target js && moon test --target native; \
  code=$?; mv /tmp/tnmb.moon.mod.bak moon.mod; exit $code
```

Also run:

```sh
bash tools/check-test-tautologies.sh
grep -nP 'assert_true\((.*) == \1\)' *_test.mbt *_wbtest.mbt || true
grep -niE 'fixture-first|do not call production|without adding production|future production tests' *_test.mbt *_wbtest.mbt || true
git diff --check
```

## Active work slices

No active missing-test slices remain.
