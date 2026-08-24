#!/usr/bin/env bash
# Smoke test for scripts/run-init.sh
#
# Covers:
#   1. Successful init creates the expected directory tree + run-state.yaml
#      with status: PLANNED.
#   2. Invalid run-id is rejected (non-zero exit).
#   3. Duplicate run-id (second init call for the same id) is rejected
#      (non-zero exit).
#
# Runs against an isolated NEXUM_ROOT under a fresh temp directory so the
# repo's real .nexum/ state is never touched. Cleans up on exit.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
run_init="$repo_root/scripts/run-init.sh"

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

export NEXUM_ROOT="$tmp_root/.nexum"

fail_count=0

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1"
  fail_count=$((fail_count + 1))
}

# --- Case 1: successful init -------------------------------------------------
run_id="smoke-run-ok"
out_file="$tmp_root/init-ok.out"
if "$run_init" "$run_id" >"$out_file" 2>&1; then
  run_dir="$NEXUM_ROOT/runs/$run_id"
  if [[ -d "$run_dir/contracts" && -d "$run_dir/research" && \
        -d "$run_dir/verification" && -d "$run_dir/reviews" && \
        -d "$run_dir/findings" ]]; then
    pass "case1: expected subdirectories created"
  else
    fail "case1: expected subdirectories missing under $run_dir"
  fi

  if [[ -f "$run_dir/run-state.yaml" ]] && grep -q '^status: PLANNED$' "$run_dir/run-state.yaml" \
     && grep -q "^run_id: $run_id$" "$run_dir/run-state.yaml"; then
    pass "case1: run-state.yaml has run_id and status: PLANNED"
  else
    fail "case1: run-state.yaml missing or malformed"
  fi

  if grep -q "Initialized $run_dir" "$out_file"; then
    pass "case1: prints Initialized <run_dir>"
  else
    fail "case1: did not print expected Initialized message"
  fi
else
  fail "case1: run-init.sh exited non-zero on a fresh valid run-id"
fi

# --- Case 2: invalid run-id is rejected --------------------------------------
if "$run_init" '/bad id!' >"$tmp_root/init-invalid.out" 2>&1; then
  fail "case2: invalid run-id was accepted (expected non-zero exit)"
else
  pass "case2: invalid run-id rejected with non-zero exit"
fi

if [[ -e "$NEXUM_ROOT/runs//bad id!" ]]; then
  fail "case2: invalid run-id unexpectedly created a run directory"
fi

# --- Case 3: duplicate run-id is rejected ------------------------------------
if "$run_init" "$run_id" >"$tmp_root/init-dup.out" 2>&1; then
  fail "case3: duplicate run-id was accepted (expected non-zero exit)"
else
  pass "case3: duplicate run-id rejected with non-zero exit"
fi

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "run-init.smoke.sh: ALL PASS"
  exit 0
else
  echo "run-init.smoke.sh: $fail_count FAILURE(S)"
  exit 1
fi
