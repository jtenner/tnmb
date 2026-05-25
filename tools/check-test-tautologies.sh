#!/usr/bin/env bash
set -euo pipefail

# Reject obvious no-op MoonBit tests such as `assert_true(x == x)` and stale
# fixture-only comments. This catches the old fixture self-check pattern without
# trying to prove all tests are meaningful.

mapfile -t files < <(git ls-files '*_test.mbt' '*_wbtest.mbt')
fail=0

if ((${#files[@]} == 0)); then
  echo "No MoonBit test files found."
  exit 1
fi

if grep -nP 'assert_true\((.*) == \1\)' "${files[@]}"; then
  echo "Self-equality assertions found above."
  fail=1
fi

if grep -niE 'fixture-first|do not call production|without adding production|future production tests' "${files[@]}"; then
  echo "Stale fixture-only comments found above."
  fail=1
fi

if ((fail)); then
  exit 1
fi

echo "No obvious no-op tests found."
