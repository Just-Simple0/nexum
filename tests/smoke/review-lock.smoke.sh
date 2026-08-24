#!/usr/bin/env bash
# Smoke test for scripts/review-lock.sh
#
# Covers:
#   1. `status` reports unlocked when no lock exists.
#   2. `acquire` holds a manual lock for a skill invocation and `release`
#      clears it afterward.
#   3. `with -- <cmd>` acquires the lock, runs the command, and releases it
#      afterward (verified via `status` before/after and the lock dir).
#   4. A second/concurrent acquire while the lock is held is rejected with
#      exit 75.
#   5. `with` without the `--` separator fails with a non-zero (usage) exit.
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

# --- Case 2: acquire/release supports a non-shell skill invocation ----------
if "$review_lock" acquire >"$tmp_root/acquire.out" 2>&1; then
  pass "case2: acquire created a manual review lock"
else
  fail "case2: acquire exited non-zero"
fi

if [[ -d "$lock_dir" ]]; then
  pass "case2: lock directory exists after acquire"
else
  fail "case2: lock directory does not exist after acquire"
fi

if "$review_lock" release >"$tmp_root/release.out" 2>&1; then
  pass "case2: release removed the manual review lock"
else
  fail "case2: release exited non-zero"
fi

# --- Case 3: with -- <cmd> acquires, runs, and releases the lock ------------
marker_file="$tmp_root/marker-status-during.out"
if "$review_lock" with -- bash -c "'$review_lock' status > '$marker_file' 2>&1"; then
  pass "case3: with -- <cmd> exited 0 for a successful command"
else
  fail "case3: with -- <cmd> exited non-zero for a successful command"
fi

if grep -q '^locked$' "$marker_file"; then
  pass "case3: status reports locked while command is running inside with"
else
  fail "case3: status did not report locked during with -- <cmd>"
fi

if [[ -d "$lock_dir" ]]; then
  fail "case3: lock directory still exists after with -- <cmd> completed"
else
  pass "case3: lock directory removed after with -- <cmd> completed"
fi

status_after_out="$tmp_root/status-after.out"
"$review_lock" status >"$status_after_out" 2>&1 || true
if grep -q '^unlocked$' "$status_after_out"; then
  pass "case3: status reports unlocked after with -- <cmd> completed"
else
  fail "case3: status did not report unlocked after with -- <cmd> completed"
fi

# --- Case 4: acquiring while the lock is already held is rejected -----------
mkdir -p "$lock_dir"
set +e
"$review_lock" acquire >"$tmp_root/acquire-held.out" 2>&1
held_rc=$?
set -e
if [[ "$held_rc" -eq 75 ]]; then
  pass "case4: acquire rejected with exit 75 while lock is held"
else
  fail "case4: acquire exited $held_rc while lock is held (expected 75)"
fi
rmdir "$lock_dir" 2>/dev/null || rm -rf "$lock_dir"

# --- Case 5: with without the -- separator fails -----------------------------
set +e
"$review_lock" with true >"$tmp_root/with-no-sep.out" 2>&1
no_sep_rc=$?
set -e
if [[ "$no_sep_rc" -ne 0 ]]; then
  pass "case5: with without -- separator fails with non-zero exit"
else
  fail "case5: with without -- separator unexpectedly succeeded"
fi

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "review-lock.smoke.sh: ALL PASS"
  exit 0
else
  echo "review-lock.smoke.sh: $fail_count FAILURE(S)"
  exit 1
fi
