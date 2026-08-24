#!/usr/bin/env bash
# Smoke test for scripts/review-lock.sh
#
# Covers:
#   1. `status` reports unlocked when no lock exists.
#   2. `with -- <cmd>` acquires the lock, runs the command, and releases it
#      afterward (verified via `status` before/after and the lock dir).
#   3. A second/concurrent acquire while the lock is held is rejected with
#      exit 75.
#   4. `with` without the `--` separator fails with a non-zero (usage) exit.
#
# Runs against an isolated NEXUM_ROOT under a fresh temp directory so the
# repo's real .nexum/ state is never touched. Cleans up on exit.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
review_lock="$repo_root/scripts/review-lock.sh"

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

export NEXUM_ROOT="$tmp_root/.nexum"
lock_dir="$NEXUM_ROOT/locks/insane-review.lock"

fail_count=0

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1"
  fail_count=$((fail_count + 1))
}

# --- Case 1: status reports unlocked when no lock exists --------------------
status_out="$tmp_root/status-before.out"
if "$review_lock" status >"$status_out" 2>&1; then
  fail "case1: status exited 0 (expected non-zero for unlocked)"
fi
if grep -q '^unlocked$' "$status_out"; then
  pass "case1: status reports unlocked with non-zero exit when no lock exists"
else
  fail "case1: status did not print 'unlocked'"
fi

# --- Case 2: with -- <cmd> acquires, runs, and releases the lock ------------
marker_file="$tmp_root/marker-status-during.out"
if "$review_lock" with -- bash -c "'$review_lock' status > '$marker_file' 2>&1"; then
  pass "case2: with -- <cmd> exited 0 for a successful command"
else
  fail "case2: with -- <cmd> exited non-zero for a successful command"
fi

if grep -q '^locked$' "$marker_file"; then
  pass "case2: status reports locked while command is running inside with"
else
  fail "case2: status did not report locked during with -- <cmd>"
fi

if [[ -d "$lock_dir" ]]; then
  fail "case2: lock directory still exists after with -- <cmd> completed"
else
  pass "case2: lock directory removed after with -- <cmd> completed"
fi

status_after_out="$tmp_root/status-after.out"
"$review_lock" status >"$status_after_out" 2>&1 || true
if grep -q '^unlocked$' "$status_after_out"; then
  pass "case2: status reports unlocked after with -- <cmd> completed"
else
  fail "case2: status did not report unlocked after with -- <cmd> completed"
fi

# --- Case 3: acquiring while the lock is already held is rejected -----------
mkdir -p "$lock_dir"
set +e
"$review_lock" with -- true >"$tmp_root/with-held.out" 2>&1
held_rc=$?
set -e
if [[ "$held_rc" -eq 75 ]]; then
  pass "case3: with -- <cmd> rejected with exit 75 while lock is held"
else
  fail "case3: with -- <cmd> exited $held_rc while lock is held (expected 75)"
fi
rmdir "$lock_dir" 2>/dev/null || rm -rf "$lock_dir"

# --- Case 4: with without the -- separator fails -----------------------------
set +e
"$review_lock" with true >"$tmp_root/with-no-sep.out" 2>&1
no_sep_rc=$?
set -e
if [[ "$no_sep_rc" -ne 0 ]]; then
  pass "case4: with without -- separator fails with non-zero exit"
else
  fail "case4: with without -- separator unexpectedly succeeded"
fi

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "review-lock.smoke.sh: ALL PASS"
  exit 0
else
  echo "review-lock.smoke.sh: $fail_count FAILURE(S)"
  exit 1
fi
