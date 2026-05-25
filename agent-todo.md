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

### Slice 1 — RFC 1143 duplicate-disable receive characterization

- Add or extend negotiator tests for duplicate `DONT`/`WONT` received while the corresponding local/remote half is already disabled.
- Use production `Negotiator::receive` APIs only; do not assert against hand-built fixtures without exercising the implementation.
- If current behavior emits a reply where RFC 1143 would no-op, keep the executable test as a passing current-behavior characterization and ensure the normative expectation remains documented in `docs/wiki/test-plan-negotiator-session.md`.
- Update `docs/wiki/09-verification-corpus.md` and `docs/wiki/conformance-matrix.md` if a new test file or materially new coverage category is added.

### Slice 2 — RFC 1143 positive replies to pending enable requests

- Add focused sequence tests for pending local and remote enable requests receiving positive replies (`DO` for local enable, `WILL` for remote enable).
- Verify state settlement, emitted actions, and no accidental mutation of the pre-receive negotiator value.
- Characterize current duplicate affirmative replies if present; do not change production code in this slice.
- Cross-link any remaining normative expectation to `docs/wiki/test-plan-negotiator-session.md`.

### Slice 3 — RFC 1143 queued-opposite `WantNo` transitions

- Add tests for `WantNo(QueueBit::Opposite)` on both local and remote halves.
- Cover the peer reply that completes the disable/refusal and the expected handling of the queued enable request.
- Prefer small table-driven helpers inside an existing negotiator characterization file rather than broad generated fixtures.
- If behavior differs from RFC 1143, keep passing current-behavior characterization and document the normative delta.

### Slice 4 — RFC 1143 queued-opposite `WantYes` transitions and race sequences

- Add stateful tests for `WantYes(QueueBit::Opposite)` on local and remote halves.
- Include at least one simultaneous local/remote enable-disable race sequence proving bounded sends and loop-prevention behavior.
- Assert exact resulting `HalfState`s and emitted `NegotiationAction`s after each step.
- Keep the tests deterministic and target-stable.

### Slice 5 — Safe invalid-span hardening coverage for public parser/codec entry points

- Review `docs/wiki/test-plan-negotiator-session.md` raw invalid `ByteSpan` gaps and add only non-panicking, executable characterization tests.
- Candidate safe cases: empty invalid spans, constructor-clamped spans, invalid spans that should be rejected before indexing, and direct codec decode calls that can return errors safely.
- Do not add expected-panic tests unless the MoonBit harness gains expected-panic support.
- If an unsafe shape cannot be tested safely, leave it documented rather than forcing a crashing test.

### Slice 6 — Encoder `assume_capacity` contract characterization

- Add additional safe tests around `Encoder::encode_data_assume_capacity` and `Encoder::encode_subnegotiation_assume_capacity` with mismatched `required` values.
- Use buffers large enough to avoid panic while asserting reported `bytes_written`, trailing-byte behavior, and canonical encoded bytes.
- Document any low-level contract ambiguity in `docs/wiki/test-plan-negotiator-session.md` or a more specific encoder test-plan section.
- Do not change production API semantics without explicit user approval.

### Slice 7 — Session-boundary test plan refinement

- Expand `telnet_session_boundary_characterization_test.mbt` or the session test-plan docs for behavior that cannot exist until a public `Session` abstraction is approved.
- Cover planned scenarios at the boundary level only: directional BINARY policy handoff, START_TLS plaintext blocking responsibility, decoded subnegotiation policy callbacks, and combined parser/negotiator/action event streams.
- Keep executable tests limited to current parser, codec, negotiator, and encoder APIs.
- Do not introduce a `Session` type in this slice.

### Slice 8 — CI target-coverage follow-up

- Decide whether CI should run `moon test --target js` and `moon test --target native` in addition to default `moon test`.
- If CI is updated, keep the local `moon.mod` metadata-key workaround in mind and avoid making generated `.mbti` churn unless expected.
- Add or adjust target-parity tests only if they expose a concrete gap not already covered by `telnet_native_scanner_stress_test.mbt` or `telnet_target_parity_codec_encoder_test.mbt`.
- Validate with the full command block above before removing this slice.

### Slice 9 — Optional coverage-guided fuzzing campaign

- Run the experimental native fuzz harness outside the default test suite when an appropriate fuzzer is available.
- Use `tools/build-fuzz-native.sh` and the seed workflow documented in `docs/wiki/06-testing-compliance.md`.
- Promote any discovered failure into a small deterministic regression test with a named seed/wire literal.
- Do not commit long-running fuzzer outputs or `_build` artifacts.
